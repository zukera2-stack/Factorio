# 056 phase 2 — unified visual rail attachment (research before implementation)

## 1. Metadata
Starting branch feature/hsr-axis-wires-056, commit 662389ad2f8737e30170e5284c4d3ddea41d9108. Factorio 2.1.24 build 87808, mod 0.1.56. CI run 44611594056 succeeded, install artifact 14573715719; game untested. Scope: visual only. Technical network fields and native Undo untouched.

## 2. Operation and acceptance
Place ordinary and short-north mast near real HSR; its arm and decorative neighbour planner must use one sampled RailEnd projection. Equidistant distinct tracks must not be chosen by unit ID. No arbitrary wire or arm when ambiguous; normal shaft remains. At a shared endpoint of directly connected rails the same point may use a deterministic representation, not arbitrary track selection. Preserve real/ghost consistency. Test parallel tracks, reversed enumeration/IDs, shared joined endpoints, disconnected crossings, all existing CI tests, live curves A/B and Undo/Redo. No new engine writes.

## 3. Analogue and API
Existing 022 `ElectrifiedMainline/scripts/mast_facing_022.lua` and 017 `scripts/catenary_corridor_017.lua` inspected at 662389ad2f8737e30170e5284c4d3ddea41d9108; 022 independently samples Bezier projection, 017 uses native connections and RailEnd locations. Existing 056 `scripts/catenary_axis_056.lua` follows actual native end-to-end graph. Official LuaEntity runtime docs https://lua-api.factorio.com/latest/classes/LuaEntity.html (2.1.25 inspected, exact installed 2.1.24 not independently verified) confirm get_rail_end and get_connected_rail neighbour plus direction pointing back. No new API calls or prototype flags; use same methods. No separate external mod analogue needed for pure selection and batching policy; no claim of exact native spline.

## 4. Difference and hypothesis
Legacy facing uses radius 3 and a 20-chord approximation; 056 planner uses radius 5 and 24 chords. Technical association uses entity centers, leave it intact. A shared visual resolver can return selected rail, station and point, or detached/ambiguous. For visual ties within an experimental 0.05 tile distance tolerance across different projected points or disconnected rails, reject attachment. Shared identical point at directly linked ends is not a parallel-track tie; require all tied candidates to agree pairwise. Use existing native connectivity; no global block/segment assumption. Apply visual face from the chosen projection; no arbitrary arm for ambiguous cases. Keep no-rail fallback art for real detached masts; ghosts without a route may omit arm. Technical continuity is not inferred from visual attachment.

## 5. Performance
Coalesce multiple rail-change refresh buckets per tick into one graph build without changing the selected graph; retain complete refresh of legacy node fields. Global graph per mast edit still exists. Record performance limits, benchmark separately.

## 6. Falsifiable tests
Mock exact equidistant parallel rails, reversed IDs/order, clearly nearer rail, connected shared endpoint, disconnected crossing, real/ghost facing and gap recovery, multiple changes per tick. CI must pass before claiming packaging. In-game evidence pending.

## 7. Implementation
**056 visual attachment phase 2 implemented:** one RailEnd projection determines graph and arm direction, same for ghosts; near-equal independent paths (0.05 tile experimental tolerance) are excluded and ambiguous masts have no arm/wire. Direct reciprocal shared endpoint is allowed. Technical node fields, native placement/Undo and assets unchanged. Rail-change buckets coalesced to one full plan per tick; unchanged arm sprite reused. New tests cover tie/order, shared endpoint, crossing, real/ghost agreement and batching. Full graph still recalculated per mast edit/ghost preview; load tests and in-game QA pending. Baseline CI artifact 14573715719 retained.


CI and game evidence pending.
