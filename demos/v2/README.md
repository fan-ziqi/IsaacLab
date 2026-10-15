<!--
Copyright (c) 2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
All rights reserved.

SPDX-License-Identifier: BSD-3-Clause
-->

# Isaac Lab browser demos — version 2

[Play MicroDuck](https://isaac-sim.github.io/IsaacLab/demos/v2/?demo=microduck).

MicroDuck uses the native robot and BAM servo implementation from
[Isaac Lab #8270](https://github.com/isaac-sim/IsaacLab/pull/8270), with Pollen Robotics'
published v5 `velstand.onnx` actor. Physics and policy inference run on the browser's CPU.
The shared viewer provides travel and yaw sticks, arrow-key control, play/pause, and reset.
Walk forward and Stand buttons provide useful starting commands. Shift-drag the robot,
or enable Mouse push, to apply a bounded horizontal force; releasing the pointer removes it.

The courtyard uses inexpensive procedural scenery over the task's flat ground.
Its paving and lawn share an edge without overlapping ground layers. The robot keeps
the asset's material colors and flat CAD shading. Mesh reduction must preserve closed
shells, topology, and volume within 2%; otherwise the original CAD mesh is retained.
The trees are decoration.
The robot uses the published whole-body collision variant
so pushes and falls include body contacts. Its geometry, mass, inertia, and BAM
voltage/friction/delay kernels come from the native asset and task.
This export uses MJWarp's built-in collision path: the current exporter does not
relocate the native pointers used by Newton's convex support-map provider.
Encoder bias, IMU misalignment and IMU lag are disabled for deterministic exploration;
the one-control-step joint-velocity observation delay and BAM command delay remain.
Each policy tick advances four 5 ms physics steps through the task's active manager.
The viewer catches up across slower render frames while keeping that control period fixed.
This is a browser demonstration, not a policy validation benchmark; low velocity
commands can produce very little travel with this checkpoint.

The new bundle is about 7.6 MB, including the detailed CAD surfaces. Visual data use gzip
and ordered parts below 1.9 MB. The gallery reuses version 1's existing assets and
Three.js module, and loads the simulation only when a demo is selected.
All version 1 files are retained unchanged in this archive.

## Rebuild

Use Isaac Lab revision `c47ef303990cfc117a9e0053a1a5e6864b46a513` from #8270
and its frozen uv environment. The MicroDuck exporter uses Newton `1.7.0.dev0`
at `5ea82eef6f7911388025a8df6ccdb172e2fed286`, Warp `1.17.0`, and MJWarp `3.14.0`.
It shares `bundle.py` and `manipulation.py` with the existing exporters.
Use the exporters under `docs/contrib/browser_demos` in the public
[reference PR #7974](https://github.com/isaac-sim/IsaacLab/pull/7974).
The source project snapshot is `omniverse/isaac/isaaclab-browser-demos`
at commit `88f03b8`. The pinned native task is still separate from `develop`
while #8270 is open.
Install the internal Newton Web compiler at `b0795fbe6b46e08a1fea2425699421415ca4cdf1`,
ONNX, and ONNX Runtime into that environment; use Emscripten 5.0.3.

```bash
curl -fL https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/velstand.onnx \
    -o /tmp/microduck-velstand.onnx
uv run --no-sync python /path/to/docs/contrib/browser_demos/microduck.py \
    --checkpoint /tmp/microduck-velstand.onnx --output /tmp/microduck-browser-build \
    --emxx /path/to/emsdk/upstream/emscripten/em++
```

Copy `microduck-web/` into `v2/browser_demos/microduck/` and retain
the asset attribution, visual license, and policy license. Serve the complete site
over HTTP for local preview. The exporter checks the checkpoint hash and toolchain,
compares the policy observations with native Isaac Lab, and verifies native and
captured standing/walking and the solver's elapsed time before compiling.

