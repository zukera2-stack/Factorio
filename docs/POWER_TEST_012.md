# 0.1.12 rail-aware catenary field test

Branch: feature/rail-aware-catenary-012. Target: Factorio 2.1.20 build 87512. Research: [API and analogues](research/rail-aware-catenary-0.1.12.md).

## Setup
Back up the 0.1.11 save. Install exactly one ElectrifiedMainline_0.1.12.zip in mods (unwrap the GitHub Actions artifact if necessary); disable other copies of the mod. This is a test build, NOT main.

## What to test
1. **Migration:** open existing map, no static duplicate arms or Lua error; /em-35kv-status reports arm_sprites, energized=NO, transfer_MW=0.
2. **Straight rails:** build pole above/below horizontal track, then left/right of vertical track; mast stays vertical, the arm visually aims at rails automatically, without pressing R.
3. **Curves and diagonals:** build on both sides of bends; compare direction of arms and contact/messenger wires. Short segments should curve along track and must not cut a long straight shortcut across empty terrain.
4. **Isolation:** normal rail signals and chain signals before and after are unchanged, train pathing/block boundaries remain unaffected.
5. **Lifecycle:** robots, blueprint, Ctrl+Z/Ctrl+Y, pole deletion, rail building/removal and save/reload; no duplicate or abandoned sprites.
6. **Topology:** unrelated parallel lines and crossing tracks must not get a spiderweb; gaps over 16 tiles remain gaps.
7. **Performance:** if possible, check 100+ supports; report lag.

The pole's physical position is **not** snapped/teleported like a signal, to keep native Undo stable. Rotation occurs on the *visual arm only after placement*. It is an engineering compromise, not native rail-signal alignment.

Provide screenshot ZIP and factorio-current.log, plus status output. CI tests syntax/geometry/ZIP only; no actual Factorio client available during source build.
