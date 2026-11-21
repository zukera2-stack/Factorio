---
name: factorio-local-qa
description: Fast offline verification of Electrified Mainline ZIP packages and real pure Lua dispatcher, EEI and Bob's accumulator API mocks, priority diagnostics, topology and actual game logs without GitHub Actions. Use before native engine QA.
---

# Factorio local QA skill

## Native engine tier (preferred when the owner's private headless is available)

Before asking the user for manual screenshots, obtain the Linux x86-64 Factorio 2.1.24 headless archive from current uploads or personal Library `/Factorio/Local-QA/engines/` (the ARM64 archive is available but was **not tested** on the x86-64 host). Fetch exact test mod ZIP and run `python3 tools/local_qa/run_native_qa.py --headless-archive <path-to-user-private-headless.tar.xz> --mod <exact-061.zip> --expected-sha256 3771b7241848ae98e74019659baeb03616ab9aa4fa5dfcb9e7acf02efbef754c --output build/native-qa-061`. For quick repeated tests use `--engine <extracted factorio/bin/x64/factorio>` instead of unpacking each time. The runner checks executable version/build and mod ZIP hash, creates disposable saves, runs 1050-tick native rail bridge and 300-tick native EEI priority matrix, asserts real game PASS markers, prints short progress and writes exact game logs and `native-report.json`. Current tested result: **NATIVE PASS 2/2**, 1350 game ticks in 9.4s after engine extraction (see `docs/research/eei-native-priority-061-qa.md`). No commercial game binary or proprietary archive may be committed into this public GitHub repo. Do not presume engine persists in a future session without materializing it from the private Library.


1. Retrieve the exact mod source, installed game ZIP or immutable Actions ZIP; verify its SHA and version, not its filename alone. For approved 061 the packaged ZIP SHA256 is `3771b7241848ae98e74019659baeb03616ab9aa4fa5dfcb9e7acf02efbef754c`.
2. Use the toolkit in `tools/local_qa/` or its personal Library snapshot `/Factorio/Local-QA/Factorio_Local_QA_0.1.61.zip`. It needs Python stdlib and Lua 5.2 executable, or the available liblua 5.4 fallback for compatibility-only checks.
3. Run `python3 tools/local_qa/run_local_qa.py --mod <source-folder-or-zip> --expected-version 0.1.61 --report build/local-qa.json`. Add `--log <uploaded-user-game-log>` only when provided, to analyse a **previous game session**, not to replay it.
4. Show meaningful progress, test failures and execution status. The runner tests ZIP structure/hash/CRC, 43 Lua syntax units, 83 PNG, actual pure `bridge_dispatch_059` over 700 deterministic random graphs (shared 20 MW/edge, signed reverse, no spontaneous energy), actual `bridge_devices_060` with Bob's mocks, `priority_diagnostics_061` and `power_topology`. Never replace original production source with a mock algorithm for these tests.
5. **The quick `run_local_qa.py` tests are NOT native Factorio; the separate `run_native_qa.py` launches the real engine.** Lua 5.4 compatibility is not Factorio Lua 5.2, and device/network mocks cannot prove engine behavior; the absence of a native Factorio binary must be reported. Run the exact Factorio native headless smoke and power-probe suite separately when engine-specific behavior changes.
6. Do not modify user saves, mod directory, 83 frozen PNGs or `test/updater-approved` to add tests. Test-only code stays outside `ElectrifiedMainline/`. On material changes, update `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml` in the same commit and cross-branch navigation as appropriate.
