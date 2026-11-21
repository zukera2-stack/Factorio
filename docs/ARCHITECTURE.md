> **Scope: stable `main` 0.1.56 only.** Cross-branch 0.1.60 electrical bridge and 0.1.61 EEI-priority research are separate; see [`CURRENT_WORK.md`](CURRENT_WORK.md). No power-bridge source is merged into the baseline described here.

# Accepted 0.1.56 architecture

- Native ground HSR prototypes; concrete slab with static thickness/wear, native backplates tinted 0.65, native metals and lower bed. Build-time art only.
- Autonomous locomotive with 256 directions, runtime tint, native wheels, cosmetic raised/folded pantograph and contact-only spark; no real electric traction.
- `catenary_axis_056.lua` selects the first mutual mast in each direction along real HSR RailEnd connections (approximate arc, 32 tiles); `power_019.lua` maintains the graph and separate legacy technical association; `catenary_art_030.lua` draws pixel-calibrated chords and contact index; `technical_network_046.lua` is separate, not a decorative gate. Ghost preview uses same graph against existing built masts. Phase-2 unified attachment excluded.
- Lua syntax and functional preflight before eight render jobs; CI packaging and asset QA separate. [Owner acceptance](tests/catenary-0.1.56-user-acceptance.md). No actual MW or verified factory isolation, no exhaustive live regression.

---

# Historical 0.1.42 architecture — user-accepted 25 kV overhead

- The stable `main` branch was then **0.1.42**, merged via PR #20 from `experiment/25kv-visual-042-accepted`.
- Two **native Factorio electric-pole prototypes**: long southern `em-35kv-catenary-pole` and short northern `em-35kv-catenary-pole-north`. Their legacy IDs remain unchanged for save compatibility; player-facing descriptions say **25 kV**.
- The native `electric-pole.pictures` layer draws the long `pole-south-039.png` (512×512) or short `pole-north-039.png` (512×384), so cursor preview and base ghost use the same accepted art. Separate `rendering.draw_sprite` overlays select the eight approved `pole-arm-*-039.png` sprites in `scripts/power_019.lua`; ghosts mirror the overlay in `scripts/ghost_mast_023.lua`.
- Per-prototype north calibration lives in `scripts/mast_visual_034.lua` with `NORTH_DROP=2.02`; `scripts/native_wire_geometry_028.lua` applies it to the hidden wire helper. This is the approved visual position and must not be changed without a new screenshot.
- `scripts/power_019.lua` owns the HSR-connected contact graph. `scripts/native_wire_028.lua` renders native copper on curves. `scripts/catenary_art_030.lua` connects invisible copper helpers and renders separate contact, sagging messenger and dropper sprites on straight segments. Limits: 32 straight / 16 curved / 40 helper wire reach (`scripts/catenary_limits_029.lua`). No real traction energy transfer.
- All twelve approved PNGs and the SHA-256/geometry contract are verified by `scripts/verify_042_assets.py`. Unused 012/024 PNGs, the obsolete mast generators 033/035/036 and their raster tests were removed from the experimental branch. Only the 12 approved 039 images, 030 conductor graphics and actual native shadow are packaged. See [file relevance audit](FILE_RELEVANCE_042.md).
- A later Factorio 2.1.24 log confirms successful save loading, both pole variants, ghosts/robots, and Undo/Redo for straight rails plus curved rail events, followed by user acceptance. [Scoped final test](tests/catenary-0.1.42-main-acceptance-2026-11-18.md). An exhaustive boundary/multiplayer matrix is not claimed.

---

# Architecture

## Runtime constraints

Factorio discovers the following files by their exact names at the mod root:

- `info.json`
- `data.lua`
- `data-updates.lua`
- `data-final-fixes.lua`
- `control.lua`

The root Lua files are thin entry points where practical. Implementation is kept in named modules and loaded with `require`.

## Current layout

- `prototypes/bootstrap.lua` — current complete prototype definitions, loaded by root `data.lua`.
- `scripts/control.lua` — current runtime event handlers, loaded by root `control.lua`.
- `compatibility/` — isolated optional-mod adapters; currently documentation only.
- `locale/` — player-facing English and Russian strings.
- `docs/AI_CONTEXT.md` — cross-chat working handoff.
- `docs/PROJECT_STATE.yaml` — machine-readable accepted decisions and implementation status.
- `AGENTS.md` — instructions for AI contributors.

The original core rail logic remains in stable modules; the 35 kV visual subsystem now has its own prototype and runtime modules. Keep the native engine's responsibility for placement and train signaling separate from cosmetic LuaRendering objects.

## Historical 0.1.24 catenary visual subsystem

- `prototypes/power_019.lua`: clones a real `electric-pole` and uses one native steel-lattice shaft (`pole-native-mast-024.png`) and an existing shadow in `pictures`, with exactly one wire connection point matching `direction_count=1`. The entity has no native wire reach or MW transfer.
- `scripts/power_019.lua`: registers placed masts and substations, renders **only** eight cantilever/insulator overlays plus cosmetic contact/messenger/feeder connections. Some contact graph drawing is approximate and must be visually reviewed next.
- `scripts/mast_facing_022.lua`: projects the mast location onto a sampled RailEnd path for the 8-way facing; does not physically rotate or relocate native poles.
- `scripts/ghost_mast_023.lua`: ghost-tied blue arm overlay, allows Factorio engine to draw its own native shaft ghost and handle native construction/Undo.
- `scripts/catenary_cursor_018.lua`: native player cursor construction and advisory muted circles. No rail-signal-proxy placement.
- `graphics/entity/35kv/pole-arm-*-024.png`: 8 512×384 RGBA directional C cantilevers, `higher-object-above` at offset `{0,-2.53125}`; original `pole-*-012.png` full frames retained.
- [Game-accepted 0.1.24 scope](tests/catenary-mast-0.1.24-user-accepted-2026-11-15.md). **Electricity `transfer_MW=0`.**

## Intended module boundaries

### Prototype layer
- items
- recipes
- technologies
- rails
- rolling stock
- power infrastructure

### Runtime layer
- persistent storage and migrations
- rail identity/electrification
- train lifecycle and composition
- power transfer
- battery accounting and regeneration

Do not create empty placeholder modules. Extract a module when it owns real code and can be tested independently.

## Compatibility architecture

The core mod should depend only on Base unless a required feature proves otherwise. Optional integrations belong in `compatibility/<mod-name>/` and must guard every optional prototype/API reference. Unknown third-party entities must be tolerated.

## Native rail replacement and experimental fallback

- `data-final-fixes.lua` assigns **one `fast_replaceable_group` per ground rail geometry** and connects each vanilla rail's `next_upgrade` to its matching custom rail, subject to eligibility and existing-chain checks.
- The native green Upgrade Planner then owns robot mining/building, and Factorio's native Undo/Redo. `on_marked_for_upgrade` observes native orders and **must not** cancel them.
- **0.1.8 game-tested:** native green Upgrade Planner, construction-robot replacement and Undo/Redo for 26 straight + 4 curved-A + 4 curved-B rails. The half-diagonal geometry remains unverified in gameplay.
- **0.1.8 game-tested:** Ctrl+Shift superforced blueprint overlay with 14 straight + 4 curved-A + 4 curved-B rails; native Undo and Redo restored and reapplied them. See [evidence record](tests/undo-0.1.8-2026-11-12.md).
- The former experimental scripted Ctrl+Shift ghost Undo joining and fixed `undo_index=1` were **removed** in 0.1.8. Undo/Redo event handlers are observational only.
- The separate `em-rail-replacement-planner` **still** uses an independent staged deconstruction/ghost queue. It has not passed dedicated 0.1.8 gameplay regression; its Undo behavior is not promised.
- Before modifying a mechanic, follow the [working-analogue research protocol](RESEARCH_METHOD.md) and complete a [prototype research record](PROTOTYPE_RESEARCH_TEMPLATE.md). Compare prototype type, group, upgrade chain, collision, mining/placement, runtime ownership, and target-version API with a proven implementation; save the record under `docs/research/`.

## Change and verification policy

- Keep prototype names and runtime behavior stable during structural-only changes.
- Keep Factorio entry points at the mod root.
- Test data-stage loading and runtime separately.
- A successful ZIP workflow confirms packaging, not game behavior.
- Update `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml` after material changes.
