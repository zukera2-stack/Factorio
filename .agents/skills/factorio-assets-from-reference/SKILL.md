---
name: factorio-assets-from-reference
description: Create, repaint, edit, render, verify, and deliver Factorio Electrified Mainline sprites, icons, wagons, locomotive bogies, wrecks, GUI art, shadows or masks from user-supplied or verified vanilla/game reference assets. Use when the owner asks to draw, generate, show, change, or integrate in-game visuals.
---

# Factorio — создание ассетов по запросу владельца

Этот навык **обязателен для любого запроса на игровую графику** проекта `zukera2-stack/Factorio`: перекраска, переделка кузова, колёс, опор, проводов, вагонов, wreck, иконок, рендер из V3, изготовление 256-направленного атласа. Прочитай [контракт и примеры](references/asset-contract.md), [входной шаблон заказа](references/request-template.md) и [рабочую дисциплину](../../../docs/development/ASSET_WORKSHOP.md). Основной путь: **фактический источник → проверяемая правка → одинаковый ракурс «до/после» → согласие владельца → реальные спрайты → Direct Patch**.

## 3D-first rolling-stock design — owner instruction 2026-11-26

For new rolling-stock bodies, use the approved concept → real 3D → sprites pipeline, not the old vanilla repaint-only route. The owner explicitly authorizes new smooth cargo/tank/battery bodies; the original V3 locomotive is protected. First propose visual concept sketches in the V3 style, marked CONCEPT, not model renders. Record each approved sketch file SHA256 and owner approval; never start its production model before that explicit art approval. Concept images may be artistic; do not infer calibrated dimensions from perspective drawings. Show same-scale side/top/three-quarter views where possible. If a conceptual choice is unresolved, record it as a proposal. After concept approval, iterate autonomously on real geometry and show only a verified final model candidate, not intermediate blockouts as finished work.

Use [A3DS reference-to-model skill](https://github.com/zukera2-stack/Agent-3D-Studio/blob/3c0f4d057f8569bc410120baf3f009dce86b9eab/.agents/skills/a3ds-reference-to-model/SKILL.md) and [method](https://github.com/zukera2-stack/Agent-3D-Studio/blob/3c0f4d057f8569bc410120baf3f009dce86b9eab/docs/REFERENCE_TO_MODEL_METHOD.md), **method B** for mechanical assemblies. Pin this exact source revision; A3DS main is bootstrap only, Stage 04B stacked experimental branch is frozen, do not modify it or start Stage 05. Reuse its V3 parametric generator and original geometry; Blender may be used for inspection, materials and rendering, not required for A3DS core. Do not equate sketch, verified GLB, sprite candidate, and in-game acceptance. See [rolling-stock task](../../../docs/development/ROLLING_STOCK_3D_DESIGN.md).

## 0. Сначала — что именно пользователь просит

- **Эскиз/концепт/«покажи»**: сделать **1–2 реальные пробы** на конкретных исходниках в одинаковом масштабе. Когда пользователь просит именно нарисовать новое изображение, допускается генерация изображения, но *её результат нельзя называть отредактированным ванильным спрайтом*. Не генерируй плакат с выдуманным поездом, если задача — перекрасить ванильный вагон.
- **Перекраска/«возьми ваниль»/«оставь геометрию»**: требуются реальные исходные пиксели из игры/библиотеки/точного источника; работай с ними программно (Pillow) или инструментом редактирования по референсу. Без оригинала — только помеченная `reference study`, не рабочий спрайт.
- **Новые детали**: допустимы ассеты из принятой 3D-модели/своего исходника или отдельная прорисовка, **без изменения неоговорённых силуэтов**. Тележка из EM082 — реальный слой с собственными точками крепления, поворотом и тенью; её нельзя просто растянуть поверх вагонного PNG и назвать готовым.
- **Новый фантазийный объект**: можно создать концепт генерацией по свободному запросу, но не подменять им существующий ванильный предмет.

## 1. Референсы перед работой

1. Прочитай живые `AGENTS.md`, `docs/CURRENT_WORK.md`, `docs/AI_CONTEXT.md`, `docs/PROJECT_STATE.yaml`, [Direct Patch](../../../docs/development/DIRECT_PATCH_WORKFLOW.md) **на выбранной ветке**.
2. Найди точный исходник: GPT Library `/Factorio/Working-Mod/`, `/Factorio/Models/`, `/Factorio/References/`, предыдущие Direct Patch; GitHub `ElectrifiedMainline/graphics/...` и `art/sprites/...`; загруженные изображения владельца. **Фиксируй имя, путь, SHA256, происхождение, разрешённую область правки.** Показанный скриншот — не равнозначен оригинальному спрайт-атласу. Linux Factorio headless не гарантирует наличия Base PNG. Если фактический оригинал недоступен — явно укажи блокер, не придумывай «ванильный исходник».
3. Для сторонних/ванильных ассетов оцени право на изменение/распространение; при сомнении оставляй исходник как reference, а игру заставляй использовать `__base__/...` или собственную оригинальную графику; не включай сомнительные изображения в дистрибутив.
4. Перед созданием на одной короткой строке зафиксируй: `Объект / референс / что сохраняем / что меняем / результат (study, concept, sprites, patch)`. Нельзя незаметно сменить medium или форму.

## 2. Реальная переделка (source-first)

- Сначала предъяви **исходник слева, ту же перспективу после правки справа**, одинаковое обрамление и масштаб; не делай рекламный концепт-лист вместо требуемой переделки.
- Сохранить все заранее утверждённые контуры, функциональную форму, количество секций, двери/сливы/сцепки, ориентацию/габариты, pivots, привязку к рельсам. Проверяй именно тот конкретный кадр, а не узнаваемость «по мотивам».
- Отдели `body`, `runtime tint mask`, `shadow`, `wheels`, `wheel shadow`, `roof/overlay`, `effects`, `icon`. Тени — **отдельная** карта/слой, не земля как часть спрайта. Для графики Factorio сверяй `shift`, `scale`, `apply_projection`, размер кадра, `direction_count`, `line_length`, `lines_per_file`, native joint offset, render layer и mask flags по реальному прототипу. Не переносить параметры локомотива на вагоны автоматически.
- Перекраска кузова: сравни исходный и новый alpha **пиксель-в-пиксель**. Для добавленных деталей используйте отдельные слои; `RGBA` должна сохранять правильную прозрачность без прямоугольного фона. Сохранение силуэта — вычислимый контракт, не обещание.
- Если пользователь просит новый эскиз, сначала нарисуй **один утверждаемый образец**, и только после приёмки размножай на повороты. Для поворотов используй настоящую 3D-геометрию/исходные кадры и фиксированную камеру; **нельзя делать 256 направлений из одного скриншота вращением плоского изображения**.

## 3. Формат исполнения

- **Study**: фотомонтаж на настоящем скриншоте, явно `НЕ ИГРОВОЙ PNG`. 2D crop в игре — лишь видимость одного ракурса, не доказательство корректной sprite-layer.
- **Concept**: свободный рисунок, владелец оценивает художественную идею; `НЕ ИГРОВОЙ PNG`, если нет контрактов точной геометрии.
- **Preview**: настоящие верифицированные кадры/слои с графической проверкой, но не утверждённые в игре.
- **Runtime**: точный совместимый PNG-атлас/слой + SHA256 и QA + действительный прототип/поворот.
- **Direct Patch**: только изменённые игровые файлы и `info.json` в ZIP с путями **от корня распакованного мода**, manifest и исходники отдельно, проверки по `scripts/direct_patch.py`; не считать одобрением до проверки владельца в Windows.

## 4. Проверки

Используй 
`python scripts/assets/qa_sprite_edit.py --source PATH --candidate PATH --mode repaint --frame-width W --frame-height H --frames N --report REPORT.json`
для **pixel-exact** перекраски; `--mode component` только для отдельно нарисованной детали (для намеренно пустого вспомогательного слоя, например `pantograph-down`, явный `--allow-empty-layer`), `--mode study` для скриншота/концепта (результат не игрового уровня). Тесты: `python -m unittest discover -s tests -p 'test_asset_workshop.py' -v`. Проверка PNG по одному кадру **не проверяет** повороты, сцепку, тени в Factorio и примыкание к рельсу; проверить все нужные направления, размеры, маски, тени, колёса, двери/анимацию и ghost в 2.1.

У каждой поставки есть `source_provenance` и `qa.json`: ref + SHA, target + SHA, режим, ограничения, исходная и целевая версия, механика изменялась/нет, результат тестов, что не проверено. Плоский концепт, ZIP с исходниками и игровой ZIP — разные артефакты. Не заявляй «в игре проверено» по картинке, рендеру или Linux Headless.

## 5. Исторический пример перекраски моторных вагонов (до нового 3D-задания 26.11.2026)

В `ElectrifiedMainline/prototypes/em072_c5_fullmod_trial_063.lua` оба моторных вагона являются **копиями native cargo-wagon / fluid-wagon**. Не создавать пассажирскую электричку, закрытый «моторный ящик» или новый кузов. Принцип: тот же грузовой вагон и цистерна, **только одобренная графитово-серая/красная окраска и согласованная тяговая тележка V3/EM082**. Количество и форма резервуаров/грузовых отсеков берутся из реальных исходных кадров, не из воображения. Никакого самостоятельного пантографа на вагоне — источник тяги остаётся в электровозе. У тележки нужны отдельные положение/собственные колёса/тень, сохраняется физика и сцепка.

Архив исследования `/Factorio/References/Motor-Wagon-Vanilla-Sprite-Studies/cargo_actual_screenshot_before_after_2d_preview.zip` содержит реальный игровой crop с «до/после», extract кадра EM082 и код 2D пробного repaint. **Это только один screenshot reference study, не ванильный многокадровый sprite atlas, не принятый арт и не Direct Patch**. Для `cargo`/`fluid` runtime сначала добыть именно Base sprite sheets и проверить прототип `pictures`/`wheels`; затем отдельная графическая приёмка.

Не менять `main`, принятый электровоз, поведение электроснабжения и игровые файлы без отдельного запроса. Если запрошены только скилл/документация — никакого тихого графического изменения.
