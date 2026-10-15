// Copyright (c) 2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
// All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause

export const demos = [
  { id: 'stiffness', title: 'VBD material stiffness', group: 'Solver and actuator tuning', description: 'Adjust shear, volume stiffness, damping, and gravity on three deformable cubes.' },
  { id: 'cloth_bending', title: 'VBD cloth bending', group: 'Solver and actuator tuning', description: 'Compare cloth sheets draping over rollers with different bending stiffness.' },
  { id: 'rigid_friction', title: 'MJWarp sliding friction', group: 'Solver and actuator tuning', description: 'Change friction on an incline and compare sliding motion with fixed references.' },
  { id: 'joint_pd', title: 'Joint PD tuning', group: 'Solver and actuator tuning', description: 'Tune a suspended arm using step and sine commands and a live tracking plot.' },
  { id: 'mpm', title: 'MPM material response', group: 'Solver and actuator tuning', description: 'Drop 1,728 particles onto a cylinder. Try sand, snow, clay, and water references.' },
  { id: 'cartpole', title: 'Cartpole balancing', group: 'Policy control', description: 'Push a pretrained balancing policy with up to 300 N in either direction.' },
  { id: 'g1', title: 'G1 velocity control', group: 'Policy control', description: 'Command travel and yaw using the published WBC-AGILE policy.' },
  { id: 'anymal', title: 'ANYmal-D velocity control', group: 'Policy control', description: 'Drive a published Isaac Lab Newton policy with travel and yaw controls.' },
  { id: 'franka_reach', title: 'Franka reach', group: 'Manipulation', description: 'Move the target and watch a pretrained joint-position policy reach for it.' },
  { id: 'franka_lift', title: 'Franka lift', group: 'Manipulation', description: 'Watch a pretrained policy lift a cube and adjust its target position.' },
  { id: 'franka_drawer', title: 'Franka drawer opening', group: 'Manipulation', description: 'Play, pause, and reset a pretrained drawer-opening policy.' },
];
