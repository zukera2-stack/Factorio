# Development status

**Branch-specific status:** `diagnostic/blueprint-rail-undo`, ElectrifiedMainline **0.1.7**.
**Last verified in-game session:** 2026-11-12, Factorio **2.1.20** (user installation directory labelled 2.1.20b).

## Verified

- The 0.1.7 mod loads with the user's Bob's Mods environment and opens the existing test save.
- Vanilla **straight ground rails** upgrade to high-speed straight rails through the **native green Upgrade Planner** and construction robots.
- **Ctrl+Z** reverses the upgrade and robots restore the original vanilla straight rails; **Ctrl+Y** upgrades them again. Both Undo and Redo logged **20 `upgraded-entity` actions**, with corresponding mining/building events.
- `data-final-fixes.lua` configured four corresponding ground-rail prototype pairs (straight, curved-A, curved-B, half-diagonal), and logged successful eligibility checks. This does **not** mean all four have passed gameplay tests.
- Earlier separate tests confirmed the unified custom rail planner places custom rail entities with robots and recognizes additional rail geometries for detection.

## Unverified or still experimental

- Native green Upgrade Planner upgrade/Undo/Redo for **curved-A, curved-B, half-diagonal** rails.
- **Ctrl+Shift superforced blueprint overlay** and its Undo/Redo. Do not equate that workflow with the confirmed green planner test.
- The separate `em-rail-replacement-planner` selection tool and its staged deconstruction/ghost workflow.
- Complete rail signal/route behavior, train occupancy, simultaneous work, inventory refunds and modpack compatibility.
- Actual electric traction, overhead transfer, onboard battery, bidirectional substations and regenerative braking are **not implemented**.

## Known legacy behavior

The 0.1.6 scripted superforce-ghost `undo_index=1` experiment allowed Undo to remove new rails but **did not restore** the originals. The old two-stage fallback remains in current source, and must not be described as fully reversible.

## Evidence & development

- [Project state — authoritative statuses](PROJECT_STATE.yaml)
- [Current AI handoff](AI_CONTEXT.md)
- [Research-first engineering method](RESEARCH_METHOD.md) — **mandatory: inspect working examples and prototype/API contracts before implementing a workaround**
- [Architecture](ARCHITECTURE.md)

CI packaging and Lua syntax checks do **not** prove in-game behavior. Every claim must have a scoped game test or be labelled unverified.
