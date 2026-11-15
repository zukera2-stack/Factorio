# ElectrifiedMainline 0.1.18 — user in-game native player mast build test

**Evidence date:** 2026-11-14 (Factorio log 19:14:43+ local game clock). **Factorio:** 2.1.20 build 87512, win64 Steam Space Age, Bob's mods. **Build under test:** 0.1.18, source commit 78a010cb44995ba71bcfe8e5337a7f63070eff8f, [CI-built ZIP #14115959103](https://github.com/zukera2-stack/Factorio/actions/runs/43601951663/artifacts/14115959103).

**User attachments (not committed):**
- `2026-11-14_19-15-49.zip` (SHA256 `3f0c73b15c927f92251d6eec8251ca8583f7d1fec3f80d7ada2a86f049c778ff`), contains exactly two screenshots `2026-11-14_19-15-49.png` (1927x1080) and `2026-11-14_19-17-06.png` (1921x1080).
- `factorio-current(20261114-161744).log` (SHA256 `cde83d4ac340496a2f384cca2a6e89e7887eff27200106fda518f4141b6b32a3`), 670 lines. The filename has a timestamp different from game clock; the contents unambiguously identify Factorio version and game run.

## Screenshots: cursor-visible marker display

- Screenshot at 19-15-49 shows the real 35kV catenary pole item held, small green outlined squares along ground HSR straight/curved/branching rails, with red squares concentrated inside/between closely spaced rails.
- Screenshot at 19-17-06 shows long parallel straight tracks with green outer rows and many red interior squares; the G-shaped physical poles are already present at several points. No screenshot proves whether an individual visible mast was placed by Alt+LMB vs ordinary click.
- The overlay is clearly visible and follows rails, but is denser and visually brighter than a production UI ought to be. The green positions are **real pole tile centers derived from native rail-signal reference locations**, not exact vanilla green square UI; red is a placement preflight failure, not automatic guarantee of arm/wire geometry.
- No 16-tile sparse filter was applied, consistent with user's request. Arm rotation, catenary suspension and exact mast base-to-wire distance remain visually unverified.

## Runtime log, construction and native Undo

| Tick | Exact log evidence | Conclusion |
|---:|---|---|
| 47958 | `on_pre_build` + `on_built_entity`: real em-35kv-catenary-pole at (24.5,-30.5) | Native ordinary building succeeded |
| 48143, 48221 | `on_undo_applied` built-entity target (24.5,-30.5), marked for deconstruction, later robot mined | Ordinary built pole Undo demonstrated |
| **49936** | `[0.1.18][place] request` cursor (30.758,-17.605), snapped base **(30.5,-17.5)**, source em-high-speed-straight-rail. `on_pre_build` 2 records, `on_built_entity` **1** record, entity type **electric-pole** | **Alt+LMB script-triggered native player.build_from_cursor succeeded**; no evidence of two entities |
| 50119, 50217 | player built entity-ghost (32.5,-28.5), robot later built real pole | Vanilla robot placement still operates |
| 50611, 51505 | player built ghost (-34.5,-33.5), robot later built real pole | Second ghost/robot placement works |
| 50971 | ordinary on_pre_build + on_built_entity at (-31.5,-33.5) | Native normal placement |
| 51794, 51883 | Undo of **(-31.5,-33.5)**, robot subsequently mined pole | Native Undo for another pole |
| 51987, 52063 | Undo of **(-34.5,-33.5)**, robot subsequently mined pole | Native Undo for robot-built ghost |
| 52180, 52285 | Redo of **(-34.5,-33.5)**, restored ghost and robot rebuilt pole | Native Redo works |
| 52588, 52697 | Redo of **(-31.5,-33.5)**, restored ghost and robot rebuilt pole | Native Redo works |

**Double pre-build observation:** in tick **49936**, both `on_pre_build` records target exactly (30.5,-17.5), but only **one on_built_entity** occurs. A second `on_pre_build` alone is NOT proof of duplicate entity or double item loss. Possible conflict between custom input and native placement remains a hypothesis, not established root cause; custom-input `consuming="game-only"` is intended to block conflicting game events, so this requires a focused test of event source and inventory counts, not a scripted workaround.

**Ctrl+Z/Ctrl+Y limitation:** the log has no `on_undo_applied` / `on_redo_applied` entry targeting **(30.5,-17.5)**. Consequently, Undo/Redo for **Alt+LMB** is **NOT VERIFIED**, even though Undo/Redo for ordinary and ghost-based pole placement is game-tested. Do not collapse these into a general 0.1.18 native Undo pass.

The engine successfully loaded 0.1.18, did not show Lua errors / MainLoop errors in this session, and quit normally (`user-quit`, `Goodbye`). No train signal or block invariance test was carried out; no evidence of a new rail-signal proxy appears, consistent with source that creates none. Item consumption for Alt click is engine-defined per LuaPlayer.build_from_cursor API, but **exact before/after inventory counts were not logged**.

## Verdict, remaining gates, and next experiment

**GAME-TESTED PASS:** Factorio 2.1.20 loads 0.1.18; held real 35kV mast shows near-HSR green/red squares; one logged Alt+LMB action calls `LuaPlayer.build_from_cursor` and produces a real `electric-pole` at the snapped native pole grid cell; normal LMB builds, ghosts/robots and normal pole Undo/Redo remain functioning in the observed session.

**UNVERIFIED:** native Undo and Redo specifically for the ALT-built mast; item loss/duplication in the double-prebuild tick; physically correct mast-facing and overhead connection; train block invariance under live traffic; all four HSR geometries isolated for Alt clicks; full case matrix including negative/no-rail and permission restrictions.

**Next minimal falsification test** on the **same 0.1.18 ZIP**: remove all nearby masts, equip exactly 3 mast items, perform a SINGLE Alt+LMB at a GREEN candidate, capture count before/after and tick from log, immediately Ctrl+Z and Ctrl+Y **without any other intervening build commands**, verify same coordinate and whether a built-entity Undo action is present and robots carry out deconstruction/reconstruction, and re-check item count. Repeat while using normal LMB as a control. Inspect double `on_pre_build` behavior at the same tick. Only after it passes should the Alt placement be declared Undo-safe. No 0.1.19 code decision has been taken.
