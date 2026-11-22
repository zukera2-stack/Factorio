# EM072-A5-B4 — исследование правил железнодорожного разрыва и терминала

Дата: 2026-11-22. Scope: **B4 isolated native research**, не игровая реализация. Работа относительно `experiment/em072a5-native-recharge-b3` commit `e2621ef94ae45f914273c86dd590b2934cc8321f`. Исходный ZIP — официальный GitHub Actions CI EM071/EM070 `0.1.62`, [run 44925677432](https://github.com/zukera2-stack/Factorio/actions/runs/44925677432), SHA256 `91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575`. Нативный Factorio 2.1.24 build 87808 Linux headless.

## Работающие аналоги и точный контракт

- **HSR/путь**: фактический существующий `ElectrifiedMainline/scripts/power_019.lua`, `M.on_rail_changed` принимает реальные размещённые/удаляемые игровые рельсы и ставит изменения в очередь для пересборки технического графа. Текущий `scripts/control.lua` уже вызывает `power019.on_rail_changed(e)` через `on_built`/`cleanup_train_for_entity`. В **тестовом клоне** дополнительно инвалидируем кэш охвата поездов; не подменяем события фиктивным `connected=true/false`.
- **Нативная связность**: родной `LuaEntity.get_connected_rail` и реальный `LuaTrain.get_rails()`, подтверждённые лабораторией A4/B3. Технические mast/anchor `technical_network_046.lua` имеют `sync_generation` и собственный аудит скрытых медных соединений. Подлинный `electric_network_id` сам по себе не гарантирует HSR-связность.
- **Владелец терминала**: `scripts/technical_network_046.lua` хранит разрешённый port→anchor в `bridge_ports`, подтверждает `wire_origin.script`, force/surface и native connectors. B3 внес test-only однотипный разрешённый терминал, привязанный к собственному контроллеру. B4 удаляет его на реальном событии Factorio `script_raised_destroy` и закрывает подачу энергии, пока не появится новый подтверждённый контроллер. Это **не** равно проверке Ctrl+Z или ручного mining игроком.
- **Нативное электричество**: Base accumulator остаётся настоящим (`5 MJ`, native 300 kW), test-only `ElectricEnergyInterface` имеет финитный буфер `800 kJ`, а не бесконечную генерацию. Электроэнергия дебетуется из фактического native `meter.energy` и только после HSR/ownership-qualified проверки; отдельный `LuaBurner` расходует зачисленные J. Не изменять native аккумуляторы в каждом тике.

## Фальсифицируемые условия

1. Реальное уничтожение `em-high-speed-straight-rail` на пустом участке между источником и группой из 12 поездов, с `raise_destroy=true`; после стабилизации все поездные `qualifies=false`, **0 новых J** до физической постройки этого же rail; кэш должен пересчитаться после engine событий.
2. Реальная постройка удалённого rail с `raise_built=true` восстанавливает оплачиваемую тягу, без script `train.speed`.
3. Реальное native `script_raised_destroy` контроллера удаляет только его отдельный терминальный порт и разрешение; остаток в native meter **не** даёт ни 1 J после удаления, пока owner отсутствует.
4. При новом контроллере на том же месте нужен **новый** проверенный `wire_origin.script` и `bridge_ports`; после этого реальные аккумуляторы дают энергию, только если native физическая сеть и HSR подтверждены.
5. Настоящий server SAVE **в разъединённом состоянии** и продолжение в независимом процессе LOAD не создают терминал автоматически; после восстановления соблюдается баланс всех native накопителей, EEI и израсходованного locomotive топлива. Сверять J, движение и число построений кэша.

**Ожидаемые отрицательные контрпримеры:** рельс прямо под движущимся поездом может отказать в уничтожении; условие теста обязано подтверждать **фактический `LuaEntity.destroy` и `valid=false`**. Быстрый расход до 24MW на 1–2 тика сразу после переподключения может быть оплатой из 800kJ native meter buffer и не означает, что аккумуляторы физически превысили свои 7.2MW. Ограничение 7.2MW для установившегося режима, полный замкнутый ledger для всех этапов.

Документация API: [LuaEntity](https://lua-api.factorio.com/latest/classes/LuaEntity.html), [LuaTrain](https://lua-api.factorio.com/latest/classes/LuaTrain.html), [Factorio Events](https://lua-api.factorio.com/latest/events.html), [wire connector](https://lua-api.factorio.com/latest/classes/LuaWireConnector.html). На сайте указана актуальная версия API; контракт подтверждается прежде всего **исполнением в Factorio 2.1.24**.

## Границы

На этом этапе **не** проводились ручной mining с игроком/ботами, GUI Blueprint/Undo, конфигурационная миграция с обновлением версий мода (`on_configuration_changed`), межкомпонентная магистраль с несколькими outpost, заводской brownout, MP и интеграция с энергетикой штатного `void` электровоза. B4 доказан только для одного живого HSR-коридора в disposable native test mod. Сохранить статус DRAFT, `main` не менять.