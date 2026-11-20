> 0.1.57 owner-approved candidate: vanilla-facing icon, concrete rail icon and distinct replacement tool, 2 MW / max_speed 2 / brake 20, remove redundant cargo/fluid wagon variants with JSON item/entity migration. Research phase; no main changes. [Research](research/hsr-icons-balance-057.md).

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
