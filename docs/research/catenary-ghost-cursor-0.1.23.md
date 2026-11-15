# 0.1.23 — Reference and falsifiable design for mast ghosts and cursor

## Source/API evidence

- Native game entity: `electric-pole` prototype [ElectricPolePrototype 2.1](https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html) exposes a single `pictures` RotatedSprite and separate optional `active_picture`; our existing runtime `rendering.draw_sprite` chooses one of eight viewpoints. Replacing `pictures` with full C would double-render built poles.
- Factorio [EntityPrototype](https://lua-api.factorio.com/latest/prototypes/EntityPrototype.html) offers `placeable_position_visualization` (Sprite) for placement-time visualization; we use it to show south C in the cursor while leaving `pictures` hidden. Whether the 2.1.20 client shows this precisely as intended is **not yet game-verified**.
- Factorio [LuaEntity](https://lua-api.factorio.com/latest/classes/LuaEntity.html): `name="entity-ghost"`, `ghost_name` gives the original prototype.
- Factorio [EntitySearchFilters](https://lua-api.factorio.com/latest/concepts/EntitySearchFilters.html): `find_entities_filtered{name="entity-ghost",ghost_name=...}` enables startup/save migration without modifying ghosts.
- Factorio [LuaRendering](https://lua-api.factorio.com/latest/classes/LuaRendering.html): `draw_sprite` supports entity target and tint; render objects attached to destroyed target entities auto-remove.
- Factorio [Events](https://lua-api.factorio.com/latest/events.html) supports `on_built_entity`, `on_robot_built_entity`, `script_raised_built`, `script_raised_revive`, `on_pre_ghost_deconstructed` (existing consolidated mod handlers).
- Source artwork for icon: original tested `ElectrifiedMainline/graphics/entity/35kv/pole-south-012.png`, rendered at 512×384; icon = deterministic transparency-preserving resized silhouette, 64×64.
- API site consulted currently lists 2.1.24 in some pages; **Factorio user runs 2.1.20**. Gameplay verification remains necessary.

## Implementation and scope

1. `prototypes/power_019.lua`: item + entity icon from PNG, keep 1×1 electric-pole and original hidden picture; add optional `placeable_position_visualization` pointing to existing south C sprite, same 0.5 scale/offset as current rendering. Not animated. This is **not** a normal world picture and should not cause double-render of already built C poles.
2. `scripts/ghost_mast_023.lua`: on native entity-ghost build, draw translucent C image using the current RailEnd-based visual octant calculation `power_019.facing_at`. Render target is the ghost, not a new entity. Rebuild existing ghost visuals during init/config change; remove tracked visuals when ghost mined/deconstructed, auto-destruct when robot revives ghost.
3. `scripts/catenary_cursor_018.lua`: circle outline with muted alpha instead of two vivid ground rectangles per candidate. Colours keep READY/BLOCKED/OUT_OF_REACH/ERROR; authoritative `player.can_build_from_cursor` and placement rules unchanged.
4. The graphic selection of *built* poles and rail power topology remains as 0.1.22. No ghost teleportation, no manipulation of Undo records, no special terrain, no signal-proxy entity or interception of ordinary LMB.

## Test / acceptance

- CI: Lua syntax + mocked lifecycle; PNG header/dimensions and transparency; source ZIP builds (not a Factorio game load).
- Game: put item in cursor, inspect full mast visualization + ground circles on straight and curves; place real mast (one image only); remove item and check overlay clears.
- Ghost: place item in ghost mode (Shift+click), blueprint ghost, robot replacement, robot building, manual deconstruction and Ctrl+Z/Ctrl+Y. A ghost should be **blue translucent C** before build and full color after build. Exactly one sprite per entity, no stuck ghosts after removal.
- Save/reload with multiple ghosts should restore without duplicate images.
- 0.1.22 already game-tested orientation is preserved; tests of 0.1.23 needed. No assertions that rendering is verified in Factorio yet.
