# 0.1.57 appearance, locomotive balance and wagon removal

## 1. Metadata
Owner approved 2026-11-20; branch feature/hsr-icons-balance-057 from 7849d192ba35823d9636abe9bc6d370beb41adfa; target Factorio 2.1.24 build 87808 (last known, screenshot exact build unverified). Original 0.1.56 remains main.

## 2. Observed behavior
Owner screenshot archive 2026-11-20_12-03-19.zip: rail planner and replacement planner indistinguishable, both vanilla gold sleeper rails; custom locomotive diagonal top-left to bottom-right while base red locomotive faces lower left, diagonal lower-left to upper-right. Tooltip 324 km/h, 600 kW, weight 2000. Custom wagons duplicate vanilla.

## 3. Acceptance
Compare item, recipe and entity icons in inventory and crafting at real UI scale; concrete rail clearly distinct from vanilla, replacement tool unmistakable with arrow and separate frame. Locomotive nose lower left. Test 432 km/h nominal limit (2 tiles/tick), 2 MW, brake 20, weight 2000; actual loaded train speed depends on composition and resistance. Load disposable 056 save with loaded custom wagons, fluid, items, filters, schedules and blueprints; verify vanilla replacement and retained contents. Retest native rail planner and Undo/Redo; no changes to network or pantograph motion.

## 4. Native analogue
Inspected wube/factorio-data tag 2.1.24, base/prototypes/entity/trains.lua blob 8ca4c05de9d5cf66c5f09a9fb23e14fca951f795 via GitHub. Vanilla loco: 1.2 tiles/tick, 600kW, weight 2000, braking_force 10, friction 0.50. Vanilla wagons: weight 1000, braking_force 3, same native clones used in our bootstrap. Native icons refer to base locomotive.png and rail.png; actual native orientation seen in submitted screenshot. model_049.py declares front +Y; camera at angle(160) is on +Y/-X side, front projects lower-left; existing 96 is opposite diagonal. Use same procedural thumbnail camera, do not rotate gameplay atlas. No third-party assets copied.

## 5. API
Official https://lua-api.factorio.com/latest/prototypes/RollingStockPrototype.html and LocomotivePrototype.html describe max_speed in tiles/tick, max_power and brake; https://lua-api.factorio.com/latest/auxiliary/migrations.html describes JSON prototype renaming before map load. Exact 2.1.24 docs URLs inaccessible at research time; latest pages report 2.1.21/25, exact native 2.1.24 source inspected. Migration maps old entity and item names to existing vanilla counterparts. No runtime destruction/recreation. Old recipes removed; do not rename to vanilla recipe to avoid implicitly unlocking it. Existing crafting queues for removed recipes unverified. Same-type rename behavior and payload preservation need game validation.

## 6. Hypothesis
Change only inventory camera from 96 to 160 for 057, generate two original 64px HSR icons after existing asset validators. Apply icon to item/entity/recipe/technology consistently, clear inherited icons. Effective cloned locomotive properties changed in bootstrap (including redundant initial prototype), preserve physical geometry, native wheels/masks, void placeholder and runtime untouched. Remove item/entity/recipe/unlock and RU/EN strings of redundant wagons; add native JSON migration. CI tests prototype and migration contract; no assertion that save migration works until live test. 056 rollback requires pre-upgrade save backup. Owner specifically approved numbers and scope; no new traction mechanics.
