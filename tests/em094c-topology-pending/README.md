# EM094C diagnostic reproduction
Base exact 0.1.102 from Library /Factorio/Local-QA/EM091_0.1.102_full_EXPERIMENT.zip; engine 2.1.24 build87808. Builders use /mnt/data base path; adjust locally. Exact probe ZIPs archived in Library EM094C-Topology-Pending folder. ZIP metadata may differ when rebuilding; runners pin archived exact SHA. Not playable mods. QA-only source and mutation commands.

```
python prepare_integrated.py
python prepare_disable_probe.py
# Use archived exact bytes for hash-pinned runner:
python suite/run_integrated.py --factorio /path/to/factorio --full-mod topology-probe-QA-ONLY.zip --output small --workers 3 --worker-mib 700 --case topology-join --case topology-normal-join --case topology-split --case topology-same --case topology-foreign --case train-exchange-pair --case train-same-terminal
python suite/run_integrated.py --factorio /path/to/factorio --full-mod topology-probe-QA-ONLY.zip --output large --workers 1 --worker-mib 1600 --case train-exchange-large100
python suite/run_integrated.py --factorio /path/to/factorio --full-mod topology-probe-QA-ONLY.zip --output join --workers 1 --worker-mib 700 --case train-topology-join
python suite/run_disable.py --factorio /path/to/factorio --full-mod disable-probe-QA-ONLY.zip --output disable --workers 1 --worker-mib 700 --case train-topology-disable
python save_pending.py # adjust engine path if needed; private localhost test server
python suite/run_integrated.py --factorio /path/to/factorio --full-mod topology-probe-QA-ONLY.zip --output reload --workers 1 --worker-mib 700 --case train-pending-reload
```
All output paths must be fresh. `topology-foreign` deliberately reproduces unsupported scripted hidden port injection; passing its assertions is not a safety pass. Runners inherited additional case names not all fixtures in this package; use only listed cases. Earlier failed fixtures in `topology-first.lua` and `train-topology-first.lua`; evidence contains original and rerun logs. No production files or player installation modified. See REPORT.md.
