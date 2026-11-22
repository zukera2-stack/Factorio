# EM072 — AUTHOR DECISION: EM070 AUTO may rescue a brownout factory (policy Б)

**Author approval:** 2026-11-22. **Status:** APPROVED CONCEPTUAL POLICY, not a production release or approval to merge experimental runtime.

The author explicitly chose **Б**: «AUTO может поддерживать завод даже при дефиците тяговой мощности».

## Contract

- When a source-side factory is overloaded, an EM070 in `AUTO` **may export finite, source-backed energy from its connected 25kV rail corridor into the factory**, even if that leaves trains undersupplied.
- **Do not automatically switch all stations to traction-first import** merely because there is active demand from trains; respect the existing AUTO reversible bridge direction, energy flow ceilings and conservation, isolation of unrelated electric networks, and manual station controls.
- Each locomotive can independently use a **finite onboard battery reserve** to compensate for the portion of its traction demand not met by actual metered line energy. Hybrid grant per game tick must not exceed its traction power limit, must debit a persistent per-locomotive battery before granting real J, and must not mint free J. Exhausted onboard battery provides zero subsequent battery credit. The B9 proof uses **2MJ initial / 1MW peak per loco as TEST ONLY**, not as product specs.
- Preserve source-side factory under-supply warnings and locomotive under-supply conditions; AUTO doesn't guarantee either industrial load or trains receive full requested power.

## Measured native evidence

- B8 on Factorio 2.1.24: one HSR, 2 real EM070, 16 actual moving trains. Factory B 30MW load, 25.2MW native battery ceiling; AUTO EM070 B exported 10,217,391.304 J to the source factory with 32MW competing nominal traction demand; global energy ledger ≈0J. [B8 research](../research/native-shared-two-station-b8-072a5.md).
- B9 with the same **AUTO policy B**: 16 test loco onboard reserves (2MJ each, 1MW max) assisted traction for 136 simultaneous grid+battery ticks, debited exactly 32MJ, source-backed native grid J **148,492,753.623 unchanged** from the 0MJ onboard negative control, actual train burner grants increased by precisely 32MJ, and source B still exported 10,217,391.304J. Both native 500 ticks + real server SAVE at t300 and independent LOAD+200 pass. [B9 report](../research/native-onboard-battery-b9-072a5.md).

## Explicitly outside this approval

- The earlier B7 stationary corridor-buffer **battery-first vs factory-first** policy was **not chosen** by this answer. The approved B rule concerns reversing EM070 toward an overloaded factory when traction is also in deficit.
- The product onboard battery capacity, charge/discharge speeds, efficiency, native implementation, regen, energy-source migration, persistence through entity mine/Blueprint/Undo/upgrade, train split/merge, and MP have not been approved or passed as gameplay.
- No `main` merge, release, installer or patcher is authorized. B9 proofs use a disposable cloned burner locomotive and a finite script-owned per-locomotive battery inventory; the playable EM electric locomotive in 0.1.62 still has `energy_source.type="void"`.