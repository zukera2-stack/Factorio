---
name: factorio-updater-release
description: Safely build, test, promote and deliver Electrified Mainline versions to the owner's already-installed Windows Updater 1.1. Use when asked for a patch, install/update, test build, updater, rollback, releasing a version or distributing a ZIP.
---

# Updater-driven releases, not repeated manual downloads

**Current arrangement snapshot (2026-11-21):** user already has Updater **1.1** working on Windows. Source is on `feature/git-updater-060/tools/updater/` ([README](https://github.com/zukera2-stack/Factorio/blob/feature/git-updater-060/tools/updater/README.txt), [Updater.ps1](https://github.com/zukera2-stack/Factorio/blob/feature/git-updater-060/tools/updater/Updater.ps1)). The updater pins `refs/heads/test/updater-approved`, which held `0.1.60` at SHA `ea9366a9798cd78efec4b675c81d086c09170c28`. Verify live refs and updater script before acting.

## Release gate

1. Determine whether the output is **test-only research code**, **installable gameplay mod**, or **updater software**. They are different. `tests/em061-native-probe/` is not an installable ElectrifiedMainline release and must not move the approved pointer.
2. Work in an isolated branch with an exact base SHA. For development of 060 electrical bridge, preserve current 060 baseline: don't branch from bare 0.1.56 and silently lose Phase-2. Keep all accepted 83 art PNGs unchanged absent approved defect.
3. Verify GitHub Actions build at the proposed exact source commit, expected package contents and SHA256. If mechanic changes, run real exact-version Factorio headless QA plus owner-scoped in-game acceptance tests when required. **A build success alone does not authorize promotion.**
4. Request **explicit owner approval** for promoting the precise tested gameplay commit. Without that, leave `test/updater-approved` alone. No implicit permission to merge to `main`.
5. After approval only, update approved ref to the exact source with verification and commit lease; verify approved tree contents, game version and provenance again. Do **not** edit Updater's `$ApprovedRef` to point at experimental branch instead.
6. User instruction when approved build is available: close Factorio, launch **existing** `Update.bat`, choose **1** install/update, confirm; option **2** verifies and option **3** rolls back when backup exists. Do not ask user to re-download updater or manually swap ZIP every time. The updater requires Git for Windows / PowerShell 5.1, refuses duplicate mod installations and edits neither saves nor mod-list.
7. Updater caches/backups are under Windows TEMP and can be cleaned: instruct the user to back up the game save independently. On failure stop, inspect exact error; do not claim auto-rollback if backup vanished.
8. If updater itself needs a new version, modify its separate updater branch, test Windows PowerShell 5.1 and real Git (clean install, ZIP conversion, incremental repair, rollback, duplicate handling, interrupted fetch); do not distribute an untested patcher.
9. Update `docs/AI_CONTEXT.md`, `docs/PROJECT_STATE.yaml` and cross-branch `docs/CURRENT_WORK.md` through reviewed docs PR with exact new approved commit/version and QA evidence. Never rewrite owner's active save or silently update main.

**Historical QA:** [native 060 run 44762226742](https://github.com/zukera2-stack/Factorio/actions/runs/44762226742), [frozen package run 44772684519](https://github.com/zukera2-stack/Factorio/actions/runs/44772684519), [Updater 1.1 Windows QA 44783774432](https://github.com/zukera2-stack/Factorio/actions/runs/44783774432). Treat these as *scoped* successes.
