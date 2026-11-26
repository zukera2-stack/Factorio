---
name: factorio-handoff
description: Recover active Electrified Mainline work from GitHub when starting a new chat, resuming a paused task, checking versions, status, branch differences, or past acceptance evidence. Prevent mixing accepted main, installed updater build and experiments.
---

# Factorio repository handoff

Use this whenever the user asks to continue, says "новый чат", asks what to test next, references last session, or a branch/version appears ambiguous.

1. Identify repo `zukera2-stack/Factorio` and fetch live heads for `main`, `test/updater-approved`, `feature/git-updater-060`, and the experiment branch referenced in `docs/CURRENT_WORK.md`. If access fails, report uncertainty and do not invent commit SHAs.
2. Read [current work](../../../docs/CURRENT_WORK.md), then [AGENTS](../../../AGENTS.md) and the target **branch's own** `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml`. Never mistake branch-scoped 0.1.56 docs for full repo status.
3. Read exact `ElectrifiedMainline/info.json` on that branch and inspect relevant code. An experimental 061 test-only tool does not imply the installable mod version is 0.1.61.
4. Separate **main stable visuals** (0.1.56), **approved test/patched 060** (0.1.60), **updater software 1.1**, and **not-engine-tested 061 native-priority research**. The branch map is an as-of snapshot, not authoritative live state.
5. Compare proof levels explicitly: planning / implementation / syntax tests / package CI / official native engine / owner actual save / owner-approved deployment. Give exact run/commit/artifact links.
6. Preserve user constraints: do not change accepted art without a reproduced defect; no unapproved main merge or updater ref promotion; do not require repeated manual ZIP installs when existing updater suffices.
7. If user asks to continue development, identify the **actual next open acceptance test** before coding. For current 061: P1–P7 EEI input/output priority matrix must be **implemented in a disposable probe and game-tested**; existing P8 overlap-only test and CI are not that matrix.
8. After any material decision, test result or code change, update `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml` on the affected branch **in the same commit**; if other branches' roles change, propose a documentation-only PR updating `docs/CURRENT_WORK.md` in main.
9. End with a succinct handoff: current branch/HEAD, changed files, QA level, user action (if any), open risks and next task. No imagined asynchronous work.

Never copy old commit logs into a new answer as if live; fetch and reconcile first.

## Parallel native functional QA (EM087N)

Before running a regression batch, read [parallel QA standard](../../../docs/development/PARALLEL_QA_STANDARD.md) and [runner](../../../tests/em087m-mixed-outposts/PARALLEL_QA.md). Measure actual RAM/CPU and calibrate workers; on the tested 4 GiB/4 CPU environment prefer up to 3 small workers, 2 medium, 1 large with 768 MiB reserve and separate writable paths. Never run independent QA alongside UPS/profiling benchmarks. Reuse exact engine/mod, record per-case results and resource peaks. The sampled memory guard is not an absolute OOM guarantee. EM087N 11/11 serial and parallel, 2.18x batch throughput; no runtime acceleration implied.
