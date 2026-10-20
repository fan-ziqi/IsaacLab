<!--
Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
All rights reserved.

SPDX-License-Identifier: BSD-3-Clause
-->

# Browser demos — version 5

Drag the Move or Turn joystick to its edge to lock a command. Pull it back toward
the center to stop, or press Escape to clear both. Keyboard arrows remain momentary.
Reset and loss of window focus clear all commands. MicroDuck starts standing;
turning from rest adds a visible 0.25 m/s forward command to engage this checkpoint's gait.

MicroDuck walks in the authored MicroDuckWarehouse scene. The Factory subset uses
base-color textures and instanced visual meshes. Display meshes are reduced for
browser rendering; robot CAD surfaces and the policy reuse the unchanged v2 assets.
The exported Newton simulation uses convex geometry from enabled authored colliders:
1,868 fixed shapes, including four containment walls, and 12 movable floor props nearest
the starting robot. The remaining 30 floor props and shelf loads stay fixed to keep
CPU work bounded. Free props use nominal 250 kg/m³ density, calculated mass/inertia,
and real MJWarp contacts with the robot, floor, and other objects. Reset restores
their captured state. This is a compact browser adaptation of the static source scene.
MicroDuck's native velocity task is trained on flat/rough terrain, not this warehouse.

Robot dragging applies 2 N horizontally; background dragging orbits the camera.
The scene and texture conversion require the pinned internal warehouse asset only
at build time. Runtime files and third-party notices are included in the release.
Deploy v1 through v5 together; older versions remain unchanged.

## Rebuild

In the pinned #8270 environment documented by the reference source, run:

```bash
uv run --no-sync python /path/to/exporters/warehouse.py --output /tmp/microduck-warehouse
uv run --no-sync python /path/to/exporters/microduck.py \
    --checkpoint /tmp/microduck-velstand.onnx \
    --warehouse /tmp/microduck-warehouse/source/d23d5612652f8635.usdc \
    --output /tmp/microduck-build --emxx /path/to/emsdk/upstream/emscripten/em++
```

The MicroDuck exporter includes the warehouse binary and textures in its output.
Retain all attribution and license files. The release reuses v2 robot meshes and weights;
compare body mapping, topology, geometry, and actor bytes before reusing those files.
Version 5 also reuses the unchanged v4 warehouse binary and textures.
[Reference source #7974](https://github.com/isaac-sim/IsaacLab/pull/7974) contains the exporters.
