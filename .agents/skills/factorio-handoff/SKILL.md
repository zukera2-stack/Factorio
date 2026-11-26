---
name: factorio-handoff
description: Recover active Electrified Mainline work from GitHub when starting a new chat, resuming a paused task, checking versions, status, branch differences, or past acceptance evidence. Prevent mixing accepted main, installed updater build and experiments.
---

# Factorio — восстановление проекта и цикл Direct Patch

**2026-11-26 — repository cleanup complete:** `main` is the sole active development branch (0.1.103); `archive/pre-main-0.1.103-20261126` is a retention-only branch at `25f91ad775007f80aca048a8c69eff90a3d9686e`, never merge it into main. All 135 original branch tips verified reachable after deleting their old names (93 also main ancestry, 42 archive-only); 605 reachable commits in archive. All 51 superseded PRs closed with original bodies preserved and archive notes; 0 open PRs, 2 branches verified. Historical branch references below may no longer resolve by name: use [archive inventory](https://github.com/zukera2-stack/Factorio/blob/25f91ad775007f80aca048a8c69eff90a3d9686e/docs/development/BRANCH_ARCHIVE_20261126.md) and exact commit SHA. Restore historical work only when needed; new tasks branch from live main. No runtime/artwork change, issue closure, release, tag or owner installation. The existing native 111/111 and CI 169/169 remain the validated baseline; Windows GUI, multiplayer and UPS remain unverified.

**2026-11-26 — CURRENT AUTHORITATIVE CHECKPOINT:** Owner explicitly approved merge of PR [#91](https://github.com/zukera2-stack/Factorio/pull/91). `main` is the unified **0.1.103 development baseline**, merge commit `4bdbacda206fca1d040a809ce276f5fce1dfab69`. All 130 commits preserved; post-merge game tree `8d64e44d74c37f5a202a01ef09fcda3cda3d01af` identical to tested integration head `ed8639230112668b3c8dd9a12e565988bfde3656`. Native 111/111 (106 explicit completion + 5 stand assertions), CI 169/169 payload including 99 PNG; latest pre-merge CI 45886890810 passed. Start new development from live main. Full package requires frozen EM080/081/083 staging; do not install the unstaged tree. For future intentional runtime changes, update the exact integration payload manifest together with the source and verify the full staged archive; never bypass parity. Last confirmed owner-running archive remains 0.1.84; Windows GUI/actual owner save, multiplayer and UPS unverified. No release, tag, Mod Portal upload, installation or branch deletion authorized by this merge. Historical experimental branches and evidence remain preserved pending separate retention audit. Older status statements below are historical, not current instructions.

> **26.11.2026:** active integration candidate 0.1.103, branch `integration/em094d4-main-candidate`. [Audit](../../../docs/development/EM094_INTEGRATION_AUDIT.md), [test plan](../../../docs/development/EM094_INTEGRATION_TEST_PLAN.md). Final CI and native regression pending, owner0.1.84, main0.1.62. Use latest branch handoff over historical version references below.

> Graphic requests: first read [factorio-assets-from-reference](../factorio-assets-from-reference/SKILL.md) and [Asset Workshop](../../../docs/development/ASSET_WORKSHOP.md). Reference screenshot study is not an atlas; do not invent vanilla body geometry.


**Текущее решение владельца: 25.11.2026.** Малые версии мода передаются **Direct Patch ZIP в чате**, без обязательной GitHub Actions сборки на каждом шаге. Полная CI — только при интеграции/контрольной полной сборке. Старый Windows Updater не использовать. `main` не менять без прямого разрешения.

## При начале нового чата

1. Прочитай `/Мод фактроио/00_СТАРТ_АГЕНТА_Factorio.md` в GPT Library. Проверь фактический SHA `main` и рабочей ветки в `zukera2-stack/Factorio`, открытые PR/Issues, `ElectrifiedMainline/info.json`.
2. Прочитай **на выбранной ветке** `AGENTS.md`, `docs/CURRENT_WORK.md`, `docs/AI_CONTEXT.md`, `docs/PROJECT_STATE.yaml`. Исторический `main` 0.1.62 и игровые испытания 0.1.84/0.1.85 — **разные состояния**.
3. Прочитай **[обязательный стандарт](../../../docs/development/DIRECT_PATCH_WORKFLOW.md)**, [реестр патчей](../../../patches/registry.json) и [рабочую библиотеку](../../../docs/development/GPT_LIBRARY_WORKSPACE.md). Реально установленная у владельца копия, подтверждённая архивом, — 0.1.84; 0.1.85 интеграционно проверена Linux/CI (157/157 совпадений), но отдельная Windows-приёмка 0.1.85 ещё не записана.
4. Для воспроизведения найди в Library `/Factorio/Working-Mod/ElectrifiedMainline_0.1.84_OWNER_RUNNING_20261125.7z`, `/Factorio/Patches/`, `/Factorio/Local-QA/`. Материализуй файлы, проверь точные SHA256, не угадывай их доступность по именам. Сохраняй резервную копию, никогда не меняй пользовательскую установку/сохранения.
5. Новое изменение: минимальная отдельная ветка от **текущей воспроизводимой базы**, Lua/графические проверки, native headless full-mod тесты при возможности, **ZIP только изменённых игровых файлов** + `info.json` и внешний manifest. `python scripts/direct_patch.py build/verify` сравнивает два точно восстановленных дерева, не устанавливает мод; при удалениях записывает только список для ручного удаления. Указывать версии **from → to**, SHA256 и точные действия владельцу.
6. Сначала вручную выдать Direct Patch ZIP в чате, записать его в Library и `patches/registry.json` вместе со статусом. Не ждать полного CI на каждый патч. Только положительная игровая проверка владельцем разрешает менять поле owner acceptance; native PASS не равен Windows GUI PASS.
7. На интеграционном рубеже воспроизвести **полную** игру из исходников и точных архивов графики, запустить GitHub Actions CI, сравнить все игровые файлы с архивом владельца и реальные SAVE/LOAD миграции. Отдельная приёмка перед возможным PR в `main`. Никаких автоматических merge/releases.
8. Любое материальное изменение кода/решений — обновление `docs/AI_CONTEXT.md` и `docs/PROJECT_STATE.yaml`; в нужных случаях `docs/CURRENT_WORK.md` и реестра. Не стирать историю/доказательства, не воссоздавать Updater.

## Уровни подтверждения

Исходники, статический тест, формат ZIP, GitHub CI, нативный Linux Factorio, Windows GUI/реальное сохранение владельца, принятие владельцем, merge в `main`, релиз — **разные этапы**. Графика требует реального визуального подтверждения; успешная загрузка Headless не свидетельствует о правильной отрисовке.

Остальные экспериментальные исследования в старой истории нужны для технического анализа, но **не переопределяют** этот актуальный рабочий процесс.
