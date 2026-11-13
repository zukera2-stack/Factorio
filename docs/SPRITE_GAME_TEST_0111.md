# 0.1.11 — Г-shaped catenary sprite GAME-TEST build

Branch: feature/catenary-sprite-game-test-0111 (separate from stable main and 0.1.10).

## Scope

- Replaces only the visual prototype of em-35kv-catenary-pole with a four-frame RotatedSprite: frames 1–2 point right, 3–4 are true horizontal mirrors pointing left.
- Adds a separate shadow layer with draw_as_shadow=true, and registers a contact-wire SpritePrototype for future experiments.
- Uses 512x384 pixel frames, a 2x2 atlas (1024x768), 0.5 scale, mast-foot at (256,354), and shift {0,-2.53125} tiles. No change to item/recipe collision, rail Upgrade Planner, Undo/Redo, topology, or 35 kV energy transfer.
- CI builds the PNGs from the **synthetic QA fixture**, not from a final artist-approved image. The test ZIP is playable in principle, but **Factorio 2.1.20 has not been run**.
- Runtime contact spans still use rendering.draw_line; the wire texture is only registered, not used. No power transfer.

## Technical verification

The official [ElectricPolePrototype API](https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html) defines pictures as RotatedSprite. The [RotatedSprite API](https://lua-api.factorio.com/latest/types/RotatedSprite.html) defines layers, direction_count, line_length, apply_projection, draw_as_shadow, scale and shift. Docs inspected: 2.1.24, target game: 2.1.20; version mismatch explicitly unverified.

Build steps in GitHub Actions: Lua 5.2 syntax + topology tests; Pillow unit tests (including symmetric-T rejection and atlas mirror); generated PNG SHA/dimension report; zip content validation. The build does **not** assert a successful Factorio data-stage load.

## Game test checklist

1. Back up the 0.1.10 save; close Factorio.
2. Download the GitHub Actions ZIP artifact, extract the single ElectrifiedMainline_0.1.11.zip and place it in Factorio mods. Remove/disable the older version ZIP so two copies are not loaded.
3. Start Factorio 2.1.20. If it fails, send factorio-current.log; do not overwrite the old save.
4. Open a TEST copy of the old save and verify existing poles display the Г-shaped lattice sprite, with the mast to the side and arm over the rail, no missing magenta texture and no shadow in the sky.
5. Try rotating a new pole with R through four directions. Confirm whether Factorio actually changes the frame; note which directions show the mirrored arm. If rotation is ignored, we will implement two separate pole prototypes instead of pretending direction_count solves it.
6. Place poles beside straight and curved high-speed rails, a substation and spans of 2, 8 and 16 tiles; check that the original contact lines still appear and do not connect diagonally to every pole.
7. Run /em-35kv-status. It must still say energized=NO, transfer_MW=0. Test blueprint, robot placement, Ctrl+Z/Ctrl+Y and save/reload.
8. Send a screenshot as an image FILE or ZIP, plus the log and status text. We will correct contact-wire attachment offsets only after seeing real gameplay evidence.

## Known limits

A four-frame atlas does not guarantee that a vanilla electric pole can be manually rotated; this is the central experiment. No native Factorio 2.1.20 test is available in CI. The generated art is a technical fixture; it must not be mistaken for the polished AI illustration or production-ready game sprite.

## CI evidence

[GitHub Actions #43410505808](https://github.com/zukera2-stack/Factorio/actions/runs/43410505808) passed 28 Python tests, Lua syntax, topology tests and ZIP packaging. [Artifact 14029696360](https://github.com/zukera2-stack/Factorio/actions/runs/43410505808/artifacts/14029696360) is the test mod ZIP wrapper. A documentation CI version mismatch was discovered and corrected separately. This build remains gameplay-unverified.
