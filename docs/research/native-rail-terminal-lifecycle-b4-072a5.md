# EM072-A5-B4 — настоящий разрыв рельса, восстановление и жизненный цикл служебного терминала

**Дата:** 2026-11-22. **Статус:** `NATIVE ENGINE BENCHMARK + INDEPENDENT REAL SAVE/LOAD PASS`, **RESEARCH ONLY / NOT GAMEPLAY RELEASED**.

Ветка-родитель `experiment/em072a5-native-recharge-b3` SHA `e2621ef94ae45f914273c86dd590b2934cc8321f`; база исходного игрового мода `0.1.62` (same exact verified EM071/EM070 CI artifact, SHA256 `91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575`, [GitHub CI run 44925677432](https://github.com/zukera2-stack/Factorio/actions/runs/44925677432)). **Factorio Linux headless 2.1.24 build 87808, Base, без DLC.** Штатное дерево `ElectrifiedMainline/` в GitHub и `main` **не изменено**.

## Суть проверенного сценария

Стенд унаследован от B3: **12 отдельных настоящих `LuaTrain.id`** с действительными burner-locomotive и `character.riding_state.accelerating` (запись в `train.speed` запрещена); **1 реальная EM070 AUTO ≤20MW**; **84 штатных фабричных accumulator =420MJ**, **24 штатных коридорных accumulator =120MJ/7.2MW** (начинали с **0J**); **346 штатных solar-panel создано, 270 подключились к заводской сети**, солнечные панели уничтожены на t225, замкнутый конечный ledger начат на t231. 12 поездов запрашивали статические лабораторные 2MW каждый с t240, EM070 OFF на t300. Вся энергия доставлена через настоящую native коридорную сеть, finite 800kJ EEI meter и затем в настоящий `LuaBurner`.

Ключевое изменение B4 в **одноразовой копии**: test-only `power_019.on_rail_changed` сбрасывает ограниченный HSR-кэш; `reach_cache` также сверяет техническое поколение `sync_generation`. В тестовом `root-hook.lua` проверка `terminal_owned` **предшествует каждому праву** на новые locomotive J, требуя живого контроллера, terminal port, правильного владельца `bridge_ports`, физической native copper connection с `wire_origin.script`, совместимого force/surface и реального совпадения HSR-сети. Test-only probe подписан на **настоящее** событие `script_raised_destroy` и вызывает `detach`, удаляя скрытый порт и запись whitelist, затем обеспечивает явное повторное `attach` при новом владельце.

| Tick | Фактическое действие в движке | Нативный результат |
|---:|---|---|
| 315 | **Удалён настоящий HSR rail при x=-115** через `destroy{raise_destroy=true}`; подтверждено `valid=false` | Родной event срабатывает, rail-кэш инвалидирован |
| 331 | Проверка после физического split | **Все 12 поездов недоступны**, **0 новых J** после установления разрыва — **PASS** |
| 335 | Построен настоящий HSR rail в той же позиции через `raise_built=true` | Реальная связность восстановлена |
| 354 | Проверка после rejoin | Выдача действительно списанных native J возобновилась — **PASS** |
| 355 | Контроллер уничтожен с `script_raised_destroy` | Native event удаляет служебный порт и собственную авторизацию — **PASS** |
| 365 | Проверка отсутствия владельца | Нет terminal port, `qualifies=false`, **0 новых J** даже при непустом native meter — **PASS** |
| 385 | Headless сервер физически записал **SAVE** при **отсутствующем терминале** | SAVE действительно создан |
| 390 | Проверка отдельного состояния до восстановления | Нет порта и **0 J** после сохранения; идентично после LOAD — **PASS** |
| 400 | Создан новый контроллер и выполнено **новое авторизованное** script-owned подключение | Служебная цепь снова правильная |
| 420 | Проверка реактивации | Native батареи снова дают оплаченную тягу — **PASS** |
| 496 | Конечный closed ledger | **12 поездов двигались**, равные реальные J, residual ≈0 — **PASS** |

### Числа, собранные реальным Factorio

- Native benchmark: **500 тиков PASS**, независимый **сохранённый сервером tick385 → LOAD +115 ticks PASS**.
- Полная выдача native `LuaBurner` **39,533,333.333 J**, расход native `LuaBurner` **39,533,333.333 J**, min/max/каждый поезд **3,294,444.444 J**, минимальное реальное движение **194.172 tiles**.
- Физический finite-J ledger включает все фабричные аккумуляторы, все 24 коридорных, все EM070 input/output EEI, native traction meter EEI и ещё не сгоревшее burner топливо + потраченную engine-native энергию. Остаток **−0.000002 J** (погрешность чисел с плавающей точкой).
- Native HSR cache **3 rebuilds** (первая геометрия, уничтожение и восстановление рельса).
- Финальный действительный SAVE-файл тестового сервера **827,135 bytes**, не пользовательское сохранение.
- Full native benchmark log SHA256 **`cad4a33893e347d46f900d18d54eb8162b3b45cfc681508768994ccfeef5c0ec`**; separate native LOAD log SHA256 **`27f3da5cab988b4fb7c12bd52d901073925616fa2a01de46b9de616f4317cf63`**. Native full/reload измерения идентичны.

### Зафиксированные отрицательные открытия

1. Первоначально попытка удалить rail при x≈-89 **вернула `false`**, поскольку первый живой поезд находился x≈−88.086; рельс `valid=true`. Признать такой «разрыв» PASS нельзя. Тест отнесён к пустому участку x=-115 и проверяет `destroy` и `valid=false`.
2. Непосредственно после rejoin конечный **800kJ native EEI meter** может отдать буферный импульс с мгновенным темпом выше 7.2MW нативных аккумуляторов. Контроль **7.2MW** применяется к установившейся выдаче батареи; full ledger включает meter, поэтому физические J не возникают бесплатно.
3. Удаление через `script_raised_destroy` **не равно** реальной пользовательской операции mining, Ctrl+Z, blueprint или construction robot. Отдельной игровой реализации `on_player_mined_entity` / `on_robot_mined_entity` у аванпоста **нет**.

### Повторение теста

Встроенный `tests/run_native_lifecycle_072a5b4.py` требует настоящий Factorio Linux 2.1.24 build 87808 и **точный оригинальный** CI ZIP, который он проверяет по SHA256 и Git Blob SHA. Исходники `tests/em072a5-b4-probe/` — минимальный одноразовый лабораторный мод, а test-only patch'и накладываются на его извлечённую копию `ElectrifiedMainline/`. Пример:

```bash
python3 tests/run_native_lifecycle_072a5b4.py \
 --factorio /path/factorio/bin/x64/factorio \
 --ci-game-zip /path/verified/EM071-0.1.62-CI.zip \
 --output /path/new-empty-disposable-directory
```

**Дальше остаётся проверить:** реальные пользовательские building/mining / Blueprint / Undo; миграцию `on_configuration_changed` (в отличие от обычного SAVE/LOAD, который уже PASS); физически отдельные 2+ компонента/2+ аванпоста, rail cut с другим местом подключения, factory brownout, 60UPS & MP, dynamic throttle и 500kW моторизованные вагоны. Движение электрического локомотива `em-electric-locomotive` в `main` **до сих пор `void`**. Все test hooks и whitelist разрешения исключительно disposable; этот PR **не встраивать** в `main` до отдельных испытаний и явной авторизации владельца.

**NO MAIN MERGE / NO RELEASE / NO TAG / NO PATCHER.**