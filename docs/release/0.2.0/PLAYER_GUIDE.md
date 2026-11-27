# Руководство игрока / Player guide

## Русский
1. Изучи «Электрификация железных дорог», «Высокоскоростные рельсы» и «Высокоскоростной электровоз». Для аккумуляторного вагона нужны «Рекуперативное торможение» и «Аккумуляторный подвижной состав».
2. Построй рельсы ВСМ. Для замены существующего пути используй планировщик замены рельсов ВСМ: он отмечает ванильные рельсы для демонтажа и создания соответствующих призраков. Убедись, что строительные роботы и материалы доступны.
3. Удерживая контактную опору 25 кВ, используй Alt + ЛКМ рядом с рельсами ВСМ. Соедини контактные участки и подведи питание через тяговую подстанцию. Не соединяй заводскую и контактную сети напрямую. Одна подстанция рассчитана на 20 МВт; при нехватке добавь параллельные подстанции и обеспечь генерацию.
4. Поставь электровоз «Магистраль», сцепи моторные вагоны. Задай маршрут штатными средствами Factorio. Отдельное топливо вагонам не требуется. Пантограф поднимается при отправлении. При недостатке энергии проверь наличие контактного провода, питание подстанции и запас батарей.
5. Аккумуляторный вагон не перевозит груз. Он хранит 600 МДж по умолчанию и питает состав при нехватке сети. Сначала заряжаются батареи электровозов. Рекуперация возвращает энергию сети, затем батареям. Зарядка на стоянке включается в настройках карты и по умолчанию выключена.

| Накопитель | Ёмкость | Заряд | Разряд |
|---|---:|---:|---:|
| Электровоз | 60 МДж | 2 МВт | 4 МВт |
| Аккумуляторный вагон | 600 МДж | 5 МВт | 10 МВт |

Это значения по умолчанию; менять их можно в настройках запуска мода. Аккумуляторный блок — компонент рецепта, не самостоятельный накопитель.

Установка ZIP: закрой игру, сохрани старый мод за пределами `mods`, положи полный ZIP в `mods` (Windows: `%APPDATA%/Factorio/mods`) и запусти игру. Не оставляй одновременно распакованную копию и ZIP. Сделай резервную копию сохранения. Для 0.2.0 миграция отдельно не проверялась.

## English
1. Research Electrified Railways, High-speed Rails and High-speed Locomotive. Battery Rolling Stock requires Regenerative Braking and its prerequisites.
2. Build high-speed rails, or use the rail replacement planner with construction robots and materials to replace vanilla rails.
3. Hold a 25 kV overhead mast and Alt + left click near high-speed rails. Connect the overhead sections and feed the separate network through traction substations. Each substation is rated at 20 MW; add parallel substations and adequate factory generation if needed.
4. Place a Mainline electric locomotive, couple motor wagons and use normal Factorio train schedules. Separate wagon fuel is not needed. If power is missing, check the overhead contact, substation supply and batteries.
5. A battery wagon stores energy rather than cargo. Locomotive batteries charge first. Regeneration returns energy to the grid, then the batteries. Stationary charging is a map setting, disabled by default.

Default locomotive storage: 60 MJ, 2 MW charge and 4 MW discharge. Battery wagon: 600 MJ, 5 MW charge and 10 MW discharge. These are configurable startup settings.

To install, close Factorio, back up your save, remove the old mod from `mods` and copy in the complete ZIP. Do not retain both an unpacked copy and a ZIP. Migration to 0.2.0 has not been separately tested.
