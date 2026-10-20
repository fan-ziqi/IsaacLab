// Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
// All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause

import { demos as releasedDemos } from '../v6/demos.js';

export const activities = [
  { id: 'tuning', label: 'Tuning', description: 'Change material, solver or actuator settings and compare the response.' },
  { id: 'policy', label: 'Policy inference', description: 'Steer pretrained policies, move their targets or test their response to a disturbance.' },
  { id: 'scripted', label: 'Scripted scenes', description: 'Explore contact interactions with a programmed controller.' },
];

export const physics = [
  { id: 'rigid', label: 'Rigid', description: 'Rigid bodies and robots' },
  { id: 'vbd', label: 'VBD', description: 'Soft bodies, cloth and cables' },
  { id: 'mpm', label: 'MPM', description: 'Particle materials' },
];

const releasedCategories = {
  stiffness: { activity: 'tuning', physics: ['vbd'] },
  cloth_bending: { activity: 'tuning', physics: ['vbd'] },
  rigid_friction: { activity: 'tuning', physics: ['rigid'] },
  joint_pd: { activity: 'tuning', physics: ['rigid'] },
  mpm: { activity: 'tuning', physics: ['mpm'] },
  dominoes: { activity: 'tuning', physics: ['rigid'] },
  cartpole: { activity: 'policy', physics: ['rigid'] },
  g1: { activity: 'policy', physics: ['rigid'] },
  anymal: { activity: 'policy', physics: ['rigid'] },
  franka_reach: { activity: 'policy', physics: ['rigid'] },
  franka_lift: { activity: 'policy', physics: ['rigid'] },
  franka_drawer: { activity: 'policy', physics: ['rigid'] },
  microduck: { activity: 'policy', physics: ['rigid'] },
};

const existing = releasedDemos.filter((demo) => !['ant', 'cable_bending'].includes(demo.id)).map((demo) => ({
  ...demo,
  ...releasedCategories[demo.id],
  description: demo.id === 'mpm' ? 'Drop 2,744 fine particles onto a cylinder. Try sand, snow, clay, and water references.' : demo.description,
  assetRoot: demo.id === 'mpm' ? './browser_demos/grains-v1'
    : demo.id === 'dominoes' ? '../v6/browser_demos' : demo.assetRoot,
}));

export const demos = [
  { id: 'cable_bending', title: 'VBD cable bending', group: 'Deformable lab', activity: 'tuning', physics: ['vbd'], description: 'A shorter clamped cable that settles. Tune stiffness and the tip load.', assetRoot: './browser_demos' },
  { id: 'franka_soft', title: 'Franka soft-body policy', group: 'Deformable lab', activity: 'policy', physics: ['rigid', 'vbd'], description: 'A pretrained VBD policy grasps and lifts a flexible beam. Change the target, tune stiffness, or pull the beam.', assetRoot: './browser_demos/policy-v1' },
  { id: 'franka_cloth', title: 'Franka cloth policy', group: 'Deformable lab', activity: 'policy', physics: ['rigid', 'vbd'], description: 'A pretrained VBD policy grasps a cloth sheet with real contacts. Change bending or target height and test recovery.', assetRoot: './browser_demos/policy-v1' },
  { id: 'franka_stack', title: 'Franka cube stacking', group: 'Manipulation', activity: 'scripted', physics: ['rigid'], description: 'Stack cubes with a scripted controller, or take over the arm with keyboard IK.', assetRoot: './browser_demos/teleop-v1' },
  ...existing,
].map((demo) => demo.id.startsWith('franka_')
  ? { ...demo, manualControl: `./browser_demos/teleop-v1/${demo.id}.json` } : demo);
