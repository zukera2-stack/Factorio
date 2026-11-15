# Research: 0.1.17 connected-corridor engine slot preview

**Date:** 2026-11-14. **Branch:** feature/catenary-corridor-preview-017, parent feature/catenary-snap-research-017 @ 91f1120dbceca10ecae996b3247816a127361648. **Game target:** Factorio 2.1.20 build 87512. **Before implementation:** read source and previous native-signal-snap-for-catenary-0.1.17.md.

## Observable problem and acceptance test

0.1.16 draws only four mast proposals around two ends of one HSR rail; native rail-signal preview shows legal positions across a whole corridor. We need a bounded continuous-along-rails READ-ONLY marker experiment before any mast placement mechanics. Start on straight HSR, curved A/B, half-diagonal; verify both sides. Empty or vanilla-only track must show nothing. No entity changes, signal blocks, Undo/Redo records, inventory or train behavior modifications.

## Native precedent / evidence / comparison

- Base Factorio 2.1.x: true rail signals show engine-owned snap squares. Their native entity type is rail-signal; electric-pole does not acquire such placement UI through a flag.
- API 2.1.20: LuaEntity.get_rail_end, LuaRailEnd in/out/alternative signal locations, LuaEntity.get_connected_rail, LuaSurface.can_place_entity, LuaRendering.draw_circle. See https://lua-api.factorio.com/2.1.20/classes/LuaRailEnd.html and https://lua-api.factorio.com/2.1.20/classes/LuaSurface.html. These methods expose reference locations and collision checks; they DO NOT guarantee correct G-arm geometry or native snapping.
- Same-type precedent: AudricSan/Factorio-Mods, commit 3c9b713244c5721e7cb582ce5ee46381659323fb, ElectrifiedRailways source v0.3.26; its true rail-signal proxy provides native cursor snap and gets destroyed/replaced. It is NOT copied or used: proxy can affect rail blocks, native Undo and inventory; its mod portal v0.3.25 differs.
- Our source: scripts/rail_slot_debug_014.lua already reads LuaRailEnd slots on one rail. scripts/mast_geometry_016.lua uses rail-end offsets, not native signal slots; existing mast is true electric-pole in prototypes/power_019.lua. Reuse the read-only slot reader instead of inventing geometry.

## Falsifiable hypothesis / design

Walking connected custom HSR rails with engine get_connected_rail, collecting native LuaRailEnd signal locations, and deduplicating by physical position should show a dense trackside candidate layer over straight-to-curved corridors with no rail-signal creation or runtime state. 0.1.17 deliberately does NOT create poles, set automatic spacing, guarantee placement grid alignment, or inherit the exact cursor signal UI. If markers appear on disconnected parallel rail, include vanilla/elevated, or mutate entities/Undo, the design fails.

Implementation: scripts/catenary_corridor_017.lua. On-demand /em-35kv-corridor [8..32], radius 24 default around selected starting rail, only HSR ground geometry, max 128 rails/160 points, temporary 900-tick circles. Engine can_place_entity at each native signal slot indicates ONLY collision clearance, not legitimate pole alignment. One extra cyan nearest highlight; no per-tick scanning, signal proxies, replacement or inventory operations. One bounded read-only command, all existing commands preserved.

## Test plan and evidence boundaries

CI: Lua 5.2 parser; mocked two connected HSR rails + vanilla continuation + disconnected parallel HSR; dedupe, elevated filter, collision preflight, invalid args, negative case, immutability source guard; ZIP packaging. In-game target 2.1.20: screenshots of horizontal/vertical straight, curve A/B, half-diagonal, parallel/disconnected, crossing, occupied spot, only vanilla; record marker count and actual geometry. Compare native signal item view. Use real trains/signals to check block invariance and Ctrl+Z/Redo separately. CI is NOT an in-game test. Until tested, verdict is implemented / gameplay unverified.

Rollback: switch to 0.1.16 branch/build. Stable main 0.1.8 untouched. No GPL source/assets copied.


## 2026-11-14 gameplay result

[Evidence: 9 screenshots and exact Factorio 2.1.20 log](../tests/catenary-corridor-0.1.17-2026-11-14.md) confirms read-only connected native rail slot rendering, nine calls with no API errors and two intentional 160-slot limits. Outer green and inner blocked candidate patterns on close rails show that native reference plus pole collision is useful, but it cannot establish mast base/arm geometry or desired 16-tile spacing. Verdict: read-only *reference acquisition* GAME-TESTED; actual native pole installation / Undo / signalling safety UNVERIFIED.
