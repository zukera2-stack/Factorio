# EM090B — classical brake calibration and read-only native estimator

**Status: PASS for diagnostic calibrated calculation; production energy credit not implemented.** Date 2026-11-26. Parent EM090 `c02e48e6f82ff7fc9887fe357b05c88c231cc8ad`, unchanged 0.1.101 SHA256 `6e2b48acea118b4542ff0be0b8101c1b844bb74e1359897af1b2653818fd8376`. Actual Factorio 2.1.24 build87808 linux64 headless. Owner approved classic formula with calibration, not virtual kinetic storage. No main/owner/release change. Research before implementation: RESEARCH.md. Wiki https://wiki.factorio.com/Locomotive, API https://lua-api.factorio.com/latest/classes/LuaTrain.html and https://lua-api.factorio.com/latest/classes/LuaEntityPrototype.html; native runtime exact version is the proof, not API latest. Base exact locomotive/cargo-wagon analogue; no third-party code copied.

## Native matrix

8/8 independent same-weight (3000), same-power (2MW), same friction (1), leading locomotive air (.0075) cases. A coast, B locomotive brakes 20 + wagon .001, C loco .001 + wagon 20, D both 20, D bonus +100%, three auto station variants. The near-zero .001 is not literal zero. Manual stop via switch to manual mode (not player input); B/M law exact for nonterminal moving samples. Native locoonly/wagononly and autolocoonly/autowagononly trace numeric rows identical after exchanging brake coefficients. For 378 coast intervals t123..500 the wiki-type coast law matches to 9.72666391874e-13 tiles/tick. Manual brake does not add separate drag. Auto station differs: reject terminal adjustment, conservatively subtract predicted coast and cap by nominal B/M. No proof of exact mechanical brake work or signal/player variants.

| Manual case | B/M | Moving brake intervals | Max abs error |
|---|---:|---:|---:|
| locoonly | 0.006667000000 | 165 | 2.0036e-16 |
| wagononly | 0.006667000000 | 165 | 2.0036e-16 |
| both | 0.013333333333 | 82 | 6.6667e-13 |
| bothbonus | 0.026666666667 | 40 | 6.6674e-13 |

## Calibrated calculation (test-only)

K=C*M*v^2/2 (v tiles/tick, M native game mass), C=450 experimental. Minimum positive paid acceleration ratio dJ/(M*(v1^2-v0^2)/2) in 8 matrix training cases 976.784774859; chosen rounded down below half training minimum. Independent prior EM090 holdout 10 traces minimum 632.279343727, fullmod consumption is inferred from paid grid + store discharge - native burner reserve, not a direct mechanical measure. These are sample bounds, not a universal constant. Experimental eta .65 and 2MW loco regen rating not final approved balance. Native braking work allocated by B_motor/B_total and capped by installed regen watts/60. Manual verified exact B/M uses observed K drop; auto station nominal-to-nominal-plus-coast band uses conservative predicted coast subtraction and nominal cap. Reject terminal adjustment, zero speed, unknown samples/direction/composition/parameters, unverified source, damage, gaps and abnormal deceleration. No virtual energy pool: start certification at verified rest, require every positive K change <= measured native debit (0.001 J numerical tolerance); invalidation until rest. Sum K declines cannot exceed increases in a certified epoch from rest, so hypothetical output is bounded by verified consumption with numerical tolerances. This proof depends on accurate paid source and interval attribution. No real recovery: estimator is read-only QA Lua, not in production. First version incorrectly rejected tiny negative roundoff during idle in fullmod; normalize only [-1e-6,0) J to zero. Retain prior logs; final exact estimator copies identical, final rerun 15/15.

## Final diagnostic Lua cases

| Base case | Actual finite fuel J | Hypothetical J | Max J/tick |
|---|---:|---:|---:|
| autoboth | 7435555.556 | 536332.468 | 7140.644 |
| autocollision | 20000000.000 | 130647.928 | 7140.644 |
| autolocoonly | 6268888.889 | 647845.999 | 4005.408 |
| autowagononly | 6268888.889 | 32.392 | 0.200 |
| both | 4002222.222 | 264263.292 | 6381.723 |
| bothbonus | 4002222.222 | 257817.846 | 12529.446 |
| coast | 4002222.222 | 0.000 | 0.000 |
| cycle | 12002222.222 | 800466.400 | 6428.531 |
| locoonly | 4002222.222 | 534939.942 | 6440.220 |
| passive | 4002222.222 | 0.000 | 0.000 |
| starve | 4000000.000 | 0.000 | 0.000 |
| wagononly | 4002222.222 | 26.747 | 0.322 |

Three actual accelerate/stop cycles (no fuel recycling), cumulative fuel 12002222.222 J, hypothetical 800466.400 J. Native starvation from a finite 4MJ source: 779 speed decreases, no brake flag, 0 J estimate. External cutoff control also 0 (source intentionally unverified after cut). Passive-only hypothetical motor share 0 gives 0 despite actual brakes. Real tank collision tick243, speed 1.575710420819 -> 0; t242 damage and t243 zero estimate; earlier ordinary braking yields positive estimate, not collision credit.

| Fullmod enabled storage | Estimated native fuel J | Hypothetical J | Max J/tick |
|---|---:|---:|---:|
| onboard-empty | 0.000 | 0.000 | 0.000 |
| onboard-move | 11933333.333 | 992395.939 | 8670.089 |
| onboard-outage | 12352885.933 | 1144618.356 | 8875.529 |

Fullmod move/outage both arrive x=-696 with preserved cargo/fluid, closed fixture source/store/paid balance unchanged. Real weight4001 incl helper, native B=36, motorB=26 (real loco20 + motor wagons3+3), F=2, regen nameplate trial 3MW. Hidden helper B=10 participates only in denominator. Verified 178/196 positive estimated intervals respectively, rejected 22/24 terminal adjustments. Empty source 0. No energy actually credited to battery/network; no live train speed writes.

## Execution and limitations

4GiB cgroup memory, 4 CPU quota, reserve 768 MiB; Base workers 3, fullmod workers 2, separate writable dirs, full archives copied per process. Original matrix 11.389s peak 2299125760 bytes; final Base 14.057s peak 2373943296 bytes; final fullmod 8.114s peak 1928863744 bytes. No OOM or guard trigger. 8 original matrix + 15 final diagnostic executions, overlapping scenarios not 23 unique. Prior 10 holdout traces reused as analysis, not new runs. Earlier diagnostic and rounding variants retained. No full 91-case regression because runtime unchanged. No general source/collision guarantee, exact native per-interval debit for arbitrary helper lifecycle/mixed diesel or external edits, save/load while braking, active player control, signals, reverse, long/100-train UPS or multiplayer validated. 0.1.101 still experimental, storage opt-in. Next EM091: prove native debit boundary through existing transfer layer, integrate opt-in real onboard credit only with receiver capacity and no same-tick double counting; validate repeated cycles with actual reused energy, full/empty receivers, loss, split/reload, no free energy. Preserve final priority 25kV->store->loss; isolated battery-first research only. No unapproved main merge, owner install or release.
