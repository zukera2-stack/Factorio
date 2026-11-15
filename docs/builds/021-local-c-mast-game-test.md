> **Historical build report:** The statements below that 0.1.21 C art was not pushed to GitHub were true when the local ZIP was created. The exact 8 gameplay PNGs and shadow are NOW committed to current 0.1.22 source. The redundant old ZIP was later deleted from the active tree, recoverable from [this historical Git commit](https://github.com/zukera2-stack/Factorio/blob/64f81365ae5aa654d9b6cca1598cd30cc98289b3/art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip). The current tested build is 0.1.22, not 0.1.21.

# ElectrifiedMainline 0.1.21 — art-only local test ZIP from approved C mast

**Created:** 2026-11-15. **Requested by user:** Eight art sprites for selected variant C, with south projection east-like and north projection west-like, plus ZIP for gameplay testing.

**Evidence class:** LOCALLY GENERATED ZIP + STATIC ZIP/IMAGE VALIDATION. **No Factorio gameplay proof** and **no GitHub Actions CI run** for these new PNG. Do not mistake locally checked ZIP for an in-game tested build.

## Art decisions
- User explicitly chose variant C, then asked for the full game sprite set and ZIP. Treat this as approval to proceed from C2 concept to art build, **not** approval of final visuals.
- East / South share broad screen-oriented east-looking side-on visual style.
- West / North share broad west-looking side-on visual style.
- Four diagonal frames also provided; each facing sprite is separate.
- Existing rendering (Lua) selects eight facing images based on nearby custom ВСМ rail. New images stay 512×384 RGBA, scale 0.5, common runtime render offset (0,-2.53125).
- P0 foundation aligned at image (~256,365). P2 wire hanger is **not calibrated** against current `scripts/overhead_geometry_012.lua`; wires unchanged.
- Base-only 512×384 shadow replaces old 4-dir atlas's first-frame shadow for this test. Directional cast shadow fidelity still needs in-game review.
- Physical `electric-pole` prototype, click placement, Undo/Redo, Upgrade Planner, train block semantics and contact graph unchanged.

## Exact artifacts and provenance
- Mod ZIP (conversation-local downloadable attachment): `ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip`.
- ZIP size: **654494 bytes**; SHA256 **`234f26cd11a1efa380dd849af2278234db3db90ec23b8049096c66cf0863da42`**.
- Preview PNG: `ElectrifiedMainline_0.1.21_C_mast_preview.png`.
- Conversion source script local to creation runtime: `build_em_021_art.py` (not committed).
- Source compiled from existing, previously game-loaded [0.1.18 GitHub Actions artifact 14115959103](https://github.com/zukera2-stack/Factorio/actions/runs/43601951663/artifacts/14115959103).
- Generated source images were supplied in this conversation by ImageGen and accessible in the original chat. **The image binaries and 0.1.21 ZIP have NOT been pushed to GitHub**. They are downloadable only from the current conversation until a later artifact persistence process. This branch/commit is a documentation checkpoint only.
- The repository's checked-in `ElectrifiedMainline/info.json` remains version 0.1.18. The **local ZIP only** contains modified `info.json` with version 0.1.21. Do not run the repository's build workflow expecting these PNG to appear until they have been committed separately.

## ZIP exact diff against game-tested 0.1.18
Changed, no others:
- `ElectrifiedMainline/info.json` — 0.1.18 to 0.1.21
- `ElectrifiedMainline/graphics/entity/35kv/pole-{east,southeast,south,southwest,west,northwest,north,northeast}-012.png` — 8 new 512×384 RGBA frames
- `ElectrifiedMainline/graphics/entity/35kv/pole-shadow-4dir-hr.png` — universal base-only 512×384 shadow

Added (ordinary non-executable files):
- `ElectrifiedMainline/ART_021_SOURCE_MANIFEST.json` — per-direction exact source SHA256, crop bounds and generated PNG SHA256.
- `ElectrifiedMainline/TEST_C_MAST_ART_021.txt` — install and in-game validation guide.

Not changed: all `.lua`, `data.lua`, `control.lua`, `data-final-fixes.lua`, `data-updates.lua`, all other prototypes, locale, rail physics, signal definitions, original wire rendering code.

## Static checks performed
- ZIP local integrity test PASS; exactly 45 files and one mod info JSON.
- All eight sprites decode as 512×384 RGBA, with rendered (nonempty) alpha and no trimming outside canvas.
- All base footprints aligned to common sprite base anchor by rescaling generated art.
- `info.json` version and `factorio_version:2.1` checked.
- Zip diff confirmed code/prototypes unchanged. **No Factorio engine run or image-by-image proof of correct physical suspension over HSR**.

## First user game test (NEXT)
1. Remove/disable older ElectrifiedMainline archives, install ONLY local `ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip` in Factorio mod folder.
2. Use **copy** of `ВСМ.zip` save, Factorio **2.1.20 build 87512**.
3. Confirm startup and first mast placement without Lua/data-stage error.
4. Put mast back into inventory (so green/red marker squares vanish) and screenshot each facing: 4 straight directions, four diagonal ones, curves A/B, half-diagonal tracks, both sides, parallel tracks and switches.
5. Special requirement: South MUST look like east-facing full cantilever; North MUST look like west-facing full cantilever, not foreshortened edge-on.
6. Check contrast/shadow/foundation at game zoom, arms over rails, mismatch P2–current visual wires. **Do not assume P2 alignment passes just because images are attractive.**
7. Check Undo/Redo for plain LMB on actual pole; unchanged code makes regression unlikely but not proven until game test.
8. Send **full-resolution screenshots and factorio-current.log**. Record specifics under `docs/tests/` and make corrections in separate art pass.

## Later stages
After game approves masts: contact+messenger wire geometry along ВСМ (no shortcut onto adjacent parallel rails), THEN electrical traction system (currently `energized=NO`, `transfer_MW=0`).

## Prohibitions
Do not revive failed 0.1.20 capsule placement, signal/terrain proxies, or change stable main 0.1.8 without approval.
