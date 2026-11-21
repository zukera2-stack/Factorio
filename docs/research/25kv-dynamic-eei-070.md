# EM070 — нативный dynamic EEI вместо переключения фиксированного приоритета

**Дата:** 21.11.2026. **Статус:** экспериментально реализовано; нативный полный CI 060/061/062 **3/3 PASS** на исходном коде, оба EM065 закрытых энергобаланса и EM067-48 + три EM062 stress PASS локально. **НЕТ разрешения на выпуск, CI-exact ZIP не перепроверен в независимом 065 стенде и сохранение владельца не проверено.**

## 1. Основание, источники, версии
- Репозиторий `zukera2-stack/Factorio`, дочерняя ветка `experiment/native-dynamic-eei-070` от `experiment/eei-buffer-lifecycle-069` @ `5c8f120b24b2a7d3382ac75156f217030c2b31f3`. Мод игровая версия **0.1.62**; `main` **0.1.56**; `test/updater-approved` **0.1.61**, обе защищены.
- Реальный движок **Factorio 2.1.24 build 87808**, Linux x86-64 headless, SHA эталонного Base файла `data/base/prototypes/entity/entities.lua` **a6d0356285a56ad4af0b08d9acee669981c888dd5962cb0ee5d79d9b31294d1b**, строки **8931–8951**: встроенный `electric-energy-interface` использует `energy_source.usage_priority = "dynamic"`.
- Официальный API: [ElectricUsagePriority 2.1.24](https://lua-api.factorio.com/2.1.24/types/ElectricUsagePriority.html), значение `dynamic` только для EEI; [LuaEntity 2.1.24](https://lua-api.factorio.com/2.1.24/classes/LuaEntity.html), RW `electric_interface_mode`, `energy`, `input_flow_limit`, `output_flow_limit`; [Energy 2.1.24](https://lua-api.factorio.com/2.1.24/types/Energy.html) — МВт → Дж/тик через /60.
- Наш `prototypes/power_bridge_058.lua`: отдельные технические EEI на скрытой лабораторной поверхности, прежние fixed `secondary-input`/`secondary-output` и буфер 333334 Дж; `scripts/power_bridge_058.lua` EM069 меняет режим существующего EEI и направление мостовой пары. На fixed прототипе это меняло значение свойства, но **не** физический приоритет.
- Прямой same-type пример — Base того же exact установленного движка, сторонний код/ассеты не копировались.

## 2. Воспроизводимый A/B нативный тест **до изменения игрового мода**
Отдельный disposable мод `tests/em070-native-eei-priority-probe/`, зависимость только Base 2.1.24; `elevated-rails`, `quality`, `recycler`, `space-age` явно **отключены** в `mod-list.json`. Восемь **раздельных заводских электросетей** (собственный `substation`, EEI, нормальный ванильный `accumulator`), без генерации; в каждой **2 000 000 Дж** первоначально, `power_production=0`; установка `electric_interface_mode` на tick 30 и динамического лимита **2 МВт**. `--benchmark-ticks 200`, итог tick 180. Native result:

| Прототип / mode после смены | Output: батарея получила | Input: EEI получил | Закрытый баланс |
|---|---:|---:|---|
| `secondary-input` fixed | **0 Дж** | 895000 Дж | 2 МДж |
| `secondary-output` fixed | 895000 Дж | **0 Дж** | 2 МДж |
| `dynamic` clone | 750000 Дж | 750000 Дж | 2 МДж |
| настоящий Base `electric-energy-interface` dynamic | 750000 Дж | 750000 Дж | 2 МДж |

В fixed случаях запись `electric_interface_mode` возвращает **success**, readback нужного enum, но противоположное направление **не проводит ни одного джоуля** — это воспроизведённая причина native 060 FAIL в EM069. Полный нативный журнал Base-only SHA256 `94b381cb6d7500e93b7473780df11500ba2f187bd2e57fd085140b7a3bb0091d`. Тестовая геометрия и результаты не являются доказательством совместимости полной контактной сети, только именно switching behavior.

## 3. Гипотеза, минимальная правка и откат
**Гипотеза:** если перевести обе существующие EEI-прототипные записи `em-25kv-bridge-input-058` и `em-25kv-bridge-output-058` на `usage_priority="dynamic"`, и при первом создании явно устанавливать native `secondary_input` / `secondary_output`, то физический solver Factorio сможет выполнять реверс простым изменением `LuaEntity.electric_interface_mode` без destroy/recreate, ручного возврата энергии или дополнительного глобального ledger.

**Кодовая правка всего в двух файлах, без нового runtime-модуля**:
1. `ElectrifiedMainline/prototypes/power_bridge_058.lua`: две строки `usage_priority` в точках вызова `interface(...)` меняются на `dynamic`; имена, лимиты 20 МВт, вместимость и форма не меняются.
2. `ElectrifiedMainline/scripts/power_bridge_058.lua`: при создании ставится `e.electric_interface_mode` из прототипной роли. EM069 обмен ссылками/режимами при реверсе остаётся прежним.

**Отказ/rollback:** оставить ветку экспериментальной, при неуспехе отложить её без изменения одобренной 0.1.61. Не создавать для игрока сборку из локального архива.

## 4. Нативная интеграционная проверка локального кандидата (НЕ GitHub Actions ZIP)
Исходный код EM069 `em069-swap-final-test.zip` + ровно две упомянутые Lua-правки, **локальный QA ZIP SHA256 `96fb991c755b99630a186fcc2d4476f9a390c21bcfc9e8946fec3d1c651c6fd6`**, 130 game files, 83 PNG, 0 прочих runtime изменений. Это временный стенд, **не распространяемый install ZIP**. Factorio Headless **2.1.24 build 87808**:
- EM065/069 finite 700 МДж source, 0 новой генерации, 10/10 topology: **1350 ticks PASS**; списано строго **166667 Дж** собственной демонтированной B, **0 Дж** иных потерь и **0 Дж** создания. Реальный серверный save и независимый disk reload **200 ticks PASS**, дополнительно доставлено 13 333 333 Дж.
- Тот же стенд + 8 нативных аккумуляторов: **1350 ticks PASS**, списано строго **186667 Дж** собственной B, **0 Дж** иных потерь/создания. 8/8 прежних unit_number, нативные лимиты заряда/разряда, источник/приёмник группы аккумуляторов в конце **20 000 000 Дж / 20 000 000 Дж**. **200 disk reload ticks PASS**, дополнительные 13 333 333 Дж.
- EM067-48: **960 ticks PASS**, 6×20 МВт источников, 42 приёмника, reroute/outage и fairness. Средний 13.999 мс/тик в этом разовом запуске **включает создание 48 подстанций**, это НЕ гарантия 60 UPS.
- **Не проверено на этапе этого отчёта:** точный исторический native 060 (ранее с fixed-прототипом FAIL), полная GitHub Actions CI-exact сборка, миграция реального владельческого сейва с предыдущими EEI, Bob's, MP, Undo, долговременная orphan-EEI очистка. Все эти пункты остаются релизными gate.

## 5. Как воспроизвести чистый A/B
Скопировать каталог `tests/em070-native-eei-priority-probe/` в временный `mods/em070-native-eei-priority-probe_0.0.1`, создать `mod-list.json` с `base` и этим модом включёнными, DLC отключёнными, и независимый `config.ini` с `read-data` на Factorio 2.1.24 и изолированным `write-data`. Запустить `factorio --config ... --mod-directory ... --create start.zip`, затем `factorio --config ... --mod-directory ... --benchmark start.zip --benchmark-ticks 200 --benchmark-runs 1`. Ожидаемые восемь строк `[EM070 RESULT]` и `[EM070 NATIVE COMPLETE]`, с нулевым расходом у fixed противоположного направления, положительным у dynamic и 2 МДж суммарного учёта.

## 6. Релизная проверка
**Сначала** полный CI native 060 `em062-power-probe`: обратный приёмник >500000 Дж после смены направления и штатный аккумулятор действительно разряжается. Затем два закрытых EM065, save/load, 48-substation, 32/multisource/brownout, Undo/MP/Bob's и owner-save; сделать нативный тест старого сейва после миграции фиксированных прототипов. Пока не выполнены, эксперимент не одобрять для Updater.

## 7. Фактический полный GitHub Actions и дополнительные нативные проверки

- **Source:** `4c5e026bffdc1082925563d725c94751cd1acb73`, `experiment/native-dynamic-eei-070`; [полный workflow 44920768721](https://github.com/zukera2-stack/Factorio/actions/runs/44920768721) **SUCCESS**, документационный CI **44920768690 SUCCESS**, native/CI game build 2.1.24 build 87808.
- **Native Factorio 2.1.24 в CI — 2030 тиков, 3/3 PASS:** [наследованный EM060 native](../tests/em062-power-probe/control.lua) требует более **500000 Дж** обратной доставки и разряда внешних ванильных аккумуляторов после смены направления — **PASS**, вместо **0 Дж** в EM069. [EM061 native matrix](../tests/em062-priority-probe/control.lua) PASS (раздельные сети, приоритеты), [EM062 native fairness](../tests/em062-fairness-probe/control.lua) PASS. Логи: `[EM061 NATIVE PASS]`, `[EM061 MATRIX PASS]`, `[EM062 NATIVE PASS]`, `[EM062 ENGINE QA PASS] 3/3 real native Factorio scenarios, 2030 ticks`.
- Lua 5.2 проверка синтаксиса, mock 058/059/060 и **1675/1675 EM067 differential inputs PASS**, CI упаковка PASS: 130 файлов, 83 PNG (исходные сохранены).
- **Артефакт GitHub Actions:** [`ElectrifiedMainline-test-build`, ID **14713602030**](https://github.com/zukera2-stack/Factorio/actions/runs/44920768721/artifacts/14713602030). **Вложенный install ZIP** `ElectrifiedMainline_0.1.62.zip` SHA256 **`391e8d3df756f048996fd4794a3b0b695d74f13475f2da3dca582252709f19cb`** (не путать с SHA внешней обёртки artifact upload). Проверен по строке `sha256sum` в packaging CI; ни ZIP, ни перепакованные копии **не загружались в ChatGPT Library**.
- **Дополнительные локальные game tests** на том же `96fb991c...` локальном QA исходнике: [сценарий 32 подстанций](../tests/em062-stress-probe/control.lua) 1050 ticks PASS, [многократные источники](../tests/em062-multisource-probe/control.lua) 1050 ticks PASS, [brownout/заводской дефицит](../tests/em062-factory-reserve-probe/control.lua) 950 ticks PASS. Автоматический runner `tests/run_native_stress_062.py` из старой лаборатории. Вкупе с EM067-48 960 ticks эти отдельные тесты являются реальной игровой проверкой в указанных сценариях, но не профилированием устойчивых 60 UPS в реальной игре.
- **Нюанс исторической проверки EM066:** CI `tests/switching_dissipation_contract_066.py --self-test` выводит **1 500 000 / 1 537 742 Дж** из старых архивных JSON как `energy_gate=FAIL` и **сам классификатор PASS**, поскольку правильно НЕ разрешает эту старую потерю. Это **не показание текущего EM070**. Закрытые **реальные EM070 2×1350 тиков** дали **0 Дж** unexplained и **0 Дж** created с допустимым B-only demolition, а реальные 2×200 тиков disk reload прошли.

## 8. Итог и текущие границы
**Game-tested:** EEI `dynamic` работает в обе стороны, включая полнофункциональный сценарий аккумуляторного **реверса 060**, ранее разрушенный EM069; оба EM065-closed, fair-share/48, 32/multi/factory и обе независимые disk reload. **API-confirmed:** тип `dynamic` и смена `electric_interface_mode`, сам Base 2.1.24. **Unverified:** точный скачанный CI install ZIP в отдельных EM065/48 стендах; миграция реального владельческого сохранения с установленной **0.1.61**, Bob's Power, multiplayer, Undo, длительная стабильность и отсутствие накопления замороженных сиротских EEI.

**Решение:** EM070 DRAFT, допускается дальнейшая адресная QA; **не сливать в main, не менять updater-approved ref, не выпускать** до owner approval. Следующий минимальный опыт — CI-exact ZIP + тест владельческого сохранения и жизненного цикла после обновления; дополнительных runtime-обёрток пока не создавать.
