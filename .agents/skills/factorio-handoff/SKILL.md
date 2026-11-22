---
name: factorio-handoff
description: Recover active Electrified Mainline work from GitHub when starting a new chat, resuming a paused task, checking versions, status, branch differences, or past acceptance evidence. Prevent mixing accepted main, installed updater build and experiments.
---

> **2026-11-22 ACTIVE OVERRIDE:** Historical references below to stable main 0.1.56, installed updater 0.1.60 or active research 061 are outdated. Consult live branch heads and [the current work index](../../../docs/CURRENT_WORK.md). Every autonomous acceptance or parallel game test must follow [the FULL MOD boundary protocol](../../../docs/tests/AUTONOMOUS_FULLMOD_BOUNDARY_PROTOCOL.md) and [run record](../../../docs/tests/AUTONOMOUS_FULLMOD_RUN_TEMPLATE.yaml). Test the latest full GitHub Actions mod ZIP on unchanged gameplay bytes, **never** a reduced probe as a substitute, and report known P0/P1 and unsupported GUI/migrations explicitly. No user save or main merge.


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
