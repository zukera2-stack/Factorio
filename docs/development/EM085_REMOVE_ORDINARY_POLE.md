# EM085 — Remove obsolete ordinary factory pole

Status: **locally tested Direct Patch**, not Windows acceptance or release. User explicitly requested complete removal of the duplicate "Электрическая опора" (em-electric-pole) seen in a chest; **do not touch** the 25 kV catenary poles em-35kv-catenary-pole / em-35kv-catenary-pole-north, hidden technical network masts, substation, or any vanilla power pole.

Base: owner-confirmed EM082 archive + EM083 raised-panto patch + EM084 wagon-GUI patch, exactly version 0.1.84. Deliver **Direct Patch 0.1.84 → 0.1.85**, only 7 replacement files: data.lua, info.json, scripts/control.lua, prototypes/bootstrap.lua, locale/en/en.cfg, locale/ru/ru.cfg, migrations/0.1.85.json. ZIP SHA256 `e01c4935c9d3fd323a91bbe64430764da725570a9758da3664824218a87389f8`, 17099 bytes. Library file: `/Factorio/Patches/EM085_remove_obsolete_pole_Direct_Patch_from_0.1.84.zip`.

Changes:
- Remove em-electric-pole *item*, *recipe*, cloned electric-pole entity, technology unlock, and all four localization keys in each language.
- Delete legacy retired prototype module from GitHub (`prototypes/em063_retire_ordinary_pole_064.lua`), remove require in data.lua and unused on-built handler from scripts/control.lua.
- **JSON migration** `migrations/0.1.85.json`: entity and item `em-electric-pole` → base `small-electric-pole`. This avoids discarding old placed poles and inventory stacks; already placed poles become a normal vanilla entity. This does NOT create a new mod pole or change catenary.
- ZIP extraction cannot remove legacy files from already unpacked folders. User must also delete exactly `ElectrifiedMainline/prototypes/em063_retire_ordinary_pole_064.lua` manually after extraction; the unused file is harmless if left, as its require is gone, but source checkout removes it.

Validation on actual Linux Factorio 2.1.24 headless with full mod and Space Age:
1. Fresh 0.1.85 map generated without prototype errors. Old `em-electric-pole` not registered.
2. On 0.1.84, created *real* `em-electric-pole` at (0.5,0.5) and steel chest at (15.5,15.5) holding **7** old pole items; saved fixture using headless server console.
3. Loaded a **copy** of that save under 0.1.85, Factorio JSON migration: **PASS**. At (0.5,0.5) exactly one `small-electric-pole`, chest has 7 `small-electric-pole` items, old entity and item prototype absent. Log contains `EM085 MIGRATION PASS`; no external network access or user saves modified.
4. Applied ZIP over extracted 0.1.84 folder, leaving old no-longer-required module on disk to simulate simple manual overwrite; benchmark on upgraded full save **30 ticks PASS**. Original 0.1.82 owner archive SHA256 ed60bbfe6a1027adceb1d8ecc910624d360ba9f9bda5b9cb6af906033a762f80 preserved.
5. Direct ZIP CRC & exact per-file SHA256 checked. Art, electric traction, motor wagons, pantograph and native base power network unchanged. No Windows test. Do not call this EM085 fully accepted until owner checks version 0.1.85 and inventory/placement.

QA: Linux log `/Factorio/Local-QA/native/EM085_*.log`; manifest `/Factorio/Patches/EM085_manifest.json`; build recipe `/Factorio/Patches/EM085_build.py`. Full binaries are in GPT Library, not automatically committed to GitHub. Main remains unchanged.
