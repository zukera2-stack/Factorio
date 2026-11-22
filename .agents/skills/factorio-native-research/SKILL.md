---
name: factorio-native-research
description: Research or alter Factorio 2.1 game mechanics (rails, catenary, electrical grids, EEI priorities, native accumulator behavior, Undo/Redo) through same-type precedents and exact engine tests before implementation. Use for debugging or designing Electrified Mainline.
---

> **2026-11-22 FULL SYSTEM ACCEPTANCE RULE:** The Base-only disposable-mod experiments described for the old EM061 priority research below are valid **only for isolating a physical hypothesis**. They **never** certify the complete Electrified Mainline mod. For any autonomous integration, traction, or regression PASS, load the **latest complete GitHub Actions game ZIP** and test the actual production/research prototypes together on native Factorio with real boundary/negative cases. See [the full-mod boundary protocol](../../../docs/tests/AUTONOMOUS_FULLMOD_BOUNDARY_PROTOCOL.md) and [run template](../../../docs/tests/AUTONOMOUS_FULLMOD_RUN_TEMPLATE.yaml). No prototype trimming, invented Joules, silently skipped motors/Undo, or release on a green diagnostic run with known FAIL.


# Factorio native-engine research and validation

Mandatory for non-trivial code, new prototype, electric-distribution logic, compatibility workaround, rail changes or claim that a mechanic "cannot work".

1. Check [AGENTS](../../../AGENTS.md), [research method](../../../docs/RESEARCH_METHOD.md), and [prototype research template](../../../docs/PROTOTYPE_RESEARCH_TEMPLATE.md). Scope to a known branch and exact Factorio version; owner's last confirmed environment: **2.1.24 build 87808**.
2. State **one falsifiable operation** with controls, initial game state, actions, expected network IDs, energy J, limit J/tick, and exact failure rule. Log existing source and checksum/prototype properties. Never merge unrelated scenarios.
3. Find the Base entity/prototype or same-type working mod on a version-matched ref; inspect the source plus official Lua/Prototype API. Record version/provenance and explicit mismatches. A wiki claim is a hypothesis until tested in the target engine.
4. For electricity: distinguish engine priority (`solar`, `primary`, `secondary`, `tertiary`) from voltage. Inspect exact `electric-energy-interface` prototype flags, `usage_priority` and runtime `electric_interface_mode`; do not assume an EEI with fixed `secondary-input` can switch priority dynamically. Never infer that two separate electrical networks are connected because of equal priority.
5. Important 061 trap: a normal accumulator has **no two independent copper ports**; overlapping disconnected pole supply areas can include the same tertiary accumulator, but that is not proof of 20 MW controllable throughput, battery-to-battery flow or multi-hop transfer. The separate test-only `tests/em061-native-probe/` currently investigates overlap; **P1–P7 priority matrix is only documentation, not implemented or game-tested** on the 061 branch.
6. For an electrical priority experiment, build a **disposable Base-only test mod**; evaluate secondary-input vs tertiary-input on the source (including native battery and normal factory load), secondary-output vs tertiary-output to the sink (including battery charge), primary demand competition, power limits and mode transitions. Keep the 060 working Lua bridge intact. Native circuits, native network IDs and conservation must be measured. No custom Lua joule teleportation for the *pure native overlap* test; if checking bridge EEI scheduling, explicitly isolate the existing accounted Joule transfer as a separate experiment.
7. Run static Lua/data-stage/CI, then **actual Factorio native solver** on the exact specified engine and a disposable save. Report tests independently: code syntax PASS ≠ installed-game PASS; don't extrapolate from two networks to three, or vanilla batteries to Bob's.
8. Never alter accepted 060 runtime, `test/updater-approved`, or `main` solely to try a hypothesis. Record failed tests, log tick values and ledger before modifying architecture. If native priority semantics cannot deliver a required user feature, retain the Lua bridge or propose a measured hybrid.
9. Commit research evidence in `docs/research/` and update branch handoff and machine state together as required by AGENTS.

Relevant current research is linked in `docs/CURRENT_WORK.md`. No unsupported hidden Factorio APIs or unverified magic flags.
