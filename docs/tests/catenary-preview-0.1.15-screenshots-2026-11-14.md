# ElectrifiedMainline 0.1.15 — screenshots of in-game mast candidate previews

**Observed:** user-provided archive `Скрины.zip` with seven PNG screenshots dated 2026-11-14 (original timestamps in filenames). **Evidence class: GAME SCREENSHOTS** for successful command execution and visible markers on the **specific** displayed rail geometry/offset combinations. The PNGs were inspected in the conversation; their bytes were **not uploaded to this public repository**. The Factorio build number and precise mod binary checksum are **not visible** in these screenshots. Target environment remains Factorio 2.1.20 build 87512 as specified by the project's test plan, not independently verified from screenshot metadata.

## Test outcomes visible on screenshots

| Screenshot file from user's ZIP | In-game selection | Command offset (tiles) | Engine signal slots | Candidate bases | CLEAR | BLOCKED | API_ERR |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `2026-11-14_13-11-05.png` | `em-high-speed-straight-rail`, horizontal | 1.0 | 4 | 8 | 4 | 4 | 0 |
| `2026-11-14_13-11-39.png` | `em-curved-high-speed-rail-b` | 1.0 | 5 | 10 | 5 | 5 | 0 |
| `2026-11-14_13-12-06.png` | `em-high-speed-straight-rail`, vertical | 1.0 | 4 | 8 | 4 | 4 | 0 |
| `2026-11-14_13-12-47.png` | `em-high-speed-straight-rail`, horizontal | 1.5 | 4 | 8 | 4 | 4 | 0 |
| `2026-11-14_13-13-13.png` | `em-curved-high-speed-rail-b` | 1.5 | 5 | 10 | 5 | 5 | 0 |
| `2026-11-14_13-13-35.png` | `em-curved-high-speed-rail` (curve A) | 1.5 | 5 | 10 | 6 | 4 | 0 |
| `2026-11-14_13-13-58.png` | `em-high-speed-straight-rail`, vertical | 1.5 | 4 | 8 | 4 | 4 | 0 |

**What can be verified visually:**

- The console summary in each capture begins `[EM 0.1.15]` and reports signal slots and temporary candidate markers. Screenshots display colored circles and textual compass-facing labels (`north/south/east/west/northeast/southwest`) with CLEAR/BLOCKED statuses.
- All seven console summaries report `0 non-ground slots skipped`. The selected shapes belong to the custom ВСМ prototype whitelist. No `API_ERR` string appears in the shown output.
- Straight horizontal/vertical tracks: outward offset candidates show green markers on both sides of the rail while inward candidates intersect or approach rail collision and show red markers. This demonstrates **collision classification at sampled coordinates**, not correct mast anchoring.
- Curve B: 5/10 candidates CLEAR at both tested offsets. Curve A: 6/10 CLEAR at 1.5 tiles, including **both candidates at slot 3 (`alternative_in`)**. This shows `CLEAR` alone does not choose a unique safe/appropriate side or position.
- Candidate labels and guide lines crowd/overlap around both curves; color-coded ring positions are visible, but the clutter complicates reliable interpretation. On curves some geometrically legal (green) points may be on a visually unsuitable side or too close to adjacent slots.
- The user had previously supplied one 0.1.14 screenshot showing four numbered `in/out` rail-signal markers on one ВСМ segment; it is **separate evidence** and does not test the 0.1.15 candidate resolver.

**What these screenshots do NOT demonstrate:**

- The actual physical mast foot, sprite overlay, cantilever clearance and contact-wire path at the sampled candidate positions (the 0.1.15 command does not construct masts).
- Correctly unique positions for parallel tracks/crossings or consistent track association; the code renders candidates for **every** engine signal slot, not selected resolved placement slots.
- Half-diagonal geometry; no-ВСМ negative case; invalid-command response; offsets 0.5/2/3; construction or mining; robots; native rail/chain signal behavior under traffic; Undo/Redo; save/reload/multiplayer.
- That 0.1.15 was tested on exactly Factorio build 87512; that number is in the project target, not visible in captures.
- That the collision results imply the correct arm facing: this preview aims the guide toward the **signal reference**, which is not a measured rail contact-wire centerline.

## Engineering interpretation and next smallest experiment

**Game-tested on shown screenshots:** execution of `/em-35kv-preview` and temporary marker rendering, with usable console output, for straight horizontal/vertical, curved A and curved B rails at the listed offsets. The console did not display an error.

**Not accepted as production geometry:** Neither offset 1.0 nor 1.5 is yet chosen as globally correct. Curve candidates can have more than one CLEAR per slot; close, partially duplicate and overdrawn candidates must be resolved before actual build functionality.

**Recommended next step, read-only first:** derive candidate filtering and deterministic de-duplication per real track side; use actual rail geometry (not signal reference alone) to verify arm direction and reasonable clearance; render fewer nonoverlapping labels with stable IDs. Then test the missing half-diagonal and both sides of curves. Only afterwards investigate Undo-safe real mast placement; do not clone rail signals or inject Undo actions.

## Source and provenance

- GitHub branch: `feature/catenary-preview-015`, code [`d07755c`](https://github.com/zukera2-stack/Factorio/commit/d07755c0f3491003d7bc7558b5f0c3b84c7d1d80).
- [Read-only algorithm research](../research/catenary-mast-preview-0.1.15.md).
- [Static build and Lua mocks PASS](https://github.com/zukera2-stack/Factorio/actions/runs/43572452213); the mock tests are not independent Factorio execution.
- Status: **PARTIAL GAME SCREENSHOT PASS**, geometry acceptance remains **OPEN**.
