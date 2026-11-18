> **0.1.49 planning branch:** [development plan](plans/HSR_VISUAL_049.md). Gameplay payload remains stable 0.1.48 until actual implementation. Pantograph/rail/locomotive artwork research and visual approval before code. No new build requested.

> **Stable main 0.1.48, owner-approved merge [PR #27](https://github.com/zukera2-stack/Factorio/pull/27), commit `7218360acb4fc5079e48cf4f38448fa086f1af96`.** Live acceptance: actual HSR required, rail ghosts do not restore spans, vanilla rails break spans, native Undo/robots. All game files unchanged by clean packaging; 51 runtime files, 16 PNGs. CI distributable ZIPs only. Factory isolation IDs and real energy transfer remain unverified. Freeze catenary visual behavior. Next development branch: `feature/hsr-rolling-stock-visual-049`, visual HSR rails and locomotive/pantograph (plan-only, no mechanics yet). [Archived branch register](history/BRANCH_ARCHIVE_048.md).

> **0.1.48 live visual continuity accepted by user.** Factorio 2.1.24 build 87808, `factorio-current(9).log`: real HSR required, rail ghosts do not restore wire, vanilla replacement breaks visible span; six rails restored through Undo/robots and two vanilla replacements undone, no Lua errors. Freeze accepted visual scope. Actual network IDs/factory isolation not measured; no MW. User requires all distributable ZIPs built through GitHub Actions; use [clean CI artifact](https://github.com/zukera2-stack/Factorio/actions/runs/44413378503/artifacts/14478116616), not local repacks. [Live evidence](tests/catenary-0.1.48-user-acceptance.md). Draft PR #27 remains separate; main unchanged.

> **Clean 0.1.48 install package verified.** Active test branch `experiment/package-cleanup-048`, draft PR #27; prior PR #26 and stable main unchanged. Build at `6027c9d789cef8b6ba5ee78cce355758e76d50a6`: [run 44413378503](https://github.com/zukera2-stack/Factorio/actions/runs/44413378503), [artifact 14478116616](https://github.com/zukera2-stack/Factorio/actions/runs/44413378503/artifacts/14478116616). Package/CRC and byte comparison passed: 51 runtime files (16 PNGs) identical to original 048, 20 dev files relocated without content changes. 302634 bytes, SHA256 `dfdeeab22c4cfb16cc9ec8e319d8566362cf86478d440ce7d738b55f9f309d15`. No gameplay change; scoped live visual acceptance recorded above.

> **Repository cleanup (0.1.48 packaging-only):** game files are isolated in `ElectrifiedMainline/`; manual test guides, QA JSON and developer notes moved with unchanged blobs. `scripts/package_mod.py` rejects unexpected files and verifies every ZIP entry against source bytes. Build ZIP in `build/package/`; atlas in `build/qa/`, separate CI artifact. No Lua, CFG, PNG, info.json or gameplay changes; main untouched. [File map and policy](REPOSITORY_LAYOUT.md).

> **0.1.48 experimental — CI passed; subsequent scoped live visual acceptance recorded above.** User accepted 047 visual scope; 048 preserves candidates/art and displays only confirmed own-script component plus bounded HSR path. Tested code `9afb6beef2c8542d86d4cd8ce6673ed95fe3bf0b`; [build 44411407669](https://github.com/zukera2-stack/Factorio/actions/runs/44411407669), [artifact 14475494795](https://github.com/zukera2-stack/Factorio/actions/runs/44411407669/artifacts/14475494795); docs run 44411407655 successful. ZIP verified: 71 files, 16 PNGs. Draft PR #26, do not merge; live 048 QA and ordinary grid isolation remain outstanding. No MW. Main 0.1.42 unchanged. [Research](research/25kv-visible-connectivity-048.md).

> **0.1.48 experimental — CI passed; subsequent scoped live visual acceptance recorded above.** User accepted 047 visual scope; factorio-current(7).log confirms load, construction, rail removals, native Undo/robot restoration, ghost revival and clean exit, not electrical isolation. 048 preserves 047 candidate policy and 045 art, requires actual confirmed own-script connected component and bounded HSR path before drawing. Ghost forecast uses same planned technical graph, no helper. No voltage condition or MW. Main unchanged. [Research](research/25kv-visible-connectivity-048.md).

> **0.1.47 experimental — CI passed, live game QA pending.** Tested code `8e760a4c6c2d40d7150407f9d05e4795b1badd18`; [build 44408148534](https://github.com/zukera2-stack/Factorio/actions/runs/44408148534), [installable artifact](https://github.com/zukera2-stack/Factorio/actions/runs/44408148534/artifacts/14476051835), docs run 44408148473 successful. ZIP verified, 70 files, 16 PNGs. Draft PR #25, do not merge. Actual HSR gate, visual quality, network ID isolation and large network performance require game QA. Main 0.1.42 unchanged. [Research](research/25kv-relaxed-visual-hsr-gate-047.md).

> **0.1.47 experimental — CI passed, pending game acceptance.** 046 log confirms actual script copper for reported pairs; factory isolation remains unverified. Visual near HSR, max 32 both straight/curve, max two, nearest projected points, no side/tangent/continuous path gate. Technical 40, max five, bounded continuous HSR path, zero native reach and script origin unchanged. Rail edits replan both systems. Placed ghost uses same visual planner. Main 0.1.42 unchanged. [Research](research/25kv-relaxed-visual-hsr-gate-047.md).

> 0.1.46 tested source `1a1f62ee9c805c9919b1ca15beb8fc6c90ea2712`: build 44403984586, docs 44403984565 SUCCESS; [installable artifact](https://github.com/zukera2-stack/Factorio/actions/runs/44403984586/artifacts/14473543411). Actual Factorio script copper/zero-reach isolation and ghost QA pending. Main unchanged. This follow-up commit changes docs only.

> **0.1.46 EXPERIMENTAL / CI passed, not game-tested:** separate zero-native-reach technical poles with bounded script-origin copper links (40 tiles, own types/force/surface, nearest-first max 5); visual art independently uses existing rail graph and 045 PNG landmarks. Single placed ghost predicts existing visual algorithm against real neighbours. No continuous cursor or multi-ghost guarantee; no MW bridge/traction. Main 0.1.42 unchanged. [Research](research/25kv-isolated-network-preview-046.md).

> **0.1.45 EXPERIMENT — pixel-authored attachment geometry, pending game verification. Initial CI corrected historical ghost test version gate; subsequent build 44385067719 passed; corrected atlas panel clipping and expanded diagnostic filter reasons.** Visible endpoints use unchanged 039 arm PNG landmarks and exact console shift, independent of hidden helpers. Steel separate endpoints; near-vertical-only bow. Stable 042 graph, assets, limits, Undo unchanged. `/em-25kv-pairs` logs missing-span evidence. [Research](research/25kv-unified-geometry-045.md). Main stays 0.1.42.

# ACTIVE HANDOFF: EXPERIMENT 0.1.44 — CURVED CATENARY CHORDS

User uploaded 11 Factorio 0.1.43 screenshots on 2026-11-18 (ZIP SHA256 6934acd38ba981a29ac7f093006ace9f84924b010c5e53082c507899345c5313), showing protruding conductors, pipe-thick steel and weak-looking droppers on curves. Root cause: 043 Catmull-Rom trace through rail entity centres does not anchor to C-arm registration points. 044 experiment uses contact wire planar chords between original accepted hanger tips on every valid curved/straight graph edge. `scripts/power_019.lua` is restored byte-identically from stable 0.1.42 (SHA256 b3940d1921c990bcca7ea19ac7f73b386ae017bd3c99f1f3911f3bcdb00f1094), preserving existing HSR/Undo graph. Steel y_scale=0.40, copper y_scale=0.48; riveted droppers made slightly wider and denser. Original 12 mast art PNG and 3 original 043 wire textures unchanged, NORTH_DROP=2.02, 32/16/40, native hidden curved graph. Added tests/25kv_curve_chord_044.lua, scripts/verify_044_assets.py, TEST_CURVE_044.txt. All offline results MUST NOT be represented as game acceptance. Do not merge PR until user test. Full report: research/25kv-curved-catenary-screenshot-audit-044.md.

---

# AUTHORITATIVE HANDOFF — STABLE MAIN = Electrified Mainline 0.1.42 (2026-11-18)

**PR #20 merged** into `main` (merge commit `5e2625c49b40f03c1262507e2fbfd8862f91ba7f`). Final clean GitHub Actions build was tested by user, who reports «все работает». Uploaded `factorio-current(3).log` is from Factorio 2.1.24 build 87808. It confirms successful mod and saved-game initialization, two native pole variants, rail-based C-arm facing, robot/ghost construction, Undo and Redo of straight rails, curved rail placement/Undo and no runtime errors. [Test report](tests/catenary-0.1.42-main-acceptance-2026-11-18.md).

Stable sprite set: exactly 16 used PNGs (12 approved 039 masts/arms/icons, three 030 contact/messenger/dropper textures, one actively used native shadow). All unused 012/024 art removed. Mast visual calibration is **`NORTH_DROP=2.02`**. HSR rail graph plus 32 straight / 16 curve / 40 helper reach remains. **Real power MW, electric traction and regeneration are NOT implemented.** New experiments branch from `main`. User acceptance is scoped to their tested game; it does not establish exhaustive multiplayer/rail boundary coverage.

---

## Historical pre-merge notes (older status references below are not current)

# 0.1.42 — очистка исторических изображений (2026-11-18)

По решению пользователя удалены 20 неиспользуемых исторических PNG, старые генераторы мачт 033/035/036 и проверки их устаревшей геометрии. В `prototypes/power_019.lua` активные `pole-south-039.png` и `pole-north-039.png` указаны непосредственно, неиспользуемый `em-35kv-contact-wire-texture` больше не регистрируется. **Тень `pole-shadow-4dir-hr.png` оставлена**, поскольку реально используется движком. Эталонные 12 PNG и три PNG проводов не перерисовывались; `NORTH_DROP=2.02`, ВСМ, 32/16/40, Undo не менялись. См. [аудит](FILE_RELEVANCE_042.md).

---

# Latest handoff — accepted 25 kV C mast visuals 0.1.42 (2026-11-18)

Experimental branch `experiment/25kv-visual-042-accepted` forked from `experiment/25kv-south-art-036`; `main` stable 0.1.24 untouched. User accepted the Factorio 0.1.42 screenshot showing a long SOUTH and a short NORTH mast with their C console/hangers visually aligned. The 0.1.39 alpha-cropped sprite correction provides the active 12 binaries: 2 mast shaft sprites, 8 direction-specific separate cantilevers (rendered with `higher-object-above`) and 2 item icons; `NORTH_DROP=2.02` is the final accepted micro-adjustment. The actual 0.1.42 ZIP source and each new 039 PNG were checked by SHA-256 and transferred to GitHub. Original 024 PNGs remain tracked for history. Historical 033/035/036 sprite generator scripts remain, but their generated PNG outputs are intentionally absent from the 0.1.42 archive; none must regenerate or overwrite 039 assets.

Main gameplay changes are inherited from experimental 0.1.29/0.1.30: 32-cell straight/16-cell curve/40-cell native hidden-connector reach; HSR path connectivity only; separate textured contact/messenger/dropper art on straights, visible native copper on curves; no MW electricity. 0.1.31 runtime `require()` crash was fixed and must stay fixed. 0.1.42 visuals are user-accepted; no evidence of full multi-direction rail graph/Undo regressions in this exact version. User-screenshot evidence: `docs/tests/catenary-visual-0.1.42-user-accepted-2026-11-18.md`. Static asset gates: `scripts/verify_042_assets.py`, `tests/25kv_visual_042.lua`; older 033–036 geometry tests historical-version gated. File roles: `docs/FILE_RELEVANCE_042.md`. Do not merge into main without separate review.

---

# 0.1.36 calibrated native SOUTH mast placement + truss seam repair

User screenshot 21:51:56 at high zoom shows SOUTH standard C mast hanger ~32px ABOVE northern short mast hanger and visual base ~32px ABOVE ground placement marker. Undo the native standard mast/arm -0.40 tile from 0.1.34, not the actual contact wire and not the real native connector (both stay 0.1.35 coordinates). Replace 0.1.35 bicubic-resized truss with module-duplication from original 024 sprite: generated 512x512 `pole-south-lattice-036.png`, exact alpha bbox (224,29,383,429), 54 rows inserted without stretching, 10px seam blend. Branch experiment/25kv-south-art-036, PR draft, main 0.1.24 untouched. HSR 32/16/40, rail continuity, native Undo/Redo unchanged. Need game validation.

---

# 0.1.35 explicit screenshot-based rail-side height correction

User image 2026-11-16_20-21-29.png shows 27px vertical difference between two lower contact conductors at near-identical rail span. Native standard mast (SOUTH side facing NORTH) needs 54 RGBA source rows of truss extension at scale 0.5; footing stays fixed via 512x512 sprite and 64px pad. Independent C arm and CUSTOM sprite contact raised by 0.84375 game tile (27px). Native hidden copper helper returned to original pre-0.1.34 geometry (no -0.40). North short mast untouched. Code on experiment/25kv-south-geometry-035 from 0.1.34; main remains 0.1.24. New generator scripts/sprites/extend_south_035.py and tests/25kv_south_035.lua. All Factorio game acceptance still pending; screenshots need same zoom.

---

# 0.1.34 on latest real screenshots (2026-11-16)

Screenshot archive 2026-11-16_19-08-49.zip shows missing cantilever on shortened north-of-track mast and lower contact/whole mast image on the standard south-of-track side. Fixed native arm overlay for BOTH prototypes, not another sprite edit. Pure shared scripts/mast_visual_034.lua defines north short image shift (+2.20 tiles), standard south image lift (0.40 tiles), and shared helper y adjustment only for north short face=south and standard face=north. No change to rail prototypes, native Undo, C arm PNGs, 32/16/40, traction MW=0. Ghosts now handle both native pole types. Branch experiment/25kv-mast-alignment-034; in-game test pending, main untouched.

---

# 0.1.33 north-of-track independent native shorter mast

Branch experiment/25kv-north-native-033 from 0.1.32. User screenshot 17:46:35 shows north-of-rail mast too high. A separately native placeable electric pole variant uses deterministic cropped original C mast PNG (70 source px removed from lattice middle), image shifted +2.20 tiles, resulting base ~1.11 tiles lower near ballast; native wire helper tip y +2.20, original south masts unchanged. No scripted entity swapping to avoid native Undo/blueprint problems. Item `em-35kv-catenary-pole-north` must be placed manually on north side to test. Factorio 2.1.20 game QA not yet confirmed, 32/16/40 limits and HSR graph retained, main still 0.1.24.

---

# 0.1.32 south-side mast screenshot calibration

Four Factorio 2.1.20 screenshots in user archive 2026-11-16_17-21-40.zip confirm successful 0.1.31 dual contact/messenger/dropper sprite rendering. South-of-track C masts point north. Their sprite wire endpoints are too high versus triangular hangers. New branch experiment/25kv-south-art-032 changes only art-endpoint for north to (-0.22,+0.90) tiles via catenary_art_030.lua visual_point. Real invisible copper connector positions and other 7 faces unchanged. 32 straight /16 curved /40 hidden copper, native Undo, HSR rails, C-mast sprites unchanged. Still no MW traction power. Requires in-game acceptance; main unchanged. Research docs/research/catenary-south-alignment-0.1.32.md.

---

# 0.1.31 critical runtime require fix (2026-11-16)

Actual user `factorio-current(2).log` shows 0.1.30 failure at `catenary_art_030.lua:170` during `control.lua:on_configuration_changed`: dynamic `require("scripts.native_wire_028")` not allowed during gameplay. Fix in `experiment/25kv-catenary-031` by resolving dependency at module load. Simulated game callback test temporarily forbids all `require` after module load, exercises rebuild, sync, tick and cleanup. Do not reuse 0.1.30 ZIP; use 0.1.31. Functional design otherwise unchanged: 32 straight /16 curved /40 reach, hidden real native connectors and textured sprites on straight, vanilla native copper on curved, 25kV only nominal. Main unchanged; real Factorio validation of fix and graphics still needed.

---

# 0.1.30 experimental straight two-wire art

Branch experiment/25kv-catenary-art-030 from 0.1.29. Straight spans real but invisible copper connectors, with original Factorio-style sprites (contact, messenger, droppers); curves retain native visible conductor. Stable main 0.1.24 untouched. Limit straight 32, curved 16, reach 40. No MW. Requires Factorio 2.1.20 in-game verification. Docs/research/catenary-sprite-pilot-0.1.30.md and test guide docs/tests/manual/TEST_ART_030.txt.

---

# 0.1.29 experimental catenary length (2026-11-16)

Branch `experiment/25kv-span-029`, derived from 0.1.28 experiment (not main). User-approved **32 tile straight / 16 tile curves / 40 tile helper reach**. New shared pure module `scripts/catenary_limits_029.lua` controls data/runtime limits. A bounded HSR-only connected rail walk rejects vanilla rail gaps, detours and routes with any curve longer than 16 tiles. The straight 32-tile corridor is sampled ~every 2 tiles; rail middle-removed invalidation range expanded. Preserves user-approved 0.1.27 SOUTH hanger, eight C-mast sprites from 0.1.28 and game native wire. No new textured contact/messenger drawing yet; rendering of the 25kV system is still native copper. No actual AC/MW power. Main 0.1.24 untouched; needs Factorio 2.1.20 screenshots and Undo regressions. Guide `docs/tests/manual/TEST_SPANS_029.txt`. Research `docs/research/long-catenary-spans-0.1.29.md`.

---

# 0.1.28 automatic contact-wire experiment, nominal 25 kV AC

Branch experiment/auto-25kv-028 is based on user-accepted SOUTH 0.1.27. Visible labels for catenary mast and substation now 25 kV; **internal em-35kv-* IDs remain for save compatibility**. Native hidden copper anchors auto-created and connected ONLY from topology graph edges that pass real get_connected_rail on custom ВСМ rail paths; disconnected tracks and no-rail masts excluded. Eight screenshot/sprite-based P2 offsets, only SOUTH user verified; use /em-25kv-tune FACE DX DY; /em-25kv-status reports spans. Manual probe command retired. Previous Lua line drawing stays disabled. 25 kV power, MW bridge and train traction still not implemented. Test guide docs/tests/manual/TEST_AUTO_WIRE_028.txt; research docs/research/auto-catenary-25kv-0.1.28.md. Main 0.1.24 not touched. Draft PR only, no merge before in-game verification.

---

# 0.1.27 experiment — native wire on C-arm insulators, no cosmetic Lua wires

User game tested 0.1.26 Factorio 2.1.20: native visible copper connection confirmed (net 24, contacts 1/1), but wire ends at mast shaft, not triangular insulators. User screenshots support a SOUTH correction of approximately (+1.75,-2.30) tiles from previous helper point. The experiment/native-25kv-wire-027 branch adjusts default SOUTH helper to (+1.75,-0.80) relative to mast; other seven facings provisional. Fine tuning via /em-25kv-probe start DX DY. Removed ALL rendering.draw_line overhead and feeder lines while preserving rail graph and accepted 0.1.24 C-mast sprites/ghosts/Undo. Tracked and orphan 0.1.26 helpers removed during configuration upgrade. No actual 25 kV AC transfer yet. See docs/research/native-copper-wire-alignment-0.1.27.md. DO NOT MERGE prior to new gameplay screenshots.

---

# EXPERIMENT 0.1.26 — native copper-wire endpoints for future 25 kV AC catenary (2026-11-15)

Branch **experiment/native-25kv-wire-026** starts from the accepted 0.1.24 main commit 04a290da, not from the separate 0.1.25 cosmetic-line branch. Probe is for **visual native wiring only**, NOT voltage, MW traction, battery or regeneration. Maintains all main C mast sprites, rail algorithms, native Undo and current thin cosmetic lines. Two hidden zero-collision helper electric poles at projected C-arm tips are created ONLY by /em-25kv-probe start; player-origin copper connector is requested. Status/clear and parent mast removal handle cleanup. PR #9 initial package CI hit the legacy curve test due to a version selector limited to 0.1.24; selector expanded to cover 0.1.26. Offline tests do not establish actual wire visibility; user must test on Factorio 2.1.20 with screenshots and log. See docs/research/native-copper-wire-probe-0.1.26.md and docs/tests/manual/TEST_NATIVE_WIRE_026.txt. Main remains **0.1.24**, approved. Do not merge before successful in-game QA.

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
- Original eight `pole-*-012.png` full frames retained as reproducibility/rollback. New nine 0.1.24 sprites verified 512×384 RGBA by the retired 0.1.24 verifier (now only in Git history) and the [historical manifest](builds/024-art-manifest.json).

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
