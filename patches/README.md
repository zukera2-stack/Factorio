# Direct Patch registry — metadata only

This directory contains **small text metadata**, not distributable ZIP files, generated PNGs or user saves. Canonical policy: [Direct Patch workflow](../docs/development/DIRECT_PATCH_WORKFLOW.md). Test tooling: [scripts/direct_patch.py](../scripts/direct_patch.py).

* `registry.json`: strictly sequential patch history. Every entry provides source/target versions, patch SHA256 and exact **GPT Library** location, verified acceptance evidence/status and manual deletion list.
* Real binary Direct Patch ZIPs and external per-file `*.manifest.json` are in `/Factorio/Patches/` in the user's GPT Library. Owner-running snapshots are in `/Factorio/Working-Mod/`. Source code/recipes and reproducible graphics derivations remain in GitHub.
* To make a patch from two locally restored mod folders, use `python scripts/direct_patch.py build --base ... --target ... --out ... --manifest ...` and independently verify. This never writes into the owner's working mod.
* Do not change status from pending to accepted based on CI or Linux headless alone. An archive from the owner's PC confirms exact installed **files**, not all runtime graphics/energy scenarios.
* When changing registry: add a sequential new entry, preserve existing historical identities/hashes and test it in GitHub Actions. No `main` merge or release implied.
