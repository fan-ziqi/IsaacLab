<!--
Copyright (c) 2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
All rights reserved.

SPDX-License-Identifier: BSD-3-Clause
-->

# Interactive demos

Hosted gallery: <https://isaac-sim.github.io/IsaacLab/demos/interactive/>.
The gallery reuses the existing static assets. Only the selected simulation is loaded.

The gallery filters by activity (tuning, policy inference or scripted scenes) and
physics (rigid bodies, VBD or MPM). Categories live in `demos.js`; coupled scenes
can have multiple physics tags. Filters combine, update the URL and survive the
return from a demo. For example, `?activity=policy&physics=vbd` selects both VBD policies.

| Scene | Physics and interaction | Scene preparation |
| --- | --- | --- |
| VBD cable bending | Clamped rod with live bending stiffness and tip load | Ten segments, 0.45 m long, 24 VBD iterations and eight substeps; actual rigid root clamp |
| Franka soft-body policy | Pretrained policy controls an MJWarp arm coupled to a VBD tetrahedral beam; stiffness, target height and bounded mouse pulling | Native `Isaac-Lift-Soft-Franka` observations, relative joint actions, actuators and contacts; published Newton checkpoint |
| Franka cloth policy | Pretrained policy grasps and lifts a VBD sheet through hand/finger contacts; bending, target height and bounded mouse pulling | Native `Isaac-Lift-Cloth-Franka` with a compact 5 × 5 particle grid; published Newton checkpoint; 20 observed nodes as in training |
| Franka cube stacking | Scripted contact grasp and stacking, or manual end-effector control | Contrib Franka scene with aligned 50 mm, 20 g procedural cubes and a matching tabletop collider; native Newton IK sequence |
| MPM material response | Sand, snow, clay and water references falling into a tub | 2,744 particles, 14% smaller radii than the initial preview, at the same block volume and density; finite contact clearance and checker ground beneath the tub base |

The beam and cloth demos run their published RSL-RL actors in the browser using
the existing MLP evaluator. The captured graph builds and normalizes all 93
observations, applies the eight actions and advances native physics. Both grasp
through contacts; the cloth has no attachment. Cube stacking still uses scripted IK.
The visible tabletop matches the native support collider; bench legs are decorative.
Mouse pulling adds a spring force capped at 2 N; it does not edit particle poses.
Changing the material tests policy generalization, not performance on its
original training distribution. Material settings are available in either mode.

For the beam and cloth, physics stays at 120 Hz with two substeps for deformables. Each captured control
step includes four physics steps and one 30 Hz policy decision. Relative arm targets
are reapplied at each native action boundary, preserving the task's update schedule.
Policy mode repeats the five-second training horizon. Manual mode continues until
reset. Rendering runs at up to 30 Hz; playback speed still depends on the device.
The beam uses the native coarse tetrahedralization; more vertices materially
increase the browser CPU cost. Published meshes are fixed in each bundle.

## Control the Franka

Reach, lift, drawer opening, beam lifting and cloth lifting offer **Policy / Manual**.
Cube stacking offers **Scripted / Manual**. The selected mode owns the arm and gripper;
there are no separate policy-grip or release overrides. The reach task has no gripper action,
so it shows movement controls only.

In Manual, focus the viewport and hold **WASD / arrow keys** to move relative to the
camera, **R/F** to raise/lower, **Q/E** to turn, and **G** to open/close the gripper.
**Shift** gives finer movement; **Esc** stops. Releasing movement keys or touch buttons
stops the requested motion. Small screens show a movement pad and gripper button.
Pause and reset stay in the viewport. Reset keeps the selected mode; returning to
Policy hands over the current scene, while selecting Scripted restarts its sequence.

The shared browser IK controller uses exported native joint frames, axes, limits,
mass/COM and actuator stiffness. It writes the existing action inputs, with gravity
compensation and velocity damping; physics and contact handling stay in the same WASM
simulation. The blue marker is the manual target. Joint limits, contacts and actuator
dynamics constrain the actual motion. No joint, rigid-body or particle poses are edited.

The legacy drawer bundle has an overlapping reset pose. Before displaying it, the
controller performs a short IK retreat through 90 steps of the original physics.
Reset performs the same initialization. Its original absolute-action offsets are
retained; the current registered task's EMA controller is a different action profile.

## Rebuild

From the Isaac Lab checkout used for these captures (`380ddac0`), use the
Newton 1.7.0.dev0 / Warp 1.17.0 / MuJoCo Warp 3.14.0 environment.
`scenes.validate_toolchain()` checks these versions and Newton Web revision
`b0795fbe6b46e08a1fea2425699421415ca4cdf1`. Use Emscripten 5.0.3.
Follow the [export guide](../../exporters/README.md) for compiler installation.

```bash
export PYTHONPATH=/path/to/newton-web/src:/path/to/IsaacLab/source/isaaclab_teleop
demo_repo=/path/to/isaaclab-browser-demos
build_dir=/tmp/isaaclab-browser-lab
emxx=/path/to/emsdk/upstream/emscripten/em++
checkpoint_root=https://omniverse-content-production.s3-us-west-2.amazonaws.com/Assets/Isaac/6.2/Isaac/IsaacLab/PretrainedCheckpoints/rsl_rl
curl -fL "$checkpoint_root/Isaac-Lift-Soft-Franka_newtonmjwarpvbdproxy_none_rsl_rl.pt" -o /tmp/vbd-soft.pt
curl -fL "$checkpoint_root/Isaac-Lift-Cloth-Franka_newtonmjwarpvbdproxy_none_rsl_rl.pt" -o /tmp/vbd-cloth.pt
uv run --no-sync python "$demo_repo/exporters/scenes.py" cable_bending --output "$build_dir" --emxx "$emxx"
uv run --no-sync --with 'pytetwild[all]>=0.3,<0.4' python "$demo_repo/exporters/deformable.py" soft --checkpoint /tmp/vbd-soft.pt --output "$build_dir" --emxx "$emxx"
uv run --no-sync python "$demo_repo/exporters/deformable.py" cloth --checkpoint /tmp/vbd-cloth.pt --output "$build_dir" --emxx "$emxx"
uv run --no-sync python "$demo_repo/exporters/stacking.py" --output "$build_dir" --emxx "$emxx"
for kind in reach lift drawer soft cloth stack; do
    uv run --no-sync --with 'pytetwild[all]>=0.3,<0.4' python "$demo_repo/exporters/franka_control.py" \
        "$kind" --output "$build_dir/control/franka_$kind.json"
done
```

Copy the beam/cloth `<name>-web/` outputs to `site/interactive/browser_demos/policy-v1/<name>/`,
stacking to `site/interactive/browser_demos/teleop-v1/franka_stack/`, and the six control JSON
files to `site/interactive/browser_demos/teleop-v1/`. Fresh captures emit `manual-control.json`
beside their build data; use that metadata from the same capture when publishing new
physics. The standalone command above prepares the existing capture profiles.
Replace current bundles at their existing paths and regenerate the publishing checkout.
The publishing script stamps the source commit into cache revisions. Retain the
existing compatibility directories. Other scenes use
`site/interactive/browser_demos/<name>/`.
MPM retains the pinned Newton 1.6.0 / MuJoCo Warp 3.12.0 export toolchain in the
export guide. Rebuild it separately and publish `mpm-web/` under
`site/interactive/browser_demos/grains-v1/mpm/`; the viewer places its checker ground
beneath the tub while the inner floor and collision boundary stay at z=0.
Coupled control copies use a build-local Warp gather adapter because Warp 1.17
CPU graph capture cannot record the original indexed `wp.copy`. It implements
the same gather and restores Newton's helper after capture.

Checkpoint hashes and layer widths are pinned in the exporter. Exports compare
the observation/action adapters to the actual task managers through a native
policy rollout. Float32 operation order and relative-target update boundaries
match the task. They fail if the default policy cannot lift, positions/velocities
become non-finite, or CPU capture differs from eager playback by more than 1 μm.
Native trajectory references cover approach, grasp, lift and hold. `validation.json`
records hashes of the exact browser files associated with `reference.npz`;
keep those build artifacts together when comparing native and WASM execution.
Tetrahedralization is not guaranteed to reproduce an identical mesh on rebuild.
Browser checks verify the actor output, observation formula on the browser's own
state, and learned lifting/tracking with closed-loop inference. Contact trajectories
can diverge between native CPU and WASM due to floating-point differences;
full per-particle equality after grasp is not a suitable cross-platform gate.
In a browser, verify controller handoff, manual pose holding and movement, keyboard
and touch release, gripper contacts, pause/reset, slider persistence, mouse picking,
blur/cancel cleanup, material endpoints, and playback speed. Compare FK with native
reference poses along motion, not only at reset. Stacking must keep the blue cube
at 25 mm and leave the red cube 50 mm above it, within contact-solver tolerance.

## Other contrib candidates

| Candidate | Remaining work before a useful browser demo |
| --- | --- |
| Shoelace | Dual-arm ADMM coupling, contact/sensor bookkeeping and collision preparation need their own CPU/export and performance validation |
| Franka pouring / UR10 particle pushing | Sparse MPM grid operations and collider assets need export support and a measured CPU budget; particle count alone does not bound grid work |
| Factory / assembly | Backend-specific contacts and task controllers need a separate port; no browser parity has been established |

These are source reviews, not claims that those tasks currently export. The
small stack and native VBD policy scenes are the first validated additions here.
