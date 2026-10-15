// Copyright (c) 2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
// All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause

import { demos as releasedDemos } from '../v1/demos.js';

export const demos = [
  ...releasedDemos.map((demo) => ({ ...demo, assetRoot: '../v1/browser_demos' })),
  { id: 'microduck', title: 'MicroDuck walking', group: 'Policy control',
    description: 'Walk through a miniature courtyard using native BAM servos. Steer or give the robot a gentle mouse push.' },
];
