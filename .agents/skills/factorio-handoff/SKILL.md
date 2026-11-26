---
name: factorio-handoff
description: Recover active Electrified Mainline work from GitHub when starting a new chat, resuming a paused task, checking versions, status, branch differences, or past acceptance evidence. Prevent mixing accepted main, installed updater build and experiments.
---

# Factorio — восстановление проекта и цикл Direct Patch

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
