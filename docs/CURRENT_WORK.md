> **Verified integration 0.1.62 (2026-11-21):** [main merge PR #46](https://github.com/zukera2-stack/Factorio/pull/46) is DRAFT and mergeable; [combined-branch real Factorio headless native CI #44922029418](https://github.com/zukera2-stack/Factorio/actions/runs/44922029418) SUCCESS, 3/3 native power cases, battery reverse restored, 2030 ticks. CI inner ZIP SHA256 **391e8d3df756f048996fd4794a3b0b695d74f13475f2da3dca582252709f19cb**, same as exact source EM070; [CI install artifact](https://github.com/zukera2-stack/Factorio/actions/runs/44922029418/artifacts/14714291612). Main **still** 0.1.56 until owner approves merging, existing Updater-approved 0.1.61 **unchanged**; 0.1.62 should be explicitly labeled public beta, with backup-save warning.

> **INTEGRATION NOTE (2026-11-21):** This index was written for stable 0.1.56 and older 0.1.60/0.1.61 experiments. New public beta candidate **0.1.62** is reviewed in [PR #46](https://github.com/zukera2-stack/Factorio/pull/46) from `release/0.1.62-main-integration` and contains native dynamic-EEI repair [EM070](../docs/research/25kv-dynamic-eei-070.md), native 060 power reverse and 0J closed-reservoir energy loss tests. **Authoritative live branch info** must always be checked against GitHub and `ElectrifiedMainline/info.json`. Existing Updater-approved branch is currently **0.1.61**, not the older 0.1.60 snapshot described below. Direct PR merge does not itself update the installed updater channel. `main` remains 0.1.56 until PR #46 is explicitly merged.

# Electrified Mainline — START HERE / текущая работа

> **Snapshot: 2026-11-21.** This is a cross-branch navigation index, **not** a claim that experimental code is present in `main`. Always re-fetch live branch HEADs before working. Russian quick summary: стабильная версия в `main` — **0.1.56**; патчер устанавливает проверенную тестовую **0.1.60**; исследование **0.1.61** не является игровым обновлением.

## Read this first in every new chat

1. Determine the exact repository `zukera2-stack/Factorio`, current working branch and HEAD; compare the live branch list below with GitHub. Do not infer version from the current conversation, a historical notebook or a filename.
2. Read `AGENTS.md`, **this file**, then `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml` **on the same chosen branch**. The `main` copies describe the accepted 0.1.56 baseline only.
3. Read the relevant **other branch's** handoff and implementation source when continuing 0.1.60 or 0.1.61, rather than resetting the work to main.
4. Inspect `ElectrifiedMainline/info.json` and actual relevant code on the target branch before making implementation or game-compatibility claims.
5. Distinguish `implemented`, `CI syntax/package tested`, `native-engine-tested`, `owner-tested` and `owner-approved for update`. Provide links to the exact commit, Actions run and artifact for every test claim.
6. Use the scoped skills in `.agents/skills/`: `factorio-handoff`, `factorio-native-research`, `factorio-updater-release`. These are portable Agent Skills; any chat assistant without automatic skill discovery can read their `SKILL.md` explicitly.

## Verified branch map — snapshot 21 Nov 2026

| Role | Branch / HEAD at audit | Game mod state | Evidence and constraints |
|---|---|---|---|
| **Accepted stable** | [`main`](https://github.com/zukera2-stack/Factorio/tree/main), `7849d192ba35823d9636abe9bc6d370beb41adfa` | **0.1.56** | Owner-accepted HSR visuals; [PR #30](https://github.com/zukera2-stack/Factorio/pull/30), [CI 44614544575](https://github.com/zukera2-stack/Factorio/actions/runs/44614544575). No actual locomotive traction MW. `docs/STATUS.md` and architecture in main are **main-scoped**, not a report about all branches. |
| **Approved test distribution** | [`test/updater-approved`](https://github.com/zukera2-stack/Factorio/tree/test/updater-approved), `ea9366a9798cd78efec4b675c81d086c09170c28` | **0.1.60** | Frozen 129 runtime files / 83 PNGs; [package CI 44772684519](https://github.com/zukera2-stack/Factorio/actions/runs/44772684519); earlier [exact 2.1.24 native engine test 44762226742](https://github.com/zukera2-stack/Factorio/actions/runs/44762226742) scoped to configured EEI + accumulator charging/reversal. Source of bytes is locked, not all user scenarios passed. **Only this ref is read by Updater 1.1.** |
| **Windows updater development** | [`feature/git-updater-060`](https://github.com/zukera2-stack/Factorio/tree/feature/git-updater-060), `9bc032daf5910564db8622986c907b89b193db16` | **Updater 1.1**, not a new game mod | Exact source: [README](https://github.com/zukera2-stack/Factorio/blob/feature/git-updater-060/tools/updater/README.txt), [PowerShell](https://github.com/zukera2-stack/Factorio/blob/feature/git-updater-060/tools/updater/Updater.ps1). [Windows QA 44783774432](https://github.com/zukera2-stack/Factorio/actions/runs/44783774432), artifact 14650879317. Owner confirmed successful Windows install on 2026-11-20. **These updater files are not in `main`.** |
| **061 research only** | [`experiment/native-accumulator-gateway-061`](https://github.com/zukera2-stack/Factorio/tree/experiment/native-accumulator-gateway-061), `96e5fdfced96677f8f2a0e635039e6e32d381a55` | **Still 0.1.60 runtime**, plus independent test-only `em061-native-probe` | [Research and priorities](https://github.com/zukera2-stack/Factorio/blob/experiment/native-accumulator-gateway-061/docs/research/25kv-native-accumulator-gateway-061.md). [061 static/package CI 44869633734](https://github.com/zukera2-stack/Factorio/actions/runs/44869633734) **is not a native gameplay pass**; native matrix P1–P7 is **planned/documented, not implemented/tested**. This is **not** an Updater release. |

**Unchanged approval policy:** `main` = accepted visuals. `test/updater-approved` = exactly reviewed and explicitly promoted TEST package, never an arbitrary feature branch. The owner has **not** authorized 0.1.61 gameplay installation or any 061 merge.

## What the code actually does

- 0.1.56 `main`: user-accepted real HSR rail geometry, catenary visuals, locomotive art, cosmetic pantograph/sparks. No measured traction consumption.
- 0.1.60 test: **native electrically isolated corridor** with hidden poles, 20 MW/station bidirectional energy transfer via **accounted Lua buffered EEI bridge**. A configured exact-engine 2.1.24 headless test verified delivery and vanilla accumulator charge/reverse discharge; owner verified 20 MW on a configured EEI setup. No evidence of universal ordinary-generator/Bob's battery behavior or real electric locomotive traction.
- 061 research: question whether engine-native `electric-energy-interface` **primary/secondary/tertiary input/output priorities** can simplify dispatch. These are **scheduling priorities, not voltages or independent inter-network connectors**. A native accumulator can overlap two unconnected pole supply areas (not have two wire terminals); tertiary battery-to-battery and multihop transfer are **unproven**. Existing `tests/em061-native-probe/` tests accumulator-overlap hypotheses only; it does **not yet execute** the documented EEI priority matrix.

## NEXT — pick up at exact paused task

**First task:** build a **separate disposable Factorio 2.1.24 build 87808 native-engine probe** for the EEI priority matrix P1–P7 (source-side secondary vs tertiary input; sink-side secondary vs tertiary output; native accumulator discharge/charge, ordinary secondary loads, critical consumers). Respect `docs/RESEARCH_METHOD.md` and the research record on the 061 branch. Measure actual J/tick, network IDs and energy conservation, not just Lua mock results. Do **not** modify accepted 060 while researching.

**After test evidence:** compare with the 060 bridge; reject a fully native replacement if battery discharge, two-way 20 MW transfer, safe isolation or multihop fail. Only an independently verified future gameplay build may be proposed for owner-approved updater promotion. GUI, Bob's integration, live rail break/recovery and traction are further work, **not already completed**.

## Updater 1.1: do not force manual ZIP downloads

- User already has Windows updater. The latest source is on `feature/git-updater-060`, not `main`. `Update.bat` opens Russian menu: **1 install/update**, **2 verify**, **3 rollback**, **4 choose mods folder**. Requires Git for Windows + Windows PowerShell 5.1; not Python/admin.
- `Updater.ps1` hard-pins `refs/heads/test/updater-approved`. It stages and verifies Git blobs, downloads only missing/changed files, refuses a running game or multiple installs, and does not edit saves or `mod-list.json`. Its backups are under Windows TEMP and may be removed by Windows.
- **Research 061 is a separate test-only mod**, intentionally *not* delivered via this updater. Do not promote experimental branch just to allow a test. For future actual mod builds: engine CI → owner review/explicit permission → move exact reviewed commit of `test/updater-approved` → user runs existing `Update.bat`. No automatic main merge. A direct Actions ZIP artifact is a fallback if patcher fails; avoid needless manual downloads.

## Where documentation lives and what it means

| Document | Meaning |
|---|---|
| `AGENTS.md` | Mandatory AI contributor policy, protected baselines, skills |
| `docs/CURRENT_WORK.md` | Cross-branch index / first document for a new chat |
| `docs/AI_CONTEXT.md` / `docs/PROJECT_STATE.yaml` | Scoped to the **checked-out branch**; synchronized when relevant state changes |
| `docs/STATUS.md` / `docs/ARCHITECTURE.md` on `main` | Accepted 0.1.56 scope only |
| `PROJECT_CONTEXT.md` | Historical notebook dated 2026-11-09; **not a current task list** |
| `docs/research/25kv-native-accumulator-gateway-061.md` **on 061 branch** | Current power-priority hypotheses, no native 061 verdict |
| `tools/updater/README.txt` **on updater branch** | Actual user update workflow and constraints |
| `docs/DOC_AUDIT_2026-11-21.md` | Audit evidence, conflicts and closure checklist |

### Handoff update contract

On any material implementation, branch-status, test-evidence, decision, approved-pointer or distribution change:
1. Capture target repo/ref, SHA, Factorio build, scope and evidence; distinguish user assertion from logs.
2. Update `docs/AI_CONTEXT.md` **and** `docs/PROJECT_STATE.yaml` in that changed branch in the **same commit**.
3. Update this branch-map index through a **documentation PR to main** when cross-branch state changes; never silently edit stable gameplay or rewrite old evidence.
4. Check the links and the three skills; preserve archived notes rather than deleting history.
5. Treat a future new chat as stateless: recover from the repo, not a claimed long-term assistant memory.

This snapshot may age. **Live GitHub refs + actual source + exact CI/game evidence take precedence**, and a mismatch must be reported, not silently overwritten.
