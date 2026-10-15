<!--
Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
All rights reserved.

SPDX-License-Identifier: BSD-3-Clause
-->

# Browser demos — version 3

Version 3 adds transparent viewport controls for MicroDuck, G1, and ANYmal-D.
Hold the Move and Turn joysticks, or use their arrow keys; release to stop.
MicroDuck starts standing. Drag its robot to apply a fixed 2 N horizontal push;
drag the background to orbit, and scroll to zoom. Touch supports steering and
turning together. Pause and reset sit in the viewport's upper corner.

The viewer reuses the unchanged version 1 and version 2 physics, policies, and
geometry. Deploy all three directories together. No simulation rebuild is
required for this UI update. The release archive retains earlier versions.

MicroDuck's pinned native task, physics adaptations, policy and asset provenance,
and rebuild instructions are documented in the
[reference source PR #7974](https://github.com/isaac-sim/IsaacLab/pull/7974).
