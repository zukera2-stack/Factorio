# AI handoff — ElectrifiedMainline 0.1.24 accepted visual milestone

**Updated:** 2026-11-15. Repository: [zukera2-stack/Factorio](https://github.com/zukera2-stack/Factorio). **Current `main` mod version 0.1.24, [PR #8 merged](https://github.com/zukera2-stack/Factorio/pull/8), merge SHA `43dd05a544a02de75f3b4a3c3689cd795f853d21`**. Prior 0.1.8 ZIP preserved as historical rollback; all next development should branch from updated `main`.

## What was verified

User's actual Factorio **2.1.20 build 87512** ran `ElectrifiedMainline 0.1.24` on `ВСМ.zip`, accepted the look and asked for merge. Screenshot shows native cursor shaft, composites of lattice shaft + directional G arm, bluish ghosts and subtle colored circular diagnostic markers. Log: manual placement, ghost creation, robot placement, Undo and Redo, no Lua exception. **Test is scoped, not exhaustive**. [Exact test evidence and SHA](tests/catenary-mast-0.1.24-user-accepted-2026-11-15.md) · [CI artifact](https://github.com/zukera2-stack/Factorio/actions/runs/43738070195/artifacts/14171451634).

Historical rail upgrade + Undo/Redo working 0.1.8 test: [26 straight/8 curved and blueprint](tests/undo-0.1.8-2026-11-12.md); do not treat it as a new full regression of all rail paths in 0.1.24.

## Current graphics architecture (DO NOT undo casually)

- `ElectrifiedMainline/prototypes/power_019.lua`: real 1×1 Factorio `electric-pole`, native `pictures` one shared C lattice shaft `graphics/entity/35kv/pole-native-mast-024.png` and base shadow, 1 wire connection point matching direction count; `maximum_wire_distance=0`, `supply_area_distance=0`. The native picture powers ordinary placement cursor and ghost shaft blur. Do not set it transparent again, or re-enable obsolete `placeable_position_visualization` as an alternate world model.
- `ElectrifiedMainline/scripts/power_019.lua`: real masts draw **only eight C arm/insulator overlays**, chosen by `scripts/mast_facing_022.lua` using RailEnd projection; render layer `higher-object-above`, offset `{0,-2.53125}`. Preserve user artistic preference **SOUTH≈EAST silhouette**, **NORTH≈WEST silhouette**. On a mast with no nearby custom HSR, facing defaults to east.
- `ElectrifiedMainline/scripts/ghost_mast_023.lua`: `entity-ghost` arm-only blue-tinted overlay anchored to ghost with cleanup on bot revival, cancellation/Undo and save migration. Native Factorio draws shaft's own ghost. Never add duplicate full shaft Lua draw.
- `ElectrifiedMainline/scripts/catenary_cursor_018.lua`: conventional native build and advisory muted circular markers, not green signal-grid proxy. 64×64 `graphics/icons/35kv-mast-south-icon-64.png` comes from SOUTH C.
- Original eight `pole-*-012.png` full frames retained as reproducibility/rollback. New nine 0.1.24 sprites verified 512×384 RGBA via [scripts/sprites/verify_024.py](../scripts/sprites/verify_024.py) and [manifest](builds/024-art-manifest.json).

## IMPORTANT: status boundaries

- **Real power is NOT IMPLEMENTED**: `energized=NO`, `transfer_MW=0`; rendered contact/messenger wires are cosmetic. A substation-looking prototype does not imply MW transfer. Batteries, regeneration and grid-corridor exchange remain future work.
- No Factorio rail signal/proxy ghosts as support placement, no scripted fake Undo join, no capsule-based placement. Ghosts and robot mining/building belong to native engine.
- Full 0.1.24 rail geometry, P2 hanger-to-contact-wire alignment, multiplayer, interrupted bot jobs, separate rail-replacement selection tool and half-diagonal Upgrade Planner regression remain unverified. Do not infer them from the one screenshot.
- `docs/PROJECT_STATE.yaml` records both current accepted state and historical 0.1.8 evidence; previous obsolete trial status logs are accessible via Git history, not current authority.

## Next task (proceed only when requested)

**Visual overhead contact + messenger lines**: check anchor P2 over rail on all eight orientations (especially curves A/B and half-diagonal), realistic hanging point and spans, without touching newly accepted shaft/ghost graphics or rail mechanics. Then design actual power integration as a separate project phase. Start new feature branch off `main`, keep `main` as proven checkpoint. After changes, run GitHub Actions Lua/PNG/ZIP tests and real Factorio gameplay, record evidence.

[Current status](STATUS.md) · [architecture](ARCHITECTURE.md) · [build manifest](BUILD_024.yaml) · [0.1.24 gameplay](tests/catenary-mast-0.1.24-user-accepted-2026-11-15.md) · [contributor rules](../AGENTS.md).

## Post-merge source of truth

The `main` branch at merge `43dd05a544a02de75f3b4a3c3689cd795f853d21` contains 0.1.24. [Build #43748406702](https://github.com/zukera2-stack/Factorio/actions/runs/43748406702) **PASS**, [download nested 0.1.24 ZIP from artifact #14175755233](https://github.com/zukera2-stack/Factorio/actions/runs/43748406702/artifacts/14175755233), [documentation CI #43748406753](https://github.com/zukera2-stack/Factorio/actions/runs/43748406753) **PASS**. `info.json` matches the YAML canonical project version. The original user screenshot and log remain attachments to the 2026-11-15 conversation; checksums in [test record](tests/catenary-mast-0.1.24-user-accepted-2026-11-15.md).
