# 0.1.23 Visual polish test manifest

Date: 2026-11-15. Parent: `feature/catenary-facing-geometry-022` at `3d17febec3676ad34728f22b09100f13dd8a8a14`. Work branch: `feature/catenary-visual-polish-023`. Source image of icon: exact user-game-tested `pole-south-012.png`, PNG RGBA 64x64 SHA256 `de5cbe2ca3efa20b1f8ca3914eb49b13ebe6dd6e932335642631338a1d8715ec`.

Changes: prototypes icon + placement preview; one runtime ghost overlay module + minor shared facing helper; muted circle markers; tests; docs. **Actual sprite PNGs `pole-*-012.png` not changed.** `main` 0.1.8 untouched.

Static QA: Lua syntax and stub tests, packaging and icon PNG contract by GitHub Actions. **Factorio 2.1.20 gameplay remains UNVERIFIED**. Ghost visibility and build preview particularly need physical game screenshots.

User test checklist is in `ElectrifiedMainline/TEST_VISUAL_023.txt` inside mod ZIP. Expecting screenshots/log. If placement preview absent, investigate native UI with same prototype type; do not fabricate `LuaPlayer.cursor_position` or overwrite default LMB.

## Actual GitHub Actions result

- Commit with implementation: `08aa383e3a4a33a29b547645d97107a484cbbc42`; two test-mock follow-up commits corrected a missing Factorio `log` stub and obsolete rectangle-count expectation, **without changing gameplay code**.
- Final source build CI: [#43731628908](https://github.com/zukera2-stack/Factorio/actions/runs/43731628908) **SUCCESS**, [artifact #14168876545](https://github.com/zukera2-stack/Factorio/actions/runs/43731628908/artifacts/14168876545).
- Linux Lua5.2 syntax and mocked regressions passed: ghost 0.1.23, cursor 0.1.23, facing 0.1.22, historical 0.1.13–0.1.18. 64×64 RGBA icon check passed. Package generated `dist/ElectrifiedMainline_0.1.23.zip`, **38 files**.
- Real Factorio 2.1.20 display/ghost lifecycle: **not yet tested**. The only authoritative next validation is user's actual screenshots and log.
