# EM073 — два штатных направленных скрытых локомотива, выбор тяги движком Factorio

**23 ноября 2026. Статус: локальная и точная официальная 0.1.73 native PASS (12/12), independent SAVE/LOAD PASS, synthetic old 0.1.72 SAVE→0.1.73 LOAD PASS. Windows GUI / MP / пользовательские сохранения НЕ проверены; НЕ релиз.** Ветка — `experiment/em073-native-directional-heads-20261123`. База — официальный полный `ElectrifiedMainline_0.1.72.zip`, SHA-256 `67766bf58c390d3b644dd84f4b27e12a789a1cf4fd9b640f65ad7b6a758b2753`, 139 игровых файлов и 83 неизменённых PNG. Нативный движок: Factorio 2.1.24 build 87808 linux64 headless.

## Решение владельца и правило реализации

- Оставить ванильному Factorio физику локомотивов, выбор направления, ускорение, торможение и сжигание топлива. **Не писать в `LuaTrain.speed`, не переключать `orientation` при реверсе, не вводить внешний контроллер направления.** Ручной реверс редок и не является приоритетом; автоматический рейс должен проходить оба направления.
- Каждый **настоящий** `em-electric-locomotive` может авторизовать скрытый нативный локомотив, но только **один на физическое направление** в составе. Мод выбирает один реальный EM для каждого из `LuaTrain.locomotives.front_movers/back_movers` с минимальным `unit_number`; два EM одинаковой ориентации делят одну моторизацию.
- Каждая физическая сторона получает свой агрегатный booster `0.5 MW × N` (N реальных моторных грузовых вагонов и цистерн, максимум 256), ориентированный так же, как авторизовавший электровоз. Встречные бустеры представляют **одни и те же вагоны**, и **их мощность нельзя складывать как одновременную тягу**.
- При 200 моторах: 100 МВт дополнительной паспортной мощности **на направление**. Реальный локомотив 2 МВт. В push-pull `(EM + 200 motor + EM)` по обеим сторонам есть отдельный 100 МВт helper, но native Factorio работает с направлением и расходует топливо работающего; не 200 МВт механической мощности одновременно. Два EM в одной голове → 1 helper 100 МВт, не 2.
- Помощники получают конечный `BurnerEnergySource` через проверенный общий native `secondary_input`/25кВ мост, без независимого токоприёмника на вагонах и без придуманного топлива. Для длинных сценариев источник настоящего первичного `electric-energy-interface` = 120 МВт, электрический мост 120 МВт **только в эксперименте**.
- При демонтаже заряд помощника уничтожается как утрата оплаченной энергии по утверждённой политике. Только реальный EM разрешает создание и заряд; 200 моторных вагонов без EM должны оставаться пассивными.

## Код

Изменён `ElectrifiedMainline/scripts/helper_lifecycle_067.lua` (направленная группировка, авторизация, сцепка, cleanup), комментарии `ElectrifiedMainline/scripts/traction_paid_065.lua` и `ElectrifiedMainline/prototypes/em072_c5_fullmod_trial_063.lua`; версия `info.json` 0.1.73. Используется существующий source-paid allocator 0.1.72, не отдельный распределитель. Мод сам создаёт технические локомотивы; QA только создаёт настоящие рельсы/контактную сеть, поезда и полноценный 120-МВт тестовый фабричный источник, отдаёт через штатный native EEI и читает состояние. QA **не создаёт помощников, не меняет запас их J, не пишет скорость**.

## Измерения: настоящая физика полного мода

| Нативный сценарий | Подтверждено / тик | Результат |
|---|---|---|
| `single` — 1 EM + 2 мотора | t300: 1 helper 1 МВт, дистанция −155.664, мотору оплачено 2.833 МДж | PASS |
| `double_opposite` — 2 EM на противоположных концах + 2 мотора | t300: 2 helper по 1 МВт; +105.094 клетки тяги влево; неактивный восточный helper остаётся с 16,666.667 Дж | PASS |
| `bidir_reverse` — аналогичный двухголовый состав, движение вправо | t300: +105.094 клетки (в обратную сторону), восточный helper J=0, западный helper 16,666.667 Дж | PASS |
| `bidir_reversepassive` — два обычных вагона | t300: +70.086 клетки, 0 helper, 0 моторных J | PASS, отрицательный контроль |
| `bidir_auto` — *реальный AUTO* между двумя физическими станциями ВСМ | t355 первая `EM072_NATIVE_AUTO_TARGET`, t802 вторая `EM073_NATIVE_RETURN_TARGET`; оба знака native train.speed; в каждой половине фактически сгорал правильный ориентированный native burner | PASS |
| `long200highopp` — 200 моторных, электровозы на обоих концах, фабричный источник 120 МВт | t300: 2 helper по 100 МВт, 204 native cars, −109.859 клетки, оплачено мотору 282.200 МДж, западный helper J=0, встречный восточный J=0.966667 МДж | PASS |
| `long200highopp_rev` — точно такой же тяжёлый состав в противоположную сторону | t300: +109.859 клетки, скорость −1.30530 клетки/тик, оплачено мотору 282.200 МДж, восточный helper J=0, западный J=0.966667 МДж | PASS |
| `long200highsame` — 200 моторных и 2 EM в одной голове | t300: **ровно один** 100-МВт helper, −114.754 клетки, 283.333 МДж оплата мотора | PASS |
| `standalone200` — 200 физически сцепленных моторных вагонов, EM удалён **до игрового тика** | t300: 200 native cars, 0 helper, 0 EM, paid_J=0, путь=0, 37 железных плит и 9000 воды целы | PASS |
| `bidir_zero` — 2 EM/2 helper при реальном источнике 0 Вт | t300: 0 motor J / 0 движение / 0 EM burner J | PASS |
| `bidir_offgrid` — 2 EM/2 helper при отключённой реальной контактной сети | t300: 0 motor J / 0 движение / 0 EM burner J | PASS |
| `bidir_ownerloss` — после заряда разрушена одна настоящая голова | t115: её помощник удалён; t300: один оставшийся ориентированный helper, lost_J=16,666.667 Дж, cargo/fluid в безопасности | PASS |

В первом длинном push-pull сценарии на t300 настоящий 25кВ consumer показывал `1,700,000 Дж/тик` **запроса**, что равно 102 МВт — не двум агрегатным двигателям по 100 МВт. В противоположном направлении показания точно такие же. У двух EM в одной голове при движении направленным курсом запрос 1,733,333.333 Дж/тик = 104 МВт (два EM + 100 МВт моторизации). **Запрос — не гарантия фактически переданной мощности в каждом тике.** Совокупный расход за 300 тиков в любом случае оплачивался нативной электрической сетью; никаких независимых 200 МВт из воздуха.

**12/12 локальных полных нативных сценариев PASS** на локальной полной экспериментальной 0.1.73 (на базе строго проверенного официального полного 0.1.72 ZIP). Файл теста `tests/em072-bidir-qa/scenarios/native/control.lua` и полный runner включены в ветку. Все сохранённые исходные 83 PNG побайтово совпадают с официальным 0.1.72 ZIP. **Эти 12 сценариев сначала испытаны локально, а затем каждый повторён на точном официальном ZIP 0.1.73 с теми же результатами (см. официальный отчёт ниже).**

## Реальный SAVE → LOAD двухголового поезда

Отдельный серверный сценарий с полнофункциональным модом и настоящими рельсами, сетью и двумя помощниками: новый нулевой мир, физический вызов `game.server_save` на тике 125, два разных процесса Factorio 2.1.24, независимая загрузка физического ZIP, на тике 300 **дословно совпали численные снимки**: 6 native cars / 2 helpers, `motor_paid_J=2,883,333.333`, `paid_J=12,583,333.333`, путь `-105.094`, скорость `1.19416`, 37 iron + 9000 water. Остатки обоих helper одинаковы в непрерывном и reload запуске. Физический checkpoint 758,535 байт. Экспериментальный серверный сценарий `tests/em072-bidir-server/control.lua`. Не путать с реальными сохранениями пользователя — они не открывались.

## Открытые границы и запрет релиза

- Реальный **AUTO обе стороны прошёл на коротком** двухголовом поезде; **200-вагонный AUTO с полным повторным рейсом не проводился**. Для 200 вагонов доказаны оба направления нативной механики в отдельных 300-тиковых прогонах без записи скорости.
- **Не проверены** реальный игровой GUI Windows, невидимость обоих helpers в обычном UI, GUI локомотивов, Blueprint/Undo, миграция пользовательских SAVE старых версий 0.1.72→0.1.73, многопользовательская синхронизация, 60UPS под продолжительной нагрузкой, разрыв/аварии в движении при двух помощниках, сетевые электрические комбинации нескольких одинаковых поездов.
- **Ручное реверсивное управление не автоматизируем:** движок в нативном тесте выбирал активный booster сам, но специфические fallback-сценарии ванильного `reversing_power_modifier` с нехваткой топлива могут требовать дополнительных граничных проверок. Не вводить Lua-симуляцию движения без прямого запроса.
- Источник 120 МВт — технический EEI полигона; не реализована крафтируемая станция на 120 МВт. `main` по-прежнему 0.1.62 и пользовательские 20-МВт установки не изменены.
- Гарантия «не создаёт двойной тяги» ограничена измеренными сценариями: видно, что противоположный бустер не тратил J при наличии работающего нужного направления. Новое нестандартное управление и исчезновение настоящей головы на ходу требуют отдельного QA.

**Никакого merge, тега, Mod Portal и релиза.**

## Окончательная приёмка точного официального GitHub Actions ZIP 0.1.73

**Source commit:** `acf3aa7a7de1c97c425977d8be57aba3c1f4c74d` на отдельной ветке `experiment/em073-native-directional-heads-20261123`.

- **GitHub Actions fullmod build:** [#45082646087](https://github.com/zukera2-stack/Factorio/actions/runs/45082646087) SUCCESS (Lua preflight + package ZIP). **Documentation CI:** [#45082646089](https://github.com/zukera2-stack/Factorio/actions/runs/45082646089) SUCCESS.
- Artifact ID `14778316033` (outer ZIP SHA256 `eef434470e8ebbbefcd108f0cd38855fa1477323f238b568568ff1789e28c869`). Exact **inner game `ElectrifiedMainline_0.1.73.zip`** SHA-256 **`30ba63f788cafbcfcc8454e62759cb00017f7459739b9fb211a1e7fd52433276`**. All 139 native game ZIP members match local tested source **byte-for-byte**, including all 83 approved PNG. Four gameplay tree files differ from 0.1.72, of which only helper lifecycle contains behavior changes; original user mods and saves untouched.
- **12/12 OFFICIAL native fullmod scenarios PASS in unchanged genuine Factorio 2.1.24 build87808**, testing the exact GitHub Actions inner ZIP: `single`, `double_opposite`, `bidir_reverse`, `bidir_reversepassive`, `bidir_auto`, `bidir_zero`, `bidir_offgrid`, `bidir_ownerloss`, `standalone200`, `long200highopp`, `long200highopp_rev`, `long200highsame`. Genuine game runtime creates/feeds helper; QA never calls create_entity(helper) or credits hidden burner directly.
- **Real AUTO HSR roundtrip (short):** two native stations, arrival `EM072_NATIVE_AUTO_TARGET` tick355 and `EM073_NATIVE_RETURN_TARGET` tick802; native AUTO (`manual=false`) maintained, correctly oriented helper burns on each leg. No Lua speed or direction switching.
- **200 motor-wagon double opposite EM / real 120MW factory grid:** two opposite booster engines each rated 100MW; actual t300 direction A `-109.859 tiles`, direction B `+109.859 tiles`; in each drive motor 282,200,000J native paid and **inactive opposite booster still has 966,666.667J**, i.e. no double native traction. Actual native sink demanded **102MW** at t300 (not 202MW); this is requested, not necessarily delivered all ticks. All 200 cars physically connected, cargo 37 iron/fluid 9000 water preserved.
- **200 motors / two EM in SAME direction:** ONE booster rated 100MW, -114.754 tiles in 300 ticks, actual motor paid 283,333,333.333J (real source; no duplicate boost).
- **200 motors WITHOUT ANY REAL EM:** physically coupled 200 wagons, 0 invisible locos /0 paid traction J /0 movement at t300; cargo and water preserved. **0W** and **offgrid**: 0 paid J, 0 movement even with both invisible locos physically present. Owner head demolition: lost charged helper paid energy 16,666.667J while other head intact.
- **Real independent fullmod disk SERVER SAVE/LOAD on EXACT official 0.1.73 ZIP:** brand-new native t0 map; physical server save tick125 (964,462 bytes); separate second Factorio process LOAD of that saved ZIP; native t300 snapshot exactly identical to separate continuous server t300, including `cars=6 helpers=2`, `paid_J=12,583,333.333`, `motor_paid_J=2,883,333.333`, distance `-105.094`, speed `1.19416`, both native booster fuel 16,666.667J, 37 iron, 9000 water. The earlier local test checkpoint was moved to isolated workdir before this test, never overwritten.
- **Official 0.1.72 SAVE → official 0.1.73 LOAD migration PASS (test save only):** new world in original exact official 0.1.72, one helper saved at tick125 (physical checkpoint 1,064,213 bytes); new independent server loads exact official 0.1.73 and mounts second helper automatically by tick130, native t300 `cars=6 helpers=2`, cargo37/water9000 preserved, movement and physical paid-J continued. This is **not** a blanket claim of compatibility with all user saves.

**Still untested / release blockers:** Windows GUI invisible engine/stock list, Blueprint and Undo/Redo restoration, true MP synchronization, genuine 200-wagon AUTO roundtrip to two real distant stops, train splitting during motion and rogue third-party mutation, 60UPS under many heavy moving trains, actual user save upgrades. Per owner request, manual reverse fallback is low priority and no new Lua direction controller shall be invented without necessity. The 120MW generator remains a native test EEI and bridge-cap research, **not** a player-craftable power plant; standard `main` remains 0.1.62. **No merge, release or production approval.**