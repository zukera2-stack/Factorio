# EM076 — «Нет тягового питания» и скрытие топливных предупреждений технических локомотивов

**Дата:** 2026-11-23. **Ветка:** `fix/em076-traction-power-status-20261123`, основана на `integration/em072-em075-20mw-20261123`. **Статус:** исправление интерфейса и локальная нативная QA, не релиз/merge.

## Принятое решение

1. Для **видимого электровоза** заменить неточную надпись «Нет контактной сети» на **«Нет тягового питания»** (EN: **No traction power**). Она означает отсутствие доступной тяговой энергии и не утверждает, что провод обязательно отсутствует. Используется штатный красный электрический warning icon `__core__/graphics/icons/alerts/electricity-icon-red.png`; ванильное «Нет топлива» на реальном электровозе не используется.
2. Для всех **256 скрытых логических локомотивов** `em-c5-technical-booster-*` явно установить `energy_source.render_no_power_icon=false`. Официальная Factorio 2.1 `BaseEnergySource.render_no_power_icon` применяет этот флаг и к нативной иконке **no fuel** у burner. Прозрачная `BurnerUsagePrototype.icon` из EM074 сохранена как дополнительная защита, **но не является основным способом отключения**.
3. Не изменять ванильный `burner-usage.fuel` и его значки, реальные `fuel_categories`, `max_power`, 20-МВт мост, скорость, тягу, оплаченные Дж, графику или игровую обработку событий.

## Документированные основания

- Нативный Factorio 2.1.24 исходник `data/core/prototypes/burner-usage.lua` содержит `fuel.icon` (red fuel) и `no_fuel_status`.
- Factorio API `BaseEnergySource.render_no_power_icon` прямо говорит: “Also applies to the ‘no fuel’ icon when using burner energy sources.” https://lua-api.factorio.com/latest/types/BaseEnergySource.html
- `BurnerEnergySource.burner_usage` позволяет задавать отдельный статус каждому типу локомотива, без глобального переопределения vanilla. https://lua-api.factorio.com/latest/types/BurnerEnergySource.html
- `render_no_power_icon` управляет **иконкой над сущностью**. Это не доказательство отсутствия глобального уведомления `train_out_of_fuel` в панели предупреждений Factorio. Глобальные предупреждения необходимо отдельно проверять в Windows GUI. Не отключать `train_out_of_fuel` глобально, поскольку это сломает ванильные поезда.

## Проверено локально на настоящем Factorio 2.1.24 build 87808

Рабочая *копия* полного интегрированного `ElectrifiedMainline_0.1.74` из 140 игровых файлов; на предыдущем этапе все семь отличавшихся от исходного 0.1.73 ZIP файлов были подтверждены Git blob SHA объединённой ветки, исходные 83 PNG неизменны. Для EM076 изменены только `prototypes/traction_status_074.lua` и две локали; тестовый мод отдельно.

- **PASS**: отдельный реальный headless `--test-scenario` прототипов. `[EM076 DATA PASS]`: 256/256 технических `BurnerEnergySource.render_no_power_icon=false`, у электровоза предупреждение осталось, красный электрический значок на месте, ванильное топливо нетронуто.
- **PASS**: `[EM076 NATIVE PASS]` — Factorio runtime `LuaBurnerPrototype.render_no_power_icon` на реальном `em-electric-locomotive` = `true`, на `em-c5-technical-booster-500` = `false`; назначения обоих `burner_usage` корректны. Это настоящий native runtime, не mock.
- **PASS**: свежая native карта с полным модом `--benchmark-ticks 2830`, с энергостендом в той же сессии. `[PARALLEL FULL_BIDIR PASS]` и 20/40/60/120 MW по 1/2/3/6 стандартным подстанциям, включая реверс и 40-МВт перегрузку на единицу с жёстким пределом 20 МВт.
- Логи: `status_native.log` и `native_scaling_fresh_2830.log` в локальном комплекте QA. **GitHub Actions не запускались**.

## Осталось проверить

Нативный headless не создаёт изображение Windows GUI. Подтверждение того, что красная пиктограмма электричества и её надпись видны правильно, а **у логических локомотивов ничего не мигает**, требует игрового скриншота. Отдельно проверить глобальный `train_out_of_fuel`, потому что статус поезда — иной механизм. SAVE/LOAD, MP и конкретные 200-вагонные сценарии не повторялись в этой EM076 серии.

**Правила:** `main` не менять, утверждённые PNG не менять, игровые бинарники и исходные пользовательские архивы не трогать, не запускать GitHub Actions, не делать merge/release без разрешения владельца.
