# 0.1.23 Visual polish test manifest

Date: 2026-11-15. Parent: `feature/catenary-facing-geometry-022` at `3d17febec3676ad34728f22b09100f13dd8a8a14`. Work branch: `feature/catenary-visual-polish-023`. Source image of icon: exact user-game-tested `pole-south-012.png`, PNG RGBA 64x64 SHA256 `de5cbe2ca3efa20b1f8ca3914eb49b13ebe6dd6e932335642631338a1d8715ec`.

Changes: prototypes icon + placement preview; one runtime ghost overlay module + minor shared facing helper; muted circle markers; tests; docs. **Actual sprite PNGs `pole-*-012.png` not changed.** `main` 0.1.8 untouched.

Static QA: Lua syntax and stub tests, packaging and icon PNG contract by GitHub Actions. **Factorio 2.1.20 gameplay remains UNVERIFIED**. Ghost visibility and build preview particularly need physical game screenshots.

User test checklist is in `ElectrifiedMainline/TEST_VISUAL_023.txt` inside mod ZIP. Expecting screenshots/log. If placement preview absent, investigate native UI with same prototype type; do not fabricate `LuaPlayer.cursor_position` or overwrite default LMB.
