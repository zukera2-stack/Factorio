# EM072 — первичный обзор API нативной тяги и моторных вагонов (до реализации)

**Дата:** 2026-11-21. **Статус:** API examined / hypothesis open, **никаких игровых тестов новой тяги**. Исходный `main` `fef938c503a07826b1cc75b90ed0c164d4a5d9a5`; mod 0.1.62, Factorio native target 2.1.24 build 87808. Полный утверждённый архитектурный [план](../plans/DISTRIBUTED_TRACTION_072.md).

## 1. Задача

Проверить нативную схему, в которой настоящий электровоз `em-electric-locomotive` с установленной мощностью 2 МВт получает джоули от EM070; два новых настоящих `cargo-wagon`/`fluid-wagon` прибавляют по **500 кВт** мотор-колёс через внутреннюю магистраль состава; вагоны никогда не подключаются к 25 кВ. Требование: `LuaTrain.speed` не изменяется скриптом.

## 2. Источники/факты и неопределённость

| Источник | Что подтверждает | Чего не подтверждает |
| --- | --- | --- |
| [Base Factorio 2.1.24 trains.lua](https://github.com/wube/factorio-data/blob/2.1.24/base/prototypes/entity/trains.lua) и наш [bootstrap](../../ElectrifiedMainline/prototypes/bootstrap.lua) | Родной локомотив и грузовые типы разные; наш effective loco сейчас `VoidEnergySource`, 2 МВт | Увеличение тяги посредством вагонов |
| [LocomotivePrototype](https://lua-api.factorio.com/latest/prototypes/LocomotivePrototype.html) | `max_power`, `energy_source` принимает Burner или Void | Прямой electric источник или runtime запись max_power |
| [CargoWagonPrototype](https://lua-api.factorio.com/latest/prototypes/CargoWagonPrototype.html), [FluidWagonPrototype](https://lua-api.factorio.com/latest/prototypes/FluidWagonPrototype.html) | Cargo/fluid типы имеют штатные грузовые свойства, без поля тягового max_power | Возможность дать wagons нативную силовую тягу одним свойством |
| [LuaTrain](https://lua-api.factorio.com/latest/classes/LuaTrain.html) | `carriages`, `weight`, `speed`; API прямо предупреждает об опасности скриптовой записи speed для braking distances | Энергетически корректное увеличение тяги на +500кВт |
| [LuaBurner](https://lua-api.factorio.com/latest/classes/LuaBurner.html), [BurnerEnergySource](https://lua-api.factorio.com/latest/types/BurnerEnergySource.html) | `currently_burning`, `remaining_burning_fuel`; нет текущего горящего топлива → запись remaining silently ignored | Безусловный runtime ввод джоулей из EM070 |
| [ItemPrototype fuel acceleration](https://lua-api.factorio.com/latest/prototypes/ItemPrototype.html) | Доступен множитель ускорения топлива | Равенство множителя дополнительным 500000 W и корректный measured fuel burn |

**Версии:** источники типа `latest` во время просмотра могут отдаваться как 2.1.21/2.1.24/2.1.25, поэтому не утверждать без native 2.1.24 теста, что exact-версионная семантика полностью установлена. Официальные `/2.1.24/...` страницы не открылись в текущем веб-доступе; эталон для испытания — установленный native Base 2.1.24.

## 3. Falsifiable native experiment EM072-A / EM072-C

Стенд на Base 2.1.24, без EM070 в первой части: две одинаковые поездные конфигурации, равная масса и одинаковые рельсы, конечный запас энергии (0 генерации). A: `void` baseline vs native `burner` под контролируемым fuel; снять `speed(t)`, расстояние, реально израсходованные Дж, native brake behavior, save/reload, тяга при нуле. C: после доказанного A, 0/1/4 моторных вагонов против равномассного пассивного контроля: ожидаем относительный рост native acceleration/тяги, но **не** увеличение от скриптовой `train.speed` и **не** сверхлимит 2+0.5N МВт. Если fuel modifier не даёт честной добавки мощности с расходом — гипотеза FAIL, остановить код и оценить альтернативу.

Проверить `on_train_created` разрыв/сцепку, front/back locomotives, orientation, ordinary/HSR rail, persistent stacks, train schedule и отсутствие токосъёма у вагонов. Для EM074 отдельно нужен API-эксперимент *типов торможения*, прежде чем создавать энергию из `Δspeed`.

## 4. Заключение / статус доказательств

- **API-confirmed (narrow):** локомотив — native driven stock, cargo/fluid — native unpowered wagon types; идентификаторы/отдельные свойства; writable speed опасен; LuaBurner fuel bookkeeping available with conditions.
- **Implemented in main:** визуальная контактная сеть EM071, native 20MW network bridge EM070, `void` locomotive, event/control и пантограф.
- **Planned/Unverified:** моторные вагоны 500 кВт, штатное сложение мощности 2+0.5N, энергопитание движка, аккумулятор и рекуперация, save/migration, multiplayer.
- **No examined same-type third-party implementation** of 500кВт native-driven `cargo-wagon`/`fluid-wagon` with conserved Joules; Base is an adjacent engine analogue only. No external source code/assets copied.
- **Next:** native stand-alone A/B as in the plan; failure results preserved, no bypass through editing train speed.
