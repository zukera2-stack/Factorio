# Recovery record: uploaded ElectrifiedMainline 0.1.12 -> 0.1.13 (2026-11-13)

**Purpose:** Restore a verifiable development handoff. Do not conflate the user-supplied 0.1.13 **data-stage hotfix** with the separately discussed 0.1.13 **visual patch**. No release, merge, or gameplay approval is implied.

## Source-of-truth hierarchy

1. **Stable gameplay baseline:** `main`, mod **0.1.8**, native Upgrade Planner and scoped Undo/Redo user-tested in Factorio **2.1.20 build 87512**. Leave untouched.
2. **GitHub experimental branch:** `feature/rail-aware-catenary-012` at `a8cb3772930779dcc02dc0c959fa8695a0b69d69`, source `info.json=0.1.12`. This branch contains **a different 0.1.12 rendering implementation** from the user-uploaded ZIP and **does not track the PNGs** in `ElectrifiedMainline/graphics/entity/35kv/`. Its existing CI does not establish provenance of the uploaded ZIP.
3. **User-uploaded test ZIPs:** `ElectrifiedMainline_0.1.12(1).zip` and `ElectrifiedMainline_0.1.13(2).zip`. These were inspected locally in ChatGPT, **not imported to GitHub**. They are the only complete copies of the specific test build supplied in this handoff.
4. **Visual redesign:** The separately generated `EM_visual_patch_013.zip` is a proposed art/rendering patch, **not contained in the uploaded 0.1.13 hotfix**. Give the next combined test build a distinct version (e.g. 0.1.14) after reconciling sources.

## Exact uploaded ZIP provenance

| User-provided archive | SHA-256 | Entries | ZIP CRC |
| --- | --- | ---: | --- |
| `ElectrifiedMainline_0.1.12(1).zip` | `13a1bb62c9d26387b649cc53a590bb875b8b20902ce689c0742f7dac0f0e6c41` | 31 | pass |
| `ElectrifiedMainline_0.1.13(2).zip` | `e89d803dcd87252c50786949f53bb028f64af2f9df0e6daa16b3e29fbb959174` | 32 | pass |

Compared byte-for-byte, **29 existing entries are identical**. The 0.1.13 archive:
- Changes `ElectrifiedMainline/info.json` version from 0.1.12 to 0.1.13.
- Changes **only** `ElectrifiedMainline/prototypes/power_019.lua` among Lua files: clones one vanilla `connection_points[1]` entry to match the single-direction invisible `electric-pole.pictures`. The included `TEST_HOTFIX_013.txt` attributes this to Factorio's *"Count of wire positions doesn't match the count of pictures of the pole"* error. The claimed original game log is **not included** with these uploads.
- Adds `ElectrifiedMainline/TEST_HOTFIX_013.txt`.
- Leaves **all 12 PNGs** and all runtime Lua files unchanged.

All 12 PNG files pass basic PNG decoding and dimensions checks in the local inspection. **No Factorio engine was launched in this handoff.** A ZIP CRC check or static prototype stub is not a 2.1.20 game-load test.

## Graphics provenance (same in both uploaded ZIPs)

Path prefix: `ElectrifiedMainline/graphics/entity/35kv/`. SHA-256 below verifies exact bytes; none of these are tracked in the current 0.1.12 GitHub branch.

| File | SHA-256 |
| --- | --- |
| contact-wire-hr.png | `df922489d8c41b11e3074116017e9996bc47f733fba9860e08605a9036887d3a` |
| hidden-pole-012.png | `c2153f77e11087fcb078ae38527fa83bef29791e3700e30cc87fec4405a66d0f` |
| pole-4dir-hr.png | `0c15cd55f9c5e75a0c3ae7dc415dfd402a5ab117dfd4d19971e80365c5f0cc3b` |
| pole-east-012.png | `3365cfd6bf2c310024c3246ae4d54ca576590cd20aeefc114fa8484ba460af68` |
| pole-north-012.png | `1026994ea4bb04e2019d6cdce473a831f210bbd09904e4ae040a792ea1b6191e` |
| pole-northeast-012.png | `cd61380cde6b75ed2db5094122ca2a85a3a28810f23ce12c74fbfe6be8befc7b` |
| pole-northwest-012.png | `c2ea52253b5dddd51e0ce8b7520f06c7c8142a7a7f28d4b15e190f9454fd29b9` |
| pole-shadow-4dir-hr.png | `35c04b2668756a053113f2d23d5e947295fdacb73ed0c48762717b858dfe4630` |
| pole-south-012.png | `6c2c3d94acc57862febb469c2c64a390e4815fe284a1ec19c4952e0be099d93d` |
| pole-southeast-012.png | `42314ae7575370cf7f2f33384481d149a045ef03f902a5b834f18fc522eeea76` |
| pole-southwest-012.png | `8cd1ef1b94caeb37ab929df4e06025d11ec64a76ca98764680670c3c0178a37d` |
| pole-west-012.png | `0599d0a4c7d541551b79374d1a425e630a06814b4bbc518fb393123da3ab4078` |

**Static image concern:** `pole-north-012.png` has alpha bounding box touching image top (`y=0`), so its clipping/margin should be checked at game zoom.

## Screenshots supplied with the 0.1.13 archive

`Zagruzka(2).zip` contains four 1920×1080-ish gameplay screenshots (2026-11-13, filenames 17-20-17, 17-21-43, 17-22-12, 17-23-09). They show placed mast sprites on straight/curved HSR, but do **not visibly demonstrate a continuous correctly attached overhead wire**. Treat correct cantilever reach, wire alignment and turn continuity as **unverified**, not as passing. The images are user-provided visual evidence, not an automated test or proof of exact game version.

## Reconciliation and next acceptance gate

1. Import **the exact 0.1.13 archive source and PNGs** to a dedicated GitHub branch (not `main`), retaining byte-level provenance. Do not merge conflicting 0.1.12 renderers blindly. The recovery branch currently stores **documentation only**; its `ElectrifiedMainline/` source remains 0.1.12.
2. Add a reproducible single-ZIP GitHub Actions build and compare the resulting mod payload files to the archived SHA-256 manifest. Record any intentional changes. A release build must include all referenced PNGs.
3. Reproduce Factorio **2.1.20** data-stage load on a test save and collect `factorio-current.log`. Confirm the `connection_points` hotfix without changing native rail signals.
4. Check `/em-35kv-status`, actual pole facing on both sides of straight/diagonal/curved HSR, visual contact and messenger wires across a 90° curve, save/reload and build/remove/Undo/Redo.
5. Only after that, integrate a separately versioned visual-art patch, and run regression tests for Upgrade Planner and Undo/Redo from the known 0.1.8 baseline. Real traction energy transfer remains **OFF**.

## Handoff rule

On each subsequent session, read `AGENTS.md`, `docs/AI_CONTEXT.md`, `docs/PROJECT_STATE.yaml`, this recovery record and the live branch source. Every change must state: branch, parent commit, modified files, CI run, exact game-tested behavior, and remaining unverified behavior. Do not describe local ZIP files as committed GitHub assets.
