> Updater 1.1 Windows run 44779144690 failed Git fetch --stdin because Windows PowerShell pipeline serialized the OID with a BOM/trailing character (invalid refspec). ZIP conversion, cross-volume TEMP backup and verify passed. Fix: pass validated hex OIDs directly as positional refspecs in batches of at most 400; normal 129-file install is one fetch. Re-run real Windows fresh install and all regressions. No gameplay change.

> Updater 1.1 CI 44778965679 caught script parser error from a duplicated source suffix during edit of confirmation regex. Removed duplicate and restored valid expression. No user files affected. Full Windows retest required.

> Updater 1.1: owner removed ZIP intentionally; initial install failed with connection failed / promisor blob f0dcbbb440536f695332d37667dd62c1a4f065dd, no installed folder created. Replace per-object network fetch with explicit batch --stdin (upstream Git promisor-remote.c v2.54.0 and git-fetch docs), retry metadata and object fetch 3 times, enumerate locally present objects, disable lazy fallback in blob extraction, Russian menu with path choice and versions, progress, move cache/staging/backups to Windows TEMP keyed by mods path. Cross-volume transfer copies to temporary sibling and verifies before publish. Temporary backups may be cleaned by Windows. New real Windows fresh-install regression; game payload and approved ref unchanged. QA pending.

> Windows updater QA PASS: run 44774421856 / artifact 14649231054 / source 911d6f95015fd1f7c1508a6f8e69acaf7655ce02. Native Windows PowerShell 5.1 and real Git: 129 reused, 0 fetched converting exact 060 ZIP; verify passed; deliberate one-file change detected and repaired (128 reused, 1 fetched); two rollbacks restored modified folder and original ZIP byte-exactly; duplicate installation refused; sentinel other mod and mod-list untouched. Earlier Git path and rollback variable defects fixed. Owner PC test pending. Approved ref remains ea9366a9798cd78efec4b675c81d086c09170c28; main unchanged.

> Windows QA 44774196359 confirmed exact ZIP conversion (129 reused, 0 fetched), integrity check, deliberate modification detection and one-blob repair (128 reused, 1 fetched). Rollback caught case-insensitive PowerShell variable shadowing of the backup root. Renamed root variable to DisplacedRoot; rerun complete test before shipping.

> Updater Windows QA run 44773898757 caught multiple installed git.exe paths; selecting first executable instead of treating all paths as one command. Retest pending; no mod payload change.

> Owner approved Windows Git updater. New explicit opt-in distribution mode: unpacked development mod only, from dedicated test/updater-approved ref pinned to CI-verified exact runtime tree. Install ZIP rule unchanged. Stable main untouched. First pointer ea9366a9798cd78efec4b675c81d086c09170c28, byte-identical 060 verified CI 44772684519 and original native run 44762226742. Fetch blobless Git metadata, reuse local matching bytes and fetch only missing/changed blobs, stage and verify full tree before switch; retain previous mod outside mods, refuse duplicate installs and running game, never modify saves/mod-list. Windows tests pending. Future pointer moves explicitly by contributor only after validation; never follow arbitrary development HEAD.

> 060 frozen fast CI PASS: run 44772684519, source ea9366a9798cd78efec4b675c81d086c09170c28, artifact 14646859081, 83 PNG SHA256 checks, 129 game files, render052 SKIPPED, full Lua preflight passed. Inner ZIP SHA256 exactly matches verified 060: 10b00013e66ed1d63ec901449fb166ab9a80fa391c2afb0d0f0c0910901fcbf9. No installation needed; same artifact bytes. Owner 060 log factorio-current(20261120-155649).log lines 685–714 confirmed sustained 20MW automatic transfer after configuring primary_output/secondary_input; tertiary mode and owner accumulator integration remain open. Use this frozen branch as base for next development; updater not implemented. No main merge.

> 060 asset freeze succeeded in run 44772563088, commit 7b723f4feb65e366c9ae11c13a17864b3c435fbc: recovered 67 PNGs; 83 total manifest SHA256 checks passed; all 129 runtime files byte-identical to native-tested CI archive. Original 060 freeze job 44772452636 failed only at push of a workflow file (GitHub App permissions), not content. Normal build now skips artwork generation when manifest is present, retaining legacy path if absent. Fast CI validation pending. No gameplay changes, no main merge.

> 060 asset-freeze experiment: reuse the exact native-tested CI archive run 44762226699 / artifact 14642176934 / SHA256 10b00013e66ed1d63ec901449fb166ab9a80fa391c2afb0d0f0c0910901fcbf9. Existing Git tree has 16 runtime PNGs; installed archive has 83. Freeze remaining PNGs without changing any runtime byte, record full graphics manifest, keep original rendering scripts and historical workflows available. Test-only branch, no main merge. Freeze job verifies all 129 payload bytes before committing and only then enables normal fast packaging; status pending.

> 060 VERIFIED HEADLESS: exact Factorio 2.1.24 build 87808, package source 581724a99b129b2c3772b207ac358ca1c3b00e34, package run 44762226699 artifact 14642176934, inner ZIP SHA256 10b00013e66ed1d63ec901449fb166ab9a80fa391c2afb0d0f0c0910901fcbf9. All Lua and package QA passed (129 game files, 83 PNGs). Native run 44762226742 success, logs artifact 14642681077: isolated native corridor, 20 MW source/sink, delivered 78666666.666667 J; four vanilla accumulators stored 7140000 J, reverse sink received 5940000 J, batteries retained 1180000 J. Transition loss bounded by buffer/solver timing; no creation of energy. Prior native reverse failure corrected by pre-change request accounting and bounded input buffer. Owner save with Bob's mods and live rail removal are not yet native-tested. No main merge.

> 060 native trace 44761862987 reproduced startup feedback exactly: dt601 new reversal EEI displayed 20k J/tick input limit; dt602 native secondary demand nevertheless 333333 J/tick on battery and corridor, causing false local load, idle and 60-tick restart. Fix: bound both input buffer and runtime rate, account upper-bound pre-change native request/offer for transition tick only, keep measured joule debit. Added regression using actual recorded spike 333333->20000, and repeat exact CI package on real engine. Earlier artifact withheld.

> 060 native test run 44761644008 exact Factorio 2.1.24/87808 compiled package: cold start 78,666,667 J received, four accumulators charged 7,100,000 J, reverse FAILED (0 J recipient, 7,020,000 J remaining). Auto direction flaps idle within a few ticks. Do not deliver this intermediate artifact as a fixed build. Added per-tick engine observation to isolate feedback. Native probe logs artifact 14642005570.

> 060 added separate exact-build headless QA workflow with test-only mod. Downloads CI artifact 44761190848 inside runner; installs official 2.1.24, creates test surface, real HSR, masts, substations, vanilla EEIs and accumulators, measures native delivery/reversal; no test code in game distribution. Download or native test may fail; result pending.

> 060 CI audit: restored 057 prototype and 058 manual bridge regression gates, which were omitted for later versions by historical hard-coded version lists. No gameplay change.

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
