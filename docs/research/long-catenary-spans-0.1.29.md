# Experiment 0.1.29 — 32/16 tile limits, 40 tile copper helper

Base: experimental 0.1.28 commit 544465dc5649f5bee60ebb684adeaf9dd64014f6.
Branch: experiment/25kv-span-029. Main remains approved 0.1.24.
Target Factorio 2.1.20 build 87512.
User specifically approved straight=32, curve=16, connector reach=40.
The 25 kV label is nominal only; no AC power model or transfer_MW.
The approved drawn contact+messenger+droppers visual is NOT a run-time
texture yet. This experiment retains native copper wire for regression.

## Source of truth
scripts/catenary_limits_029.lua is a pure Lua module loaded in data and
runtime stages. ElectricPolePrototype.maximum_wire_distance=40 (official
API max64). Straight-span graph radius=32; bend graph radius=16.
Source: https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html

## Safety / path validation
The 0.1.28 three-sample corridor was insufficient for 32 tiles: now
samples every ~2 tiles. A bounded least-cost walk over connected
custom ВСМ rails returns rail-path approximation and records if any
rail is curved. If the path contains curve-A, curve-B or half-diagonal,
the 16 tile limit applies, even if both endpoint rails are straight.
Never traverse vanilla rail. Reject long detours and distant rail loops,
as well as opposing sides of a continuous straight line. The
straight-line topology's existing tangent/side criteria still apply.
A corner connection also requires a physically connected custom
rail path and a turning geometry candidate. Legacy tests are retained.

On rail mining the influence radius is STRAIGHT+RADIUS+4 to reach masts
at both ends of 32-tile spans. No direct modification to native train
blocks, Upgrade Planner or Undo/Redo ownership.

## Known limits
"Track length" is approximated from rail-entity center distances, not
true rail spline arc length. At complex junctions, end tangents can
still reject a valid pair or admit an unintended branch. Real in-game
validation required; static CI never proves the graphical layer or
actual curved track topology. No per-pole custom copper texture
exposed by the engine. Do not merge before screenshots/log.
