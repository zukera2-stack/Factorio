# 0.1.48 — live acceptance of HSR-dependent contact line

## Provenance
User report and uploaded `factorio-current(9).log`, 710 lines, SHA256 `c000d276150c02354d0ef2caf6b15efed916549642dcd5c6109910d30e85da59`. Log timestamp 2026-11-19 01:34:58 local to the game; conversation/system date 2026-11-18. Factorio 2.1.24 build 87808, Space Age, Bob's mods. Loaded save ВСМ. Version 0.1.48 confirmed by lines 59, 476, 498. Exact installation archive hash is not printed by Factorio; original and clean 048 packages have identical runtime file bytes. Clean artifact: [GitHub Actions 14478116616](https://github.com/zukera2-stack/Factorio/actions/runs/44413378503/artifacts/14478116616), source 6027c9d789cef8b6ba5ee78cce355758e76d50a6. No personal paths or full raw log committed.

## User-observed visual acceptance
- Contact network appears only when actual HSR is present.
- HSR rail ghosts do not draw/restore the contact wire.
- Replacing HSR with ordinary vanilla rail interrupts the visible span.
- These are the owner's direct game observations. The log corroborates construction events, not the pixels themselves.

## Log evidence

| Lines | Evidence |
|---|---|
| 631–633 | Legacy probe cleanup, schema 4 graph rebuild and ghost restore |
| 634–649 | One north mast placed/mined; two regular mast ghosts revived by robots at (-19.5, 2.5) and (9.5, 2.5), 29 tiles apart |
| 650–658 | Six HSR straight rails mined, x=-13,-11,-9,-7,-5,-3 at y=1 |
| 659–686 | Six native Undo events create HSR ghosts; robots build all six actual HSR rails |
| 688–692 | Two HSR rails replaced by vanilla straight rails at x=-5 and -7, y=1, tick 86583 |
| 693–706 | Native Undo tick 86839 creates two HSR ghosts and marks vanilla rails for demolition; robots remove vanilla rails and build actual HSR at ticks 86900/86902 |
| 707–710 | Normal user quit |

Seven Undo events total in this session; no Redo observed. No Lua error, exception or traceback found. No EM048 pair/status output or network_id measurements. Construction from placed mast ghosts is confirmed; their tinted preview appearance is not independently established by this log.

## Scope and status
**Game-tested, user accepted HSR-dependent visual continuity.** Freeze accepted art, 047 neighbour selection and 048 visible/technical consistency unless a reproducible defect justifies a change. No energy transfer or voltage simulation yet; physical script-origin network IDs, factory network isolation, large-map performance and full regression across all rail geometries remain open. Do not mistake the visual pass for proof of actual energy delivery or network isolation.

No main merge requested in this turn. Draft PR #27 remains separate; main 0.1.42 unchanged.

## Build requirement
User explicitly requires game ZIPs to be built by GitHub Actions. Distribute the exact CI artifact (the inner game ZIP), never a local repack. Atlas/QA artifacts remain separate. Record source commit, run/artifact IDs and checksum. This acceptance commit changes docs only and does not create a new game version/archive.
