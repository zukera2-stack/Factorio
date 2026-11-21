# EM071 — косметический третий пролёт на настоящей стрелке

**Статус: исследование до реализации.** Дата: 2026-11-21. Ветка: `experiment/catenary-turnout-cosmetic-071`, от исходного `main` `56a19fa32d389fe79c9c78558436ec694648616b`; мод 0.1.62, НЕ релиз и НЕ патчер. Factorio 2.1.24 build 87808. Пользовательский исходный симптом: скриншот стрелки ВСМ, контактный провод отогнутой ветки и провода прямого пути не соединяются визуально; сам пользователь предложил «по два на столб».

## Поведение и доказанный корень
- **Факт из наших исходников** `ElectrifiedMainline/scripts/catenary_axis_056.lua`: текущий M.select уже допускает один пролёт по каждому знаку пути (всего 2), применяет взаимную проверку и запасной лимит по отношению длины физического пути к хорде. `catenary_visual_policy_047.lua` задаёт MAX_DEGREE=2, но **не используется в активной функции build_edges** (`scripts/power_019.lua` напрямую вызывает `axis056.plan`). Поэтому простая замена 2→3 в policy не исправит снимок.
- **На пользовательском скриншоте** показаны одна опора кривой с двумя уже существующими пролётами (вниз/влево и вверх) и одна опора прямой с проводом вправо; отсутствующий третий проход через реальную стрелку мог бы устранить зазор. **Реальная RailEnd-связность именно этого сохранения пока не извлечена; фото само по себе не подтверждает наличие подключённого третьего ответвления**.
- Нативный Factоrio 2.1.24 API [LuaEntity.get_connected_rail](https://lua-api.factorio.com/2.1.24/classes/LuaEntity.html): `rail_direction`, `rail_connection_direction` с `straight/left/right`; возвращает только действительно соединённые рельсы. Наш M.plan уже использует именно этот API в row.links, не нужны новые wire-коннекторы или прототипы. [rendering.draw_sprite](https://lua-api.factorio.com/2.1.24/classes/LuaRendering.html) используется отдельно косметическим `catenary_art_030.lua`. Версия из игрового API точная; поведение визуального пролёта не обеспечивается API автоматически.
- Работающего *стороннего* same-type косметического пролёта на 3-ходовой стрелке **не подтверждено**: не будем выдавать соседние механизмы за доказательство. Нативный аналог — только рельсовая топология Base 2.1.24 и её API; визуальный алгоритм остаётся пользовательским.

## Минимальный эксперимент и критерии
Гипотеза: если M.select на одном направлении проходит настоящую физическую развилку (выявленную `#row.links(sign)>1`), можно включить **ближайшие опоры обеих исходящих ветвей** без перескакивания промежуточной опоры, на каждую мачту не более **3** косметических пролётов; на линейном пути останется максимум 2. Только двусторонний выбор; оставляем `M.REACH=32`, `ATTACH=3`, ограничение честной хорды, прежнюю графику и изолированные электрические подсистемы.

**Тест до кода:**
1. Чисто Lua RailEnd-like 4-rail fork с 1 upstream + 2 downstream mast, 3 достоверных взаимных пролёта на центральном mast.
2. Удалить одну ветку: два ребра вместо трёх; несоединённая соседняя пара не склеивается даже при близости.
3. На линейном и параллельном путях прежние `tests/25kv_axis_056.lua` и `tests/25kv_axis_integration_056.lua` PASS без новых диагоналей. Проверить детерминизм, максимальную степень 3.
4. No game code in `main`; GPU rendering/скриншот именно этой стрелки, save/load и Ghost/Undo остаются **НЕ ПРОВЕРЕНЫ**, пока пользователь не проверит эксперимент на сохранении.

## Зона изменения, безопасность и откат
- Менять только `scripts/catenary_axis_056.lua` (сбор кандидатов в существующем обходе, отбор ребра) и **добавить один** отдельный Lua regression `tests/25kv_turnout_cosmetic_071.lua`, подключённый в `tests/35kv_topology.lua` к запуску 0.1.62; никакой модификации `power_019.lua`, технической сети, энергии, прототипов, `migration`, Undo, предметов или существующих рельсов.
- Гейтинг: только `experiment/catenary-turnout-cosmetic-071`; не сливать в `main` и не двигать Updater. Отказ от эксперимента = возвращение к неизменённому main.
- Фальсификация гипотезы: появление спана на не связанных физических рельсах, более 3 пролётов на мачту, разрыв линейной цепи, скачок через первую ближайшую мачту или нативная несовместимость рендеринга.

## 7. Implementation of narrow hypothesis (EM071)
Changed only `scripts/catenary_axis_056.lua` active cosmetics. The bounded walk keeps the closest endpoint per rail path, records exactly one alternative discovered after a real fork, requires reciprocal selection on both endpoints, allows degree 3 ONLY if the candidate path has `fork=true`. Keeps max reach 32, projected chord 1.35 + 1.5, same native rail topology, no disconnected rails. Separate pure-Lua `tests/25kv_turnout_cosmetic_071.lua` models a RailEnd-style Y fork, a disconnected parallel fifth rail, branch break, deterministic repeat, max 3. Current 0.1.62 inherited runner `tests/35kv_topology.lua` triggers new fixture; existing 056 geometry/integration tests retained. **Game screenshot and live native verification PENDING; no merge**.

## 8. Реальные результаты проверок и приёмочные границы

**Source commit:** `1f5f683e251e8485f7860b9bea2b1a60d9d478d6`, [CI run 44925677432](https://github.com/zukera2-stack/Factorio/actions/runs/44925677432) — **SUCCESS**, настоящий Factorio 2.1.24 build 87808. CI Lua 5.2 fixture `071 turnout PASS`: 3/3 реальных rail-end-like соединений в модельной Y-ветке; после физического отсоединения одной ветки не создаёт третью космодугу; отдельный близкий, но неприсоединённый рельс не получает связи; тот же результат при повторном планировании; ни одной мачты со степенью более 3. Наследованные `056 axis PASS` и `056 integration PASS` сохраняют прямой, параллельный и rail cut case. Строгий текущий native energy Factorio **3/3 сценария, 2030 тиков PASS** (реверс, приоритеты, fair share), `EM067 differential PASS` 1,675 cases. Упаковка 130 game files, 83 PNG PASS, документация PASS.

**Root cause первых двух test FAIL в EM071:** предложения альтернативных fork-links сортировались только по физической длине; короткие два ответвления занимали у центральной опоры лимит 2, прежде чем попал обязательный прямой upstream wire. Исправление до успешной CI: **не-fork edges сортируются раньше** optional fork edges, затем ближайшая длина/ID. Новые тройные ответвления не уничтожают обычную прямую подвеску.

**Установочный тестовый ZIP из GitHub Actions**, НЕ релиз: [artifact 14714614745](https://github.com/zukera2-stack/Factorio/actions/runs/44925677432/artifacts/14714614745), вложенный `ElectrifiedMainline_0.1.62.zip` **SHA256 `91aef47ca13a0009e46ab92c9ad5735e0af30c6acc16bab1cf0507a8855a2575`**. Это эксперимент с той же версией 0.1.62, а не автоматическое обновление; `main` и `test/updater-approved` не двигались.

**НЕ ПРОВЕРЕНО:** реальная игровая Y-стрелка на предоставленном скриншоте — снимок показывает лишь косметический зазор, без unit_number/rail end topology. В native CI проверялось сохранение физики/энергии на других сценариях, а не native turnout rendering. Отдельно потребуются: такой же поворот, проверка 2/3 спанов в GUI, изменение/удаление рельса, save/load, ghost preview, Undo/Redo, отсутствие лишней линии поперёк соседнего пути. Не давать пользователю ложную гарантию исправления конкретного снимка до игрового теста.

**Статус:** implemented/Lua-verified/energy-native-regression-PASS, **turnout screenshot unverified**, PR #47 DRAFT. После owner screenshot pass можно отдельно обсуждать merge в main.
