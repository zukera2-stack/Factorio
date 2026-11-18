# File relevance audit — Electrified Mainline 0.1.42

Audited 2026-11-18 against the user's actual 0.1.42 ZIP and the existing experimental 0.1.36 GitHub branch. This is a **runtime/source distinction**, not a proposal to delete historical evidence.

## Runtime assets referenced by 0.1.42

| Class | Relevant files | Role |
| --- | --- | --- |
| Native mast sprites | `graphics/entity/35kv/pole-south-039.png`, `pole-north-039.png` | Long south and short north actual in-game shaft bodies, cursor previews and ghosts |
| Eight directional arm sprites | `graphics/entity/35kv/pole-arm-{east,southeast,south,southwest,west,northwest,north,northeast}-039.png` | Separate consoles/insulators rendered in the chosen facing by `scripts/power_019.lua` |
| Item/selection icons | `graphics/icons/25kv-{south,north}-039.png` | Separate inventory and item icons |
| Wire art | `graphics/entity/25kv/{contact,messenger,dropper}-030.png` | Runtime textured straight-span art |
| Shadow | `graphics/entity/35kv/pole-shadow-4dir-hr.png` | Still referenced by native electric-pole pictures |
| Graph and rendering | `scripts/{power_019,power_topology,native_wire_028,native_wire_geometry_028,catenary_art_030,catenary_limits_029,mast_visual_034,ghost_mast_023}.lua` | HSR-connected graph, 32/16/40 span checks, hidden/native copper, 8-way art, ghost, 2.02 visual shift |
| Factorio entry points | `info.json`, `data.lua`, `control.lua`, `data-final-fixes.lua` and loaded `prototypes/*.lua` | Active prototypes, recipes/rail upgrade and runtime initialization |

All twelve 039 PNG byte digests, dimensions, RGBA encoding, active references and eight contact-point records are checked by `scripts/verify_042_assets.py`; `tests/25kv_visual_042.lua` validates accepted north geometry.

## Retained historical or optional files

- Original `graphics/entity/35kv/*-024.png` and `pole-*-012.png` are **tracked historical PNGs** and remain unmodified in GitHub for provenance and rollback; they are not the active 039 images. The first `pole-native-mast-024.png` picture assignment in `prototypes/power_019.lua` is overridden by the final 039 assignment before prototype registration. Do not replace original 024 assets with the modified, unused copies from the locally repackaged user ZIP.
- `pole-north-short-033.png`, `pole-south-long-035.png`, `pole-south-lattice-036.png` were **build-generated** by past 033–036 workflows, and occur in the user's older experiment ZIPs, but are intentionally not committed or packaged in the GitHub 0.1.42 build. Their original generator scripts and build history remain available. They are not needed by 0.1.42.
- `scripts/sprites/{generate_north_033,extend_south_035,extend_south_036}.py`: historical image generators, intentionally version-gated to 0.1.33–0.1.36. **Never run on the accepted 039 PNGs.**
- `tests/25kv_{north_033,mast_alignment_034,south_035,alignment_036}.lua`: obsolete geometry expectations for their original versions; run only with 0.1.33–0.1.36, not 0.1.42.
- `scripts/{native_wire_probe_026,mast_preview_015,rail_slot_debug_014}.lua` and prototype `native_wire_probe_026.lua`: optional diagnostic commands/legacy tooling still loaded; do not delete without dedicated dependency and save compatibility review.
- `ElectrifiedMainline/TEST_*.txt` and `SPRITES_039_QA.json`: **non-runtime** game-test instructions/evidence. Old versions' guides remain for traceability; they do not change gameplay.
- `dist/ElectrifiedMainline_0.1.8.zip` and `docs/history/`: historical verified Undo baseline and prior handoff; not the latest mod source.
- Registered `em-35kv-contact-wire-texture` and old `graphics/entity/35kv/contact-wire-hr.png`: historical texture placeholder, not the actual active 0.1.42 contact/messenger runtime artwork.

## Audit findings and action

1. Previous docs describe 0.1.24/0.1.36 as current without separating stable `main` from experimental visuals; README/STATUS/ARCHITECTURE/AI_CONTEXT/PROJECT_STATE now distinguish them.
2. Older sprite CI hardcoded historical source sizes and north shift. Keep history but gate to historical versions; new **0.1.42** check verifies exactly the user-approved assets.
3. No existing tracked code or image was deleted during this audit. Legacy *build-generated* 033/035/036 PNGs are omitted from the 0.1.42 GitHub package; previous versions remain reproducible through their version-gated generators, while old 024 source images remain tracked.
4. The accepted in-game screenshot does not confirm full 32/16/40, multi-direction rail connectedness or Undo regressions in 0.1.42; separate gameplay test is required before main merge.

## GitHub Actions archive versus accepted local ZIP

The GitHub 0.1.42 ZIP is rebuilt from GitHub with the 12 exact active 039 PNGs and the same runtime/entry-point code as the user-approved ZIP. The historical 024 source PNGs intentionally remain in their original Git states; the user's ZIP contained modified but unused 024 copies. Past generated 033/035/036 PNGs are omitted. Thus **whole-ZIP SHA-256 will differ**, but active runtime assets and scripts are verified by direct SHA comparisons. This preserves historical source integrity without changing observed 0.1.42 gameplay art.
