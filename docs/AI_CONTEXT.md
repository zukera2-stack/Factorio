# 0.1.32 south-side mast screenshot calibration

Four Factorio 2.1.20 screenshots in user archive 2026-11-16_17-21-40.zip confirm successful 0.1.31 dual contact/messenger/dropper sprite rendering. South-of-track C masts point north. Their sprite wire endpoints are too high versus triangular hangers. New branch experiment/25kv-south-art-032 changes only art-endpoint for north to (-0.22,+0.90) tiles via catenary_art_030.lua visual_point. Real invisible copper connector positions and other 7 faces unchanged. 32 straight /16 curved /40 hidden copper, native Undo, HSR rails, C-mast sprites unchanged. Still no MW traction power. Requires in-game acceptance; main unchanged. Research docs/research/catenary-south-alignment-0.1.32.md.

---

# 0.1.31 critical runtime require fix (2026-11-16)

Actual user `factorio-current(2).log` shows 0.1.30 failure at `catenary_art_030.lua:170` during `control.lua:on_configuration_changed`: dynamic `require("scripts.native_wire_028")` not allowed during gameplay. Fix in `experiment/25kv-catenary-031` by resolving dependency at module load. Simulated game callback test temporarily forbids all `require` after module load, exercises rebuild, sync, tick and cleanup. Do not reuse 0.1.30 ZIP; use 0.1.31. Functional design otherwise unchanged: 32 straight /16 curved /40 reach, hidden real native connectors and textured sprites on straight, vanilla native copper on curved, 25kV only nominal. Main unchanged; real Factorio validation of fix and graphics still needed.

---

# 0.1.30 experimental straight two-wire art

Branch experiment/25kv-catenary-art-030 from 0.1.29. Straight spans real but invisible copper connectors, with original Factorio-style sprites (contact, messenger, droppers); curves retain native visible conductor. Stable main 0.1.24 untouched. Limit straight 32, curved 16, reach 40. No MW. Requires Factorio 2.1.20 in-game verification. Docs/research/catenary-sprite-pilot-0.1.30.md and test guide ElectrifiedMainline/TEST_ART_030.txt.

---

# 0.1.29 experimental catenary length (2026-11-16)

Branch `experiment/25kv-span-029`, derived from 0.1.28 experiment (not main). User-approved **32 tile straight / 16 tile curves / 40 tile helper reach**. New shared pure module `scripts/catenary_limits_029.lua` controls data/runtime limits. A bounded HSR-only connected rail walk rejects vanilla rail gaps, detours and routes with any curve longer than 16 tiles. The straight 32-tile corridor is sampled ~every 2 tiles; rail middle-removed invalidation range expanded. Preserves user-approved 0.1.27 SOUTH hanger, eight C-mast sprites from 0.1.28 and game native wire. No new textured contact/messenger drawing yet; rendering of the 25kV system is still native copper. No actual AC/MW power. Main 0.1.24 untouched; needs Factorio 2.1.20 screenshots and Undo regressions. Guide `ElectrifiedMainline/TEST_SPANS_029.txt`. Research `docs/research/long-catenary-spans-0.1.29.md`.

---

# 0.1.28 automatic contact-wire experiment, nominal 25 kV AC

Branch experiment/auto-25kv-028 is based on user-accepted SOUTH 0.1.27. Visible labels for catenary mast and substation now 25 kV; **internal em-35kv-* IDs remain for save compatibility**. Native hidden copper anchors auto-created and connected ONLY from topology graph edges that pass real get_connected_rail on custom ВСМ rail paths; disconnected tracks and no-rail masts excluded. Eight screenshot/sprite-based P2 offsets, only SOUTH user verified; use /em-25kv-tune FACE DX DY; /em-25kv-status reports spans. Manual probe command retired. Previous Lua line drawing stays disabled. 25 kV power, MW bridge and train traction still not implemented. Test guide ElectrifiedMainline/TEST_AUTO_WIRE_028.txt; research docs/research/auto-catenary-25kv-0.1.28.md. Main 0.1.24 not touched. Draft PR only, no merge before in-game verification.

---

# 0.1.27 experiment — native wire on C-arm insulators, no cosmetic Lua wires

User game tested 0.1.26 Factorio 2.1.20: native visible copper connection confirmed (net 24, contacts 1/1), but wire ends at mast shaft, not triangular insulators. User screenshots support a SOUTH correction of approximately (+1.75,-2.30) tiles from previous helper point. The experiment/native-25kv-wire-027 branch adjusts default SOUTH helper to (+1.75,-0.80) relative to mast; other seven facings provisional. Fine tuning via /em-25kv-probe start DX DY. Removed ALL rendering.draw_line overhead and feeder lines while preserving rail graph and accepted 0.1.24 C-mast sprites/ghosts/Undo. Tracked and orphan 0.1.26 helpers removed during configuration upgrade. No actual 25 kV AC transfer yet. See docs/research/native-copper-wire-alignment-0.1.27.md. DO NOT MERGE prior to new gameplay screenshots.

---

# EXPERIMENT 0.1.26 — native copper-wire endpoints for future 25 kV AC catenary (2026-11-15)

Branch **experiment/native-25kv-wire-026** starts from the accepted 0.1.24 main commit 04a290da, not from the separate 0.1.25 cosmetic-line branch. Probe is for **visual native wiring only**, NOT voltage, MW traction, battery or regeneration. Maintains all main C mast sprites, rail algorithms, native Undo and current thin cosmetic lines. Two hidden zero-collision helper electric poles at projected C-arm tips are created ONLY by /em-25kv-probe start; player-origin copper connector is requested. Status/clear and parent mast removal handle cleanup. PR #9 initial package CI hit the legacy curve test due to a version selector limited to 0.1.24; selector expanded to cover 0.1.26. Offline tests do not establish actual wire visibility; user must test on Factorio 2.1.20 with screenshots and log. See docs/research/native-copper-wire-probe-0.1.26.md and ElectrifiedMainline/TEST_NATIVE_WIRE_026.txt. Main remains **0.1.24**, approved. Do not merge before successful in-game QA.

---

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
