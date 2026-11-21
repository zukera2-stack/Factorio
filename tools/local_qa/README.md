# Electrified Mainline: fast, offline QA kit

Run `python3 tools/local_qa/run_local_qa.py --mod /path/to/ElectrifiedMainline_0.1.61.zip --expected-version 0.1.61 --report build/local-qa.json` from any directory. It also accepts an unzipped `ElectrifiedMainline/` folder or the outer GitHub Actions artifact ZIP. Use `--log /path/to/factorio-current.log` for a separately labelled analysis of a real previous game session.

The runner needs only Python 3 and a Lua interpreter: `lua5.2` is preferred; if absent on Linux, `liblua5.4.so.0` is used through Python `ctypes`. No external Python packages, network, GitHub Actions, or game installation is needed for fast unit and ZIP checks. Every stage prints `[PASS]`/`[FAIL]` immediately, and optionally writes JSON. Lua 5.4 compatibility is not exact Lua 5.2 compatibility: official Factorio 2.1 testing remains a separate acceptance gate.

It checks actual packaged game files: ZIP structure and CRC, metadata and PNG inventory, compiles all runtime Lua, then executes pure Lua tests of the **real** `scripts.bridge_dispatch_059`, `scripts.bridge_devices_060`, `scripts.priority_diagnostics_061` and `scripts.power_topology` modules. Dispatch includes 700 seeded randomized multi-node graphs, conservation constraints, reverse flows, 20 MW/station caps and storage. Bob's accumulator test is a *mocked device API* with observed 240/960 kW properties, not Factorio/Bob's native simulation.

## Scope and limits

- **Does prove:** the downloaded versioned byte-for-byte package passes local static checks, real pure-module Lua control laws satisfy test invariants for the generated scenarios, 061 read-only diagnostic uses correct unit conversion, and any supplied log has historical observations.
- **Does not prove:** actual Factorio electric solver dispatch, priority scheduling, in-game locomotive load, Bob's engine compatibility in all circumstances, save-game migration, integrity of physical rail layout. Native Factorio checks must be run with the real engine; when it is unavailable, this toolkit clearly reports so and never labels local Lua emulation `Game PASS`.
- No game or updater code is modified. This QA kit never writes savegames or user mods. It consumes temp extracted copies.

Repository path: `tools/local_qa`. For new chats see `docs/CURRENT_WORK.md` and `.agents/skills/factorio-native-research/SKILL.md` in the **main** branch; check live refs.

## Native Factorio headless QA (added 2026-11-21)

The user supplied the official Factorio **2.1.24 build 87808** Linux headless archives. With the x86-64 engine executable or archive, run an actual game simulation locally **without GitHub Actions and without any user placement actions**:

```bash
python3 tools/local_qa/run_native_qa.py \
  --headless-archive /path/to/factorio-headless_linux_2.1.24.tar.xz \
  --mod /path/to/ElectrifiedMainline_0.1.61.zip \
  --expected-sha256 3771b7241848ae98e74019659baeb03616ab9aa4fa5dfcb9e7acf02efbef754c \
  --output build/native-local-qa
```

For repeated tests, extract the engine once and pass `--engine /path/to/factorio/bin/x64/factorio` instead of re-extracting. The runner checks the exact game build and ZIP SHA, creates a temporary map per test-only mod, runs headless benchmark ticks and checks native PASS markers. Results are summarized in `native-report.json`, with detailed game logs in the selected output directory. It does **not** modify the actual mod installation or the user's saves.

**First native result (2026-11-21):** exact 0.1.61 ZIP SHA above, 2/2 game scenarios PASS, 1350 game ticks, 9.38 seconds including two map generations and benchmark launches. The scenarios are `em061-power-probe` (20 MW bridge, isolated nets, vanilla battery charge/reverse) and `em061-priority-probe` (6 actual Factorio EEI priority/accumulator circuits). Details in `docs/research/eei-native-priority-061-qa.md` and `native-report.json`.

**Relevant engine discovery:** secondary-input EEI drew 1.2 MJ from a native charged battery over 240 ticks; tertiary-input EEI drew 0 J. Secondary-output EEI charged a native battery by 1.2 MJ, while tertiary-output charged it by 0 J in the tested setup. A primary-input consumer received 8 MJ while a competing secondary-input consumer got 0 J at the same 2 MW supply. Never infer unrelated Bob's Power, shared-accumulator-cross-network behavior, or dynamic-mode support solely from this fixture.

Factorio headless tarballs are **not bundled in this library or committed to GitHub**: they are owned by the user, subject to the game's licensing, and are supplied separately. ARM64 archive is not needed on an x86-64 host; it was not executed in this run.