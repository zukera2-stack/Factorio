# Prototype research record — template

> Copy this file for each non-trivial mechanic, compatibility change, or bug workaround. Save the completed record under `docs/research/<topic>-<version>.md`. Fill sections 1–6 **before implementation**; complete section 7 after coding and sections 8–9 after testing. Do not edit this template in place.

## 1. Research metadata

- **Feature / issue:**
- **Owner / contributor:**
- **Date opened:**
- **Repository branch and starting commit:**
- **Target Factorio version and build:**
- **Installed modpack and relevant mod versions:**
- **Our mod version:**
- **Research status:** `open` / `blocked` / `implemented` / `game-tested`

## 2. Exact behavior to explain

Describe one observable player-facing operation. Avoid vague goals such as “make upgrades work”.

- **Player action / API operation:**
- **Entity or prototype type:**
- **Expected result:**
- **Failure or regression conditions:**
- **Separate workflows that must not be conflated:** (for example, green Upgrade Planner, Ctrl+Shift superforced blueprint, and a custom selection tool)

## 3. Acceptance test

Write the smallest reproducible test before changing code.

1. **Save / test setup:**
2. **Required items, entities, robots, and mods:**
3. **Exact action sequence:**
4. **Expected visible result:**
5. **Expected log or API evidence:**
6. **Undo / Redo / cancellation / partial-operation checks:**
7. **Regression risks:**

## 4. Analogue search log

Search in this order: native Factorio behavior and Base prototypes first; then a working mod using the same prototype/entity type and operation; then adjacent analogues if no same-type example exists.

| Kind | Repository / source | Exact file or API page | Branch, tag, or commit | Mod / game version | Same as installed version? | What was actually verified |
|---|---|---|---|---|---|---|
| Native | | | | | | |
| Same-type mod | | | | | | |
| Adjacent analogue | | | | | | |

- **Search terms and locations checked:**
- **Same-type analogue found?** yes / no
- **If none was found, what was searched and why are adjacent examples relevant?**
- **Version / revision mismatches and missing provenance:**

A forum post, screenshot, mod description, old changelog, or unverified claim is a search lead—not proof that the mechanism works. Inspect the source and identify the exact revision. If a commit SHA was not captured, say so; do not invent one.

## 5. Prototype and API comparison

Include only properties relevant to this mechanic. Do not cargo-cult unrelated flags.

| Property / behavior | Working analogue | Official API requirement (version + link) | Our current source | Difference / consequence |
|---|---|---|---|---|
| Prototype / entity type | | | | |
| Flags / lifecycle | | | | |
| Placement / item mapping | | | | |
| Mining / products | | | | |
| Replacement / upgrade chain | | | | |
| Collision / geometry | | | | |
| Runtime events / event ownership | | | | |
| Energy / buffers / state (if relevant) | | | | |
| Compatibility with other mods | | | | |

- **Official API pages and exact target version:**
- **Are the docs version-matched to the installed game?** yes / no; explain.
- **Which behavior is already owned by the engine?**
- **Which behavior genuinely requires our runtime code?**
- **Existing third-party prototype chains or compatibility hazards:**

## 6. Hypothesis and minimal design

- **Hypothesis:** If we change ______, then ______ should happen because ______.
- **Evidence supporting the hypothesis:**
- **What this hypothesis does not claim:**
- **Smallest proposed change:**
- **Alternative considered and rejected (with reason):**
- **Rollback / save-compatibility plan:**
- **Falsification condition:** what result would show the hypothesis is wrong?

If no suitable analogue or API contract can be established, stop and document the uncertainty. Do not convert a guess into an implementation claim. A controlled experiment may be proposed, but its assumptions must be explicit.

## 7. Implementation record

Complete after coding.

- **Files changed:**
- **Commit(s):**
- **Reference behavior independently reimplemented:**
- **Native engine behavior preserved:**
- **Third-party code/assets copied?** must be no unless separately approved and legally reviewed.
- **Static checks / Lua syntax:**
- **Data-stage checks:**
- **CI / package result:**

## 8. Game experiment results

| Test case | Factorio build / mod setup | Exact operation and geometry | Result | Evidence (log lines, ticks, save, screenshot) | Status |
|---|---|---|---|---|---|
| | | | | | |

Keep each geometry and each player workflow as a separate row. A successful test for one case does not prove another case.

- **Observed behavior (facts only):**
- **Unexpected behavior:**
- **Errors or warnings:**
- **Was the test repeated from a clean / disposable save?**
- **Did Undo and Redo restore the actual original entities?**
- **What did the experiment not test?**

## 9. Conclusion and evidence labels

Use only these labels, with a precise scope:

- **Implemented** — code/configuration exists in the current branch.
- **API-confirmed** — supported by official API documentation for the stated version.
- **Game-tested** — the exact operation completed in the named game build and setup.
- **Inferred** — plausible from comparison, but not isolated by a test.
- **Unverified** — not tested or evidence is insufficient.
- **Planned** — not implemented.

- **Confirmed conclusion:**
- **Unverified cases:**
- **Known limitations / causal ambiguity:**
- **Next smallest experiment:**
- **Documents that must be synchronized:** `docs/STATUS.md`, `docs/AI_CONTEXT.md`, `docs/PROJECT_STATE.yaml`, and `CHANGELOG.md` as applicable.

## 10. Source-use and licensing note

Record each external source's license when available. Learn from behavior and API contracts; independently implement the solution. Do not copy third-party code, fragments, assets, or prototypes into Electrified Mainline without explicit approval and a compatible licensing review.
