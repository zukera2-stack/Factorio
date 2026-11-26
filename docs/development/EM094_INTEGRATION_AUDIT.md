# Integration audit — EM094D.4 to main candidate (2026-11-26)

**PREPARED FOR FINAL TEST, not merged, not released, not owner accepted.** Branch integration/em094d4-main-candidate, runtime base 949a99f2f281fc226356d5f6e247a84dce12b4f8. Current main 0.1.62 cf75656fda374824944311f26bbd454bc90ad45b, D4 ahead127/behind0. Keep exact 0.1.103 runtime, no version bump or gameplay changes. Prior 92/92 and mixed100 PASS belong to D.2; final D.4 18/18 exact +4/4 separate QA-only setting tests. Do not equate packaging with game acceptance.

## Audit and reproducibility

Recovered exact D4 full QA ZIP (169 files, 99 PNG, SHA256 9c95be93b9a49e60e60402abfab4bd7c4dacb45840c114d7de22270de28ac17e). Owner-derived 0.1.85 and historical CI 0.1.85 match all157 game files. D4 relative to 0.1.85: 12 added, 13 modified, no removed; all99 PNG equal both earlier ZIPs and owner-running 0.1.84 manifest. GitHub D4 raw tree has153 blobs including83 PNG. All70 non-PNG files verified exactly via matching Git root blobs and directory tree SHAs (locale, migrations, prototypes, scripts); all non-locomotive graphics subtrees match; 16 bogie/bogie-shadow files absent in raw tree, 41 existing locomotive PNGs differ (body8, mask8, shadow8, down8, up8, icon1). No redraw: committed EM079/080/081 patch ZIPs and EM083 pinned reconstruction already reproduced exact EM085. Old workflow stages them only for 0.1.85. Integration workflow stages frozen artwork whenever integration-runtime.json exists, then checks every final archive entry, code Git blob SHA1 and PNG SHA256 before upload. This is a self-contained reproducible repository recipe, not a claim that the unstaged tree is an installable mod. Full CI run/artifact verification remains mandatory. Local payload verifier PASS169/169; negative missing bogie, changed Lua, duplicate entry rejected. Exact archive native smoke empty/battery PASS 2/2 on Factorio 2.1.24 build87808; max2 independent processes, 5.05s, peak1754128384 bytes, no OOM. No full regression started here.

## Accepted scope and exclusions

25kV; 20MW per station (parallel 2/3/6, no single120MW); 2MW native paid loco, 500kW motor wagon, 200-wagon helper blocks; same physical loco train bus; finite opt-in onboard storage, onboard regen, grid regen all default off; latest D.2 bridge buffer and D.4 anchor settlement fixes; vanilla wrecks and accepted EM082/083 artwork, EM084 localization, EM085 ordinary pole removal/migration, maintenance and validated EM087L lineage. Do not copy failed EM087M/P or rejected wagon batteries, single120MW or draft 3D/art studies into gameplay. Direct Patch and Asset Workshop tooling copied from 0da3f4d8c24ae65f3c58b048fe36179358d60256; original Blender skill and read-only 3D tools from PR87 ae441037a0ce0c4ea3bbdbcab2f5d6f3cae32b8f, separate from runtime; their historical reports are not fresh test evidence. Registry entries preserved, old handoff headers not authoritative. No auto updater.

## Final test gate

Run CI package and docs; compare full169 with the pinned manifest, then native 92 on exact archive, mixed100 with grid on, anchor robot faults, repeat ring, pending save/load and setting QA-only results distinguished from actual GUI. Separate worker configs, 4GiB/4CPU, reserve768MiB, admit 2–3 small or 1 large depending on measured RSS, monitor cgroup/guard, no UPS claim. Owner Windows/UI/migration check and explicit merge authorization remain distinct; UPS optimization not a blocker to development main once functional gates and package parity confirmed. No merge, branch deletion, issue closure or release in this task.

## Open PR inventory (52 before integration PR)

GitHub compare D4 against all52 PR heads: ancestor/identical or divergent with zero changed paths in ElectrifiedMainline/ in divergent PR compare. This does not imply every historical lab result is equivalent to current behavior; divergent research remains preserved. After integration approval close superseded PRs with references; preserve unique branches until their histories/evidence are archived. No blind merging of stale documents, no branch deletion before retention review.

| PR | Head | SHA | Handling |
|---|---|---|---|
| #90 | `experiment/em094d4-anchor-settlement` | `949a99f2f281fc226356d5f6e247a84dce12b4f8` | included in D4 history |
| #89 | `test/em094d3-full-regression` | `44d129087d976a7f599f5045e331a2a45eccb939` | included in D4 history |
| #88 | `experiment/em094d2-bridge-output-capacity` | `ae5d032dab8db9ed5e5250f5fd6eb017edb63834` | included in D4 history |
| #87 | `docs/blender-unity-skill-20261124` | `ae441037a0ce0c4ea3bbdbcab2f5d6f3cae32b8f` | tooling copied; review separately |
| #86 | `fix/em078-hide-technical-no-path-icons-20261123` | `b9e494c4963483269265b4eff4c9d3ba5cc093e9` | included in D4 history |
| #85 | `experiment/em077-block-traction-200-native-20261123` | `651e760323715f7d45890a3bd3760c5c20437b32` | included in D4 history |
| #84 | `fix/em076-traction-power-status-20261123` | `adcf849ddcafafbaa4e4369f389cdb726d455280` | included in D4 history |
| #83 | `fix/em074-20mw-parallel-only-20261123` | `21114f065828432274604054c0bfc80afd61ee92` | included in D4 history |
| #82 | `docs/factorio-library-entrypoint-20261123` | `b25ebc7b9dbbd5506d812751a7ad9bcbeb6fcfb6` | diverged, no independent game-file changes in compare; preserve research/ref |
| #81 | `docs/owner-approved-parallel-20mw-20261123` | `e14864b877dc58bbdf2757008b1fba6a8b2c9fcd` | diverged, no independent game-file changes in compare; preserve research/ref |
| #80 | `docs/em065-audit-20261122-cross-branch` | `95f55f4ee2134d7a544487477656fcaaef912040` | diverged, no independent game-file changes in compare; preserve research/ref |
| #79 | `audit/em065-native-multitrain-20261122` | `718a8011edf38a064364f7ceb9c7e2529b5a6799` | diverged, no independent game-file changes in compare; preserve research/ref |
| #76 | `experiment/em065-source-paid-locomotive-drive-native` | `053fdd9d528b39db8f57eba5698aebfe9d79c506` | included in D4 history |
| #75 | `experiment/em063-source-traction-audit-legacy-pole-20261122` | `eeccfcc9b15cefb808423731e506d4a112c0bbc4` | included in D4 history |
| #72 | `experiment/em063-fault-matrix-parallel-20261122` | `cbd5e6c76b7c7d7f43790044427e0ce20b11191b` | diverged, no independent game-file changes in compare; preserve research/ref |
| #71 | `experiment/em072-fullmod-player-test-063` | `2650d44b3caccc63189d6516b14bcd11d4800b8d` | included in D4 history |
| #70 | `docs/em072-c5-crossbranch-index-20261122` | `87c826f505fa25f705dc6f907956844762b65ec2` | diverged, no independent game-file changes in compare; preserve research/ref |
| #69 | `experiment/em072-c5-client-gui-observer` | `1d68af703ef6f6ab3bb6fa7130a8bbfe90a453d1` | diverged, no independent game-file changes in compare; preserve research/ref |
| #68 | `experiment/em072-c4-locomotive-mounted-booster` | `6e71496bb7972efc989f8b7d9398591335a43f97` | diverged, no independent game-file changes in compare; preserve research/ref |
| #67 | `experiment/em072-c3-native-zero-length-phantom` | `7b1f2f89fb0649bf0e65bbf7e3181a11ebf1251b` | diverged, no independent game-file changes in compare; preserve research/ref |
| #66 | `experiment/em072-c2-maxpower-runtime-api` | `6fa82b49e07df9285f2937e3f1132fb340a6eaa0` | diverged, no independent game-file changes in compare; preserve research/ref |
| #65 | `experiment/em072-c-motor-wagon-native-blocker` | `07ca502c134fb5843fdbd5d2423953b3e74e579e` | diverged, no independent game-file changes in compare; preserve research/ref |
| #64 | `experiment/em072-b10r-compliant-loco-bus` | `72b86a539dda638becf33591aa8cf39083f86457` | diverged, no independent game-file changes in compare; preserve research/ref |
| #63 | `docs/em072-train-bus-current-state-20261122` | `7c9e98acbc0ddb7b17e4e7cd4667aa36b1b4cefb` | diverged, no independent game-file changes in compare; preserve research/ref |
| #62 | `experiment/em072a5-native-train-bus-b10` | `f909a7670813699a72ffeb5906942ea87fc73f81` | diverged, no independent game-file changes in compare; preserve research/ref |
| #61 | `experiment/em072a5-native-loco-battery-b9` | `f1e6b5ee65cb43f638ad5558b8e88cc8b6007c9c` | diverged, no independent game-file changes in compare; preserve research/ref |
| #60 | `experiment/em072a5-native-sharedline-b8` | `e9c70b2e5d7d788fe686806ea9f4a83090115bcd` | diverged, no independent game-file changes in compare; preserve research/ref |
| #59 | `experiment/em072a5-native-demand-cache-b7` | `c5f2cacc4189d04533afac5ac0f9ba05531e8bfd` | diverged, no independent game-file changes in compare; preserve research/ref |
| #58 | `experiment/em072a5-native-brownout-b6` | `80f41b04f1299071d263a228f9bf4fcc4779454d` | diverged, no independent game-file changes in compare; preserve research/ref |
| #57 | `experiment/em072a5-native-dualcomponent-b5` | `219edd0d4247986f1beb336761604b02fdf3744c` | diverged, no independent game-file changes in compare; preserve research/ref |
| #56 | `experiment/em072a5-native-lifecycle-b4` | `75e8878dc9f2ff3fb0b7d8aa91d409cd7a07f2fb` | diverged, no independent game-file changes in compare; preserve research/ref |
| #55 | `experiment/em072a5-native-recharge-b3` | `e2621ef94ae45f914273c86dd590b2934cc8321f` | diverged, no independent game-file changes in compare; preserve research/ref |
| #54 | `experiment/em072a5-native-buffer-b1` | `8531bf0eb726de98ecdfa534b1d48233ef6b3d3d` | diverged, no independent game-file changes in compare; preserve research/ref |
| #53 | `experiment/em072a5-native-overload-b0` | `ba19d1a53ac7d99ed23aed0e021eb7c484f68f76` | diverged, no independent game-file changes in compare; preserve research/ref |
| #52 | `experiment/em072a5-buffer-outpost-design` | `5cb0ec316b540857e3821bba9f26bd0eab069734` | diverged, no independent game-file changes in compare; preserve research/ref |
| #51 | `experiment/native-em070-multitrain-cache-072a4` | `e200614daddb70915193071b65476b3fd5c554c1` | diverged, no independent game-file changes in compare; preserve research/ref |
| #50 | `experiment/native-em070-auto-demand-072a3` | `c8618aaf7ba419873350df21b1185e5493a72054` | diverged, no independent game-file changes in compare; preserve research/ref |
| #49 | `experiment/native-em070-burner-debit-072a2` | `04e70e365d5d69d1d47ae47b1b8f26c864dbe4cf` | diverged, no independent game-file changes in compare; preserve research/ref |
| #48 | `experiment/native-burner-traction-072a` | `10859a93571d816762964113e84af3d87996ab07` | diverged, no independent game-file changes in compare; preserve research/ref |
| #45 | `experiment/native-dynamic-eei-070` | `5a2d7861e87eb4723ce461aff832bc98b5a422db` | included in D4 history |
| #44 | `experiment/eei-buffer-lifecycle-069` | `5c8f120b24b2a7d3382ac75156f217030c2b31f3` | included in D4 history |
| #43 | `experiment/eei-disposal-diagnostics-068` | `064682e4acc4ccb557741dfae3cc206afe816c29` | included in D4 history |
| #42 | `experiment/dispatch-cache-067` | `0215b599c2bc80fbd750190ea19095cc31328183` | included in D4 history |
| #41 | `experiment/switching-dissipation-policy-066` | `9042dd6b3e7c56ad05a4f37f6f4ca1f611306136` | included in D4 history |
| #40 | `experiment/closed-energy-ledger-065` | `8497f9a343412281a1160de2e8b3a7e5e921560d` | included in D4 history |
| #39 | `experiment/topology-lifecycle-064` | `305d0dd93d811dc714b6b1c20632a9f49782a73e` | included in D4 history |
| #38 | `experiment/buffer-flush-063` | `4c050e598e19d4bf9607d7670c7972373e4cdce9` | included in D4 history |
| #37 | `experiment/buffer-source-sink-063` | `e52d59e9ce4225506deb29de312f90224f330a2c` | included in D4 history |
| #36 | `experiment/network-fair-share-opt-062` | `6f8a8d8fe8fe142e39ff602b910b2ca1d251100c` | included in D4 history |
| #35 | `experiment/network-fair-share-062` | `08b8b656983705619c4cc511e62f13e535baa79f` | included in D4 history |
| #34 | `feature/local-qa-library-061` | `ae2fb16f83779fe7f5ecd6aaa7a0515a737571b8` | diverged, no independent game-file changes in compare; preserve research/ref |
| #33 | `feature/handoff-061-patcher-promotion` | `c0f0a3692f008a063ed691e6ced665fb28e02d06` | diverged, no independent game-file changes in compare; preserve research/ref |

## Test files and recovery

Exact runtime in Library /Factorio/Local-QA/EM094D4-Anchor-Settlement/EM094D4_0.1.103_CODE_ONLY_QA.zip. Prior D.3/D.4 evidence archives and test stand in Library; integration test stand named EM094_INTEGRATION_TEST_STAND.zip. See [final test plan](EM094_INTEGRATION_TEST_PLAN.md). No user's installed files changed.

## CI preparation follow-up

Initial CI run 45884484004 failed old static test 25kv_auto_wire_028.lua:118: the runtime signature has the optional phase-local context, not the pre-cache exact textual signature. Both signatures recognized, original dynamic disconnected/connected assertions retained, and new dynamic technical_path context checks added. Direct Patch run 45884484133 failed registry KeyError zip_sha256 on a historic full-only fork (0.1.92→0.1.94); registry validation now distinguishes strict adjacent Direct Patch vs explicit full-only experiment and checks hashes, known lineage and no patch delivery. Added omitted experiment references 0.1.98/100/101/102 and final 0.1.103 QA-only using exact Library manifests. No runtime changes, no waived gates. CI rerun pending. Stand ZIP /Factorio/Local-QA/EM094-Integration/EM094_INTEGRATION_TEST_STAND.zip SHA256 51c2837023c94914f354c534b0b4f9b8cf4cb28a54aa3f3740f95be9816bc2d5 (221 entries), dry-run verified 14+69+9 regression, mixed100, 18 targeted; not executed. Local payload manifest SHA256 fe2aff879f43a1fc9c9751b5bab77038b02bf21790fba8e8ae04892cbddaba01; Git blob matches local. Initial docs and Asset Workshop CI passed.
