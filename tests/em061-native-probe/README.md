# EM061 — test-only native accumulator probe

**Do not install on the owner's production save. Do not include in ElectrifiedMainline ZIP.** Branch: `experiment/native-accumulator-gateway-061`.

A standalone Factorio 2.1.24 Base-only test. It does **not** patch ElectrifiedMainline and does **not** script any power transfer.

Run on a disposable map with this directory installed as `em061-native-probe_0.0.1`. Under a 2.1.24 headless executable:
```sh
factorio --mod-directory MODS --create em061-test.zip
factorio --mod-directory MODS --benchmark em061-test.zip --benchmark-ticks 1600 --benchmark-runs 1
```
Ensure `MODS/mod-list.json` enables `base` and `em061-native-probe` only. Verify that `[EM061 TWO-NET PASS]` appears in the native log and that there are no exceptions. Capture the entire exact-version log. The 3-net and battery-only diagnostics are **not** passes or failures until measured and interpreted. If assertions fail, preserve evidence instead of changing the live 060 bridge.

Probe phases (ticks since setup):
- 60: verify two copper-disconnected substations and shared gateway network IDs
- 300: vanilla accumulator A→B at native 300 kW
- 320–620: test-only 20 MW accumulator replacement, actual A→B delivery
- 640–940: reverse EEI source/load direction, native B→A delivery
- 970–1200: battery-only→gateway→battery observation (diagnostic)
- 1250–1550: separate A→B→C shared gateways (diagnostic)

Source: `docs/research/25kv-native-accumulator-gateway-061.md`.
