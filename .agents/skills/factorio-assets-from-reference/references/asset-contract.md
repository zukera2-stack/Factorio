# Asset contract — actual source vs generated art

## The five output classes

| Stage | Real reference pixels | Geometry preservation | Game-ready | Example |
|---|---|---|---|---|
| `study` | Can be screenshot crop | Visual only | **No** | EM086 freight wagon crop + repaint |
| `concept` | Optional | No | **No** | Requested new decorative item design |
| `repaint-preview` | Required | Pixel-exact alpha | **No**, until full atlas | Validated 2D recolor of one native frame |
| `sprite-candidate` | Exact game sheet or 3D render | Contracted pivot/frames/shadows | Not yet owner accepted | All directions/passes verified |
| `direct-patch` | Source lineage + QA | Contracted | Tested candidate | Scoped ZIP + external manifest |

## Never confuse these

- `source screenshot` ≠ `vanilla sheet`; `generated concept` ≠ `repaint`; `green Github CI` ≠ `Windows acceptance`.
- Do not invent extra panto/window, roof boxes, container, cab, cargo compartments or third-party logo. Never replace an open hopper with a closed electrified coach when user asked for **existing vanilla motor cargo wagon**.
- Two wagons are separate native types: `cargo-wagon` and `fluid-wagon`. Their base frame count and shader/layer/door/wheel contracts must be inspected in the actual Base build (or real mod prototype); locomotive 256 directional art is not a shortcut for them.
- Reuse accepted locomotive bogie only after checking scale, wheel pivot/track plane, orientation, direction count, z-order and bogie shadow. Changes in wheel attachment must not alter transport mechanics.
- Substantial geometry replacement or brand-new fictional art must be explicitly requested, not justified as «same style».

## Layer record (per asset)

Record `name`, actual input PNG/model (sha), format/size/alpha, source license status, transformations, orientation mapping, row/col, pivot and scale, shift, mask/tint settings, shadow light direction and ground projection, and corresponding game prototype. Record the **same** settings for output; if changed, explain why. Preserve native inventory icons and minimap visualization until explicitly changed.

## Review before 256 frames

1. View original and updated at same coordinate and zoom, including a transparent-background checkerboard.
2. Side-by-side three views: front/rear (as needed) and a side view, with one frame named by its exact orientation; for a one-frame screenshot study show only that frame.
3. Measure pixel change: alpha equality for paint-only, proportion of modified RGB, bounding rect before/after and occupied alpha. If mask is a separate layer, ensure no color/tint leaks into background.
4. Verify no fake ground shadows; include shadow as a separate layer with transparent space. Inspect per-direction pivots for bounding-space shifts. For wheel changes inspect 4/8/256 cardinal/diagonal samples plus turning through all directions.
5. Ask for artistic acceptance only when useful. If user wants autonomously continue, work to a reproducible game candidate and report pending Windows acceptance instead of deferring to an arbitrary approval loop.

## Shipping and rights

Do not bundle original Factorio proprietary Base PNGs in new distributable mod ZIP just because they are available as references. Confirm that a proposed use is licensed; when uncertain, reference vanilla assets by `__base__` or produce original artwork. Store owner reference and local outputs in GPT Library with exact provenance. Game-only ZIP contains no README, manifest, screenshot, reference license, or QA files. No release/main merge.
