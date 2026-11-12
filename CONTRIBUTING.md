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

## Before requesting review

- [ ] The exact user-visible behavior and test scope are stated.
- [ ] A native or same-type working analogue was inspected, or the absence of one is documented.
- [ ] Official API requirements and target-version uncertainty are recorded.
- [ ] Relevant prototype/runtime differences are compared.
- [ ] The change is minimal and independently implemented.
- [ ] CI/source validation is complete and not misrepresented as gameplay proof.
- [ ] In-game results and unverified cases are clearly separated.
- [ ] `AI_CONTEXT.md`, `PROJECT_STATE.yaml`, status, and changelog are synchronized where applicable.
