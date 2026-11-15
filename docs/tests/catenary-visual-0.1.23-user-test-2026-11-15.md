# Factorio 2.1.20 user test — ElectrifiedMainline 0.1.23, icon / cursor / ghost

**Date:** 2026-11-15. **Game:** Factorio 2.1.20 (build 87512, win64). **Mod:** ElectrifiedMainline 0.1.23. User uploaded 5 screenshots and factorio-current log in the chat.

**Evidence identification (original files in user conversation; NOT stored as full-resolution binaries in GitHub):**
- `2026-11-15_19-16-02.zip` (5 PNGs: `19-16-02`, `19-18-46`, `19-19-00`, `19-19-22`, `19-19-55`), SHA256 `d5d469fee17308c74b277cbc67bc170d26d4db37571b107b8186f93e422a56e1`.
- `factorio-current(20261115-162212).log`, 44,305 bytes, SHA256 `db5ebcf6a47f61f020819109abc4d676e7abc53e6a432f49472f36d849f2e5e1`.

## What user confirmed

- SOUTH C sprite-derived inventory icon appears correctly.
- Native entity-ghost creation, copying, deconstruction, robot building, and undo/redo appear operational. User explicitly confirms this in conversation.
- Mast model is still **absent from cursor placement preview**, despite 0.1.23 `placeable_position_visualization`.
- User observed standard blurred/blue ghost aesthetic on vanilla pole; native rendering differs from our custom tinted Lua ghost.
- Five screenshots show real C masts and ghost placements, and new subtler **circular** green/red markers in the intended places. Screens alone do not prove all ghost-orientation combinations.
- Game log: mod loads successfully and game enters `ВСМ.zip`; no explicit Factorio Lua exceptions. Events at ticks 47971 etc. create `entity-ghost` with `ghost_name=em-35kv-catenary-pole`. Robots produce actual `em-35kv-catenary-pole` at ticks 50513–50525; Undo/Redo marks/removes and robot rebuild events at 50681–51613. 0.1.22 face traces remain active.
- Important limitation: some robot-built masts have `face=east via=no_rail_default` when away from actual ВСМ; this is expected fallback, not evidence of a graphics crash.

## Engineering conclusion

Current prototype `prototypes/power_019.lua` keeps `catenary.pictures` as hidden 1-pixel sprite plus shadow to avoid duplicating full C artwork, while LuaRendering draws full 8-way mast after placement. Factorio's **native** cursor placement preview and native entity-ghost shading normally derive from electric-pole `pictures`. Inventory `item.icon` does not affect world placement picture. `placeable_position_visualization` is a supplemental placement marker (the official Space Age thruster supplies a cursor box sprite), not a replacement for `pictures`; it did not display the full held mast in user game.

The 0.1.23 bespoke `ghost_mast_023.lua` overlay supplies a visible translucent C, but that is a **tinted LuaRendering sprite**, not literally the native ghost's blur shader. The native game already owns ghost data, copy/undo/robot life cycle and those should not be altered.

See [API-grounded decision](../research/catenary-native-cursor-ghost-decision-0.1.24.md) for exact prototype references and next isolated 0.1.24 art experiment. No further gameplay changes have been made by this report.
