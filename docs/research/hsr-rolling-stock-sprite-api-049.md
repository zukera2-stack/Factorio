# 0.1.49 — API спрайтов ВСМ и электровоза, исследование до реализации

## 1. Метаданные и источники

Ветка `feature/hsr-rolling-stock-visual-049`, исходный commit `62a8784c4eb339374bea261d98844f492e19afad`. Стабильная версия мода 0.1.48, Factorio 2.1.24 build 87808. Статус: research, не игровой тест; код и PNG не изменены.

Проверены непосредственно файлы официального [wube/factorio-data, tag 2.1.24](https://github.com/wube/factorio-data/tree/2.1.24), commit `acf5a342afcb66c066b9d88d202e8622112da117`:
- [trains.lua](https://github.com/wube/factorio-data/blob/2.1.24/base/prototypes/entity/trains.lua): все четыре наземные rail prototypes, locomotive, native color mask, lights, wheels, geometry.
- [rail-pictures.lua](https://github.com/wube/factorio-data/blob/2.1.24/base/prototypes/entity/rail-pictures.lua): new_rail_pictures, make_new_rail_pictures, layer filenames, x/y, width/height, variation count, endings.
- Наши `ElectrifiedMainline/prototypes/bootstrap.lua` и `scripts/control.lua` на исходном коммите: полные deepcopy базовых прототипов, native rail geometry, locomotive speed/train diagnostics.

Документация: [RailPrototype](https://lua-api.factorio.com/latest/prototypes/RailPrototype.html) (индексированная 2.1.24), [RailPictureSet](https://lua-api.factorio.com/latest/types/RailPictureSet.html), [RollingStockPrototype](https://lua-api.factorio.com/latest/prototypes/RollingStockPrototype.html), [RotatedSprite](https://lua-api.factorio.com/latest/types/RotatedSprite.html), [LuaRendering](https://lua-api.factorio.com/latest/classes/LuaRendering.html), [LuaEntity](https://lua-api.factorio.com/latest/classes/LuaEntity.html), [RollingStockDrawData](https://lua-api.factorio.com/latest/concepts/RollingStockDrawData.html), [ScriptRenderTargetTable](https://lua-api.factorio.com/latest/concepts/ScriptRenderTargetTable.html). Прямые URL /2.1.24/types/... не открылись; индексированные страницы разных версий 2.1.17–2.1.25, поэтому точные runtime-особенности подлежат проверке на 2.1.24. Прототипы Base прочитаны именно из нужного tag. PNG/вспомогательные метаданные sprite_load с диска игры не инспектировались.

Сравнимый мод [Electric Train Models](https://mods.factorio.com/mod/ElectricTrainModels) описывает 256 ракурсов, слои краски, тени, свет и дополнительную наклонную графику; [Electric Train](https://mods.factorio.com/mod/electric-train) также заявляет искры пантографа. Это описание возможностей, а не проверка исходников, не доказательство реализации поднятия/опускания. Исходник стороннего динамического пантографа ещё нужен. Не копировать чужие PNG/код. До реализации выполнить отдельный узкий runtime research/probe.

## 2. Рельсы: native pictures, не произвольный плоский спрайт

В нашем bootstrap четыре rail type копируются целиком и имеют те же pictures, что Base. Base использует функцию new_rail_pictures("straight" / "half-diagonal" / "curved-a" / "curved-b"), тип RailPictureSet. В каждом направлении отдельные layers; наследуем render_layers, rail_endings, segment_visualisation_endings, размеры, shift, x/y, вариации и порядок отрисовки. Не менять геометрию, коллизии, сигналы, upgrade, путь.

| Rail type | Активные поля направления в Base | Размер кадра в пикселях источника | Варианты на направление |
|---|---|---|---|
| straight | N,E | 256×256 | 8 каждый |
| straight | NE,SE | 384×384 | 3 каждый |
| half-diagonal | N,NE,E,SE | 384×384 | 3 каждый |
| curved-a | 8 | 512×512 | 4 каждый |
| curved-b | 8 | 512×512 | 4 каждый |

Всего 24 активных direction entries, 98 ячеек с вариантами на каждый из пяти обычных слоёв при строгом повторении Base, не число обязательных отдельных файлов. Segment visualisation без случайных вариаций; окончания отдельно. Слои размещены в общих листах с разных x/y. Base scale=0.5, shift для этих rail keys нулевой. Число кадров и размер листов можно оптимизировать только отдельно от геометрии; точные размеры оригинальных PNG не измерены. Нельзя заменить всё одной картинкой и ожидать native стыков.

| Поле | Исходный файл (в __base__/graphics/entity/rails/rail/) | Роль |
|---|---|---|
| metals | rail-metals.png | рельсовый металл |
| backplates | rail-backplates.png | подкладки/крепления |
| ties | rail-ties.png | шпалы |
| stone_path | rail-stone-path-inside.png | внутренний балласт |
| stone_path_background | rail-stone-path.png | внешний балласт |
| segment_visualisation_middle | rail-segment-visualisations-middle.png | диагностическая сегментация |

Первые художественные гипотезы: сохранять металлы, окончания и визуализацию сегментов штатными, экспериментировать с отличимыми бетонными шпалами и более светлым/ровным основанием. Для быстрого прототипа возможен tint штатных слоёв без копирования PNG (проверить наследуемые SpriteParameters), затем оригинальная графика. Для настоящего плитного пути необходимо нарисовать точные стыки всех геометрий и проверить пересечения, ответвления, переходы vanilla/HSR. Сохранить штатные rail endings до согласования новых, проверить цвет на переходах. Не менять elevated rails в этом этапе.

## 3. Локомотив: штатная перекраска

Наш фактический `em-electric-locomotive` уже наследует базовые pictures, wheels, front_light_pictures, color, настройки станции. В Base tag 2.1.24 locomotive.pictures.rotated.layers = кузов, mask, shadow. Отдельные front_light_pictures.rotated и wheels. У всех этих основных направленных слоёв direction_count=256 и scale=0.5; Base использует sprite_load и для кузова/маски/тени dice=4, allow_low_quality_rotation=true, usage="train". 256 — эталон качества Base, не доказательство обязательного минимума engine. 256 направлений означают один полный оборот, native projected views, не поворот одного плоского PNG. На подъёмах и высоте нужны отдельная проверка наклонной графики и fallback; наземный источник Base не задаёт sloped в этом блоке, elevated-rails может изменять данные отдельно.

Цвет:
- Base color={r=0.92,g=0.07,b=0,a=1}, default_copy_color_from_train_stop=true.
- Native mask: flags={"mask"}, apply_runtime_tint=true, tint_as_overlay=true. RollingStockPrototype.allow_manual_color имеет default true по API. Runtime LuaEntity.color read/write, copy_color_from_train_stop read/write.
- Сохранить встроенную GUI смену цвета, в том числе опцию станции. Не вводить свою GUI/скрипт окраски, не перезаписывать цвет на тиках.
- Основной кузов серебристый/нейтральный с тёмной крышей, окнами и фиксированной технической арматурой. Цветовая полоса/боковые панели определяются согласованной маской; исходный красный — только начальный цвет, не запечённый в кузов. Маска согласована с освещением и альфа всех ракурсов; тестировать белый/чёрный/красный/синий/зелёный, цвет станции, копирование настроек, сохранение/загрузку.
- Независимый shadow, windows, металл и пантограф не перекрашивать. Wheels/headlights можно оставить native в первом тесте; проверить совпадение расположения фар, сцепок и тележек.
- Base collision {{-0.6,-2.6},{0.6,2.6}}, selection {{-1,-3},{1,3}}, connection_distance=3, joint_distance=4, vertical_selection_shift=-0.5. Сохранить текущую геометрию и physics. Наш void, 600kW, speed 1.5 остаются.

Рекомендованный production pipeline: собственная 3D-модель с ортографической/калиброванной Factorio-проекцией, одним освещением и точными camera/pivot, пакетный рендер 256 ракурсов. Отдельные pass'ы кузова/маски/теней; при полном новом свете ещё один pass. 3×256=768 кадров, с отдельными фарами 1024; это кадры, а не PNG-файлы. На 8/16 ракурсах сначала проверяется художественная концепция, не финальное качество вращения. Точные размеры кадра и направление нулевого кадра определить по оригинальным asset metadata и in-game тесту. Full atlas/3D source — dev material вне mod dir; runtime sprite sheets только в graphics. CI-only install ZIP.

## 4. Пантограф: отдельное визуальное состояние, технический риск

В изученном native locomotive нет поля для автоматически поднимаемого/опускаемого пантографа по скорости. Это не утверждение, что любой обход невозможен. Кандидат: LuaRendering.draw_sprite с target entity, фиксированным экранным высотным offset, orientation/orientation_target/use_target_orientation; при необходимости менять sprite на один из заранее отрендеренных ракурсов. Documented LuaEntity.draw_data (position,orientation,slope,height) может дать фактические параметры рисования rolling stock, проверить наличие и поведение в 2.1.24. Использовать draw_data orientation/position вместо наивного вращения плоской картинки, если probe подтверждает. Вначале train.speed abs и два состояния, проверка кадра/позиции на повороте и при движении в обе стороны; API auto-rotation поворачивает плоскую картинку, не воспроизводит 3D-проекцию поднятой рамки. Не вращать экранный вертикальный offset как локальное смещение крыши. Разнести ориентацию, позицию, высоту и положение токосъёмника. Render target docs 2.1.24: entity target уничтожается при удалении/смене surface; очистить хранимые ID и проверить lifecycle.

Проба до массового рендера: один локомотив, 8/16 визуальных направлений в двух состояниях, видимая тестовая точка на крыше и у контактного провода; сравнить реальные screen coordinates на прямых/кривых, развороте, в движении, при прокрутке и на наклоне. Если LuaRendering не следует интерполированной картинке — подобрать метод по результату, не добавлять ещё одну физическую entity. Сравнить dedicated native render layer с проводом; высота и перекрытия не подтверждены. Поднятие в движении, опускание в покое; гипотеза без мощности. Более плавный подъём/искра позже; нет нового power transfer. Имеющийся train_manager filter уже берёт только наши locomotives; избежать второго полного скана. Проверить item/ghost/build lifecycle, coupled trains, load/migrate, удаление, multiplayer и UPS.

## 5. Что готово / что ещё нужно проверить

Проверено по точному Base 2.1.24: структура слоёв, native направления/варианты rail, locomotive 256 views, native mask and color defaults in source. API runtime подтверждён по доступным страницам ряда 2.1.x, не в игре. Утвердить художественный образ с пользователем (нейтральный корпус + перекрашиваемые широкие полосы; бетонные шпалы/аккуратный балласт), затем отдельный малый test harness/atlas. Не считать 98/256 обязательным форматом: это подсчёт именно Base layout. PNG metadata, geometry/perspective anchors, layer order, actual dynamic pantograph analogue source и live tests ещё нужны. Отклонить любой подход, который теряет ручную перекраску или копирование цвета, нативные rail joins/ghosts/Undo, двигает catenary geometry, или меняет physics.

## 6–9. Гипотеза, проверка и статус

Acceptance: native tint GUI works on all frames, existing colors persist, unchanged train joins/dimensions/energy; track appearance distinctive and native topology unchanged; pantograph follows roof in movement/curves, no leaked overlays, stays down stopped. No changes to game files or ZIP/version in this research turn. No merge to main. CI documentation only; implementation and in-game trials pending.
