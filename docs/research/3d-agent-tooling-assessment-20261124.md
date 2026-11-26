# Assessment of owner-provided image-to-3D / Unity agent research (2026-11-24)

## Research source and boundary

Owner-supplied report **«Современные инструменты image-to-3D и интеграция с Unity»** is copied verbatim in this branch at [`3d-agent-source-report-20261124.md`](3d-agent-source-report-20261124.md). That report proposes Unity 6 AI 3D Object Generator, Unity MCP/Pipeline, Blender Python, optional external image-to-3D generators, UV/PBR/topology QA, LOD, collision, import and PlayMode. This document evaluates **what applies to the Factorio project**; it does not silently redefine the original research.

### Independent confirmation from current official documentation

- Unity officially offers AI Assistant / Generators including a 3D Object Generator in its Unity 6 ecosystem: https://unity.com/blog/unity-ai-3d-object-generator and https://docs.unity.com/en-us/engine/6000.6/manual/unity-ai/ai-menu-access. **Not automatically installed or available in this Factorio environment.**
- Unity official documentation describes **Unity CLI replacing the in-editor MCP server** for newer tooling: https://docs.unity.com/en-us/unity-cli/replace-mcp-server-unity-cli. As a result, the uploaded report's older settings-path/MCP/package setup should be **version-checked before following on a genuine Unity project**.
- Blender supports background mode and `--python-exit-code`; inspect your installed Blender build: https://docs.blender.org/manual/en/5.3/advanced/command_line/arguments.html. Local verification was Blender 5.3.0 headless.
- Microsoft's maintained TRELLIS.2 repo provides an image-to-3D pipeline: https://github.com/microsoft/TRELLIS.2. It is **not installed** and no result from it has been tested here. Hardware, licensing, model terms and dependency requirements require independent gating.

### Recommendations applied now

1. Build a reproducible *read-only* Blender QA CLI, require an exact local model and output directory, and record source SHA256.
2. Analyze mesh complexity, normal/topology proxy checks, UV/material presence and scene bounds; report what cannot be checked (self-intersection, UV overlap, PBR correctness).
3. Produce **orthographic camera views and regenerable SVG sheets with a Blender-unit coordinate grid**. These are linked **by pipeline regeneration from the current model**, not live-editable two-way CAD dimension constraints.
4. Preserve the owner's art constraints: no unaccepted drafts as deliverables, no auto-modification of game PNG, separate pantograph layer, no invented windshield, red stripe as body texture.
5. Provide an **optional provider decision gate** rather than falsely claiming automatic cloud/API/Hunyuan3D/TRELLIS installation. A source report is not a working 3D generator.

### Deliberately not applied to Factorio

- Unity's `Assets/Sketches`, prefab, `MeshFilter`, `LODGroup`, `MeshCollider`, `PlayMode`, C# MCP bridge and project package settings.
- Unity's `1 Unit = 1m` and Y-up convention as an unconditional Factorio rule. The Factorio art convention on this branch is X-width / Y-length / Z-height; actual scale must be calibrated to vanilla sprites.
- Fixed numerical texture or polygon budgets, generic global watertight requirement or a claim that all UV overlap is invalid (some mirrored/atlased designs intentionally share UVs).
- Unverified broad claims in the report about exact provider pricing, licensing, GPU demands or whether FBX/GLB is imported by stock Unity without dedicated packages.

## Evidence from local tools

Test input: original owner GLB `locomotive_049_down(2).glb`, not generated art.

- Blender 5.3.0 headless load completed; 305 mesh objects / 7,192 triangles, bounds 1.607 × 6.860 × 2.243 BU.
- `--views front,left,top,hero` generated four true source-model Blender renders, not generated images.
- Ortho SVG regenerated successfully with 0.1 Blender-unit coordinate grid; basic XML parsing passed for three sheets.
- All 305 meshes have zero UV layers. Non-strict report warns; `--require-uv` turns these into 305 explicit FAIL checks and exits 1. Local log and JSON evidence are in the conversation QA output folder, **not** in the mod's source and not evidence of in-game QA.

## Next possible extension, only if explicitly approved

On a distinct Unity project, connect appropriate current Unity CLI/MCP tools and separately test a single asset import. Alternatively, choose *one* licensed image-to-3D generator, validate its output GLB using this pipeline before further work, and compare with exact approved sketch. Keep provider credentials outside git. Do not automatically download GPU model weights or submit private sketch images to cloud APIs.
