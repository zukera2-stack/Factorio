# Electrified Mainline — START HERE / текущая работа

> **Latest updater channel (2026-11-21):** `test/updater-approved` is now **0.1.61**, HEAD `c8a1feddddfb3f160eae5f63cd1b0231e2136ce3` (runtime `55db63f6d3be6a2f64da005d6db28433e8c42d5d` verified by real Factorio 2.1.24 and packaging [CI 44875890182](https://github.com/zukera2-stack/Factorio/actions/runs/44875890182)). User has existing Updater 1.1: run old `Update.bat` option 1 and then 2; local owner game validation remains pending. This 061 version adds only read-only `/em-25kv-priority` diagnostics and keeps 060's 20 MW bridge. **main still 0.1.56**. Independent native-accumulator 061 experiment is NOT this approved game build. Any old 0.1.60 pointer below is historical and superseded; always check live refs.

> **Snapshot: 2026-11-21.** This is a cross-branch navigation index, **not** a claim that experimental code is present in `main`. Always re-fetch live branch HEADs before working. Russian quick summary: стабильная версия в `main` — **0.1.56**; патчер предлагает проверенную тестовую **0.1.61** (только диагностика, установка владельцем не подтверждена); отдельное исследование аккумуляторного шлюза не является игровым обновлением.

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
| **Approved test distribution** | [`test/updater-approved`](https://github.com/zukera2-stack/Factorio/tree/test/updater-approved), `c8a1feddddfb3f160eae5f63cd1b0231e2136ce3` | **0.1.61** read-only diagnostics, 060 bridge unchanged | [Native Factorio 2.1.24 + package CI 44875890182](https://github.com/zukera2-stack/Factorio/actions/runs/44875890182) PASS at exact runtime `55db63f6d3be6a2f64da005d6db28433e8c42d5d`. 130 game files / 83 unchanged PNGs. Inner SHA256 `3771b7241848ae98e74019659baeb03616ab9aa4fa5dfcb9e7acf02efbef754c`. Owner's PC game test pending. Updater 1.1 fetches this branch only. |
| **Windows updater development** | [`feature/git-updater-060`](https://github.com/zukera2-stack/Factorio/tree/feature/git-updater-060), `9bc032daf5910564db8622986c907b89b193db16` | **Updater 1.1**, not a new game mod | Exact source: [README](https://github.com/zukera2-stack/Factorio/blob/feature/git-updater-060/tools/updater/README.txt), [PowerShell](https://github.com/zukera2-stack/Factorio/blob/feature/git-updater-060/tools/updater/Updater.ps1). [Windows QA 44783774432](https://github.com/zukera2-stack/Factorio/actions/runs/44783774432), artifact 14650879317. Owner confirmed successful Windows install on 2026-11-20. **These updater files are not in `main`.** |
| **061 research only** | [`experiment/native-accumulator-gateway-061`](https://github.com/zukera2-stack/Factorio/tree/experiment/native-accumulator-gateway-061), `96e5fdfced96677f8f2a0e635039e6e32d381a55` | **Still 0.1.60 runtime**, plus independent test-only `em061-native-probe` | [Research and priorities](https://github.com/zukera2-stack/Factorio/blob/experiment/native-accumulator-gateway-061/docs/research/25kv-native-accumulator-gateway-061.md). [061 static/package CI 44869633734](https://github.com/zukera2-stack/Factorio/actions/runs/44869633734) **is not a native gameplay pass**; native matrix P1–P7 is **planned/documented, not implemented/tested**. This is **not** an Updater release. |

**Unchanged approval policy:** `main` = accepted visuals. `test/updater-approved` = exactly reviewed and explicitly promoted TEST package, never an arbitrary feature branch. The owner requested 0.1.61 test files for the patcher; reviewed diagnostic build 061 was promoted, **not merged into main**. The owner's live 061 installation is not yet confirmed.

## What the code actually does

- 0.1.56 `main`: user-accepted real HSR rail geometry, catenary visuals, locomotive art, cosmetic pantograph/sparks. No measured traction consumption.
- 0.1.60 test: **native electrically isolated corridor** with hidden poles, 20 MW/station bidirectional energy transfer via **accounted Lua buffered EEI bridge**. A configured exact-engine 2.1.24 headless test verified delivery and vanilla accumulator charge/reverse discharge; owner verified 20 MW on a configured EEI setup. No evidence of universal ordinary-generator/Bob's battery behavior or real electric locomotive traction.
- 061 updater test: read-only `/em-25kv-priority` command; no priority switching, same 20MW runtime bridge; [real native CI PASS](https://github.com/zukera2-stack/Factorio/actions/runs/44875890182).
- Separate 061 accumulator research: question whether engine-native `electric-energy-interface` **primary/secondary/tertiary input/output priorities** can simplify dispatch. These are **scheduling priorities, not voltages or independent inter-network connectors**. A native accumulator can overlap two unconnected pole supply areas (not have two wire terminals); tertiary battery-to-battery and multihop transfer are **unproven**. Existing `tests/em061-native-probe/` tests accumulator-overlap hypotheses only; it does **not yet execute** the documented EEI priority matrix.

## NEXT — pick up at exact paused task

**First task:** build a **separate disposable Factorio 2.1.24 build 87808 native-engine probe** for the EEI priority matrix P1–P7 (source-side secondary vs tertiary input; sink-side secondary vs tertiary output; native accumulator discharge/charge, ordinary secondary loads, critical consumers). Respect `docs/RESEARCH_METHOD.md` and the research record on the 061 branch. Measure actual J/tick, network IDs and energy conservation, not just Lua mock results. Do **not** modify accepted 060 while researching.

**After test evidence:** compare with the 060 bridge; reject a fully native replacement if battery discharge, two-way 20 MW transfer, safe isolation or multihop fail. Only an independently verified future gameplay build may be proposed for owner-approved updater promotion. GUI, Bob's integration, live rail break/recovery and traction are further work, **not already completed**.

## Updater 1.1: do not force manual ZIP downloads

- User already has Windows updater. The latest source is on `feature/git-updater-060`, not `main`. `Update.bat` opens Russian menu: **1 install/update**, **2 verify**, **3 rollback**, **4 choose mods folder**. Requires Git for Windows + Windows PowerShell 5.1; not Python/admin.
- `Updater.ps1` hard-pins `refs/heads/test/updater-approved`. It stages and verifies Git blobs, downloads only missing/changed files, refuses a running game or multiple installs, and does not edit saves or `mod-list.json`. Its backups are under Windows TEMP and may be removed by Windows.
- **Patcher-approved game 0.1.61** is distinct from the **unshipped accumulator overlap probe** in the experiment branch. Only the diagnostic game mod was promoted. Do not promote experimental branch just to allow a test. For future actual mod builds: engine CI → owner review/explicit permission → move exact reviewed commit of `test/updater-approved` → user runs existing `Update.bat`. No automatic main merge. A direct Actions ZIP artifact is a fallback if patcher fails; avoid needless manual downloads.

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
