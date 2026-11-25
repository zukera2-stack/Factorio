# GPT Library — working mod recovery (2026-11-25)

Owner explicitly requested persistent working copy and folder structure after adopting Direct Patch. GitHub remains source/history; the owner archive is a local QA snapshot, not a release or repackaged CI distribution.

## Library paths
- /Factorio/Working-Mod/ElectrifiedMainline_0.1.82_owner.zip — exact owner upload, 25,074,586 bytes, version 0.1.82, 156 files (99 PNG + 57 other files), SHA256 ed60bbfe6a1027adceb1d8ecc910624d360ba9f9bda5b9cb6af906033a762f80. Contains single ElectrifiedMainline/ root.
- /Factorio/Working-Mod/EM082_owner_baseline_manifest.json — per-file SHA256 and archive provenance.
- /Factorio/Patches/ — sequential Direct Patch ZIPs and separate manifests. EM082_manual_patch_from_081.zip and EM082_manual_patch_manifest.json archived.
- /Factorio/Models/ — Locomotive_v3.glb, Locomotive_v3_body.glb, Locomotive_v3_pantograph.glb, Locomotive_v3_source_QA.zip, EM080_render_source_QA.zip. Original accepted V3 models preserved.
- /Factorio/Local-QA/engines/factorio-headless_linux_2.1.24.tar.xz — x64 engine (arm64 variant also available).
- /Factorio/Backups/ — future verified checkpoints, initially empty; do not duplicate current snapshot just to fill folder.
- /Мод фактроио/00_СТАРТ_АГЕНТА_Factorio.md — project startup handoff.

## Startup for a new agent
1. Read startup file, then live branch and AGENTS.md, CURRENT_WORK.md, AI_CONTEXT.md, PROJECT_STATE.yaml. Current working branch experiment/em082-wheel-visibility; game source commit a71f98e7352c36e63b1a220e55c45496c1d01e31. Main remains historical accepted 0.1.62 development baseline, not current Direct Patch base.
2. Locate archive and manifest using Library tools; materialize to isolated local QA directory. Do not assume a local path persists between chats. Verify archive SHA256, CRC, version, safe unique paths and per-file manifest before extraction. Compare with selected GitHub source and staged artwork contract. Initial owner archive validated: CRC PASS, no unsafe or duplicate paths, 156 entries; FNV-1a-32 fingerprint of sorted path + tab + hash + newline list (Git blob SHA1 for non-PNG, SHA256 for PNG) matched live source/manifest 14a9d8ce. This is a compact consistency check, not independent cryptographic proof of full equality. Exact owner archive SHA256 is authoritative for recovery.
3. Preserve original owner archive; apply each next patch to a writable copy. Verify target paths, changed hashes, info.json and regression tests; run actual Linux headless full mod where possible. Deliver Direct Patch directly, without CI wait. Only update Working-Mod to next confirmed state after owner confirmation and verification. Keep previous checkpoint in Backups and exact patch in Patches, no deletion of unique evidence. Never modify owner saves. If Library access is missing, identify exact blocker and request the needed archive instead of guessing.
4. Record path, version, source commit, archive and per-file hashes, acceptance status and unresolved tasks in docs. No main/release authorization. Current pending: custom wrecks and old collector appearance; spark visual confirmation pending. No new game changes in this documentation update.

## Owner-supplied original vanilla remnants resources (2026-11-25)
- GPT Library: `/Factorio/References/Vanilla-Remnants/remnants.7z` (original owner upload, 897,000 bytes approximately; SHA256 `682efeb6c5f9b8a6213685e4232669c1b503c4ff65baad8682901b3f044d37c0`). The upload was verified as a 7-Zip archive by file signature and successfully stored in the Library.
- **Contents not yet enumerated:** 7z extraction tools are unavailable in this container. A new agent should materialize the exact Library file, list and inspect archive entries safely before comparing vanilla wreck sprites to EM083. Do not claim any specific image is inside until confirmed.
- Treat these files as original reference assets for visual comparison, not as distributable mod sprites; do not overwrite the original archive. Changes to vanilla assets or game files are not authorized.
