# EM127 source archive — transfer status

Status: **PENDING BINARY IMPORT**. Complete 66-file source archive verified locally and saved to the project Library. The actual GLB binaries are not yet in GitHub; do not treat this index as a complete backup.

Library: /Factorio/Models/Factorio_rolling_stock_source_backup_EM127.zip
Archive bytes: 29617275
Archive SHA256: cc21aca47b94e065d3649e45b15e16025216b8b152e0555c21d4df5f04921c0a
Internal SHA256SUMS.json SHA256: a9b19b01dd655dad12449a2e41f2477e69090cc17076f068aaec5a22e8d44f71

| Relative path inside assets/source/rolling-stock | Bytes | SHA256 |
| --- | ---: | --- |
| models/v2/battery.glb | 4527628 | b3a4fee154efee48403df086737cf74708c5578fb1616c6d12caa327fe2c2507 |
| models/v2/cargo.glb | 2248180 | d7ed13d85b6f847326d11d0c757a6251cdb50c383eb9172f03f97a8b13882bdd |
| models/v2/tank.glb | 1863932 | 8b21a04c65da63ac23411bfdfec2d146f1e0784f9cd3e5b65842bf1695052f6c |
| models/v3/Locomotive_v3.glb | 3424064 | 931c9f0375c6f60f9314c9fec046c75b27ac811b4b0342f119a3fd91b377ce53 |
| models/v3/Locomotive_v3_body.glb | 3117740 | 6970a44dffaae84001b7c08bebac80083933982895461bb8f0b0c913bc566955 |
| models/v3/Locomotive_v3_pantograph.glb | 311100 | 08b69acb1d61d48d3645d4ea8fe528944de7e8f62e512d458e15c59fbbfc2586 |

Archive includes original authoring scripts, embedded UV textures, EM080/126/127 render scripts, calibration and moving-group metadata, original source archives (including V1 retention), render evidence. All six individual GLBs are byte-identical to their source archives. No external texture/buffer URI. Original render scripts keep their working-path assumptions, not a fully portable runner.

Projection standard: [PR #92](https://github.com/zukera2-stack/Factorio/pull/92).

Import procedure: obtain exact ZIP from Library, verify SHA256, extract into a clean checkout of this branch, verify every file against assets/source/rolling-stock/SHA256SUMS.json. Commit only this subtree, then push this branch and verify remote commit contents against the manifest. Do not mark complete until binary import is independently verified. Do not merge main, modify runtime, or release.

Blocked: render environment cannot resolve GitHub; GitHub connector cannot directly accept the file snapshot as binary content. Owner PC has read access to GitHub, but archive not located in checked local download directories.
