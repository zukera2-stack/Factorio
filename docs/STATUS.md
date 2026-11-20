> 060 implementation: native 059 topology confirmed in game 44 vs factory 27/61, auto stayed idle. Independent bounded physical-device sampling for vanilla dynamic EEIs and accumulators, max aggregation without duplication, nonstorage maximum-flow fallback, own offer/request subtraction, native per-interface flow caps, raw and planned diagnostics. Exact engine cause not isolated. 060 CI/live pending; main unchanged.

> 060 research: owner 059 live log proves native corridor 44, separate ordinary 27/61, visible/hidden mast IDs equal, script links verified; automatic status remained idle. No raw flow fields or EEI modes were logged, so exact engine-flow cause not isolated. Preserve topology. Inspect explicit dynamic EEI configuration (native 2.1.24), actual accumulator energy and rates, aggregate maximum/priority flow readings; correct request-vs-offer feedback and test idle start. Main unchanged.

> 059 CI PASS: source 45342457835276d2eaadf80ffc96ae82d9591714, run 44757346136, install artifact 14639915542 https://github.com/zukera2-stack/Factorio/actions/runs/44757346136/artifacts/14639915542 . Inner ZIP SHA256 d00f7625a92011ecb43c9977c3391a7c83da225c821f99185af81d30c0a593ce ; 128 game files / 83 PNGs. All 058/059 Lua model/mock tests and existing visual regressions passed. Owner 058 log: 115 actual straight rail builds and 10 remaining masts, all at y=-125.5, max adjacent x-gap 31 tiles; two stations configured, 20MW GUI evidence. Settled 058 wire IDs not logged. 059 auto flow sampling, visible native mast wire, actual charging/discharging, save/rail break and performance still require live testing. Main unchanged.

> 059 implemented experimental automatic bidirectional allocation with real native flow observations, per-station shared 20MW ceiling, no battery-to-battery transfer, actual EEI energy debit/credit, visible mast joined to own isolated anchor and audited; auto default, active 058 modes migrate to auto, off preserved; manual commands still available. 058 owner evidence 20MW manual transfer but visible mast empty. 059 CI and all live new behavior pending. Main untouched.

> 059 research: owner 058 screenshots show 20MW at station-side vanilla networks, empty visible-mast GUI; log confirms 2.1.24/87808, two mode commands and selected feeders, no settled network IDs. Owner requests automatic reversible bridge and remote vanilla accumulator charge/discharge. Preserve 058 artifact; new test branch, main unchanged.

> 058 CI PASS (run 44750917384, source e5de8a8bd425d716ff9d7d61dbfccf6cf843e10e): 058 energy/loop/lifecycle Lua mock tests and 056 regressions passed, 126 game files / 83 PNGs. Install artifact 14635601471: https://github.com/zukera2-stack/Factorio/actions/runs/44750917384/artifacts/14635601471 . Inner ZIP SHA256 5fe82a166920dfac99c0541f3e334f3e3195322f26c07fe0cb2f3ce16c400341 . Live 25 kV network IDs, cross-surface wire attachment and actual engine energy transfer remain unverified. User test pending; main unchanged.

> 058 initial CI 44750760503 failed at legacy 048 continuity fixture because inner axis-test gate omitted 058; corrected the gate, old assertions retained, no gameplay changes. Rebuild pending.

> 058 experimental implementation: genuine separate native corridor via two isolated terminal poles and fixed-direction EEIs on dedicated lab surface. 20 MW per station, explicit import/export/off (default off), zero drain, actual buffered joule debit/credit, cycle rejection and exact connector checks. Train consumption and auto direction not implemented. Main remains 056; 057 graphics and migration carried forward. CI and live game unverified. [Research](research/25kv-power-bridge-058.md).

> 058 research branch: native corridor 25kV, isolated 20 MW reversible substation bridge, manual off/import/export for first experiment. Based on 057 candidate (package failed because pad cleanup predicate omitted 057; fix in 058). Main remains 056. No traction yet. [Research](research/25kv-power-bridge-058.md).

> 057 initial CI 44710491163: all Lua syntax passed, ghost 023 legacy fixture excluded new version and asserted obsolete 024 art. Extend its current-art condition to 057; preserve all assertions. No runtime changes. Rebuild pending.

> 0.1.57 test branch: implemented owner-approved icon direction and concrete rail/replacement icons, 2 MW / 2 tiles per tick / brake 20, native wagon migration. Main remains 056; CI and live tests pending. [Research](research/hsr-icons-balance-057.md).

# Project status — stable visual baseline 0.1.56

Main merged via [PR #30](https://github.com/zukera2-stack/Factorio/pull/30), original 056 accepted by owner. Main [CI 44614544575](https://github.com/zukera2-stack/Factorio/actions/runs/44614544575) and docs checks passed. [Install ZIP](https://github.com/zukera2-stack/Factorio/actions/runs/44614544575/artifacts/14572849193); same inner SHA256 as baseline `829af87f916f35743463b0ecd61029c88a444efd0c6becd724150ba80398f545`. No new runtime source changes during cleanup.

| Subsystem | Status / evidence |
|---|---|
| HSR ground rails and visual slab/fastener layers | Implemented; original 056 screenshot shows accepted visual scope |
| Locomotive 256 directions, tint, native wheels, pantograph and spark | Implemented; 052 owner acceptance and 056 CI |
| Decorative contact graph along actual HSR | Owner accepted original 056; parallel tracks and curved continuation observed; mock regressions passed |
| Ghost previews, rail gaps and restoration | CI mock coverage; exhaustive 056 live matrix not established |
| Native Upgrade Planner and Undo/Redo | Earlier scoped game evidence; full 056 regression pending |
| Separate hidden technical network | Implemented; actual factory isolation/network IDs not measured in 056 |
| Traction MW, storage, regeneration, substations as real power exchange | Not implemented; next research |
| Phase-2 attachment experiment | Frozen and excluded from main |

## Next work
Branch from main; separate technical research from accepted visuals. Before changing power behavior, inspect native and maintained same-type analogues, confirm API of target game, record provenance and acceptance scenarios. No speculative engine flags or duplicate Undo ownership. Prioritize measured technical isolation and actual transfer before traction/storage. Full in-game regressions remain outstanding where unverified.

## Repository maintenance
[Branch archive](history/BRANCH_ARCHIVE_056.md) lists exact retained refs. No active PR or issue after closure of superseded #29 and #7 (as of cleanup); no deletion. [Current handoff](AI_CONTEXT.md), [project state](PROJECT_STATE.yaml), [current acceptance](tests/catenary-0.1.56-user-acceptance.md). Detailed chronological [old status](https://github.com/zukera2-stack/Factorio/blob/1a94fb8a7e6a860130b071da7cd8d556a4aec96c/docs/STATUS.md) remains in Git; historical claims and pending labels in it are not current.
