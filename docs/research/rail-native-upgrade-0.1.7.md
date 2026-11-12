# Research record: native ground-rail upgrade and Undo/Redo (0.1.7)

<badge>Game-tested: straight ground rails only</badge>

## 1. Research metadata

- **Feature:** replace vanilla ground rails with matching Electrified Mainline rails using Factorio's native green Upgrade Planner, including native Undo/Redo.
- **Date:** 2026-11-12.
- **Repository:** `zukera2-stack/Factorio`.
- **Branch:** `diagnostic/blueprint-rail-undo`.
- **Mod version:** `0.1.7`.
- **Target game:** Factorio 2.1.20, build 87512 (the user's installation directory was labelled 2.1.20b).
- **Test environment:** Bob's Assembly 3.0.2 and Space Age 2.1.20, within the user's larger modpack.
- **Research result:** native upgrade and Undo/Redo confirmed for straight ground rails in the stated setup. Other geometries and other upgrade workflows remain unverified.

## 2. Exact behavior and acceptance test

**Question:** Can the vanilla green Upgrade Planner order robots to replace vanilla straight ground rails with matching custom rails, while Factorio retains ownership of the upgrade transaction so Ctrl+Z restores the original rails and Ctrl+Y reapplies the upgrade?

**Acceptance sequence:**
1. Use a disposable test save with construction robots and the required custom rail items available.
2. Mark 20 vanilla straight ground rails with the native green Upgrade Planner.
3. Wait for robots to mine the vanilla rails and build the custom straight rails.
4. Press Ctrl+Z and wait for robots to restore the original vanilla rails.
5. Press Ctrl+Y and wait for robots to rebuild the custom rails.
6. Inspect the log and the actual entities after each operation.

The green Upgrade Planner, Ctrl+Shift superforced blueprint overlay, and the separate custom selection tool are different workflows and are not interchangeable test cases.

## 3. Analogue and API research

### Same-type rail analogue

- **Project:** [Minimal Electric Rails](https://github.com/snouz/minimalist-rails).
- **Inspected file:** [`prototypes/entities.lua`](https://github.com/snouz/minimalist-rails/blob/main/prototypes/entities.lua).
- **Reference:** public `main` branch. The exact commit SHA was not captured in the research notes; it must not be guessed.
- **Why it is relevant:** it is a direct ground-rail analogue. It uses matching rail geometry with geometry-specific `fast_replaceable_group` values and `next_upgrade` mappings.
- **Use boundary:** concepts and prototype contract only; no code was copied.

### Adjacent prototype analogue

- **Project:** [Bob's Mods](https://github.com/modded-factorio/bobsmods).
- **Inspected file:** [`bobassembly/prototypes/assembly.lua`](https://github.com/modded-factorio/bobsmods/blob/main/bobassembly/prototypes/assembly.lua).
- **Reference:** public `main` branch; exact commit SHA was not captured.
- **Version mismatch:** inspected public metadata was 2.1.0; the user's installed Bob's Assembly was 3.0.2. This is an adjacent assembler analogue, not proof of behavior in the installed version.
- **Why it is relevant:** it demonstrates a working engine-native upgrade pattern, but it is less directly comparable than a rail prototype.

### Official API

- [Factorio EntityPrototype](https://lua-api.factorio.com/latest/prototypes/EntityPrototype.html) — `fast_replaceable_group`, `next_upgrade`, collision and minability constraints.
- [Factorio UpgradeItemPrototype](https://lua-api.factorio.com/latest/prototypes/UpgradeItemPrototype.html) — source/target compatibility and upgrade mapping requirements.
- **Version caveat:** the research notes link to the `latest` API pages, not a pinned 2.1.20 documentation snapshot. The exact installed game test is therefore the decisive evidence for the tested path; the API links document the researched contract but should not be misrepresented as version-pinned citations.

### Native source limitation

The research notes do not preserve a specific Base-game source file or commit for the vanilla rail prototypes. The native behavior was checked through the Factorio API and then validated in the installed game. Do not invent a Base source path retroactively.

## 4. Comparison and implementation hypothesis

| Area | Earlier 0.1.3 / 0.1.6 approach | 0.1.7 approach |
|---|---|---|
| Replacement groups | One shared group for all rail geometries | One matching group per ground-rail geometry |
| Upgrade mapping | `next_upgrade` not configured | Vanilla rail points to its matching custom ground rail, subject to an existing-chain guard |
| Upgrade event | Runtime handler cancelled/requeued native orders into scripted deconstruction | `on_marked_for_upgrade` observes native orders and does not cancel them |
| Undo/Redo | Scripted superforce ghost join removed new rails but did not restore originals | Native green Upgrade Planner created native `upgraded-entity` Undo/Redo actions for the tested straight rails |

**Hypothesis:** if each vanilla/custom ground-rail pair has compatible geometry and a matching geometry-specific replacement group, the vanilla rail maps to its matching custom rail through `next_upgrade`, and our runtime handler does not cancel the native order, Factorio can own the replacement and Undo/Redo transaction for that pair.

**Minimality and causality caveat:** the 0.1.7 changes were tested together. The test does not isolate which individual property was necessary or sufficient.

## 5. Source under test

- [`data-final-fixes.lua`](../../ElectrifiedMainline/data-final-fixes.lua) — configures the geometry-specific ground-rail upgrade pairs, eligibility checks, and protection against overwriting a foreign upgrade chain.
- [`scripts/control.lua`](../../ElectrifiedMainline/scripts/control.lua) — observes native upgrade marking without cancelling the native order.

Data-stage eligibility checks passed for the four configured ground geometries. This is prototype/configuration evidence, not gameplay proof for all four geometries.

## 6. Game-test evidence

**Observed in Factorio 2.1.20, build 87512, ElectrifiedMainline 0.1.7, 2026-11-12:**

- The native green Upgrade Planner ordered 20 vanilla straight rails for upgrade at tick 14284.
- Construction robots mined the vanilla straight rails and built the custom straight rails.
- Ctrl+Z: `on_undo_applied tick=14591 player=1 action_count=20`; the 20 actions were `upgraded-entity` records with `original_name=straight-rail`. Robots removed the custom rails and rebuilt vanilla straight rails.
- Ctrl+Y: `on_redo_applied tick=14940 player=1 action_count=20`; robots again replaced vanilla straight rails with custom straight rails.
- No ElectrifiedMainline runtime errors were observed in the supplied log; the session exited normally.

**Verified scope:** 20 straight ground rails, native green Upgrade Planner, construction robots, Ctrl+Z and Ctrl+Y in the named game/mod setup.

## 7. What remains unverified

- Native green Upgrade Planner and Undo/Redo for curved-A ground rails.
- Native green Upgrade Planner and Undo/Redo for curved-B ground rails.
- Native green Upgrade Planner and Undo/Redo for half-diagonal ground rails.
- Ctrl+Shift superforced blueprint overlay and its Undo/Redo.
- The separate `em-rail-replacement-planner` selection tool and its staged fallback.
- Signals, routes, trains occupying rails, inventory refunds, partial/cancelled jobs, multiplayer, and broad modpack compatibility.

The old conclusion that native rail upgrades were categorically unsupported was falsified for the tested straight-ground-rail path. It must not be generalized into a claim that every geometry or every UI workflow now works.

## 8. Conclusion

The 0.1.7 test establishes that native rail upgrade plus native Undo/Redo is possible for **straight ground rails** under the stated conditions. It does not establish the same result for curved or half-diagonal rails, elevated rails, blueprint superforce operations, or the custom selection tool.

The next experiments must isolate each unverified geometry and workflow. Do not replace native behavior with a scripted workaround unless a same-type working analogue and the target-version API show that the native path cannot satisfy the specific acceptance test.
