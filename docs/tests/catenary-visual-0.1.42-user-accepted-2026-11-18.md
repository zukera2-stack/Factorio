# Game evidence — user-accepted mast geometry, 0.1.42

- Date: **2026-11-18**.
- Mod tested by user: **ElectrifiedMainline 0.1.42**; uploaded ZIP SHA-256 `d855747f758660aa083d6f3ae0e153550be7ce7bbcd49cdb5ccbcbb2e1dbf6a9`.
- Screenshot provided in conversation: `2026-11-18_12-56-29.png`, SHA-256 `a4e15fb8a076e24ed6ca2171981e64a1502869cb4af5f31668e81df71cc90c4b`.
- User assessment: **«идеально»** after final north height adjustment (`NORTH_DROP=2.02`).

## Supported visual observations

The game screenshot shows **two actual placed C masts** at one straight ВСМ rail line: the short northern mast and long southern mast have separate cantilevers with matching-looking hanger heights, clean lattice bodies and distinct item icons. This is acceptance of that visible arrangement and validates that Factorio rendered the sprites in the user's installed game.

## Not proven by this screenshot

- Exact 32-tile straight and 16-tile curved span limits over all rails; cross-track and graph isolation.
- Long straight contact/messenger/dropper behavior or curved native-copper fallbacks, because a complete connected span is not shown.
- Native Undo/Redo, ghost/robots, save/reload, blueprint cloning for **this 0.1.42 build**.
- Power distribution or train 25 kV traction (`transfer_MW=0` intentionally).

## Source/asset provenance

The user-tested archive was inspected in the current session. Its 12 in-use PNGs were copied byte-identically to GitHub, not regenerated from the old historical 024/033/035/036 assets. Source contract: `scripts/verify_042_assets.py`; file relevance: `docs/FILE_RELEVANCE_042.md`.

**Status:** visual art accepted, broad gameplay regression remains pending. Keep the PR draft; stable `main` stays at 0.1.24.
