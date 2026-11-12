# Engineering method: working analogues before hypotheses

**Status:** accepted project working protocol, 2026-11-12. Applies to future Factorio 2.1 work and bug fixes.

## Rule

**Find a working mechanism -> inspect its real prototypes and code -> check the exact Factorio API -> compare against our source -> change the minimum necessary -> verify in Factorio -> record evidence.**

Never guess engine flags, event order, or API effects when a comparable implementation can be inspected. Never say "unsupported" solely because an earlier prototype failed. Analogy generates a *testable hypothesis*, not a guarantee.

## Workflow

1. **Define an observable acceptance test.** Name the actual game operation (e.g., green Upgrade Planner, robot construction, Ctrl+Z, Ctrl+Y), target Factorio version, expected result, and regression risks. Keep UI operations separate: Upgrade Planner != Ctrl+Shift superforced blueprint != our custom selection tool.
2. **Search for a native example first.** Inspect Base game entities/prototypes, then functioning third-party mods with comparable entity types and behavior. Prioritize a *same-type* example over a merely similar-looking entity. Keep the URL, repository, path, commit/ref, and version; verify whether the installed mod is the same revision.
3. **Extract a comparison matrix.** Check prototype type, `flags`, `minable`, mining products, `placeable_by` / `place_result`, `fast_replaceable_group`, `next_upgrade`, `collision_box`, `collision_mask`, and differences in any special geometry or runtime events. Inspect both source and target.
4. **Verify official API requirements.** Read prototype and runtime API docs for the target Factorio version; if only a newer documentation version is accessible, label it and verify in the installed game. Check which behavior the engine already owns before creating scripted emulation.
5. **Make a minimal, isolated experiment.** Prefer prototype configuration and native engine behavior to cancel/requeue/destroy/recreate scripts. Keep a rollback path. Do not copy third-party code into this repository; reimplement independently from documented semantics.
6. **Verify with game evidence.** CI/Lua syntax/ZIP packaging proves only code and package validity. A user-confirmed test plus `factorio-current.log` can establish game behavior for the exact tested configuration. Inspect both robot mining and building, Undo/Redo action types, and actual final entities. Test each geometry and separate user path individually.
7. **Update the project memory.** Record the exact tested version/commit, environment, observed vs unverified outcomes, proof (log tick/lines or saved test), known limitations, and next experiment in `docs/PROJECT_STATE.yaml`, `docs/AI_CONTEXT.md`, and the status/test record. Update these as one coherent change set.

## Verification labels

- **Implemented**: the behavior/configuration exists in current repository source.
- **API-confirmed**: supported by a linked Factorio API definition for an identified version.
- **Game-tested**: user/test evidence shows the specific behavior actually completed.
- **Inferred**: plausible but not isolated by an experiment.
- **Unverified**: not yet tested or insufficient evidence.
- **Planned**: not implemented.

Do not upgrade a test of one geometry to a claim about every geometry. Do not infer Ctrl+Shift blueprint Undo from a green Upgrade Planner Undo test. Build artifacts are not gameplay evidence.

## Case study: native rail replacement, 0.1.3 -> 0.1.7

| Area | 0.1.3/0.1.6 experiment | 0.1.7 source and game test |
| --- | --- | --- |
| Upgrade grouping | one `em-rail-upgrade` group for all four rail geometries | one group per matching ground rail geometry |
| Default upgrade chain | `next_upgrade` not configured | vanilla rail `next_upgrade` points to matching custom rail |
| Runtime marking | `on_marked_for_upgrade` cancels/requeues to scripted deconstruction | handler observes native order only; does not cancel it |
| Undo/Redo | superforce blueprint + delayed ghost `undo_index=1` removes new rails but fails to restore originals | native green Upgrade Planner, 20 straight rails: originals restored on Ctrl+Z and upgraded again on Ctrl+Y |

**Observed in Factorio 2.1.20 (user installation labelled 2.1.20b), ElectrifiedMainline 0.1.7, 2026-11-12:**
- `[native-upgrade] CONFIGURED` for all four ground geometries during data-stage loading: **configuration only**, not four gameplay passes.
- `on_marked_for_upgrade` ordered 20 straight vanilla -> custom rails; robots mined and built them.
- Ctrl+Z: `on_undo_applied tick=14591 player=1 action_count=20`, `upgraded-entity` records contain `original_name=straight-rail`; robots mined new rails and built vanilla straight rails.
- Ctrl+Y: `on_redo_applied tick=14940 player=1 action_count=20`; robots replaced vanilla straight rails with custom again.
- No ElectrifiedMainline runtime errors observed in the supplied log; session exited normally.

**Scope of proof:** native **straight ground** rail upgrade and Undo/Redo with construction robots in this session. Curved-A, curved-B, half-diagonal, Ctrl+Shift superforce blueprints, and the separate custom replacement tool still need independent testing. All three principal 0.1.7 changes were made together; the log does **not isolate** which one alone was necessary.

The earlier assertion that native rail upgrades are categorically unsupported was **falsified for tested straight ground rails**. Preserve the older 0.1.6 experiment as history, not current guidance.

## Research trail

- [Official Factorio EntityPrototype](https://lua-api.factorio.com/latest/prototypes/EntityPrototype.html): `fast_replaceable_group`, `next_upgrade`, collision and minability conditions (latest documentation; compare to installed 2.1.20).
- [Official UpgradeItemPrototype](https://lua-api.factorio.com/latest/prototypes/UpgradeItemPrototype.html): required source/target compatibility and default upgrade mapping.
- [Bob's assembly prototypes](https://github.com/modded-factorio/bobsmods/blob/main/bobassembly/prototypes/assembly.lua): native assembler upgrade pattern; the inspected public `main` metadata was 2.1.0, **not** the user's installed Bob's Assembly 3.0.2.
- [Minimal Electric Rails ground-rail prototypes](https://github.com/snouz/minimalist-rails/blob/main/prototypes/entities.lua): direct *rail geometry* analogue with per-geometry groups and `next_upgrade`; used for concepts, **not copied code**.
- Our source: [data-final-fixes.lua](../ElectrifiedMainline/data-final-fixes.lua), [scripts/control.lua](../ElectrifiedMainline/scripts/control.lua).

## Stop conditions

Stop and research again instead of adding more workarounds when: (a) the API rules are unknown, (b) a source example is from an incompatible game version, (c) a claimed unsupported behavior has not been checked against a same-type working example, (d) code conflicts with a mod's existing `next_upgrade` chain, or (e) a fallback destroys native Undo ownership.

For major mechanics (power grids, charging, brakes, signal behavior), repeat the procedure from scratch: find native or modded precedents and measure limits before designing new runtime code.
