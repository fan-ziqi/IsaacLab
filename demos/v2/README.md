<!--
Copyright (c) 2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
All rights reserved.

SPDX-License-Identifier: BSD-3-Clause
-->

# Browser demo prototype

[Play MicroDuck](https://maxkra15.github.io/isaaclab-browser-demos/v2/?demo=microduck).

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
This prototype uses MJWarp's built-in collision path: the current exporter does not
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
Version 1 and the Isaac Lab release archive are unchanged.

## Rebuild

Use Isaac Lab revision `c47ef303990cfc117a9e0053a1a5e6864b46a513` from #8270
and its frozen uv environment. The MicroDuck exporter uses Newton `1.7.0.dev0`
at `5ea82eef6f7911388025a8df6ccdb172e2fed286`, Warp `1.17.0`, and MJWarp `3.14.0`.
It shares `bundle.py` and `manipulation.py` with the existing exporters.
Use the [prototype exporters](https://gitlab-master.nvidia.com/omniverse/isaac/isaaclab-browser-demos/-/tree/feature/microduck-browser/exporters)
from the source project's `feature/microduck-browser` branch.
Install the internal Newton Web compiler at `b0795fbe6b46e08a1fea2425699421415ca4cdf1`,
ONNX, and ONNX Runtime into that environment; use Emscripten 5.0.3.

```bash
curl -fL https://huggingface.co/pollen-robotics/microduck-policies/resolve/v5/velstand.onnx \
    -o /tmp/microduck-velstand.onnx
uv run --no-sync python /path/to/exporters/microduck.py \
    --checkpoint /tmp/microduck-velstand.onnx --output /tmp/microduck-browser-build \
    --emxx /path/to/emsdk/upstream/emscripten/em++
```

Copy `microduck-web/` into `v2/browser_demos/microduck/` and retain
the asset attribution, visual license, and policy license. Serve the complete site
over HTTP for local preview. The exporter checks the checkpoint hash and toolchain,
compares the policy observations with native Isaac Lab, and verifies native and
captured standing/walking and the solver's elapsed time before compiling.

## AlphaNIST

The native assembly demo is [Isaac Lab #8421](https://github.com/isaac-sim/IsaacLab/pull/8421).
The actor and board are now available from the public 6.2 asset root.
The exported actor converts to ONNX while preserving its normalization and
attention encoder; comparison with TorchScript passed. Its inputs are robot
history `[1, 195]` and slot history `[1, 5, 10, 40]`, with eight mean actions at 25 Hz.
The native CUDA scene also ran with the public assets and actor.

A faithful static browser demo needs additional physics support: Newton currently
requires CUDA to build and sample the scene's texture SDFs. The CPU launch fails
before capture. The insertion holes, threads, and gear contacts should retain
their SDF geometry; replacing them with convex hulls would change the assembly task.
The required next step is an exportable CPU representation and sampler for those SDFs,
plus relocation of the contact resources.

The useful interaction would be one ten-part board, an assembly progress counter,
play/pause, reset arrangement, and bounded Shift-drag forces on loose parts.
That would expose recovery from displaced parts while preserving the policy's
five-frame histories and ten-slot input contract. Its actor would use ONNX Runtime Web
alongside the shared viewer and force gesture. AlphaNIST is not listed as a runnable
browser demo yet.
