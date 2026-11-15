# Ревизия GitHub ElectrifiedMainline — 15 ноября 2026

## Объём и границы

Репозиторий: [zukera2-stack/Factorio](https://github.com/zukera2-stack/Factorio), очищаемая ветка `feature/catenary-facing-geometry-022`; версия исходного мода **0.1.22**. Исходный коммит перед чисткой: `9025ddbf2496e73c5b7ca704e9c09199894ddc1f`. **Стабильная ветка `main` 0.1.8 не меняется.**

До ревизии: **145 файлов / 9225558 байт** по дереву GitHub без учёта истории. Однозначно неиспользуемое/дублированное, удалено из ТЕКУЩЕГО дерева: **21 файлов / 6866337 байт (около 6.55 МиБ)**. Файлы остаются восстанавливаемыми по Git-коммитам; **история Git НЕ переписывалась, общий размер старых Git-объектов сервера не обязан уменьшиться**.

## Удалено из текущего дерева

| Набор | Количество | Зачем |
|---|---:|---|
| `art/sources/021-C/` — оригинальные AI PNG и индекс README | 10 | Полноразмерные изображения для генерации спрайтов; по указанию пользователя в рабочем GitHub должны быть готовые PNG, не исходники большого разрешения. [Восстановить из исторического коммита](https://github.com/zukera2-stack/Factorio/tree/64f81365ae5aa654d9b6cca1598cd30cc98289b3/art/sources/021-C) |
| `art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip` | 1 | Старый архив; его **точные** восемь спрайтов и тень уже отслеживаются под `ElectrifiedMainline/graphics/entity/35kv/`. Полный архив можно [скачать из истории](https://github.com/zukera2-stack/Factorio/blob/64f81365ae5aa654d9b6cca1598cd30cc98289b3/art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip); Git blob SHA `c339d25ae1f82c535d0810715ca5594a1793898a`; SHA256 `234f26cd11a1efa380dd849af2278234db3db90ec23b8049096c66cf0863da42` |
| `ElectrifiedMainline/graphics/entity/35kv/pole-4dir-hr.png` | 1 | Устаревший, неиспользуемый непосредственно в прототипе 0.1.22 четырёхкадровый атлас 0.1.11. Исторический генератор `scripts/sprites/game_test_pack.py` создаёт такой атлас заново, но **не нужен для запуска текущего мода** |
| `ElectrifiedMainline/TEST_*.txt` от 0.1.12–0.1.18 | 9 | Памятки старых версий не следует упаковывать вместе с 0.1.22. Их история остаётся в Git; актуальная инструкция по эксперименту: `ElectrifiedMainline/TEST_FACING_022.txt` плюс `docs/TEST_INSTALL_022.md` |

Поимённый список удалений:

- `ElectrifiedMainline/TEST_AUTO_ORIENT_012.txt` (1976 Б)
- `ElectrifiedMainline/TEST_CORRIDOR_017.txt` (2096 Б)
- `ElectrifiedMainline/TEST_GEOMETRY_016.txt` (1819 Б)
- `ElectrifiedMainline/TEST_HOTFIX_013.txt` (1440 Б)
- `ElectrifiedMainline/TEST_NATIVE_POLE_018.txt` (3054 Б)
- `ElectrifiedMainline/TEST_PREVIEW_015.txt` (1513 Б)
- `ElectrifiedMainline/TEST_SLOTS_014.txt` (1218 Б)
- `ElectrifiedMainline/TEST_UNDO_017.txt` (1197 Б)
- `ElectrifiedMainline/TEST_UNDO_018.txt` (1853 Б)
- `ElectrifiedMainline/graphics/entity/35kv/pole-4dir-hr.png` (130271 Б)
- `art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip` (654494 Б)
- `art/sources/021-C/README.md` (2913 Б)
- `art/sources/021-C/concept-C.png` (3072073 Б)
- `art/sources/021-C/east.png` (356099 Б)
- `art/sources/021-C/north.png` (422255 Б)
- `art/sources/021-C/northeast.png` (385608 Б)
- `art/sources/021-C/northwest.png` (376248 Б)
- `art/sources/021-C/south.png` (352621 Б)
- `art/sources/021-C/southeast.png` (383047 Б)
- `art/sources/021-C/southwest.png` (367258 Б)
- `art/sources/021-C/west.png` (347284 Б)

## Намеренно НЕ удалено

- **Восемь PNG C + действующая тень** `ElectrifiedMainline/graphics/entity/35kv/pole-*-012.png`, `pole-shadow-4dir-hr.png`: реально используются `prototypes/power_019.lua`, важнейшая часть игры.
- `hidden-pole-012.png` и `contact-wire-hr.png` — ссылки существуют в прототипах; без них возможна ошибка загрузки.
- `docs/tests/evidence/021-six-screenshots-contact.jpg` — наглядное доказательство ошибочного поворота мачт из пользовательского теста 0.1.21; требуется, пока проверяется 0.1.22.
- `dist/ElectrifiedMainline_0.1.8.zip` — сохранённая проверенная стабильная версия; не путать с архивом старой экспериментальной 0.1.21.
- `scripts/sprites/*`, `art/sprites/manifest.json`, `.github/workflows/sprite-pipeline.yml` — действующие автономные инструменты **демо/статического контроля** изображений, пригодятся для следующей работы над контактной сетью; **не используются как прямые игровые спрайты**.
- `docs/research/`, `docs/tests/`, `docs/history/`, `AGENTS.md`, `PROJECT_CONTEXT.md` — документация принятия технических решений и проверки механик; удаление уничтожило бы контекст будущих чатов.
- `Исходник_v2.1.20b/` — локальный справочник по модифицированным прототипам/железнодорожным файлам; пока не найден подтверждённый безопасный заменитель, оставлен.
- Старые Git-ветки и коммиты: НЕ удалялись; есть ссылки из отчётов и возможность восстановить старые экспериментальные состояния.

## Проверяемые инварианты

1. **Нет изменений Lua, JSON-прототипов, игровых PNG, данных/управления/электричества.** Версия и содержание `info.json` остаются **0.1.22**.
2. Остаётся восемь кадров C и действующая тень, выбранная пользователем художественная проекция ЮГ≈ВОСТОК, СЕВЕР≈ЗАПАД.
3. Исправленный выбор `n.face` из `scripts/mast_facing_022.lua` в исходниках сохранён, но в Factorio ещё проходит проверку пользователем.
4. Рабочие API тесты и CI не должны требовать удалённых PNG, архивов и TXT. **После очистки успешно прошли Lua-проверки и упаковка мода:** [GitHub Actions #43727816486](https://github.com/zukera2-stack/Factorio/actions/runs/43727816486), [очищенный ZIP](https://github.com/zukera2-stack/Factorio/actions/runs/43727816486/artifacts/14167038465). Проверку новой ориентации непосредственно в Factorio всё ещё выполняет пользователь.
5. **Установочный файл 0.1.22, проверяемый пользователем**, зафиксирован предыдущим успешным запуском [Actions #43725722949](https://github.com/zukera2-stack/Factorio/actions/runs/43725722949/artifacts/14166570620); результаты его игрового теста относятся к тому артефакту, не к новым неподтверждённым изменениям.
6. Сам фактический ZIP без удалённых старых памяток и атласа будет иметь изменённый SHA; это **не изменение игрового кода**.

## Восстановление и дальнейшая работа

Оригиналы концепта C доступны только по истории: [source art](https://github.com/zukera2-stack/Factorio/tree/64f81365ae5aa654d9b6cca1598cd30cc98289b3/art/sources/021-C); [старый ZIP](https://github.com/zukera2-stack/Factorio/blob/64f81365ae5aa654d9b6cca1598cd30cc98289b3/art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip). Для дальнейшего арта хранить оригиналы локально или в отдельном личном хранилище, **не возвращать в текущую рабочую ветку** без новой необходимости. Следующая задача — завершить пользовательский тест ориентации мачт на прямых, кривых A/B и полудиагоналях, затем заняться визуализацией контактной сети. Реального питания пока нет (`transfer_MW=0`). 

## CI после очистки

- Source commit: `59d8e362ccefeb36447b62808a18bd65563bc5d2`.
- Build: [GitHub Actions #43727816486](https://github.com/zukera2-stack/Factorio/actions/runs/43727816486) — **SUCCESS**; Lua syntax/regressions and ZIP integrity completed.
- Packaged mod ZIP: [artifact #14167038465](https://github.com/zukera2-stack/Factorio/actions/runs/43727816486/artifacts/14167038465) (nested `ElectrifiedMainline_0.1.22.zip`).
- Documentation CI failed on first cleanup commit because two old Markdown links pointed at deleted `art/sources/021-C/README.md`; links corrected to immutable Git history in the follow-up commit. **Docs validation must be rerun and confirmed before marking this part PASS.**
