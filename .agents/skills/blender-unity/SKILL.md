---
name: blender-unity
description: Automate Blender modeling, rigging, animation, rendering, FBX export and Unity asset import, prefab creation and validation through Python, C# Editor APIs and CLI. Use for Blender-to-Unity game asset workflows.
---

# Blender → Unity: работа автономного агента

## 1. Контракт
- Работай преимущественно через CLI, bpy и Unity Editor API; GUI только для необходимого визуального контроля. Если доступен MCP, сначала изучи его реальные инструменты и ограничения.
- Перед изменениями прочитай AGENTS.md, документацию проекта, Git status, ProjectSettings/ProjectVersion.txt, Packages/manifest.json. Определи версии Blender и Unity, render pipeline, целевые платформы, требования к ассету.
- Не меняй исходные .blend, сторонние ресурсы, пользовательские настройки, существующие .meta и чужие изменения без разрешения. Работай с копиями и отдельными выходными каталогами. Не обновляй движок или пакеты автоматически.
- Не считай наличие файла доказательством успешного импорта, а импорт — доказательством работоспособности в игре.

## 2. Обнаружение среды (Windows PowerShell)
```powershell
Get-Command blender, Unity -ErrorAction SilentlyContinue
Get-ChildItem 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -ErrorAction SilentlyContinue
Get-Content "$Project\ProjectSettings\ProjectVersion.txt"
Get-ChildItem 'C:\Program Files\Unity\Hub\Editor' -Directory
Get-Process Blender,Unity -ErrorAction SilentlyContinue
```
Установи переменные $Blender, $Unity, $Project, $InputBlend, $Script, $Output, $Logs по реально найденным путям. Проверь версию Blender через `--version`. Не запускай второй Unity на том же проекте, если он уже открыт: используй доступный Editor bridge/MCP либо изолированную копию. Не закрывай пользовательские процессы.

## 3. Матрица действий
| Задача | Blender | Unity |
|---|---|---|
| Геометрия | bpy.data, bmesh, modifiers | Mesh, MeshFilter, MeshRenderer |
| Материалы | nodes, UV, texture baking | Material, Shader, TextureImporter |
| Скелет | Armature, bones, vertex groups | ModelImporter, Avatar, SkinnedMeshRenderer |
| Анимация | Actions, NLA, F-curves, constraints | AnimationClip, AnimatorController |
| Коллизии / LOD | отдельные meshes | Collider, LODGroup |
| Проверка | render, evaluated mesh, JSON | AssetDatabase, PrefabUtility, Test Runner |

## 4. Blender: исполнение
```powershell
& $Blender --background $InputBlend --python-exit-code 1 --python $Script -- $Output 2>&1 | Tee-Object "$Logs\blender.log"
if ($LASTEXITCODE -ne 0) { throw 'Blender failed' }
```
Для новой сцены используй `--factory-startup` вместо входного файла. Python-скрипт принимает пользовательские аргументы после `--`. Применяй API данных вместо контекстных bpy.ops, где возможно. Для операторов явно задавай режим, активный объект, selection и проверяй возвращаемый статус. Перед использованием параметров экспортера проверь RNA в установленной версии. Сохраняй копию .blend и JSON-отчет.

### Геометрия
Проверь единицы, габариты, origin, pivot, нормали, UV, топологию, дубликаты, вырожденные треугольники, количество вершин и материалов. Проверяй замкнутость только там, где она необходима. Не применяй модификаторы и трансформации к исходнику без анализа влияния на rig, shape keys и анимацию. Не придумывай бюджет полигонов.

### Скелет и анимация
Сохраняй имена и иерархию костей, bind/rest pose, веса, длины костей. Не меняй масштаб костей ради подгонки позы. Проверяй нормализацию весов и лимит влияний по требованиям проекта. Для нечеловеческих существ используй Generic rig по умолчанию; Humanoid только при совместимой структуре. Проверяй root motion, FPS, длительность, замыкание циклов, скольжение ног, деформации и контакты. Запекай constraints/IK в экспортной копии при необходимости. Не обещай физическую достоверность без решателя и проверок.

## 5. Передача в Unity
По умолчанию FBX для мешей и скелетных анимаций, отдельные текстуры и исходный .blend вне Assets. Не импортируй .blend напрямую как обязательную зависимость. glTF только если проект уже поддерживает подходящий импортёр.
Пример экспортного профиля (проверить на установленной версии Blender):
```python
bpy.ops.export_scene.fbx(filepath=output_path, use_selection=True,
    object_types={'MESH','ARMATURE'}, axis_forward='-Z', axis_up='Y',
    add_leaf_bones=False, bake_anim=True,
    bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False)
```
Это стартовый профиль для выбранного активного клипа; для нескольких клипов явно управляй Actions/NLA либо экспортируй их по отдельности. Для статического меша выключи bake_anim. Проверяй выделение, статус оператора и существование результата. Проверяй масштаб и направление по тестовому ассету (например куб 1 м и стрелка вперед), не применяй двойную коррекцию осей. Blender-шейдеры не переносятся автоматически; настрой материалы под фактический Built-in/URP/HDRP.

## 6. Unity: программный импорт
Создай при необходимости отдельный C# Editor-скрипт в Assets/Editor (или существующем Editor assembly). Используй AssetDatabase.ImportAsset, ModelImporter, SaveAndReimport, PrefabUtility.SaveAsPrefabAsset. Применяй настройки только к целевым путям. Сохраняй GUID через существующие .meta. Проверяй ошибки компиляции до запуска методов. Не изменяй глобальные настройки проекта ради одного ассета.
```powershell
& $Unity -batchmode -nographics -quit -projectPath $Project -executeMethod AgentAssetPipeline.ImportAndValidate -logFile "$Logs\unity-import.log"
if ($LASTEXITCODE -ne 0) { throw 'Unity import failed' }
```
AgentAssetPipeline.ImportAndValidate — пример имени метода, агент обязан сначала реализовать публичный статический метод и проверить его компиляцию. Метод должен валидировать вход, импортировать только целевые ассеты, сохранять отчет и завершаться ошибкой при нарушении контракта. Для GPU/рендер-проверок не используй -nographics. Для Test Runner используй отдельный запуск -runTests -testPlatform EditMode или PlayMode -testResults <path>, согласно документации установленной версии; не добавляй -quit автоматически к запуску тестов.

## 7. Контроль качества
- Blender: повторно открываемый .blend, корректный FBX, отчёт с габаритами, мешами, костями, клипами, весами и предупреждениями; рендер спереди, сбоку и в перспективе при необходимости.
- Unity: импорт без ошибок, правильные масштаб и ориентация, материалы без отсутствующих шейдеров, ожидаемые клипы и rig, prefab без отсутствующих ссылок, коллизии и LOD согласно заданию.
- Для анимации: отдельная тестовая сцена, реальный PlayMode и визуальное наблюдение нескольких поз и переходов. Не утверждай, что скриншот был просмотрен, если он только создан.
- Если Blender/Unity не установлены, лицензия не активна, нет GUI/GPU или проект занят, явно отметь блокировку. Не обходи лицензирование и не подменяй реальный запуск симуляцией.

## 8. Итерации и сдача
Выполни цикл: исследование → минимальная реализация → запуск → анализ логов → исправление → повторная проверка. Остановись при необходимости опасных или неразрешенных изменений. Не публикуй приватные ресурсы и не коммить/не объединяй ветки без разрешения.
Отчет: версии и команды, входные/выходные файлы, изменения, реальные коды выхода, логи, результаты каждой проверки PASS / FAIL / BLOCKED / NOT_RUN, ограничения и следующий шаг. Сохрани исходник, экспорт, prefab (если создан), отчёт и визуальные доказательства. Не выдавай NOT_RUN за PASS.

## Документация
- https://docs.blender.org/api/current/
- https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html
- https://docs.unity3d.com/6000.0/Documentation/Manual/EditorCommandLineArguments.html
- https://docs.unity3d.com/6000.0/Documentation/ScriptReference/ModelImporter.html
