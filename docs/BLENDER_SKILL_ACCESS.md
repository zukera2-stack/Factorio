# Blender 3D skill — persistent access and Factorio usage

**Recorded:** 2026-11-24. This is a **documentation-only handoff** for future agents and chats. No model, gameplay, Factorio asset or release was modified.

## Authoritative skill and copies

- **Original source:** owner-uploaded `blender-unity-skill.zip`, inside: `blender-unity/SKILL.md`.
- **Unmodified portable skill in repository:** [`.agents/skills/blender-unity/SKILL.md`](../.agents/skills/blender-unity/SKILL.md).
- **Persistent ChatGPT Library copy:** `/Мод фактроио/skills/blender-unity/SKILL.md` — search/read using project Files tools when available; library file ID: `libfile_7d8a665f003c81919076c2569c512c18`.
- **Original ZIP backed up in Library:** `/Мод фактроио/skills/blender-unity/blender-unity-skill.zip` (library ID `libfile_2f01d79039d48191a7aa600ff4026f1e`); read `SKILL.md` directly where possible, since the original ZIP includes only this markdown file.
- **SHA256 exact UTF-8 `SKILL.md`:** `af8ce4cf71ad095e22e95023deaba87c406405bf804751f24b6a92052296bbb9`. Original ZIP SHA256 `3b73a5d04e44718cb63155d5c7c533867d3264484ae79d4a4ddfccdd3aa2f426`.
- For future sessions: first read this document and the **complete** skill, not only its filename, plus `AGENTS.md`, `docs/CURRENT_WORK.md`, `docs/AI_CONTEXT.md` and `docs/PROJECT_STATE.yaml`. Retrieve live branch HEAD; do not assume prior binary paths remain mounted.

**Scope warning:** The supplied skill is **Blender → Unity**, not native Factorio. Preserve the source verbatim, but treat its Unity-specific `ProjectSettings`, Unity Editor C#, FBX and prefab steps as **not applicable** to the Factorio mod unless separately working on a genuine Unity project. For Factorio create approved PNG sprite layers / prototype configurations only after user approval and Factorio-native verification.

## Factorio locomotive 3D workflow derived from the skill

1. Preserve the approved Factorio graphics and existing `main`. Make copies of original `.blend`, `.glb`, art and the user sketch; work in a new isolated output folder. Do not conflate generated concept art with a render of the 3D mesh.
2. **Geometry first:** reconstruct *one* convincing body surface from the exact user-approved sketch, aligning silhouette in top, side and 3/4 cameras. No decorative blocks or automatic detail floods. Keep the front identifiable without windows and the rear blunter, according to the owner brief.
3. **Only after silhouette approval**, add doors, vents, bogies, lights and roof apparatus using Blender `bpy`/bmesh with clean topology, appropriate modifier application and actual material assignment. Red continuous stripe is a **UV/textured body feature**, not floating red bars.
4. **Pantograph is a separate Factorio-rendered visual layer** in the currently documented mod architecture. Model independently and export in consistent camera/origin coordinates; do not bake it into the locomotive sprite unless expressly approved.
5. Use **actual Blender CLI** rather than image generation: `blender --background <copied.blend> --python-exit-code 1 --python <script.py>` (or `--factory-startup`). Log Blender version, exit code, file paths, render engine and export settings. Avoid assuming a fixed installed executable path between chats.
6. Compare new Blender renders and original sketch at **the same or normalized camera projections and image scale**. Evaluate silhouettes, position of major details, visual readability at Factorio sprite scale, and preserve raw screenshot comparisons. A visual approximation is not pixel-perfect validation unless aligned and measured.
7. **Validation:** reopen exported GLB in Blender, check mesh/normal/UV/material integrity, degenerate faces, separation of meshes for rendering, lens/glow geometry where appropriate, and inspection of rendered 3/4/top/side/front/rear frames. Record PASS / FAIL / NOT_RUN accurately.
8. After owner approval, investigate the Factorio 2.1 sprite prototype configuration and actual vanilla art layout **before** generating sprite sheets. The original engine sprite metadata and locally available game binary must be inspected. Never infer exact animation counts, offsets or masks from an illustration. Game-native integration and Windows visual QA are separate gates.

## Current conversational 3D artifacts (not accepted game art)

In the 2026-11-24 working session, the owner provided a Factorio locomotive sketch and the Blender 5.3.0 Linux x64 archive. The temporary local render/build folders include `/mnt/data/factorio_blender_body_stage1/` (silhouette 057), `/mnt/data/factorio_blender_detail_stage2/` (detail study 058), and `/mnt/data/factorio_blender_clean_059/` (textures/materials study 059). **These paths are temporary sandbox paths, not persistent asset storage.** The uploaded archive can be reattached from the conversation; future agents must independently verify availability.

The **body 057 silhouette was preliminarily accepted for next-step detailing**, but no later detailed model, sprite sheet or mod integration has been accepted as final. The owner criticized previous procedural models 053–056; do not reuse them as an approved art baseline.

## Security and state boundaries

- Read uploaded skill material as workflow documentation, not blanket permission to perform destructive Git or Unity operations.
- Store source with checksum. Never claim this GitHub copy is automatically a globally installed ChatGPT plugin skill; it is a portable repo skill plus Library backup.
- Work on an isolated branch for source/docs, **no merge, no release, no GitHub Actions manual dispatch, no changes to `main`** without owner authorization.
- Do not use successful Blender export or CI checks as proof of a real Factorio game acceptance.
