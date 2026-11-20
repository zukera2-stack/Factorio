> 057 initial CI 44710491163: all Lua syntax passed, ghost 023 legacy fixture excluded new version and asserted obsolete 024 art. Extend its current-art condition to 057; preserve all assertions. No runtime changes. Rebuild pending.

> 0.1.57 test branch: implemented owner-approved icon direction and concrete rail/replacement icons, 2 MW / 2 tiles per tick / brake 20, native wagon migration. Main remains 056; CI and live tests pending. [Research](research/hsr-icons-balance-057.md).

# Electrified Mainline — current handoff (0.1.56)

**Source of truth:** main, original owner-accepted visual milestone, PR #30, merge `55cb71f8f3be8c68cbd2c26fa16fd775c6ba296d`. Main CI [44614544575](https://github.com/zukera2-stack/Factorio/actions/runs/44614544575) passed; [install ZIP](https://github.com/zukera2-stack/Factorio/actions/runs/44614544575/artifacts/14572849193), inner SHA256 `829af87f916f35743463b0ecd61029c88a444efd0c6becd724150ba80398f545`, 121 files, 81 PNGs; identical to accepted CI baseline 662389ad. [User acceptance](tests/catenary-0.1.56-user-acceptance.md). Factorio target 2.1, last known owner environment 2.1.24 build 87808; screenshot alone does not establish exact game revision.

## Current implementation
- Native four ground HSR geometries; 053–055 concrete slabs, wear, native fastener art; preserve native metal and lower ballast.
- Autonomous locomotive with 256 directions, native wheels and paint, cosmetic folded/raised pantograph and spark; owner accepted 052 locomotive and rejected green 051 rail palette.
- 056 decorative planner follows real HSR RailEnd connections, selects reciprocal first masts each direction within 32 approximate axis tiles; separate 046 hidden technical network, not a visual gate. Chord art and coordinates frozen. No actual traction MW, factory-grid isolation unmeasured.
- Native placement, Upgrade Planner and Undo/Redo ownership preserved. Prior scoped game tests remain historical; full regressions at 056 not asserted.
- CI preflights all Lua syntax and version-selected tests before costly sprite generation; package only game files. All install ZIPs via direct GitHub Actions artifact links only.

## Active work and constraints
Only main is active. All 52 other refs indexed in [056 branch archive](history/BRANCH_ARCHIVE_056.md); no physical refs deleted. PR #29 and issue #7 closed as superseded. The later phase-2 experiment `e9e0883aeceb7c577b01340505fc11dfa6998704` is explicitly excluded and frozen; no further visual changes unless a concrete defect is reproduced.

Next substantive phase: research real energy supply, isolated line network, bidirectional substation and MW limits, onboard storage and regenerative braking. Do not implement until native/same-type analogue, exact API and falsifiable test are recorded. Read [AGENTS](../AGENTS.md), [research method](RESEARCH_METHOD.md), [architecture](ARCHITECTURE.md), [machine state](PROJECT_STATE.yaml) and [status](STATUS.md). Branch from main, never merge future feature work without owner approval.

## History and evidence
This concise handoff supersedes the long chronological [prior AI_CONTEXT](https://github.com/zukera2-stack/Factorio/blob/1a94fb8a7e6a860130b071da7cd8d556a4aec96c/docs/AI_CONTEXT.md) and [prior STATUS](https://github.com/zukera2-stack/Factorio/blob/1a94fb8a7e6a860130b071da7cd8d556a4aec96c/docs/STATUS.md); those exact snapshots remain in Git. The [048 register](history/BRANCH_ARCHIVE_048.md), [research records](research/) and [test records](tests/) are retained as historical evidence, not instructions to restart old branches. Historical 0.1.8 rollback ZIP remains under dist. Owner library is for geometry, textures and QA evidence; old installs/temp material archived separately.
