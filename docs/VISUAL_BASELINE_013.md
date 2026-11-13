# ElectrifiedMainline 0.1.13 — immutable baseline for visual work

**Active branch:** `feature/catenary-visuals-014` (from recovery commit `8a48ce1`). **Stable:** `main` remains 0.1.8, unchanged.

## Exact GitHub vs uploaded archive comparison

Compared `feature/rail-aware-catenary-012` at `a8cb377` with the user-uploaded `ElectrifiedMainline_0.1.13(2).zip` (SHA-256 `e89d803dcd87252c50786949f53bb028f64af2f9df0e6daa16b3e29fbb959174`).

| Category | Number of files | Meaning |
| --- | ---: | --- |
| Same bytes in both | 13 | Rail prototypes, native Upgrade/Undo runtime, locale and entry points are preserved |
| Different bytes | 4 | `info.json`, `prototypes/power_019.lua`, `scripts/power_019.lua`, `scripts/power_topology.lua` |
| Only in uploaded archive | 15 | Two test notes, eight facing PNGs, two atlas PNGs, wire PNG, hidden PNG, and `scripts/overhead_geometry_012.lua` |
| Only in previous GitHub source | 1 | Unused older `scripts/catenary_visuals_012.lua` (removed from this branch) |

**Result:** exactly **32 archive files** now form the `ElectrifiedMainline/` mod payload in this branch. Each SHA-256 and image dimension is recorded in [`builds/013-payload.json`](builds/013-payload.json). The ZIP container byte hash is for provenance only; a newly built ZIP may have different compression metadata but **identical unpacked files**.

## What the existing code actually draws

- `prototypes/power_019.lua`: invisible electric-pole prototype, one `connection_points` entry, zero copper reach, eight registered facing sprites and one registered wire texture.
- `scripts/power_019.lua`: `rendering.draw_sprite` chooses one of the **eight separate direction PNGs** from nearby HSR; the pole entity itself does **not rotate**. The physical pole position is not snapped like a rail signal.
- `scripts/overhead_geometry_012.lua`: eight-sector face selection, approximate 1.5-tile conductor endpoint offset and Bézier points for corners.
- **Important:** `contact-wire-hr.png` is registered but the current runtime renders actual contact and messenger wires via `rendering.draw_line`, **not** the wire PNG texture.
- **Important:** `pole-4dir-hr.png` is present but the current runtime uses the eight `pole-{direction}-012.png` files, not this atlas.
- **Important:** the `pole-shadow-4dir-hr.png` atlas is configured as one 512×384 sprite with `direction_count=1` on the invisible prototype. It is **not** rotated with the eight runtime-facing mast sprites.
- `render_sprite` applies the same entity offset `{0,-2.53125}` to every facing. `wire_anchor` uses a geometric offset independent of the actual attachment point in each PNG. These are **alignment hypotheses**, not confirmed causes of a particular screenshot artifact.

## Visual observations and priorities

User gameplay screenshots show thin-looking masts, inconsistent visual reach of cantilevers and wires that do not read as a coherent overhead catenary. Screenshots alone do not establish engine-side placement correctness. Prioritize:

1. **Mast anchor and sprite perspective:** one consistent mast-foot location, realistic isometric depth and readable lattice silhouette. Review 1×/2× game zoom, not only enlarged PNG.
2. **8 orientations:** preserve the eight-facing logic but align each art frame to the same physical foot and matching wire endpoint; test both sides of straight and curved HSR.
3. **Shadow:** separate a consistent ground shadow for each facing (or a genuinely orientation-independent shadow); do not reuse an atlas quadrant as if it were the whole atlas.
4. **Wire geometry:** match contact and messenger line ends to visible insulators, avoid stray diagonal shortcuts and unrealistic hard breaks. Do not assume the wire texture is in use.
5. **Visual-only change isolation:** no rail signal prototypes, Undo/Redo queue changes, physical pole teleportation, electric traction, MW transfer or rail fast-replace changes.

## Acceptance and test evidence

- **Source:** exact user archive 0.1.13 bytes; manifest check and 0.1.13 pure-Lua visual geometry assertions.
- **CI:** `build-mod.yml` runs Lua 5.2 syntax, topology/geometry tests, builds a single ZIP and verifies every extracted 0.1.13 file against the archive manifest.
- **Game (pending):** Factorio **2.1.20 build 87512**; confirm load, 8 orientations, poles along straight/diagonal/curved HSR, no stray wires, rebuild after save/load, robots and Undo/Redo, normal/chain signals unaffected.
- **Next version:** `0.1.14` for actual visual changes. Keep `0.1.13` frozen as an immutable recovery baseline. A passing CI is not a gameplay test.

## Provenance boundary

All 12 PNGs in this baseline are exact user-supplied archive bytes, not newly generated artwork. The separately discussed local `EM_visual_patch_013.zip` is **not included** here. Do not mix its prototype code with this baseline without explicit comparison and a new version.
