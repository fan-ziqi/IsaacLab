// Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
// All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause

import { demos as releasedDemos } from '../v5/demos.js';

export const demos = [...releasedDemos.map((demo) => ({
  ...demo,
  assetRoot: demo.id === 'microduck' ? '../v5/browser_demos' : demo.assetRoot,
  preview: demo.id === 'microduck' ? '../v5/browser_demos/previews/microduck.jpg' : demo.preview,
})),
  { id: 'dominoes', title: 'Domino cascade', group: 'Rigid-body dynamics', description: 'Topple 24 slabs with a short push. Change friction and compare the cascade.', assetRoot: './browser_demos' },
  { id: 'cable_bending', title: 'VBD cable bending', group: 'Solver and actuator tuning', description: 'Bend a native rod with a tip load. Explore the stiffness of a clamped cable.', assetRoot: './browser_demos' },
  { id: 'ant', title: 'Ant walking', group: 'Policy control', description: 'Steer a published Ant walking policy with the viewport stick. Drag the robot to test its balance.', assetRoot: './browser_demos' },
];
