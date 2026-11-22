# EM072-A5-B5 — правила для двух физических тяговых компонентов и миграции версии

**Дата:** 2026-11-22. **Тип:** исследование / проверяемая гипотеза, НЕ выпуск игровой функции.

## Provenance и аналоги

- Исходный код: `zukera2-stack/Factorio`, `experiment/em072a5-native-lifecycle-b4` commit `75e8878dc9f2ff3fb0b7d8aa91d409cd7a07f2fb`, лабораторные `tests/em072a5-b4-probe/{root-hook.lua,control.lua}` и `tests/run_native_lifecycle_072a5b4.py`.
- Игровой мод: точный `ElectrifiedMainline 0.1.62` от CI run `44925677432`, внутренний ZIP SHA256 `91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575`; игровой `main` имеет локомотив `void`.
- Движок: **Factorio Linux headless 2.1.24 build 87808**, только Base, без DLC.
- Нативные аналоги Base: `accumulator` с 5 MJ / 300 kW, `electric-energy-interface` с finite meter buffer и режимом `secondary_input`, `electric-pole` с copper connector. Документация API [LuaBootstrap.on_configuration_changed](https://lua-api.factorio.com/latest/classes/LuaBootstrap.html), [Data lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html), [LuaEntity](https://lua-api.factorio.com/latest/classes/LuaEntity.html) (веб-документация может быть уже 2.1.25; обязательна сверка реальным 2.1.24).
- В штатном `technical_network_046.lua` скрытые script copper разрешаются только авторизованному узлу; B3/B4 расширяли whitelist **лишь в одноразовой тестовой копии**. После `on_configuration_changed` основной мод перестраивает граф и скрытые помощники; сохранённые владельцы и портовые права не должны выдаваться по одной записи `unit_number`.

## Гипотезы и стоп-условия

1. Два независимых собственных HSR-участка на одной поверхности и одной силе НЕ эквивалентны одной тяговой компоненте. Нужны две `electric_network_id`, два native EEI meter, две батареи и раздельные ограниченные HSR BFS. Попытки перекрёстной квалификации `A_mast -> B_train` и `B_mast -> A_train` должны дать **FALSE**, даже при одинаковых force/surface.
2. Если физически перерезать рельс или удалить аванпост A, аванпост B продолжит питать **своих** настоящих локомотивов из собственных finite J. При удалении контроллера B никакой J не выдаётся из его уже заряженного meter; только после нового script-owned подключения питание восстанавливается.
3. **Ещё одна EM070 здесь НЕ требуется:** первый компонент уже содержит одну настоящую станцию и native заряд с нуля, второй проверяет независимость коридорных накопителей и допускает начальные 120 MJ только в лаборатории. Ни одну физически незаряженную батарею нельзя наполнять каждый тик скриптом.
4. Должны существовать **три** независимых тестовых запуска: 500 native ticks; настоящий серверный SAVE в t385 и продолжение `LOAD +115`; повторное `LOAD +115` после **действительного изменения версии тестового мода 0.0.1 → 0.0.2**. В третьем on_configuration_changed обязан сработать, вывести владельца B из авторизованного состояния (0 новых J), затем явно подключить новый script-owned порт и продолжить расход из native батареи без нарушения баланса.
5. `storage` **изолирован по модам**: тестовый `control.lua` не имеет права читать `storage.em` главного мода. Управлять только документированным `remote.call` под своим интерфейсом. Ошибка кросс-модного чтения `storage` может выглядеть как «пустой граф», хотя действительный граф в другом моде существует.
6. Ledger компонента B: `E_initial_24cells (120MJ) = E_24cells + E_native_meter + ΣE_native_burner_remaining + ΣE_native_consumed`. Для компонента A — прежний B4 ledger с источником 84 factory accumulators, EM070 buffers, 24 corridor accumulators, EEI meter, burner buffers и израсходованными Дж. Максимум 7.2MW у батарей относится к **native steady state**, не к однотиковому изъятию уже накопленного meter буфера. В разных сценариях SAVE/LOAD и version-change допускается различное потребление, но невязка каждого должна быть ≈0.

## Границы исходного эксперимента

Никакого имитирования GUI игрока/нажатий Ctrl+Z, нет robot mining, нет встраивания terminal в производственную версию мода, нет двух подстанций EM070, factory brownout, multiplayer, Space Age, массовой карты/60 UPS, моторных вагонов +500kW и рекуперации. Следующий тест должен изолировать каждое ограничение, а не переносить лабораторный hook в main.