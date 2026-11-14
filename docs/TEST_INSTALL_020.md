**CURRENT 0.1.20 HOTFIX ZIP (2026-11-14):** [GitHub Actions #43628474166](https://github.com/zukera2-stack/Factorio/actions/runs/43628474166), successful Lua and duplicate-locale property-tree CI, source `52344275baa2d2728a89a40addecf14215ed13c0`, [artifact #14127098330](https://github.com/zukera2-stack/Factorio/actions/runs/43628474166/artifacts/14127098330) containing `ElectrifiedMainline_0.1.20.zip`. Earlier archive #14125619952 FAILS in Factorio: duplicate `[item-name]` etc. **DO NOT INSTALL THE OLD ZIP**. Current hotfix has passed CI but actual Factorio startup and item-local LMB capsule priority are still UNVERIFIED.

**0.1.20 locale load hotfix 2026-11-14:** User Factorio 2.1.20 log on Windows (21:38:34) stops after data-final-fixes with `Failed to load locale: Duplicate key "item-name" in property tree at ROOT` due to duplicate `[item-name]`, `[item-description]`, `[recipe-name]` appended in both `ru.cfg`/`en.cfg`. These sections have been consolidated in their existing blocks. Added `scripts/validate_factorio_locale.py` to CI, which rejects duplicated sections and duplicate keys. The log's `Unknown collision layer "item"` is emitted on fallback loading `core` after Factorio disabled the failed mod, not yet evidence of another defect in the mod. Core capsule/LMB code untouched; engine gameplay of the experiment still unverified. Rebuild 0.1.20 ZIP from new source, REPLACE the previous 0.1.20 ZIP completely. Do not install both; stable main 0.1.8 unchanged.

# Factorio 0.1.20 item-local Left Click experiment

ElectrifiedMainline 0.1.20 -- ITEM-LOCAL LEFT-CLICK FEASIBILITY TEST

Target Factorio 2.1.20 build 87512. Source branch feature/catenary-item-click-probe-020.

IMPORTANT: This is a risky/isolated prototype hypothesis, NOT a completed HSR-only placement release.

The original 35kV mast item remains unchanged; it can still be placed outside HSR via normal LMB.



1. Use a DISPOSABLE save copy. Do not do this on a main save.

2. Obtain one or more existing 35kV mast items. Craft a new distinct item

   "Клик-проба опоры 35 кВ" (recipe 1 real pole -> 1 click-probe).

   The diagnostic item is a CAPSULE with place_result = the SAME original electric pole.

   It is NOT a world entity / proxy / rail signal.

3. Hold ONLY this click-probe item. It should display green/amber/red rail slot squares,

   calculated from four custom HSR rails.

4. FIRST click ordinary LMB on empty terrain FAR (>20 tiles) from any HSR.

   Required PASS: no pole appears and no item disappears.

   If an off-track real pole appears, THIS CONCEPT FAILS: the engine chose place_result

   before capsule_action. STOP; send Factorio log and screenshot. Do not continue.

5. If step 4 passes, click normal LMB directly on a GREEN square near custom HSR.

   Required PASS: one original REAL "em-35kv-catenary-pole" electric-pole at center;

   cursor stack decreases exactly by ONE; log has

   [0.1.20][probe] BUILD_REQUEST and BUILD_RESULT.

6. Immediately Ctrl+Z / Ctrl+Y and inspect Undo target and robot behavior.

7. Check ordinary LMB near vanilla rails, far from all HSR, and on RED/AMBER candidate

   squares: none should place anything from the probe item.

8. Compare geometry on straight, curve A/B, half diagonal and branching parallel rails.

9. If no on_player_used_capsule events / all candidate squares yellow, this is a

   controlled FAILURE, not permission to create fake signals or scripted replacement.

10. Send factorio-current.log and screenshots, exact cursor item count before/after.



This experiment modifies NO actual pole entity, signals, rail prototypes, custom input

bindings, terrain types, or Undo stack. It adds one test ITEM prototype, not world entities.

If it passes, a separate version can discuss changing the existing mast item to this

type, migration of saved inventory/blueprints/robots, and preventing alternative items

from placing the same pole outside HSR. Until then HSR-only is not enforced in mod.



## Verified CI artifact

**Static build: PASS**, [GitHub Actions #43626117619](https://github.com/zukera2-stack/Factorio/actions/runs/43626117619) from source commit `9dde1d23e02991c89dd569297da6d0c55241dbff`. Lua 5.2 syntax and mocked regression tests 0.1.13–0.1.20 passed; `ElectrifiedMainline_0.1.20.zip` created and verified as artifact [#14125619952](https://github.com/zukera2-stack/Factorio/actions/runs/43626117619/artifacts/14125619952). **Not yet game tested**: capsule/placement input priority and off-rail rejection.
