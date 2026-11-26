# EM075 — 120 MW single-substation design rejected by owner (2026-11-23)

**Binding decision:** A single `em-35kv-traction-substation` has a strictly **20 MW** bidirectional transmission rating. Higher total throughput is achieved **only by N identical stations in parallel**, correctly wired to the factory and contact grids (1=20 MW, 2=40 MW, 3=60 MW, 6=120 MW aggregate when genuinely supplied and loaded). No 40/60/120 MW individual station prototypes, no 120 MW per-edge bridge, no automatic upgrade to an individual superstation.

**Reason:** owner explicitly declared “станцию 120 мват считаю ошибкой удали из проекта”. Main already uses 20 MW. The experimental EM072–EM074 feeder used 120 MW per station, conflicting with the approved gameplay architecture.

## Corrected source in this isolated EM074-derived branch

- `ElectrifiedMainline/scripts/power_bridge_058.lua`: `M.LIMIT=20000000/60` J/tick **per substation**, restored from 120000000/60.
- `ElectrifiedMainline/prototypes/power_bridge_058.lua`: native bridge input/output interfaces restored from 120MW to **20MW**. The hidden 2 MJ buffer is **stored energy**, not a station power rating, and stays untouched pending separate review.
- `ElectrifiedMainline/info.json`: active game description stops claiming a 120 MW bridge.
- Both EM072 200-wagon `long200high` QA scenarios now exercise **over-supplying a single 20 MW station with a 120 MW factory-side source**, asserting the train motor ledger stays within a 20 MW budget. They no longer demand superstation performance. The changed 200-wagon scenarios are **not natively revalidated yet**.
- `tests/test_bridge_20mw_contract_075.py`: local regression guard for runtime and prototype limits, without external dependencies.

## Local native evidence and boundary

- Factorio Linux x64 headless **2.1.24 build 87808** really executed on 2026-11-23; source engine tar SHA256 `c49b66cff90aceff87b30f2973af0df7f51712cb2ee3153e0169d9bed46a964f`.
- User-supplied unmodified official 0.1.73 ZIP SHA256 `30ba63f788cafbcfcc8454e62759cb00017f7459739b9fb211a1e7fd52433276`. Local isolated derived *full* 0.1.73 copy changed **only the same two bridge Lua files** described above; shared originals have identical Git blobs between EM073 and EM074 (`1f6dfaf9...` and `4eeefe35...`).
- Native fullmod shared-network test with **N=1,2,3,6** 20MW feeders yielded 20/40/60/120MW forward and reverse. Repeated **2830-tick native test** PASS, including 40MW attempted demand per bridge with 20MW cap; another tested failure of a bridge, source starvation and 0 MW generation (see user session local QA report and source).
- This proves the isolated 0.1.73-derived bridge behavior; it **does not** prove that the exact new 0.1.74 branch ZIP, 200-wagon high cases, real saves, GUI or MP already pass.

**Historical evidence retained:** Old single-120MW branches, `docs/research/EM072_120MW_NATIVE_POWER_SOURCE_2026-11-23.md`, original 0.1.72/73/74 ZIP hashes and previous QA logs are historical **rejected experiment**, not active design. Do not delete original historical records or rewrite the assertions about what those historical runs really tested.

**Change boundary:** owner requested removal of erroneous 120 MW capability; no changes to `main`, original user binaries, assets, savegames, workflows; no GitHub Actions run, release or merge.
