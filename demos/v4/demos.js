// Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
// All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause

import { demos as releasedDemos } from '../v3/demos.js';

export const demos = releasedDemos.map((demo) => ({
  ...demo,
  assetRoot: demo.id === 'microduck' ? './browser_demos' : demo.assetRoot,
  preview: demo.id === 'microduck' ? './browser_demos/previews/microduck.jpg' : demo.preview,
}));
