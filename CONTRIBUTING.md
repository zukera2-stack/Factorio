## Autonomous boundary and COMPLETE game-mod test protocol (mandatory)

For any autonomous or parallel AI native-game test, first read [the strict full-mod protocol](docs/tests/AUTONOMOUS_FULLMOD_BOUNDARY_PROTOCOL.md) and fill [the machine-readable report template](docs/tests/AUTONOMOUS_FULLMOD_RUN_TEMPLATE.yaml). **Use the newest appropriate GitHub Actions-built FULL mod ZIP matching exact HEAD and SHA256**, not a Base-only substitute, a hand-selected subset of prototypes, a scripted fake circuit or a stale package. Small Base-only probes are permitted solely as hypothesis discovery; they never count as acceptance of the complete gameplay mod. Freeze the exact game bytes for each test campaign; a runtime fix requires packaging and rerunning on a new exact ZIP. Assert all boundary conditions, actual positive and active negative controls, all mod catalog components across campaign, genuine native electricity-flow and closed-energy accounting, true server SAVE followed by independent LOAD, full lifecycle/Undo, and frank NOT_TESTED for unsupported GUI/MP. Parallel lanes must independently load identical complete ZIP in isolated processes. Green CI with an asserted defect is a **feature FAIL**; incomplete coverage blocks release. Do not ask the owner about ordinary autonomous reruns, only architecture decisions and merge/release permissions.

> **2026-11-21:** EM071 accepted on owner screenshot and merged [PR #47](https://github.com/zukera2-stack/Factorio/pull/47). Former Windows patcher scripts have been retired and removed from their source branch; do not recreate/ship an updater. Main game source 0.1.62 is NOT a release.

> **Branch-aware handoff:** read [`docs/CURRENT_WORK.md`](docs/CURRENT_WORK.md) before choosing a base. Stable `main` 0.1.56, installed Updater-approved `test/updater-approved` 0.1.61, and proposed public beta 0.1.62 in PR #46 are distinct refs until merged. The Windows Updater 1.1 experiment is discontinued by owner decision. `test/updater-approved` is historical only; do not install with that patcher or promote it. Any future distribution must be explicitly reauthorized.

# Contributing to Electrified Mainline

This project uses a **research-first, analogy-driven engineering method**. The goal is to understand how Factorio or a proven mod already solves a problem before adding custom Lua behavior.

## Non-negotiable rule

**Do not guess mechanics. Find a working precedent, inspect its actual implementation, verify the target-version API, and only then design a change.**

An analogy is a source of a testable hypothesis, not proof that two entities behave identically. Prefer a precedent with the same Factorio prototype type and the same player operation.

## Required workflow

1. **Describe the exact behavior.** State the player action, entity type, game version, expected result, and failure/regression conditions. Keep distinct workflows separate (for example, the green Upgrade Planner, a superforced Ctrl+Shift blueprint, and a custom selection tool).
2. **Search for a native precedent.** Inspect Base game prototypes and built-in behavior first. If no suitable native example exists, search maintained third-party mods.
3. **Find a same-type working mod precedent.** Search source repositories, not just mod descriptions or screenshots. Confirm the relevant feature is actually implemented and identify the inspected branch/tag/commit and mod/game version. If the reference revision differs from the user's installed revision, say so explicitly.
4. **Inspect source and extract the contract.** Record the prototype type and relevant properties: `flags`, `minable`, mining products, `placeable_by` / item `place_result`, `fast_replaceable_group`, `next_upgrade`, collision box/mask, geometry, item mapping, runtime events, and any relevant state or ordering. Only include properties relevant to the mechanic; do not cargo-cult a flag list.
5. **Check official Factorio API documentation for the target version.** Verify prototype constraints, event semantics, and engine-owned behavior. Prefer version-matched documentation. If only `latest` docs or a different version is available, mark that uncertainty and validate in the installed game.
6. **Compare reference, API, and our source.** Build a concise table or checklist: reference behavior, API requirement, our current value/logic, mismatch, and proposed minimal change. Check existing mod chains and compatibility before mutating another mod's prototypes.
7. **Form one falsifiable hypothesis.** State exactly what the change is expected to fix and what it does not claim to fix. Avoid changing several unrelated variables in one experiment. If several changes must be combined, record that the test cannot identify which individual change was causal.
8. **Implement the smallest independent solution.** Learn from reference behavior; do not copy third-party code, fragments, assets, or prototypes. Prefer native engine behavior when it already provides the needed transaction, replacement, Undo/Redo, or lifecycle handling. Keep scripted fallbacks separate and clearly labelled.
9. **Validate in layers.**
   - Static/source checks and Lua syntax.
   - Data-stage prototype validation and diagnostics.
   - CI packaging and archive structure.
   - In-game test in the target Factorio version, with the relevant mods and save.
   - Undo/Redo, robot/item behavior, partial/cancelled operations, and regression tests where relevant.
10. **Record evidence and synchronize project memory.** Update `docs/STATUS.md`, `docs/AI_CONTEXT.md`, `docs/PROJECT_STATE.yaml`, and `CHANGELOG.md` as appropriate. Material implementation or status changes must update `AI_CONTEXT.md` and `PROJECT_STATE.yaml` in the same coherent change set.

## Evidence labels

Use these labels precisely:

- **Implemented** — code/configuration exists in the current branch.
- **API-confirmed** — the behavior or constraint is supported by official API documentation for a stated version.
- **Game-tested** — the exact operation completed in Factorio; name the version, entity geometry, test path, and scope.
- **Inferred** — supported by comparison or reasoning but not isolated in a test.
- **Unverified** — not tested, or evidence is insufficient.
- **Planned** — intended but not implemented.

A successful CI run proves only what its checks actually execute. A ZIP build is not an in-game test. A test of one geometry does not prove all geometries. A native planner test does not prove a blueprint path. Do not turn absence of evidence into a claim that Factorio does not support a feature.

## Research record template

For every non-trivial mechanic, compatibility change, or bug workaround, copy [the research worksheet](docs/PROTOTYPE_RESEARCH_TEMPLATE.md) into `docs/research/<topic>-<version>.md`.

- Complete the question, acceptance test, analogue search, prototype/API comparison, and hypothesis sections **before writing code**.
- After implementation, record changed files and static, data-stage, and CI results.
- After in-game testing, record the exact game build, modpack, player action, entity type/geometry, result, log evidence, and unverified cases.
- Do not fill missing source revisions, API versions, or test results from memory or guesswork; mark them unknown.
- For trivial documentation-only edits or isolated spelling fixes, a separate research record is not required.
- See the [0.1.7 native rail-upgrade record](docs/research/rail-native-upgrade-0.1.7.md) as a completed example.

## Case study: native rail upgrade and Undo/Redo

The 0.1.7 straight-ground-rail test demonstrates why this process matters:

- An earlier failed experiment led to an incorrect broad assumption that native rail upgrade was unsupported.
- Bob's assembling-machine prototypes provided a useful example of engine-native upgrade chains, but were not the closest entity-type match and the inspected public revision did not match the user's installed Bob's Assembly version.
- Minimal Electric Rails provided a same-type ground-rail precedent using geometry-specific `fast_replaceable_group` values and matching `next_upgrade` mappings.
- Official Factorio prototype API requirements were checked.
- The mod was changed to expose native upgrade pairs and stop cancelling native upgrade orders.
- The user confirmed that, in Factorio 2.1.20 with Electrified Mainline 0.1.7, the green Upgrade Planner replaced 20 straight ground rails with robots; Ctrl+Z restored vanilla rails and Ctrl+Y upgraded them again.

**Proof boundary:** this validates that specific straight-ground-rail path only. Curved-A, curved-B, half-diagonal, Ctrl+Shift superforced blueprints, and the separate custom replacement tool require independent tests. The 0.1.7 changes were combined, so the test does not prove which single property was independently necessary.

## Reference-use and compatibility rules

- Never copy third-party source code into this repository unless the project owner explicitly approves a compatible license and attribution process. The default is to reimplement independently from documented behavior.
- Record reference versions and disclose mismatches.
- Do not overwrite another mod's existing `next_upgrade` chain without a deliberate compatibility decision.
- Guard optional prototypes and keep optional integrations out of hard dependencies.
- If a same-type precedent cannot be found, document the search scope and uncertainty before experimenting.

## Mandatory adversarial validation gate for electrification (audit 2026-11-22)

For source-funded locomotive/25kV work, a passed package CI, one native acceleration test, or internal debit=credit Lua counters **must not** be labelled a full game or release PASS. Separate these measurable layers:

1. **Real vs virtual network load:** while an authenticated locomotive requests actual power, log both engine-side factory generator `LuaElectricNetwork.parent_network.flow_last_tick` and **native 25kV catenary demand**. Virtual `dispatch.plan(networks).load` alone cannot prove the user-visible electric network is actually loaded. Test stationary battery charging **and** powered movement independently.
2. **Scarcity and fairness:** with two identical true locomotive prototypes and an actual **1MW** native factory EEI feeding the same authenticated catenary, both must receive a nonzero finite share in the first 60 ticks (if equal priority is the chosen policy), and aggregate native source discharge and stored energy must balance. Prior native run #45043138579 reproduced locomotive B at 0J through tick120; do not change its expectation before adding a separately measured fixed case.
3. **Negative controls must be active:** a 0J locomotive without contact must have a **genuine native AUTO schedule to a connected station**. Include source shutdown **while** train moves, missing mast/bridge, depletion of a finite pre-paid reserve, splits/joins and real server disk SAVE followed by different-process LOAD.
4. **All-power ledger:** an equality between two counters incremented from the same `amount` is only a *local transfer* check. Independently snapshot generator output, each native EEI buffer, each real train reserve, ordinary accumulators, physical/explicitly approved loss events and unaccounted delta. Historical 0.1.62 tests detected 1,500,000 J unexplained network-switching deficit; new code cannot be cleared until analogous lifecycle tests pass on the **exact changed mod archive**.
5. **Entire catalog and lifecycle:** authenticate the real EM locomotive and every motor cargo/fluid item with representative contents, test hidden native-helper cleanup after owner demolition and save/load ([Issue #73](https://github.com/zukera2-stack/Factorio/issues/73)); do not energize helpers while orphan ownership is unresolved. Test native GUI, Blueprint/Undo/Redo, robots, curved/diagonal/elevated rails, migration and multiplayer separately before saying complete.
6. **Proof-level integrity:** classify each gate as source-only, static mock, package, actual native Factorio headless, native Windows GUI screenshot, owner real save, or owner-authorized release. A GREEN workflow can have **an expected reproduced defect inside it**; cite the actual assertion/result rather than calling it a feature PASS. Keep exact SHA+Factorio build+artifact and explicit remaining FAILs.
7. **Project-memory safety:** preserve earlier project docs; if a status or implementation change deletes hundreds of unrelated existing YAML/Markdown lines, **fail review and compare against the parent tree**. A former EM065 test iteration accidentally removed 2,414 documentation lines and was subsequently repaired. Do not let test code overwrite documentation with literal placeholder content.

[Detailed gated recovery plan](docs/plans/EM065_AUDIT_RECOVERY_20261122.md) · [independent native audit](https://github.com/zukera2-stack/Factorio/blob/audit/em065-native-multitrain-20261122/docs/research/em065-independent-full-audit-20261122-FINAL.md) · [draft documentation and tests PR #79](https://github.com/zukera2-stack/Factorio/pull/79).

## Before requesting review

- [ ] The exact user-visible behavior and test scope are stated.
- [ ] A native or same-type working analogue was inspected, or the absence of one is documented.
- [ ] Official API requirements and target-version uncertainty are recorded.
- [ ] Relevant prototype/runtime differences are compared.
- [ ] The change is minimal and independently implemented.
- [ ] CI/source validation is complete and not misrepresented as gameplay proof.
- [ ] In-game results and unverified cases are clearly separated.
- [ ] `AI_CONTEXT.md`, `PROJECT_STATE.yaml`, status, and changelog are synchronized where applicable.

## Game-only packaging

Run `python -m unittest discover -s tests -p 'test_package_mod.py' -v` and `python scripts/package_mod.py`. The installable ZIP is in `build/package/`; the QA atlas in `build/qa/` is a separate artifact. Place developer-only material outside the mod folder. See [repository layout](docs/REPOSITORY_LAYOUT.md).

The project owner requires all installable ZIPs distributed to users to originate from GitHub Actions. The local command above is only for developer checks; use the exact CI-built inner ZIP for distribution, with source commit, run ID, artifact ID and hash recorded. Do not repackage locally.

**Owner clarification (2026-11-19):** deliver install ZIPs only by direct GitHub Actions artifact links. Do not download, copy, extract, or duplicate distributable ZIPs into the ChatGPT Library or project files for delivery. Library is for technical material, source models, sketches, experiment outputs, and evidence. Record CI validation, source commit and artifact ID; obtain inner archive SHA256 from CI logs if emitted, not by copying the release into Library.
