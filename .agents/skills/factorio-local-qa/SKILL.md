---
name: factorio-local-qa
description: Fast offline verification of Electrified Mainline ZIP packages and real pure Lua dispatcher, EEI and Bob's accumulator API mocks, priority diagnostics, topology and actual game logs without GitHub Actions. Use before native engine QA.
---

# Factorio local QA skill

1. Retrieve the exact mod source, installed game ZIP or immutable Actions ZIP; verify its SHA and version, not its filename alone. For approved 061 the packaged ZIP SHA256 is `3771b7241848ae98e74019659baeb03616ab9aa4fa5dfcb9e7acf02efbef754c`.
2. Use the toolkit in `tools/local_qa/` or its personal Library snapshot `/Factorio/Local-QA/Factorio_Local_QA_0.1.61.zip`. It needs Python stdlib and Lua 5.2 executable, or the available liblua 5.4 fallback for compatibility-only checks.
3. Run `python3 tools/local_qa/run_local_qa.py --mod <source-folder-or-zip> --expected-version 0.1.61 --report build/local-qa.json`. Add `--log <uploaded-user-game-log>` only when provided, to analyse a **previous game session**, not to replay it.
4. Show meaningful progress, test failures and execution status. The runner tests ZIP structure/hash/CRC, 43 Lua syntax units, 83 PNG, actual pure `bridge_dispatch_059` over 700 deterministic random graphs (shared 20 MW/edge, signed reverse, no spontaneous energy), actual `bridge_devices_060` with Bob's mocks, `priority_diagnostics_061` and `power_topology`. Never replace original production source with a mock algorithm for these tests.
5. **Local tests are NOT native Factorio.** Lua 5.4 compatibility is not Factorio Lua 5.2, and device/network mocks cannot prove engine behavior; the absence of a native Factorio binary must be reported. Run the exact Factorio native headless smoke and power-probe suite separately when engine-specific behavior changes.
6. Do not modify user saves, mod directory, 83 frozen PNGs or `test/updater-approved` to add tests. Test-only code stays outside `ElectrifiedMainline/`. On material changes, update `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml` in the same commit and cross-branch navigation as appropriate.
