# 0.1.49 — первая пространственная модель электровоза (прототип)

Источник: [утверждённый эскиз](../plans/LOCOMOTIVE_ART_049.md), без кабины, остекления и фар. Оригинальная процедурная модель из mesh-деталей, не набор независимых AI-картинок. Генератор [model_049.py](../../scripts/sprites/model_049.py) сохранён побайтно (Git blob cc76c42be6e2319f7b44d7b95c404d5b63007392). Использует numpy, trimesh, vtk 9.6.2 (EGL), Pillow.

## Воспроизведение
```sh
python scripts/sprites/model_049.py --out build/qa/locomotive049 --views 8
```
Для GLB без VTK-рендеринга: --no-render. Параметр --views 256 предусмотрен, массовый рендер ещё не выполнялся. Все результаты в build/qa, не каталог runtime.

204 исходных компонента: 178 общих (включая одну отдельную цветовую полосу mask), по 13 деталей двух состояний пантографа. GLB по 191 mesh, загружаются trimesh без ошибок. 8 ракурсов на состояние, 16 RGBA кадров 512x512, проверен alpha 0..255. Повороты камеры 0..315 градусов с шагом 45; это ещё не индексы Factorio orientation. Верхняя точка модели 3.2625 условной единицы (up), 2.2625 (down); габариты 6.24×1.607, включая сцепки. Эти значения не утверждены в игровых тайлах. Native camera/pivot, couplers, bogies, color mask compositing, shadows и native draw order ещё не откалиброваны. 3D-полоса отдельна, но фактический runtime tint PNG и отдельные passes ещё не построены. Без анимации, света и искры. Детализация корпуса проще принятого эскиза, без излишних человеческих деталей; требует визуального согласования перед production.

## Локально созданные proof artifacts (не загружены как бинарные файлы в Git)
- locomotive_049_up.glb SHA256 e00bed89b62ead8feda6b21e59ad96a1422424adef45c88033f084ae78ba7bed
- locomotive_049_down.glb SHA256 fd8b650d55a36f3e6ec5b8c7bdcfda78456d34318caaffcc18471a234fd89993
- preview_049.png SHA256 fd6b1c6ae1c98d7415585d9919cc6e7380c126d012bdba7113ca69dbd5a80058
- model_049.py SHA256 b35651f3211c7c7ef83ec673a53fd882d35c04dca507da57b4f0c6cb4df326f2

Предварительная модель не является готовым игровым спрайтом; 256 направлений не выпущены. Не добавлять к моду и не менять info.json до native probe. Новые ZIP только через GitHub Actions. main и runtime payload без изменений.

## Refined v2
See [refinement and scale calibration](locomotive-calibration-049.md). The original model/proof hashes above refer to the historical v1; the renderer now has an optional calibration flag preserving default behavior.
