// Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
// All rights reserved.
//
// SPDX-License-Identifier: BSD-3-Clause

import { StiffnessViewer } from '../../v1/css/stiffness-viewer.js';
import { addIsaacLabGround } from '../../v1/css/browser-ground.js';

export class MpmViewer extends StiffnessViewer {
  static async load(canvas, simulation) {
    const viewer = new MpmViewer(canvas, simulation);
    try {
      // The tub's inner floor is z=0; its base rests on the checker ground.
      const thickness = simulation.manifest.isaacLabDemo.tub.thickness;
      viewer.disposeGround = await addIsaacLabGround(viewer.scene, -thickness);
      return viewer;
    } catch (error) {
      viewer.dispose();
      throw error;
    }
  }
}
