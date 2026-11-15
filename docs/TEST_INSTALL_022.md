# 0.1.22 — C-mast railway-facing correction, game-test

**Source branch:** feature/catenary-facing-geometry-022.
**Factorio:** 2.1.20 build 87512. **Art:** EXACT 0.1.21 C sprites (8 directions + base shadow, SHA verified). **Code:** 0.1.18 gameplay base + scoped orientation correction.

## Install
Download the GitHub Actions ZIP for this branch, extract nested `ElectrifiedMainline_0.1.22.zip`, install ONLY that mod archive in Factorio `mods`. Remove/disable old 0.1.18/0.1.20/0.1.21 archives. Use copy of existing `ВСМ.zip` save.

## Reproduce with identical physical positions (DO NOT move markers)
1. Compare to 0.1.21 screenshots `2026-11-15_17-07-03.png`, `17-08-16.png`, `17-10-20.png`, `17-11-50.png`, `17-11-59.png`.
2. Place two masts on opposite sides of one straight rail: arm direction should face toward the rail, not to the far field.
3. Build on both sides of curved-rail A and curved-rail B, including inner and outer radius. Look for abrupt 180-degree flips of otherwise adjacent mast arms.
4. Repeat on half-diagonal and straight→curve transitions; see parallel rails and turnout too.
5. Observe SOUTH uses east-like side projection and NORTH west-like projection **by user design**. The new choice must follow actual rail location, not the pole's `entity.direction`.
6. Put pole item away to hide green/red debug squares; send screenshots with exact screen position and same zoom.
7. Send factorio-current.log. Each new mast should report `[ElectrifiedMainline][face022]` with `pole=...`, `face=...`, `via=rail_end_chord|rail_end_curve|entity_center_fallback`, `rail` and `target`. If fallback appears where a curve should have real endpoints, that is a useful failure, not success.
8. Verify normal LMB pole, Ctrl+Z/Ctrl+Y and vanilla Upgrade Planner remain intact. No gameplay claims about electricity (`MW=0`).

## QA and scope
The only runtime function changed is selection of `n.face` via a pure math module, leaving native placement and contact graph untouched. Automated Lua mocking is not Factorio game validation. If an orientation still misses, capture log and image and correct the geometric reference first. DO NOT prune valid slots, alter collisions, create hidden rail signals, or add special terrain.

## References
- [User game report 0.1.21](tests/catenary-C-art-0.1.21-facing-2026-11-15.md)
- [Original 0.1.21 ZIP archived in GitHub](https://github.com/zukera2-stack/Factorio/blob/feature/catenary-facing-geometry-022/art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip)
