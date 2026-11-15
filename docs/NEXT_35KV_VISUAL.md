# CURRENT 0.1.24 — native shaft plus 8 C cantilever overlays

Code/art branch `feature/catenary-native-mast-body-024`. The previous 0.1.23 game test proved icon works and native ghost/robot/undo work, but **cursor showed only shadow**. API diagnosis in `docs/research/catenary-native-cursor-ghost-decision-0.1.24.md`.

Implemented as 0.1.24 isolated **art-splitting test**:
1. Native `ElectricPolePrototype.pictures` renders a fixed C lattice shaft+foot; should make actual placement cursor/vanilla ghost shaft visible. Existing native shadow and one wire connection point retained.
2. `SpritePrototype em-35kv-facing-*` source paths point to new `pole-arm-<octant>-024.png`: one cantilever+insulator for each existing 8 direction. Lua chooses face with unchanged `scripts/mast_facing_022.lua`.
3. Ghost overlay `scripts/ghost_mast_023.lua` uses same arm-only sprite with blue tint; the engine owns the shaft and its own native ghost blur.
4. Existing 8 full C PNGs `pole-*-012.png` remain in GitHub source as rollback. Approved south item icon and subtle circular markers unchanged.
5. Static unit tests + PNG check via `scripts/sprites/verify_024.py`; factorio 2.1.20 gameplay unverified. `main` remains 0.1.8.

**FIRST GAME QA:** install *only* 0.1.24 in disposable `ВСМ.zip` copy; check cursor shows bare steel shaft (not full arm; this limitation is intentional for current API) and native bluish shaft ghost. Check built masts still have ONE shaft and one correctly facing arm; watch for seam/duplicate steel at join. Then blueprint ghost, robot revival, manual ghost cancel, undo/redo and save/load, curves A/B, half diagonal, adjacent tracks. Send screenshot/log; confirm no wire connection point count errors.

**Important:** the full turned arm under moving cursor is NOT possible through our current engine-native `electric-pole.pictures` without cursor coordinate API; 0.1.24 shows fixed shaft preview, actual and ghost arms dynamically. Do not claim it implements a directional cursor preview.
