# EM074 — официальная 0.1.74: индикаторы питания и испытания

**Дата:** 23.11.2026. **Статус:** экспериментальная сборка для проверки владельцем, НЕ релиз.

## База и артефакт

- Репозиторий: `zukera2-stack/Factorio`.
- Экспериментальная ветка: `experiment/em074-native-traction-status-20261123`.
- Игровой исходный коммит: `9a50e062a28833c347f009de5cac5129c2ea3ca4`.
- Успешная официальная сборка GitHub Actions: https://github.com/zukera2-stack/Factorio/actions/runs/45172918546 (artifact `14818410254`).
- Независимый workflow проверки документации: https://github.com/zukera2-stack/Factorio/actions/runs/45172918591 — PASS.
- Полный официальный ZIP: `ElectrifiedMainline_0.1.74.zip`.
- SHA256 ZIP: `9a6e0f2658375d383810977c4a2bd6158dbce3a656ed0653306e2c5eeaaefe28`.
- База: полная официальная 0.1.73 ZIP SHA256 `30ba63f788cafbcfcc8454e62759cb00017f7459739b9fb211a1e7fd52433276`.

## Что изменено

Новый `BurnerUsagePrototype` `em-25kv-electric-status-074` назначен только реальному электровозу: Factorio штатно выдаёт локализованное **«Нет контактной сети»** вместо **«Нет топлива»** при исчерпании топлива внутреннего burner и показывает стандартную красную электрическую иконку. Второй usage `em-hidden-motor-status-074` назначен всем 256 техническим вспомогательным локомотивам, с прозрачной пиктограммой. Ванильный usage `fuel` не изменялся.

Изменено **пять** игровых текстовых файлов: `info.json`, `data.lua`, `locale/en/en.cfg`, `locale/ru/ru.cfg`, добавлен `prototypes/traction_status_074.lua`. Остальные файлы побайтово совпадают с официальной 0.1.73. Все **83 PNG** не изменились. Игровая логика `scripts/` неизменна, нет новых скриптовых event handlers, запретов поездов, выдачи топлива/джоулей или изменений `LuaTrain.speed`.

Изображения взяты из исходного `__core__` Factorio 2.1.24: `graphics/icons/alerts/electricity-icon-red.png` и `graphics/empty.png`. Исходный пример `core/prototypes/burner-usage.lua`; API https://lua-api.factorio.com/latest/prototypes/BurnerUsagePrototype.html и https://lua-api.factorio.com/latest/types/BurnerEnergySource.html.

## Реальные тесты — ТОЧНЫЙ ОФИЦИАЛЬНЫЙ ZIP

**Factorio 2.1.24 build87808, Linux headless; полный мод и реальная нативная сеть 25 кВ.** Сценарный QA-мод строит рельсы, подстанцию, источник электроэнергии, настоящие вагоны; **не создаёт скрытые двигатели и не кредитует их горелку** — это делает игровой ElectrifiedMainline.

**Нативная проверка прототипов — PASS:** в data-final-fixes проверены все 256 invisible boosters, электрический значок и `no_fuel_status`, ванильный usage без изменений, сохранность категории штатного внутреннего конечного топлива. В runtime обе записи burner usage зарегистрированы, настоящий `em-electric-locomotive` доступен.

### 12 интеграционных игровых сценариев

| Сценарий | Результат | Снимок на тике 300 (см. логи) |
|---|---|---|
| `single` | PASS | `tick=300 cars=4 helpers=1 helper_w=1000000 helper_J=0.000 loco_J=1964444.444 paid_J=10466666.667 motor_paid_J=2833333.333 distance=-155.664 speed=1.73962 cr` |
| `double_opposite` | PASS | `tick=300 cars=6 helpers=2 helper_w=0 helper_J=0.000 loco_J=1964444.444 paid_J=12533333.333 motor_paid_J=2866666.667 distance=-105.094 speed=1.19416 created=` |
| `bidir_reverse` | PASS | `tick=300 cars=6 helpers=2 helper_w=0 helper_J=0.000 loco_J=1997777.778 paid_J=12533333.333 motor_paid_J=2866666.667 distance=105.094 speed=-1.19416 created=` |
| `bidir_reversepassive` | PASS | `tick=300 cars=4 helpers=0 helper_w=0 helper_J=0.000 loco_J=1997777.778 paid_J=9666666.667 motor_paid_J=0.000 distance=70.086 speed=-0.79635 created=0 retire` |
| `bidir_auto` | PASS | `tick=300 cars=6 helpers=2 helper_w=0 helper_J=0.000 loco_J=1997777.778 paid_J=12233333.333 motor_paid_J=2766666.667 distance=-144.414 speed=0.51350 created=` |
| `bidir_zero` | PASS | `tick=300 cars=6 helpers=2 helper_w=0 helper_J=0.000 loco_J=0.000 paid_J=0.000 motor_paid_J=0.000 distance=0.000 speed=0.00000 created=2 retired=0 lost_J=0.0` |
| `bidir_offgrid` | PASS | `tick=300 cars=6 helpers=2 helper_w=0 helper_J=0.000 loco_J=0.000 paid_J=0.000 motor_paid_J=0.000 distance=0.000 speed=0.00000 created=2 retired=0 lost_J=0.0` |
| `bidir_ownerloss` | PASS | `tick=300 cars=4 helpers=1 helper_w=1000000 helper_J=16666.667 loco_J=2000000.000 paid_J=4033333.333 motor_paid_J=33333.333 distance=0.000 speed=0.00000 crea` |
| `standalone200` | PASS | `tick=300 cars=200 helpers=0 helper_w=0 helper_J=0.000 loco_J=0.000 paid_J=0.000 motor_paid_J=0.000 distance=0.000 speed=0.00000 created=0 retired=0 lost_J=0` |
| `long200highopp` | PASS | `tick=300 cars=204 helpers=2 helper_w=0 helper_J=0.000 loco_J=1931111.111 paid_J=291833333.333 motor_paid_J=282200000.000 distance=-109.859 speed=1.30530 cre` |
| `long200highopp_rev` | PASS | `tick=300 cars=204 helpers=2 helper_w=0 helper_J=0.000 loco_J=1997777.778 paid_J=291833333.333 motor_paid_J=282200000.000 distance=109.859 speed=-1.30530 cre` |
| `long200highsame` | PASS | `tick=300 cars=203 helpers=1 helper_w=100000000 helper_J=0.000 loco_J=1964444.444 paid_J=298600000.000 motor_paid_J=283333333.333 distance=-114.754 speed=1.3` |

Для `bidir_auto` — подтверждены две настоящие станции ВСМ и движение в оба направления. `bidir_zero`, `bidir_offgrid` — источник 0 Вт / отсутствие контактного провода, моторный и основной дебет Дж остаются нулевыми. `standalone200` — 200 настоящих моторных вагонов без электровоза, 0 скрытых локомотивов, движение 0, груз/жидкость сохранены. `long200highopp` и `long200highopp_rev` — два противоположно направленных электровоза с 200 моторными вагонами, по одному скрытому двигателю на направление. `long200highsame` — два электровоза в одной голове, только один скрытый двигатель для 200 вагонов. Все тяжёлые испытания выполнены **до тика 306**, то есть проверка запуска и первого разгона, не длительная приёмка маршрута гиганта.

### Ограничения и различие уровней доказательства

- **PASS**: исходники, нативный Factorio, настоящая полная официальная ZIP-сборка, 12/12 игровых сценариев плюс отдельная проверка прототипов и штатной энергии.
- **НЕ ПРОВЕРЕНО**: фактический вид красного/прозрачного значка в Windows GUI и уведомлениях об отсутствии топлива (это нельзя увидеть в Linux headless). Владельцу требуется поставить ZIP в отдельную копию сохранения и посмотреть в игре.
- **НЕ ПРОВЕРЕНО**: личные сохранения пользователя, совместная игра/MP, Blueprint/Undo, многосуточный UPS, работа игры при других модах.
- Важно: `no_fuel_status` статичен для истощённого нативного BurnerEnergySource. При проводе с отсутствующим напряжением он также может писать «Нет контактной сети»; полноценная дифференциация «нет провода» и «нет напряжения» требует отдельной динамической системы статусов.
- Встроенное стандартное уведомление `train_out_of_fuel` может оставаться в панели предупреждений, поскольку изменена пиктограмма конкретной горелки, **но не системный список предупреждений для поездов**. Перед утверждением полного удаления всех предупреждений обязательно подтвердить Windows GUI.
- Ни `main`, ни файлы сохранений владельца, ни принятые PNG не изменялись. Публикации/релиза нет.

## Установка для ручной приёмки

1. Закрыть Factorio. Сохранить текущий `ElectrifiedMainline_0.1.73.zip` отдельно как резерв, не удаляя старые сейвы.
2. Поместить `ElectrifiedMainline_0.1.74.zip` в `%APPDATA%\Factorio\mods\` и убедиться, что активна только одна версия `ElectrifiedMainline`.
3. Открыть **копию** карты. Проверить обычный электровоз вне линии, его предупреждение, присутствие технического помощника при наличии моторных вагонов, затем контакт под проводом и восстановление зарядки.
4. Снять скриншот, если остаётся старый значок или системное «нет топлива». Эти симптомы относятся к ещё не проверенному GUI-гейту.

## Воспроизведение

В репозитории: `tests/em074-status-qa`, `tests/em072-bidir-qa`, `tests/run_em074_status_native.sh`; скрипт принимает точный путь к Factorio 2.1.24 и SHA официального ZIP.