# EM094D reproduction (blocked, QA only)
Use exact 0.1.102 base, Factorio Linux headless 2.1.24 build87808. Exact blocked candidate in Library, not installation. `build.py` uses base `/mnt/data/EM091_0.1.102_full_EXPERIMENT.zip` and EM094C `/mnt/data/em094c/line_terminal_094.lua`; archive includes original input under `previous/`. ZIP metadata may differ, runner pins exact archived bytes. Native settings file generated from engine default, only three experimental bool bytes flipped (grid-off control keeps grid false); do not change user settings.

```
python suite/run_integrated.py --factorio /path/to/factorio --full-mod candidate.zip --output final-functional --workers 2 --worker-mib 1200 --case regen-stress-control --case train-exchange-large100 --case train-lifecycle --case train-exchange-pair --case train-same-terminal --case regen-stress12
python suite/run_integrated.py --factorio /path/to/factorio --full-mod candidate.zip --output old-controls --workers 2 --worker-mib 700 --case mixed --case ring --case empty --case battery
python suite/run_no_export.py --factorio /path/to/factorio --full-mod no-export-diagnostic.zip --output no-export-control --workers 1 --worker-mib 700 --case regen-stress-no-export
```
Output paths fresh. Mixed12 expected FAIL until fixed; keep assertions. `run_no_export.py` pins exact one-line diagnostic archive. `run_core.py` is inherited runner, not full run here; needs prior EM088 k/l fixtures at documented path. See REPORT.md. No official release.
