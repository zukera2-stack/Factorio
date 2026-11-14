# ElectrifiedMainline 0.1.17 — test native rail slot corridor preview

Experiment branch: feature/catenary-corridor-preview-017. Factorio 2.1.20 build 87512. Safe read-only preview; no pole placement.
Use the GitHub Actions Build Factorio mod ZIP artifact for THIS branch. Its outer ZIP contains ElectrifiedMainline_0.1.17.zip. Place only that inner archive in Factorio/mods; remove older simultaneous copies. Backup save first.

## Steps

1. Select one ВСМ rail on a connected straight + curve route, run:
   /em-35kv-corridor
   A set of small green/red rings should follow the connected ВСМ path within radius 24 tiles of selected rail. One clear ring nearest the player is outlined cyan. No text clutter over every candidate.
2. Repeat:
   /em-35kv-corridor 12
   /em-35kv-corridor 32
   Note number of rails, native_slots, clear/blocked, duplicates, api_errors and capped from console.
3. Compare by holding the vanilla signal and observing its green squares. The mod marks engine-derived slots but NOT exact native cursor snap; exact sprite alignment for poles is still unproved.
4. Check straight N/S, E/W, curved A and B, half-diagonal; test disconnected parallel ВСМ, vanilla-only, elevations/intersections and occupied signal positions.
5. Negative commands: /em-35kv-corridor 4; /em-35kv-corridor 50; they must report usage and not draw. Near only vanilla rails the command must draw nothing.
6. Wait 15 seconds between previews; rendering automatically expires. Confirm no real signal/pole ghosts appear, train signals and routes remain unchanged, native Upgrade Planner and Ctrl+Z/Ctrl+Y still behave normally.

Colors: green = electric-pole collision check passes at native signal slot; red = collision blocked; magenta = API error; cyan = nearest green highlight. GREEN DOES NOT MEAN POLE GEOMETRY ACCEPTED OR CONSTRUCTION ENABLED.

Provide screenshots of curved + connected straight with command summary and factorio-current.log. Mod cannot create a mast through this new preview. Previous commands /em-35kv-geometry, /em-35kv-preview, /em-35kv-slots remain available.
