# 3D assets — agent toolchain and acceptance protocol

**Recorded:** 2026-11-24. **Project:** Factorio / Electrified Mainline. **Status:** auxiliary 3D inspection tools tested locally; **no approved replacement locomotive, no sprite changes or in-game integration**.

## Why this exists

The owner supplied the research report **«Современные инструменты image-to-3D и интеграция с Unity»** (verbatim archival copy: [`docs/research/3d-agent-source-report-20261124.md`](research/3d-agent-source-report-20261124.md)). Its core value for this Factorio project is the **sketch → mesh → validation → materials/UV → reproducible renders** workflow, not Unity Prefabs or Unity-side testing. The report proposes image-to-3D generators (Meshy, Tripo, Rodin, Hunyuan3D, TRELLIS.2), Blender `bpy` automation, MCP/Unity CLI, LOD and mesh checks. Those are **candidate capabilities**, not proof any service is installed, provisioned or suitable for final art.

The owner expressly asked **not to deliver draft/blockout 3D versions**. Working hypotheses, automatic generation candidates, and rejected geometry remain internal. User-facing 3D output must be the final, inspected asset with source file, GLB, verified render comparisons and honest acceptance status. No newly generated concept images may stand in for actual 3D renders.

## Working model: Blender is authoritative for Factorio

1. Retrieve the **exact owner-approved image and source geometry**. Record SHA256 of every input, source coordinates and license. An attractive image with three apparent views may be a *perspective collage* rather than physically consistent orthographic projections; annotate inferred dimensions, never label them measurements.
2. Prefer Blender **5.3+ with `bpy`** and named, editable meshes; set local axes: **X = width, Y = front-to-back length, Z = height**. This is the Factorio-art working convention, **not** the Unity global axis convention. Use verified scale, axle centers and silhouette; keep the approved nose, no new windshield, blunt rear, and a UV/textured red livery stripe. The pantograph remains **a separately rendered Factorio layer**.
3. If an image-to-3D service is later authorized and technically available, treat its exported GLB as an **untrusted candidate**. Check permission/licensing, provenance, inference-hardware requirements and generation disclosure; do not auto-replace any approved mesh or user file. Meshy/Tripo/Rodin are not installed in this repo. Hunyuan3D and TRELLIS.2 are **not installed/proven here**. Nothing automatically calls paid APIs or starts model downloads.
4. Run the **local read-only mesh inspector** below before adjusting or shipping. It emits JSON, logs and optional orthographic Blender render PNGs. Use `--require-uv` on textured/final assets and `--require-closed` only where a closed solid is actually required (e.g. watertight collision mesh). Reject real `FAIL` and investigate warnings.
5. Generate orthographic **geometry-derived** SVG sheets with a world-unit grid via the `ortho_sheet.py` helper. These SVG sheets are refreshed by **rerunning the tool on the revised 3D source**; they are *not* live editable two-way CAD sketches and are not a substitute for FreeCAD TechDraw or a verified Blender drawing extension. They use Blender cameras; no ad-hoc re-painted projections.
6. Independently compare silhouette, material arrangement, nose/roof/bogies and details to the approved image with calibrated cameras. An image-to-3D model can invent hidden geometry. Only call views “pixel-perfect” after quantitative alignment and measurement. The optional QA PNG is technical, not a final-quality Cycle render. The source report's Unity LOD/Collider/Prefab steps do **not** apply to a Factorio sprite mod; optimize rendered sprite size and directional consistency instead.
7. Once **owner approved**, inspect the actual Factorio 2.1 prototype/vanilla sprite metadata before rendering final directional sheets. Preserve unchanged mod code/graphics until native engine testing (including pantograph overlay, scale relative to vanilla stock, and working headlight) and explicit merge approval.

## Tool entry points

- `tools/3d/asset_cli.py` — standard-library Python CLI for Blender QA, no external API or network.
- `tools/3d/blender_asset_qa.py` — executed *inside* Blender, read-only on source model; supports `.blend`, `.glb`, `.gltf`.
- `tools/3d/ortho_sheet.py` — SVG 0.1 Blender-unit grid over the **actual orthographic** Blender QA render. SVG embeds PNG so it opens standalone; regenerate after editing source model.

### Example (Windows PowerShell)

```powershell
$Blender = 'C:\Program Files\Blender Foundation\Blender 5.3\blender.exe' # verify actual path
py tools/3d/asset_cli.py --blender $Blender `
  --input 'D:\assets\locomotive.glb' --output 'D:\assets\qa-locomotive-001' `
  --views front,left,top,hero --require-uv
py tools/3d/ortho_sheet.py --qa-dir 'D:\assets\qa-locomotive-001' --grid 0.1
```

### Example (Linux)

```bash
python3 tools/3d/asset_cli.py --blender /absolute/path/to/blender \
  --input /absolute/path/to/model.glb --output /tmp/asset-qa-unique \
  --views front,left,top,hero --require-uv
python3 tools/3d/ortho_sheet.py --qa-dir /tmp/asset-qa-unique --grid 0.1
```

**Use a fresh empty output folder.** The CLI intentionally refuses overwriting a nonempty directory. It does not save or re-export the input 3D file. It runs Blender with `--disable-autoexec`, redirects process output to `blender.log`, and honors Blender's exit code; `--require-uv` or `--require-closed` can make a model fail. No downloads, cloud connections, GitHub Actions, game runs or Unity calls occur.

## What the checks actually prove

| Check / evidence | Automatically inspected | Important limitation |
|---|---|---|
| Mesh count, triangles, Blender-space bounds | Yes | Bound dimensions are in Blender units, not certified metres/Factorio collision boxes |
| BMesh degenerate faces, boundary/nonmanifold edges | Yes | Not a global proof of self-intersection-free geometry; intentional open surfaces may be valid |
| UV layers and material/image nodes | Yes, *presence* | **UV overlap and PBR material correctness NOT_RUN** |
| Blender ortho renders | Yes, from actual input | Not a calibrated comparison to artistic reference; no automatic silhouette match |
| Orthographic SVG with grid | Yes, regenerable from 3D | Not a parametric dimension-constraint or live CAD drafting system |
| Real Factorio sprite/game visuals and headlight | **NOT_RUN** | Requires game-compatible sprite export, prototype setup and native/GUI acceptance |
| Unity mesh import, Prefab, Collider, LOD, PlayMode | **NOT_APPLICABLE for Factorio** | Optional separate Unity-project workflow only |
| Image-to-3D model generation | **NOT_INSTALLED/NOT_RUN** | Needs owner-chosen provider/hardware/license and dedicated integration |

## First local verification (2026-11-24)

Input: owner-provided `locomotive_049_down(2).glb` (original reference model). Blender 5.3.0 CLI, image generator disabled. **Read-only QA run:** importer success, 305 mesh objects, 7,192 triangles, dimensions approximately X=1.607, Y=6.860, Z=2.243 BU, 0 detected degenerate faces and 0 nonmanifold edges **within individual evaluated meshes**. All 305 mesh objects have **0 UV layers** (WARN in inspection-only mode); a second test with `--require-uv` returned **FAIL and exit code 1**, as designed. Orthographic front, side/left, top and three-quarter Blender QA PNGs rendered; `ortho_sheet.py` produced parseable standalone front/left/top SVG sheets. These findings do not certify no inter-mesh overlaps or Factorio compatibility.

## Source research, confirmed vs caution

Read [`research/3d-agent-tooling-assessment-20261124.md`](research/3d-agent-tooling-assessment-20261124.md) for citations and caveats. Of particular importance, Unity has AI Object Generator and CLI, but official docs now describe migration away from earlier *in-editor* MCP integration to a Unity CLI-based MCP route. Do not hardcode a 2026 beta menu path/package name in Factorio. No unity project or `Assets/Prefabs` was created here.

## Release boundary

This update adds only **optional agent-side tooling + docs + portable skill**. No `ElectrifiedMainline` Lua, PNG sprites, `info.json`, player saves, `main` nor any approved mod graphics are changed. No new 3D design accepted. All pre-existing design and gaming defects remain independent of this QA helper.
