# EM087 — расширенная регрессионная проверка (25.11.2026)

**Статус: 51/51 завершённых проверочных сценариев после исправления тестового стенда; функциональная регрессия в проверенном объёме не обнаружена. EM087 всё ещё эксперимент, performance gate не закрыт.**

Объект: неизменённый полный `ElectrifiedMainline_0.1.87.zip`, SHA256 `b95a2b41108dd7817ffd9bf818c0010f58b0294700de79ddaa301505ad9c4434`, исходная ветка `experiment/em087-performance-r2`, commit `6f67adc25132a6a9a81b4e0959d3ac237b12a997`. Linux Factorio 2.1.24 build 87808. CRC ZIP PASS; 157 игровых файлов, 99 PNG побайтово идентичны 0.1.86. Ровно шесть отличий к EM086 (info.json и пять Lua); в ходе этого аудита игровой код не менялся. Проверки выполнялись в отдельных временных write-data/mods каталогах; пользовательские сохранения не затронуты. Последняя подтверждённая владельцем 0.1.84; 0.1.85/0.1.86 кандидаты, 0.1.87 эксперимент.

## Учёт запусков
54 реальных запуска движка: 46 с `Test passed at tick`, 5 со стендовым assertion `[EM087 SNAP]` и кодом выхода 0 (без `finish_test`); 2 первых запуска роста/уменьшения состава закончили лимит тиков до финальной проверки; 1 первая попытка прототипов использовала несуществующее runtime-поле `LuaEntityPrototype.max_power`. Все три повторены с корректной методикой и прошли. Ошибки и исходные журналы сохранены, не считать их дефектами игрового кода. 51 положительный сценарий (не 51 независимый модуль). В тестах не пишется `train.speed`, скрытая тяга создаётся модом, а не стендом. Синтетические источники и потребители задаются нативными EEI. Результат не равнозначен исчерпывающему доказательству.

## Основная механика
- 10 исходных аудит-сценариев: fair, offgrid, ownerloss, block, move, retain, visibility, gui, churn, churn100. Последний завершился на тике 12000: 100 циклов, ноль оставшихся лишних приёмников, потери 3333333.333 J учтены. Сохранение 0.1.85 с 201 моторным вагоном загружено в точной 0.1.87, сохранены ID помощников, груз, вода и счётчик энергии.
- 5 attachment-сценариев: одинаковые/противоположные направления, 200→201 и 201→200, автоматическая поездка между двумя остановками в обоих направлениях. Пять стендов 1/10/50/100 поездов с двумя моторными вагонами, и 1 поезд с 800 моторными вагонами (4 помощника, 805 физических единиц).
- Расширение: 0/1/199/200/201/400/401/600/800 моторных вагонов, dual201, zero201, passive, mixed, vanilla, standalone, split/rejoin, ownerlossdual, power401. Все 18 прошли. На 401 моторном вагоне + одном EM + 11 подстанциях: пик нативного запроса 202500000 W, движение 138.25390625 клетки; это запрос, не доказательство непрерывной выдачи 202.5 MW. Проверены собственник каждого помощника, блоки мощности, полезный груз, жидкость, запреты взаимодействия; старый helper уничтожен после split, новый ID после recouple.

## Прототипы, no_path, GUI
Все 256 исходных helper-прототипов проверены на data-stage: max_power, hidden, hidden_in_factoriopedia, selectable=false, allow_copy_paste=false, alert_icon_scale=0, отсутствие minimap sprites, прозрачные body/wheels, burner no-power icon false, обязательные flags. Runtime повторно проверяет наличие и флаги. 5 native no_path: 1, 201, dual201, zero201, 800; истинное состояние train no_path, скрытые alert/fuel icon flags отключены, настоящая EM alert scale положительна. Прямой GUI помощника и чертёж не включают его. Это проверки полей/функций движка, не Windows-рендеринг. Встроенное окно поезда/станции, пустые ячейки, GUI цистерны, визуальные alert overlays остаются OPEN. Требование владельца: игрок не видит технические единицы. Не считать выполненным полностью.

## Общая электросеть
Две новые независимые native серии (`network-topology`, `network-multi48`) адаптированы из исторических EM063/064/062, с проверкой актуальных ограниченных остаточных энергий вместо устаревшего требования мгновенно удалять все мостовые буферы.
- Три независимые фабричные сети; 20 MW источник, два потребителя. Отключение B: C получил 79666666.667 J за окно. Разрыв 2 мачт: остаток 666666.667 J; восстановление 59666666.667 J. Разрыв рельса: остаток 666666.667 J; восстановление 59333333.333 J. Демонтаж источника: остаток 333333.333 J; восстановление 59000000 J. Генератор OFF: остаток 666666.667 J. Непрерывного питания через разрыв не выявлено; остатки ограничены тестовым бюджетом, не приравниваются к точному полному балансу всей сети.
- 48 независимых фабричных сетей, 95 мачт, 6×20 MW источников. На тике 240 суммарно 474 MJ у 42 потребителей, min=max 11.285714 MJ с точностью отображения. После отключения 24 потребителей 18 активных получили перераспределённую энергию в проверенных пределах; после выключения источников остаточный прирост 2 MJ, ниже лимита теста 27 MJ. Фабричные сети не замкнулись. Не утверждать, что все возможные топологии (кривые, вилки, разные силы/поверхности, factory merge/split) проверены.

## Массовое движение
Новый тест: отдельные прямые пути, по 20 MW подстанции и генератору на поезд, два моторных вагона, 37 пластин и 9000 воды на состав. На 120-м тике нативные расписания отправляют поезда к своим станциям. Все четыре запуска (1, 10, 50, 100 поездов) завершены `finish_test(true)` на тике 501; все поезда двигались одновременно, к 360-му тику достигли станции, пройдя 76 клеток каждый. На 500-м тике исходные helper IDs, собственник, cargo/fluid и сцепление сохранены. Для 100: 7600 клеток суммарно, 601666666.667 J paid ledger, 135000000 J motor paid. Это функциональная регрессия, не benchmark: параллельные тестовые процессы, wall time не сравнивать как UPS, движения по независимым путям, не пересекающийся железнодорожный узел.

## Ограничения и продолжение
Не было Windows-клиента и owner acceptance, реального multiplayer, совместимости сторонних модов, новой полноценной 100-км карты, конкурентных маршрутов со светофорами, полного теста всех исторических сценариев и многодневного soak. Нет новых измерений p95/p99/RSS с контрольной версией. Сохраняется прежний блокер EM087: массовый стенд 100 неподвижных поездов в версии 0.1.87 давал 36.552 ms/tick vs 35.129 ms EM086; не закрывать performance gate. Не устанавливать эксперимент в основную игру; не сливать main. Следующая задача EM087B: уменьшить регулярные затраты bridge058 и сделать инкрементальный граф с независимым аудитом, затем прогнать все перечисленные сценарии; добавить фабричный merge/split, геометрические развилки, независимые поверхности/силы, сигналы, длительный прогон, Windows visibility. Аккумуляторы и рекуперация после performance gate.

## Реестр отдельных запусков

| Запуск | Статус | Метод подтверждения |
|---|---|---|
| alerts-nopath1 | PASS | Test passed at tick |
| alerts-nopath201 | PASS | Test passed at tick |
| alerts-nopath800 | PASS | Test passed at tick |
| alerts-nopathdual201 | PASS | Test passed at tick |
| alerts-nopathzero201 | PASS | Test passed at tick |
| attach-bidir | PASS | Test passed at tick |
| attach-dual | PASS | Test passed at tick |
| attach-grow-retry | PASS | Test passed at tick |
| attach-grow | INCONCLUSIVE | Test passed at tick |
| attach-same | PASS | Test passed at tick |
| attach-shrink-retry | PASS | Test passed at tick |
| attach-shrink | INCONCLUSIVE | Test passed at tick |
| audit-block | PASS | Test passed at tick |
| audit-churn | PASS | Test passed at tick |
| audit-churn100 | PASS | Test passed at tick |
| audit-fair | PASS | Test passed at tick |
| audit-gui | PASS | Test passed at tick |
| audit-move | PASS | Test passed at tick |
| audit-offgrid | PASS | Test passed at tick |
| audit-ownerloss | PASS | Test passed at tick |
| audit-retain | PASS | Test passed at tick |
| audit-visibility | PASS | Test passed at tick |
| bench-100x2 | PASS | SNAP |
| bench-10x2 | PASS | SNAP |
| bench-1x2 | PASS | SNAP |
| bench-1x800 | PASS | SNAP |
| bench-50x2 | PASS | SNAP |
| extended-0 | PASS | Test passed at tick |
| extended-1 | PASS | Test passed at tick |
| extended-199 | PASS | Test passed at tick |
| extended-200 | PASS | Test passed at tick |
| extended-201 | PASS | Test passed at tick |
| extended-400 | PASS | Test passed at tick |
| extended-401 | PASS | Test passed at tick |
| extended-600 | PASS | Test passed at tick |
| extended-800 | PASS | Test passed at tick |
| extended-dual201 | PASS | Test passed at tick |
| extended-mixed | PASS | Test passed at tick |
| extended-ownerlossdual | PASS | Test passed at tick |
| extended-passive | PASS | Test passed at tick |
| extended-power401 | PASS | Test passed at tick |
| extended-prototypes-retry | PASS | Test passed at tick |
| extended-prototypes | FAIL | Test passed at tick |
| extended-split | PASS | Test passed at tick |
| extended-standalone | PASS | Test passed at tick |
| extended-vanilla | PASS | Test passed at tick |
| extended-zero201 | PASS | Test passed at tick |
| migration085 | PASS | Test passed at tick |
| moving-1 | PASS | Test passed at tick |
| moving-10 | PASS | Test passed at tick |
| moving-100 | PASS | Test passed at tick |
| moving-50 | PASS | Test passed at tick |
| network-multi48 | PASS | Test passed at tick |
| network-topology | PASS | Test passed at tick |

Файлы: `results.json`, `results.csv`, `logs/`, `qa_mods/`, `fixtures/long201.zip`, `run_original.py`, `reproduce.py`. Проверка SHA256 внутри `SHA256SUMS.txt`. ZIP мода и движок не входят в доказательный архив.
