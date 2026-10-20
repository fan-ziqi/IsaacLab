<!--
Copyright (c) 2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
All rights reserved.

SPDX-License-Identifier: BSD-3-Clause
-->

# Version 6: compact native examples

Adds three demos to the existing twelve. Earlier version directories remain unchanged;
the registry reuses their physics, policy, visual and license files.

| Demo | Native source and adaptation | Controls | Chrome CPU step |
| --- | --- | --- | --- |
| Domino cascade | `newton-dominoes`: one row of 24 slabs instead of the 5,640-body logo; native XPBD, 8 substeps × 10 iterations | Topple pulse, friction | 6.6 ms / 16.7 ms budget |
| VBD cable bending | `cables`: one clamped 20-segment rod; native VBD, 8 substeps × 20 iterations | Bending stiffness, downward tip load | 5.9–6.7 ms / 16.7 ms budget |
| Ant walking | `Isaac-Ant`: published Newton RSL-RL actor, native effort drives and foot joint-wrench sensor | Steering stick, direct 100 N mouse/touch push, pause/reset | 0.22 ms / 16.7 ms budget, including actor |

Measured in headless desktop Chrome on an Intel Core Ultra 9 285K. Each kept up with
wall time for a six-second browser run; this is not a mobile performance guarantee.
The first second's maximum native/WASM body-position difference was zero for the
physics lessons and below 0.000001 m for Ant. All 24 dominoes toppled. The cable's
mean tip height over seconds 3–4 changed from 0.293 m at 0.001 N·m/rad to 0.621 m
at 100 N·m/rad with the default load. This is a transient qualitative comparison,
not a calibrated beam measurement.

Ant walks continuously: its trained command is a target direction, not a velocity.
The stick selects ±45°; edge latching and arrow keys reuse the shared joystick.
Pause stops playback. Falling below the native 0.31 m threshold or reaching the
16-second episode limit replays the captured reset; Python task managers are not
exported. Ant's display palette is adjusted for legibility; its geometry and drives
come from the native asset/task. Camera rendering uses Three.js and Isaac Lab's
checker ground textures.

## Rebuild

Use Isaac Lab revision `380ddac0c5b1fed6a50b4e439c24071be8b798fb` in a separate
uv environment, with Newton `1.7.0.dev0`, Warp `1.17.0`, MJWarp `3.14.0`, the pinned
Newton Web checkout `b0795fbe6b46e08a1fea2425699421415ca4cdf1`, and Emscripten `5.0.3`.
Set `PYTHONPATH=/path/to/newton-web/src` in that environment. The exporter checks
the reviewed versions before capture; no compiler is needed to serve a release.

```bash
uv run --no-sync python /path/to/exporters/scenes.py dominoes --output /tmp/browser-v6 --emxx /path/to/em++
uv run --no-sync python /path/to/exporters/scenes.py cable_bending --output /tmp/browser-v6 --emxx /path/to/em++
curl -fL https://omniverse-content-production.s3-us-west-2.amazonaws.com/Assets/Isaac/6.2/Isaac/IsaacLab/PretrainedCheckpoints/rsl_rl/Isaac-Ant_newtonmjwarp_none_rsl_rl.pt -o /tmp/ant-policy.pt
uv run --no-sync python /path/to/exporters/ant.py --checkpoint /tmp/ant-policy.pt --output /tmp/browser-v6 --emxx /path/to/em++
```

Copy only each `*-web/` output to the new version's `browser_demos/<name>/`, alongside
asset attribution/license notices and small previews. Build intermediates and
`reference.npz` trajectories are validation artifacts, not deployment files.
Both scene lessons share parameter controls and the rigid viewer. Ant shares the
captured-policy evaluator, robot viewer and viewport stick; no second framework
or browser inference dependency is added.
