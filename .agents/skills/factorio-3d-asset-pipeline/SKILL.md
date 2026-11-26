---
name: factorio-3d-asset-pipeline
description: Inspect Blender/GLB 3D assets, produce reproducible 3D-derived technical views, and gate Factorio locomotive sprite art without drafts or unjustified game acceptance claims.
---

# Factorio 3D — agent workflow after 2026-11-24 research

## Read before running

1. Read root `AGENTS.md`, `docs/CURRENT_WORK.md`, `docs/AI_CONTEXT.md`, `docs/PROJECT_STATE.yaml` on your **actual working branch**; verify GitHub refs.
2. Read `docs/BLENDER_SKILL_ACCESS.md` and `docs/3D_ASSET_PIPELINE.md`.
3. Read the owner's original portable skill `.agents/skills/blender-unity/SKILL.md` **without altering it**. Unity-specific instructions are not applied to Factorio.
4. For report provenance read `docs/research/3d-agent-source-report-20261124.md` (raw owner research) and `docs/research/3d-agent-tooling-assessment-20261124.md` (verified interpretation).

## Non-negotiable owner constraints

- **Do not deliver intermediate draft/blockout locomotives** to the owner as finished work. Iterations may be internal, with the final version supplied only after actual checks.
- Produce **real 3D geometry and real Blender renders**; never substitute AI-generated illustrations for a model render.
- Do not edit original `.blend`, `.glb`, sketch, Factоrio game sprites, `main`, saves or releases without explicit permission.
- For approved locomotive art: distinguish sharper front and blunt rear, **no invented windshield**, preserve approved shape and material palette; red continuous line is a **UV texture**, not protruding red geometry. Pantograph is normally exported separately for the current Factorio rendering architecture.
- Geometry source should drive derived projections; do not hand-paint unlinked top/side/front images and claim they are synchronized CAD drawings.

## Standard local tool invocation

Use Python + Blender (5.3.0 verified locally for the smoke test). Locate the installed Blender binary; no hardcoded sandbox path is persistent. Use absolute paths and a fresh output directory.

```bash
python3 tools/3d/asset_cli.py --blender /absolute/path/to/blender \
  --input /absolute/path/to/owner_asset.glb \
  --output /tmp/asset-qa-new-unique --views front,left,top,hero --require-uv
python3 tools/3d/ortho_sheet.py --qa-dir /tmp/asset-qa-new-unique --grid 0.1
```

The command is offline and read-only on source. It runs Blender with `--disable-autoexec`, collects JSON + log + orthographic PNG; the second tool embeds the rendered PNG beneath a vector grid in SVG. Do not call these outputs *precision blueprints* without calibrated dimensions and verified camera conventions. Source `.blend` can contain nonmesh reference planes; use a dedicated mesh-only export when appropriate.

## Mandatory QA interpretation

- **PASS** means only the implemented, explicitly reported automated checks passed. See `limitations` for `NOT_RUN` / limitations. A known missing UV is a WARN when the UV gate is off, a FAIL when `--require-uv` is on.
- Mesh topology: nonmanifold and degenerate face counts are per mesh. Do **not** call this proof of zero intersections between distinct meshes.
- Strict watertight requirement only for solids which really need it. Open visible surfaces are allowed for art; make that explicit.
- Check material nodes and UV quality manually; tool reports *presence*, not UV-overlap-free or PBR-correct. Color accuracy requires a final material-capable renderer (e.g. Blender Cycles); Workbench QA PNGs are only for geometry.
- After final art approval, derive Factorio-specific directional body and pantograph visual sheets, compare pixel scale against vanilla in identical rail layout, verify contact headlight logic and visual masking on a real Factorio 2.1 run. A GLB cannot by itself be used as Factorio locomotive sprites.

## Optional AI generator gate

Unity AI / Meshy / Tripo / Rodin / Hunyuan3D / TRELLIS.2 are **not installed or connected as part of this tool**. Use them only after recording owner authorization to send sketch data, license and cost constraints, local GPU capability or provider API availability. Never infer successful generator operation from the owner's research report. Re-open provider output through Blender inspection; no silent asset replacement.
