**0.1.25 source CI PASSED:** [Build #43750162585](https://github.com/zukera2-stack/Factorio/actions/runs/43750162585), [download playable ZIP artifact #14175542846](https://github.com/zukera2-stack/Factorio/actions/runs/43750162585/artifacts/14175542846); docs CI #43750162313 passed. Factorio gameplay of 0.1.25 is STILL PENDING. Download the outer Actions ZIP and install only nested `ElectrifiedMainline_0.1.25.zip`. Do not merge before real screenshot/log acceptance.

# 0.1.25 visual wire test — NOT merged into main

The user-accepted 0.1.24 mast baseline is in `main`. This separate experimental branch adds **two different visual cable lines and 3 suspended droppers** to existing local pole-to-pole spans. References: `docs/ART_BRIEF_35KV.md` contact texture spec, `docs/ART_DIRECTION_35KV.md` wire phase, `docs/concepts/35kv-mast-C-refinement-2026-11-15.md` P2 anchor, and original 0.1.9/0.1.10 contact topology notes.

**No mechanical/topology changes:** `SPan=16`, existing connected rails checks, pole locations, P2 offsets, 0.1.22 arm-facing, native 0.1.24 mast, ghost/cursor/Undo/robots, blue feeder and power status remain unchanged.

**User test:** install `ElectrifiedMainline_0.1.25.zip` from GitHub Actions in copied `ВСМ` save. Try 3–6 masts on straight, A/B curves and half diagonals, both sides; parallel tracks close together and switches. Inspect no spanning off-track diagonals, that each span has visibly separate messenger + contact line with three small dropper strings, end attachment to P2 and no floating/overlapping near curves. Check Ctrl+Z/Redo, ghost/drones, load/save; compare in same zoom to 0.1.24. Send screenshots and factorio-current.log. CI mocks cannot assert quality/performance in engine.

**Then:** adjust wire P2 anchors separately, avoid assuming vertical y offset corresponds to actual physical elevation. No electricity (`transfer_MW=0`). Do not merge into main without user screenshot acceptance.
