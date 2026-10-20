<!--
Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
All rights reserved.

SPDX-License-Identifier: BSD-3-Clause
-->

# Browser demos — version 4

Drag the Move or Turn joystick to its edge to lock a command. Pull it back toward
the center to stop, or press Escape to clear both. Keyboard arrows remain momentary.
Reset and loss of window focus clear all commands. MicroDuck starts standing;
turning from rest adds a visible 0.25 m/s forward command to engage this checkpoint's gait.

MicroDuck walks in the authored MicroDuckWarehouse scene. The Factory subset uses
base-color textures and instanced visual meshes. Display meshes are reduced for
browser rendering; robot CAD surfaces and the policy reuse the unchanged v2 assets.
The exported Newton simulation includes 25 static collision boxes for the room
perimeter, shelf rows, and clutter footprints. This is a compact browser adaptation,
not the complete warehouse dynamics or the original training environment.
MicroDuck's native velocity task is trained on flat/rough terrain, not this warehouse.

Robot dragging applies 2 N horizontally; background dragging orbits the camera.
The scene and texture conversion require the pinned internal warehouse asset only
at build time. Runtime files and third-party notices are included in the release.
Deploy v1, v2, v3, and v4 together; older versions remain unchanged.

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
[Reference source #7974](https://github.com/isaac-sim/IsaacLab/pull/7974) contains the exporters.
