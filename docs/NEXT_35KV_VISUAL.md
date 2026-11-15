# HANDOFF: 0.1.22 GitHub C sprite art + experimental facing correction

**Current GitHub branch:** `feature/catenary-facing-geometry-022`. Actual version `ElectrifiedMainline 0.1.22`. **All original eight 0.1.21 C PNG sprites and shadow are committed now**, byte-identical to the user's actual game-tested local ZIP. Original ZIP also saved inside GitHub `art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip`.

**Game tested baseline:** 0.1.21 loaded successfully in Factorio 2.1.20. Six user screenshots show incorrect cantilever orientation at some curves and half diagonals. Root cause is likely `power_019.lua::register` using the nearest rail entity's center. Green valid placement squares themselves are not implicated and must not be pruned. Original log/screenshot SHA in `docs/tests/catenary-C-art-0.1.21-facing-2026-11-15.md`.

**Change 0.1.22:** Added pure `scripts/mast_facing_022.lua`, projects mast to closest point on a rail-end chord or approximated curve, then picks one of the same eight facing SpritePrototypes. This affects **only** the graphical orientation. Existing `rail_tangent`/contact-edge topology, placement API, Undo, rail types, train blocks, sprites, wire graphics unchanged. Each new mast logs `[face022]` with octant and reference rail.

**Next:** CI builds `ElectrifiedMainline_0.1.22.zip`; user tests on disposable copy of ВСМ save, reproduces problem spots from prior screenshots and sends new screenshots/log. Do not label new algorithm game-proven until that happens. See `docs/TEST_INSTALL_022.md`. Fix only observed facing mismatch. Do not change placement slots or power.

**Later:** after acceptance of masts, visual contact wires; electricity last. Stable `main` 0.1.8 untouched. Do not use failed 0.1.20 capsule placement experiment.
