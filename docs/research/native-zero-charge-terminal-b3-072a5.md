# EM072-A5-B3 — 24 настоящих аккумулятора зарядились с нуля, script-owned терминал, OFF и исчерпание

**Дата:** 2026-11-21. **Статус:** `ISOLATED NATIVE FACTORIO 2.1.24 + INDEPENDENT DISK SAVE/LOAD PASS`, **не игровая реализация**. Исследовательская ветка `experiment/em072a5-native-recharge-b3`, поверх B1 commit `8531bf0eb726de98ecdfa534b1d48233ef6b3d3d` и его [PR #54](https://github.com/zukera2-stack/Factorio/pull/54). В `main` остаётся штатный `void` электровоз, gameplay 0.1.62; не изменять `main`, не публиковать, не создавать патчер/пользовательский ZIP.

## 1. Исходники, аналоги и проверяемая гипотеза

* Точный исходный игровой архив CI EM071/EM070: SHA256 `91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575`, [GitHub Actions run 44925677432](https://github.com/zukera2-stack/Factorio/actions/runs/44925677432), artifact 14714614745. Исходные native модули проверены строгим Git blob SHA1 runner до наложения тестовых патчей.
* Движок: официальный Linux headless **Factorio 2.1.24 build 87808**, Base; DLC отключены.
* Работающий аналог: **собственные** `prototypes/power_bridge_058.lua` и `scripts/technical_network_046.lua`: скрытый electric-pole port и ограниченные `LuaWireConnector.connect_to` с `wire_origin.script`, технический whitelist, аудит соединений. `scripts/mast_network_059.lua`: видимая мачта подключена к native техническому anchor. Native Base `small-electric-pole`, `accumulator`, `solar-panel`, `electric-energy-interface` служат образцами *соответствующих типов*. [LuaWireConnector API](https://lua-api.factorio.com/latest/classes/LuaWireConnector.html); [ElectricPolePrototype API](https://lua-api.factorio.com/latest/prototypes/ElectricPolePrototype.html). Указанная онлайн-версия API может отличаться от 2.1.24 — каждое использование проверено нативно на 2.1.24, а не признано по аналогии.
* Предварительно записанный план: `docs/research/native-terminal-preflight-072a5-b3.md`. Проверяемая гипотеза: **зарегистрированный script-owned hidden electric-pole terminal** с собственной supply radius 24, присоединённый *только к подтверждённому anchor контактной сети*, может питать 24 стандартных нативных аккумулятора и тяговый EEI, **не расширяя supply area штатных мачт**.

### Точная схема B3 (только в disposable тестовом моде)

- Одна настоящая EM070 AUTO с ограничением **20 МВт**. Заводская сеть отделена от контактной, в ней **84 vanilla accumulator** с начальным запасом **420 МДж**, дополнительно **346 настоящих solar-panel**, из которых **270 получили native factory electric_network_id**. Панели питали предзаряд только по родной физике игры, без `entity.energy = ...` для генерации. В тесте фиксировано дневное освещение.
- Контактная сеть: **24 обычных аккумулятора с точно 0 Дж на t1** (ёмкость 120 МДж; отдача/заряд до 7,2 МВт), **native traction EEI secondary_input**, **12 разных настоящих LuaTrain.id** с тестовыми native burner locomotives; водитель ускоряется обычным `character.riding_state`, **никогда** не меняли `LuaTrain.speed`.
- Тестовый *размещаемый по прототипу* `em072a5-b3-outpost-controller` (копия Base small electric pole) имеет **0 copper reach, 0 supply area**, предмет и рецепт. В самом стенде контроллер **создаётся скриптом** (путь ручного строительства/деконструкции/blueprint игрока не тестировался). По удалённому проверочному вызову он создаёт один скрытый `em072a5-b3-outpost-terminal`, с supply radius **24** и **script-origin** медным соединением к настоящему `em-25kv-technical-anchor-046`. В TEST-ONLY копии `technical_network_046.lua` whitelist разрешает **только registered terminal unit_number → anchor unit_number**. Не изменены `em-35kv-catenary-pole` и `em-35kv-catenary-pole-north` (`supply_area_distance=0` в исходных прототипах).
- Перед подключением проверяются force, surface, расстояние <=20, связность `technical_046.components` и `mast_connected` для проверенной HSR-мачты. Неверная force / попытка передать вместо мачты номер подстанции возвращают FALSE. После штатного технического аудита и после OFF проверяется сохранность зарегистрированного copper-провода.
- Списание тяговой энергии: EEI-метер получает Дж от **настоящего native electric solver**, затем один раз в тике записанная сумма списывается с `meter.energy` и зачисляется в `LuaBurner.remaining_burning_fuel`. **Ни один нативный аккумулятор не подкачивается через Lua в рабочих тиках.** Тестовая заявка — фиксированные 2 МВт/поезд, **не** динамическая модель throttle.

## 2. Итоги настоящего движка

| Событие | Результат |
| --- | --- |
| t1 | 24 native outpost accumulator = **0 Дж** |
| t65 | Зарегистрированный скриптовой порт подключён к техническому anchor, source/line network физически различны |
| t90 | **270 реальных solar panels** видны в factory network; 84 factory / 24 outpost native cells принадлежат нужным разным сетям; native meter в corridor |
| t95 | Неверная сила и неподходящий объект feeder: **отказ** |
| t200 | **15 720 000 Дж** физически накоплено в 24 outpost battery, без запроса поездов, native energy 0→15.72МДж |
| t225 | Все настоящие solar panels физически удалены, новой генерации нет |
| t231 | Финитный замкнутый ledger запускается от реальных **439 853 333.333 Дж** (factory + outpost + EM070 EEI + traction meter + native burners); не смешивать его с интервалом солнечной генерации |
| t240 | Включена тестовая заявка 12×2 МВт на настоящие поездные двигатели |
| t300 | EM070 переведена в OFF; peak до OFF = **24 МВт** (20 МВт максимум из станции + реальный дефицит из outpost) |
| t390 | После OFF поезда получили **10 200 000 Дж** в контроле; физический outpost запас **14 800 000 → 4 053 333.333 Дж**; factory после settle **0 Дж расхода**; все поезда продолжали движение (min +86.699 тайла) |
| t445, t451 | Outpost и native traction meter **опустошены**; дальнейшая выдача LuaBurner — **0 Дж** |
| t455 | Native результат: передано и потрачено **39 533 333 Дж**, каждому составу **3 294 444.444 Дж**; все 12 перемещались, минимум **178.4531 тайла**; полный остаток **-0.000002 Дж**, **1 построение HSR кэша** |
| SAVE/LOAD | Реальный headless server disk SAVE **t151**, checkpoint **956 607 байт**; другой процесс `--test-save` **309 тиков**: те же цифры и проверки |

**Нативный benchmark:** 460 тиков. `Performed 460 updates in 741.029 ms`, avg 1.611ms, максимальный тик 236.698ms включает создание/разрушение большой лабораторной карты. **Это НЕ проверка стабильных 60 UPS огромной сети**. Native журнал SHA256 `f91ef954969fae9a633e15be9ab776acf77d0da1c4cf7796539cdfbecdfd0ca0`; независимый reload журнал SHA256 `937fe1f7a6c3154bcec8f50d8f4c05b74c7cbdc72513566edf5fd238054d1432`. Показатели подтверждены повторным полным запуском runner с PASS.

### Отрицательный контроль — почему недостаточно «перекинуть две батареи»

До добавления генерации отдельно запускался тот же лабораторный outpost на стороне коридора, но с 84 заводскими аккумуляторами как единственными источниками. Нативная EM070 ушла в `auto-idle-no-connected-peer`; хотя технический outpost terminal был соединён с HSR anchor, буфер набрал только **240 000 Дж** и остановился, не достигнув B3 порога 1 МДж на t200. Это **FAIL для конкретного сценария чистого accumulator→accumulator без работающего завода**, а не универсальный запрет любых accumulator-to-accumulator сетей. Журнал отрицательной попытки SHA256 `88ddfbd54eb07fe74f5b3e034c378775af8e9a84a18bd8f66247b0a7fbe1a1dd`; лабораторный скрипт затем исправлен на native solar production. Обобщать до готового баланса фабрики без проверки внешних потребителей нельзя.

## 3. Доставка исследовательского стенда и реальные ограничения

- `tests/em072a5-b3-probe/`: `info.json`, `data.lua`, `control.lua`, `root-hook.lua`, `auto-demand.patch.lua`. **Все патчи накладываются только на одноразовую копию исходного CI ZIP**, `main/ElectrifiedMainline/` не меняется.
- `tests/run_native_recharge_072a5b3.py`: проверяет точный ZIP SHA256, 5 core Git blob SHA1, native Factorio build, реальное выполнение benchmark+server SAVE+отдельный LOAD, наличие обязательных маркеров и **сопоставление всех чисел**.
- `docs/research/native-zero-charge-terminal-b3-072a5.json`: полный machine-readable отчёт с хэшами; большие native logs и исследовательские исходники сохранены в библиотеке владельца `/Factorio/Network-062/buffer-072a5b3/`.
- Исследовательский запуск: `python3 tests/run_native_recharge_072a5b3.py --factorio /path/to/factorio/bin/x64/factorio --ci-game-zip /path/to/exact/CI/ElectrifiedMainline_0.1.62.zip --output /brand/new/empty/scratch`.

**НЕ доказано**: ручная установка игроком/удаление/Blueprint+Undo самого контроллера; восстановление script-owned terminal после `on_configuration_changed` и повторного `rebuild()` (его mapping может сбрасываться!); rail cut/rejoin, электрические split-components, вторая EM070/авансовое распределение спроса, factory brownout и внешняя заводская нагрузка, MP и настоящие расписания, динамический throttle, 500kW моторные вагоны и рекуперация. **Следующий native gate: EM072-A5-B4 terminal lifecycle + cut/rejoin rail and network, fail-closed, load after config change.** Сначала эти проверки, затем отдельное согласование игрового прототипа.

**NO MAIN MERGE / NO RELEASE / NO TAG / NO INSTALLER / NO PATCHER.**