# EM072-C3 — протокол воспроизводимых проверок и отрицательных контролей

Factorio native **2.1.24 build 87808**. Модель каждого `em-invisible-motor-500kw` — настоящий `locomotive`, `max_power="500kW"`, `joint_distance=0.1`, `connection_distance=-0.1`, пустые спрайты. Во всех сценариях исходные `locomotive + cargo-wagon + fluid-wagon` имеют центры на y=0/7/14. **Интеграция в production и USER BLUEPRINT не выполнялись.**

| Тест | Фальсифицирующее условие | Итог |
| --- | --- | --- |
| Несовместимая минимальная геометрия | `joint_distance=0` принимается | **REJECTED BY ENGINE** (minimum 0.1) |
| Две скрытые сущности | Прирост видимой длины >0 или не в одном `LuaTrain` | **PASS**: span=14.000000, n=5 |
| Контроль обычного поезда | n !=3 или видимая длина !=14 | **PASS** |
| Внешний несцепленный локомотив | Ускоряет чужой поезд | **NEGATIVE PASS**: скорость равна обычному составу |
| Наложение поверх занятого вагона | Дает дополнительную тягу | **NEGATIVE PASS**: `create_entity` вернул nil |
| Обратное отключение void | Можно выключить нативную тягу при 0 J через `active` или `disabled_by_script` | **FAIL/BLOCKER**: свойство active read-only, disabled_by_script игнорируется |
| Реальный native разгон | Невидимые 500кВт не отличаются от 2МВт контроля | **PASS**, отличие измерено |
| Встроенная добавка в уже сцепленный поезд | Разрыв на стоянке + вставка не возвращает единый поезд или перемещает видимые машины | **PASS**: 14.000, n=5, native train created changes ID |
| Удаление приводов и пересцепка | Идентичность вагонов теряется, состав не собирается или отличается движение | **PASS**: исходные unit_number, n=3, движение == контроль |
| Внутренний конечный запас | После нуля J phantom продолжает дополнительную тягу | **PASS** для скрытого BurnerEnergySource: 400kJ списаны, 0J после t40 |
| Нулевая энергия | Скрытый нативный burner дает ускорение даже без J | **NEGATIVE PASS**: эффект только веса +1 на единицу |
| Настоящий сервер SAVE/LOAD | Итоги после reload расходятся с benchmark | **PASS в каждом из 3 независимых стендов** |
| Реальная EM070, синхронизация HSR/батареи, кривые/стрелки, UI/MP, 60UPS | Нет теста | **NOT TESTED / BLOCKED FOR GAMEPLAY** |

Проверка одной командой для каждого стенда (гарантируется именно Linux64 Factorio 2.1.24, build87808):

```bash
python tests/run_native_zero_growth_072c3.py --factorio /path/to/factorio --output /tmp/c3-geometry
python tests/run_native_dynamic_insert_072c3.py --factorio /path/to/factorio --output /tmp/c3-dynamic
python tests/run_native_finite_phantom_072c3.py --factorio /path/to/factorio --output /tmp/c3-finite
```

Каждый `--output` должен быть пустым. Запускатели создают изолированную папку модов, настоящий мир, нативный benchmark, частный dedicated server на локальном порту, реальный zip SAVE, независимый `--test-save` во втором процессе, верифицируют контрольные числа и записывают JSON + SHA256 сырых журналов. Никаких пользовательских миров/модов, установленного `main` или релизов.