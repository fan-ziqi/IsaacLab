// Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
// All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause

import * as THREE from '../../v1/vendor/three.module.min.js';

const up = new THREE.Vector3(0, 0, 1);
const poseMatrix = (pose) => new THREE.Matrix4().compose(
  new THREE.Vector3().fromArray(pose), new THREE.Quaternion().fromArray(pose, 3), new THREE.Vector3(1, 1, 1));

// Six-dimensional damped least squares; the diagonal damping makes this matrix positive definite.
function solve(matrix, value) {
  const lower = new Float64Array(36), result = new Float64Array(6);
  for (let row = 0; row < 6; row++) for (let column = 0; column <= row; column++) {
    let sum = matrix[row * 6 + column];
    for (let k = 0; k < column; k++) sum -= lower[row * 6 + k] * lower[column * 6 + k];
    lower[row * 6 + column] = row === column ? Math.sqrt(sum) : sum / lower[column * 6 + column];
  }
  for (let row = 0; row < 6; row++) {
    let sum = value[row];
    for (let k = 0; k < row; k++) sum -= lower[row * 6 + k] * result[k];
    result[row] = sum / lower[row * 6 + row];
  }
  for (let row = 5; row >= 0; row--) {
    let sum = result[row];
    for (let k = row + 1; k < 6; k++) sum -= lower[k * 6 + row] * result[k];
    result[row] = sum / lower[row * 6 + row];
  }
  return result;
}

export class FrankaControl {
  static async load(simulation, source) {
    const response = await fetch(new URL(source, document.baseURI), { cache: 'no-cache' });
    if (!response.ok) throw new Error(`Manual-control metadata request failed (${response.status})`);
    return new FrankaControl(simulation, await response.json());
  }

  constructor(simulation, description) {
    this.simulation = simulation;
    this.description = description;
    this.chain = description.chain.map((step) => ({
      ...step, parent: poseMatrix(step.parent), child: poseMatrix(step.child).invert(),
      axis: step.axis ? new THREE.Vector3().fromArray(step.axis).normalize() : null,
    }));
    this.keys = new Set();
    this.q = new Float64Array(simulation.binding('joint_q').length);
    this.target = new THREE.Vector3();
    this.rotation = new THREE.Quaternion();
    this.transform = new THREE.Matrix4();
    this.motion = new THREE.Matrix4();
    this.quaternion = new THREE.Quaternion();
    this.position = new THREE.Vector3();
    this.orientation = new THREE.Quaternion();
    this.offset = new THREE.Vector3().fromArray(description.offset);
    this.joints = Array.from({ length: 7 }, () => ({ position: new THREE.Vector3(), axis: new THREE.Vector3() }));
    this.takeover();
    const actual = this.actualPose();
    this.forward(simulation.binding('joint_q'));
    if (this.position.distanceTo(actual.position) > .002 || this.orientation.angleTo(actual.rotation) > .02) {
      throw new Error('Manual kinematics do not match this robot');
    }
  }

  actualPose() {
    const pose = this.simulation.binding('body_q');
    const start = this.description.handBody * 7;
    const rotation = new THREE.Quaternion().fromArray(pose, start + 3);
    return {
      position: this.offset.clone().applyQuaternion(rotation).add(new THREE.Vector3().fromArray(pose, start)), rotation,
    };
  }

  forward(q) {
    const bodies = this.simulation.binding('body_q');
    this.transform.copy(poseMatrix(bodies.subarray(this.description.rootBody * 7, this.description.rootBody * 7 + 7)));
    let joint = 0;
    for (const step of this.chain) {
      this.transform.multiply(step.parent);
      if (step.coordinate !== null) {
        this.quaternion.setFromRotationMatrix(this.transform);
        this.joints[joint].position.setFromMatrixPosition(this.transform);
        this.joints[joint++].axis.copy(step.axis).applyQuaternion(this.quaternion);
        this.quaternion.setFromAxisAngle(step.axis, q[step.coordinate]);
        this.transform.multiply(this.motion.makeRotationFromQuaternion(this.quaternion));
      }
      this.transform.multiply(step.child);
    }
    this.position.copy(this.offset).applyMatrix4(this.transform);
    this.orientation.setFromRotationMatrix(this.transform).normalize();
    return { position: this.position, rotation: this.orientation };
  }

  takeover() {
    this.keys.clear();
    const pose = this.actualPose();
    this.target.copy(pose.position);
    this.rotation.copy(pose.rotation);
    const { qIndices, limits } = this.description;
    this.gripOpen = this.simulation.binding('joint_q')[qIndices[7]] > (limits[7][0] + limits[7][1]) / 2;
  }

  stop() {
    this.keys.clear();
    const pose = this.actualPose();
    this.target.copy(pose.position);
    this.rotation.copy(pose.rotation);
  }

  release(code) {
    const held = this.keys.delete(code);
    if (held && ![...this.keys].some((key) => !key.startsWith('Shift'))) {
      const pose = this.actualPose();
      this.target.copy(pose.position);
      this.rotation.copy(pose.rotation);
    }
    return held;
  }

  step(camera, dt) {
    const pressed = (...codes) => Number(codes.some((code) => this.keys.has(code)));
    const slow = pressed('ShiftLeft', 'ShiftRight') ? .3 : 1;
    const direction = camera.getWorldDirection(new THREE.Vector3());
    const forward = new THREE.Vector3(direction.x, -direction.z, 0).normalize();
    const right = new THREE.Vector3(forward.y, -forward.x, 0);
    const translation = forward.multiplyScalar(pressed('KeyW', 'ArrowUp') - pressed('KeyS', 'ArrowDown'))
      .addScaledVector(right, pressed('KeyD', 'ArrowRight') - pressed('KeyA', 'ArrowLeft'));
    translation.z = pressed('KeyR') - pressed('KeyF');
    if (translation.lengthSq() > 1) translation.normalize();
    this.target.addScaledVector(translation, .12 * slow * dt);
    this.rotation.premultiply(new THREE.Quaternion().setFromAxisAngle(up, (pressed('KeyQ') - pressed('KeyE')) * .7 * slow * dt)).normalize();
    // Bound the requested workspace in the robot frame and prevent a backlog against an obstacle.
    const bodies = this.simulation.binding('body_q');
    const root = poseMatrix(bodies.subarray(this.description.rootBody * 7, this.description.rootBody * 7 + 7));
    this.target.applyMatrix4(root.clone().invert());
    this.target.clamp(new THREE.Vector3(.1, -.65, 0), new THREE.Vector3(.9, .65, 1.1)).applyMatrix4(root);
    const actual = this.actualPose();
    const distance = this.target.distanceTo(actual.position);
    if (distance > .08) this.target.sub(actual.position).multiplyScalar(.08 / distance).add(actual.position);
    const current = this.simulation.binding('joint_q');
    this.forward(current);
    const gravityBias = this.description.descendants.map((descendants, joint) => {
      let torque = 0;
      const { position, axis } = this.joints[joint];
      for (const body of descendants) {
        const center = new THREE.Vector3().fromArray(this.description.centers[body])
          .applyMatrix4(poseMatrix(bodies.subarray(body * 7, body * 7 + 7)));
        const force = new THREE.Vector3().fromArray(this.description.gravity).multiplyScalar(this.description.masses[body]);
        torque += center.sub(position).cross(force).dot(axis);
      }
      return -torque / this.description.stiffness[joint];
    });
    this.q.set(current);
    const jacobian = new Float64Array(42), error = new Float64Array(6);
    for (let iteration = 0; iteration < 6; iteration++) {
      this.forward(this.q);
      const positionError = this.target.clone().sub(this.position).clampLength(0, .025);
      const rotationError = this.rotation.clone().multiply(this.orientation.clone().invert()).normalize();
      if (rotationError.w < 0) rotationError.set(-rotationError.x, -rotationError.y, -rotationError.z, -rotationError.w);
      const sine = Math.hypot(rotationError.x, rotationError.y, rotationError.z);
      if (positionError.lengthSq() < 1e-8 && sine < 1e-4) break;
      const angle = sine > 1e-8 ? 2 * Math.atan2(sine, rotationError.w) / sine : 2;
      error.set([positionError.x, positionError.y, positionError.z,
        .3 * rotationError.x * angle, .3 * rotationError.y * angle, .3 * rotationError.z * angle]);
      for (let column = 0; column < 7; column++) {
        const { axis, position } = this.joints[column];
        const linear = axis.clone().cross(this.position.clone().sub(position));
        [linear.x, linear.y, linear.z, .3 * axis.x, .3 * axis.y, .3 * axis.z]
          .forEach((value, row) => { jacobian[row * 7 + column] = value; });
      }
      const system = new Float64Array(36);
      for (let row = 0; row < 6; row++) for (let column = 0; column < 6; column++) {
        let sum = row === column ? .025 ** 2 : 0;
        for (let joint = 0; joint < 7; joint++) sum += jacobian[row * 7 + joint] * jacobian[column * 7 + joint];
        system[row * 6 + column] = sum;
      }
      const gradient = solve(system, error);
      for (let joint = 0; joint < 7; joint++) {
        let change = 0;
        for (let row = 0; row < 6; row++) change += jacobian[row * 7 + joint] * gradient[row];
        const coordinate = this.description.qIndices[joint];
        const [lower, upper] = this.description.limits[joint];
        this.q[coordinate] = THREE.MathUtils.clamp(this.q[coordinate] + THREE.MathUtils.clamp(change, -.15, .15), lower + .001, upper - .001);
      }
    }
    const { binding, qIndices, defaults, actionMode, actionScale, gripper, limits } = this.description;
    const action = this.simulation.binding(binding);
    const velocity = this.simulation.binding('joint_qd');
    for (let joint = 0; joint < 7; joint++) {
      const coordinate = qIndices[joint];
      const target = current[coordinate] + this.description.motionGain
        * THREE.MathUtils.clamp(this.q[coordinate] - current[coordinate], -1.2 * dt, 1.2 * dt);
      const bias = gravityBias[joint] - this.description.velocityDamping * velocity[this.description.dofIndices[joint]];
      const desired = THREE.MathUtils.clamp(target + bias, limits[joint][0] + .001, limits[joint][1] - .001);
      action[joint] = actionMode === 'relative' ? (desired - current[coordinate]) / actionScale
        : actionMode === 'absolute' ? (desired - defaults[joint]) / actionScale : desired;
    }
    const opening = this.gripOpen ? limits[7][1] : limits[7][0];
    if (gripper === 'relative' || gripper === 'position') for (let joint = 7; joint < 9; joint++) {
      action[joint] = gripper === 'relative' ? (opening - current[qIndices[joint]]) / actionScale : opening;
    }
    else if (gripper !== 'none') action[7] = this.gripOpen ? 1 : -1;
    if (!action.every(Number.isFinite)) throw new Error('Manual controller produced a non-finite target');
  }
}
