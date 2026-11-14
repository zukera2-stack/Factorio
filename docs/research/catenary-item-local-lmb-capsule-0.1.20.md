# ElectrifiedMainline 0.1.20 — item-local Left Click experiment (no extra entities)

**Status:** research-first, experimental, game result unverified. **Factorio:** 2.1.20 build 87512 with Space Age / Bob's pack. **Base:** 0.1.18 tested branch docs commit 8883b8990663349bbd0cae60b7e00d08e3460c25. **Research date:** 2026-11-14.

## 1. User's absolute requirements
- Normal Left Click only, no Alt and no global custom-input consumption.
- Green positions derived exclusively from engine `LuaRailEnd` locations associated with four custom ВСМ rails. No made-up 16-tile spacing or banned safe positions.
- Only a physical `em-35kv-catenary-pole` `electric-pole` placed; no hidden or visible rail signals, rail-support proxies, hidden entities, special tiles or placement/destruction conversions.
- A click anywhere outside the displayed green candidate must do nothing and must not consume material.
- Preserve engine collision validation, native inventory consumption, Undo/Redo, rail Upgrade Planner, ghosts/robots.

## 2. Official engine mechanisms (version-matched docs)
- `CapsulePrototype` has `capsule_action` and **inherits** `ItemPrototype::place_result`. The prototype schema accepts these properties, but **does not specify which action wins when both are present on the same capsule item**: https://lua-api.factorio.com/2.1.20/prototypes/CapsulePrototype.html and https://lua-api.factorio.com/2.1.20/prototypes/ItemPrototype.html .
- `ThrowCapsuleAction::uses_stack = false` prevents the capsule action itself from consuming an item, allowing the player-owned build to account for exactly one real pole. https://lua-api.factorio.com/2.1.20/types/ThrowCapsuleAction.html
- `on_player_used_capsule` reports `player_index`, `item.name` and target `position`; use only for matching experimental item: https://lua-api.factorio.com/2.1.20/events.html .
- `LuaPlayer.can_build_from_cursor` and `LuaPlayer.build_from_cursor` operate on current cursor item and own actual build, cursor stack decrement, `on_pre_build`, `on_built_entity`; they worked in prior user 0.1.18 logs: https://lua-api.factorio.com/2.1.20/classes/LuaPlayer.html .
- Vanilla `CustomInputPrototype` is global per key, cannot conditionally consume vanilla LMB based on cursor: https://lua-api.factorio.com/2.1.20/prototypes/CustomInputPrototype.html .
- `on_pre_build` is observational and cannot veto built-in placement.
- Previous 0.1.18 gameplay proves cursor marker overlay and real pole from Alt+LMB with native Undo. Previous 0.1.19 actual rail-signal research ZIP is NOT the basis for this build (avoids an extra real signal entity).

## 3. New hypothesis: item-local input instead of global LMB interception

Introduce **exactly one new item prototype** `em-35kv-click-probe-020` (a `capsule`) with (a) a harmless, direct `script` trigger effect and `uses_stack=false`, and (b) `place_result = "em-35kv-catenary-pole"`. The **resulting world entity** remains solely the existing `electric-pole`; no new world entity or tile prototypes. The capsule action does no damage or create entities. It is crafted one-for-one from the ordinary 35 kV pole item. The real pole's `placeable_by` stays original for robots, and mined products stay original; experimental item migration not attempted.

If the engine treats this item as a capsule when **ordinary Left Click** is pressed, `on_player_used_capsule` exposes the cursor position and our own handler can:
1. call the existing `scripts.catenary_cursor_018.collect` to compute exact native-rail-derived 1x1 pole tile centers; inspect only custom HSR rails of the current force / surface / ground layer;
2. accept only clicks directly inside the drawn green square (+a minimal tolerance), rejecting off-rail positions early;
3. use `player.can_build_from_cursor` to validate exact position;
4. invoke `player.build_from_cursor{position=approved_point}`, producing one real pole and decrementing the actual cursor item through engine code, with native Undo.
5. record relevant log events and before/after cursor counts to debug.

**Alternative, unsafe outcome:** the engine may prioritize the item's `place_result` over its capsule action, allowing vanilla arbitrary placement without raising `on_player_used_capsule`. This is the actual purpose of the experiment. A Lua mock cannot establish engine precedence. **If this occurs, reject the mechanism and do not migrate the real item.** It may also ignore the `place_result` inside `build_from_cursor` for capsule-type items; that too falsifies the hypothesis.

## 4. Smallest test on disposable Factorio 2.1.20 save

- Install 0.1.20 ZIP, load separate/save copy, craft one experimental `Клик-проба опоры 35 кВ` item from one existing pole. Do not use real operational signals; no real signal is added by this experiment.
- Hold experimental item. Colored engine-rail-derived squares should appear around custom HSR rails, exactly as for old pole.
- Click ordinary LMB **in empty field outside any rail**. REQUIRED: no entity, no consumption. Inspect Factorio log for capsule `use` vs unexpected `on_pre_build/on_built_entity`.
- Click an actual green square on HSR. REQUIRED: one real electric pole appears at marked center; cursor count exactly minus 1; `on_player_used_capsule` called; Undo/Redo restore same real pole. Record two on_pre_build events only if actually observed.
- Click on red/blocked square; vanilla-only rail; outside HSR; on curved A/B, half-diagonal, parallel track. Each off-target must refuse. Verify colored square exact click.
- Check original `em-35kv-catenary-pole`: it is **unchanged** and can still be built outside ВСМ. This means the 0.1.20 ZIP tests feasibility only, NOT completed enforcement for all items. Do not claim product requirement is met.
- Check green vanilla rail Upgrade Planner, Undo and ghosts separately.
- Failure: any off-track build from the click-probe item, or damage/projectile/extra world entity, or cursor count consumed on refusal -> reject.
- If success, **next version** can investigate migration of actual `em-35kv-catenary-pole` item to capsule type, preserve bot/blueprint semantics and safely migrate existing saves; no such migration in 0.1.20.

## 5. Analogue and rejection history
- Vanilla grenade: item-local capsule action naturally processed when the capsule is used, with event `on_player_used_capsule`; **only the prototype pattern is taken from base, without grenade effects**.
- Real world mod precedent [Mouse Bits](https://mods.factorio.com/mod/MouseBits) adjusts built objects using relocation/destruction; rejects this due to inventory/Undo side effects.
- [Restrictions on Artificial Tiles](https://mods.factorio.com/mod/RestrictionsOnArtificialTiles) uses special collision layers / placer entities; rejects because user forbids special ground or helpers.
- Rail-signal proxies in old electrified railway mods are rejected: may mutate railway signaling blocks/Undo.
- Standard selection-tool click-and-drag is not an ordinary single left-click, so inferior UX.
- Additional custom-input LMB `consuming="game-only"` is global, breaks other items; not used.

## 6. Evidence and rollback
Initial: sources + API reasoning only. Implementation + mocked Lua tests + CI are **static**, never proof that actual Factorio routes LMB through `on_player_used_capsule` or that the real 35 kV item is restricted.
Rollback to source 0.1.18 ZIP; stable main 0.1.8 never modified. Keep code experimental and in separate branch.

## 7. Licensing
Uses Factorio's own base capsule structure as reference; third-party source/assets not copied.


## 8. Implementation / static test 2026-11-14

- Extra item prototype `prototypes/click_capsule_probe_020.lua`, world entity still exactly existing electric pole. `capsule_action.uses_stack=false`, instant script effect, target is a world coordinate, `place_result` references the same pole. Recipe converts exactly one real pole item to one probe item.
- Runtime `scripts/catenary_click_020.lua` runs only on `on_player_used_capsule` for the probe item and automatically renders green/red/yellow squares while that item is held. Only clicks within the visible square (+0.09-tile margin) are accepted, and `can_build_from_cursor` must succeed before calling `build_from_cursor`. A new log line explicitly records `count_before` and `count_after`.
- Existing real pole item, Alt+LMB handler, prototypes, HSR rails, Upgrade Planner and Undo callbacks are unchanged. No direct create/destroy/teleport of entities; no new world entity or tile.
- **Static build: PASS**, [GitHub Actions #43626117619](https://github.com/zukera2-stack/Factorio/actions/runs/43626117619) from source commit `9dde1d23e02991c89dd569297da6d0c55241dbff`. Lua 5.2 syntax and mocked regression tests 0.1.13–0.1.20 passed; `ElectrifiedMainline_0.1.20.zip` created and verified as artifact [#14125619952](https://github.com/zukera2-stack/Factorio/actions/runs/43626117619/artifacts/14125619952). **Not yet game tested**: capsule/placement input priority and off-rail rejection.
- Failure criteria not waived: if LMB anywhere outside HSR places a pole by native item `place_result`, or no capsule event is fired, or genuine `build_from_cursor` refuses a capsule, reject this architecture. No final migration or release approval.


## 9. USER FACTORIO 2.1.20 RESULT: FALSIFIED (2026-11-14)

## What was observed in the game

- 0.1.20 successfully completed the data stage and locale stage, initialized and loaded the user's ВСМ save; user quit normally. Hotfix from 2026-11-14 fixed the prior fatal duplicate locale.
- Four real `em-35kv-catenary-pole` electric-pole entity placements were logged via ordinary `on_pre_build` + `on_built_entity`:
  - tick 47935, (-9.5,54.5)
  - tick 49949, (3.5,2.5)
  - tick 50503, (7.5,8.5)
  - tick 50892, (6.5,2.5)
- **No** `[ElectrifiedMainline][0.1.20][probe]` events or `on_player_used_capsule`-derived build attempts appear. The log alone doesn't label which cursor item generated each event; the **user explicitly reports** off-HSR build with the probe item.
- This **falsifies the proposed safety invariant**: an item prototype having both capsule action and `place_result` is not a reliable vanilla-LMB pre-build HSR gate on Factorio 2.1.20. Likely `place_result` takes precedence on LMB (game test supports behavioral outcome, not isolated engine cause). No reason to keep developing this dual-use capsule pathway. Keep as archived experiment; NO release to main.



See [game report](../tests/catenary-click-probe-0.1.20-game-fail-2026-11-14.md). Capsule plus place_result does NOT provide item-specific normal LMB HSR-only restriction in the tested game. **STOP trying to ship 0.1.20 as an HSR-placement gate.** User suggests simplifying requirement to rail-dependent contact wire visibility; existing `power_019.lua` implements this **visual** restriction, not real electricity. No production code changed.
