# EM143 — verified owner runtime 0.2.7 recovery (2026-11-28)

**RECOVERY ONLY — not a runnable 0.2.7 GitHub tree, no release, no new runtime fix.** Branch starts from EM138 0.2.4, which is four commits ahead of main and zero behind. The existing EM137/EM138 branches are unchanged.

- Owner unpacked runtime version 0.2.7, exactly 508 files, 428 PNG and 4 OGG. Fresh SHA256 over sorted relative paths + NUL + binary SHA256 per file matched EM142 canonical payload: `d601301c6bc71bc15f83dd1826e806e3f3a5493654e4f9b1347b8eee4d05e2bd`.
- New verified local recovery ZIP: `%TEMP%/EM143-recovery-9xpylrjt/ElectrifiedMainline_0.2.7_recovery.zip`; 111685346 bytes, SHA256 `e1384253a857583666cd84e62d259186fdfdc106c52e739dcee7f9a8c29ca3ec`. ZIP CRC and byte-for-byte comparison of all files passed; installed tree rechecked unchanged after packaging. ZIP container hash differs from EM142 canonical ZIP; payload identical.
- [Complete owner manifest](EM143_OWNER_0.2.7_MANIFEST.json), 508 per-file SHA256 and Git blob SHA1 values. EM142 original backup `%APPDATA%/Factorio/EM142-backups/20261128-091435` also exists.
- EM139 audio accepted per EM140 report; EM140 draw-position correction native PASS and isolated Windows formula screenshots; EM142 report documents 256 directions, 4096 atlas phases, 9399 consecutive phase checks, 536 speed changes and isolated Windows screenshots; subjective smoothness, elevated rails, full regression, actual save upgrade, multiplayer and UPS remain unconfirmed.
- Evidence archives in Library /Factorio Electrified Mainline/Archive/QA/EM139_0.2.5_QA.zip, EM140_0.2.6_QA.zip, EM142_0.2.7_QA.zip.
- Direct Git on owner PC failed DNS resolution of github.com; GitHub connector works for metadata. No runtime source transfer complete. Do not package this branch as 0.2.7, substitute older graphics, or apply a patch from 0.2.4 to owner 0.2.7.
- Next: transfer exact 0.2.7 payload, regenerate repository integration manifest, verify all 508 files against this manifest, run isolated tests of Issues #73/#74/#77/#78 and published 0.2.0 save upgrade, then decide any actual bugfix scope/version. Never close old issues on historical evidence alone.

No owner mod/saves modified; no new native game tests, main merge, publication or CI in this recovery step.
