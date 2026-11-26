**2026-11-26 — repository cleanup complete:** `main` is the sole active development branch (0.1.103); `archive/pre-main-0.1.103-20261126` is a retention-only branch at `25f91ad775007f80aca048a8c69eff90a3d9686e`, never merge it into main. All 135 original branch tips verified reachable after deleting their old names (93 also main ancestry, 42 archive-only); 605 reachable commits in archive. All 51 superseded PRs closed with original bodies preserved and archive notes; 0 open PRs, 2 branches verified. Historical branch references below may no longer resolve by name: use [archive inventory](https://github.com/zukera2-stack/Factorio/blob/25f91ad775007f80aca048a8c69eff90a3d9686e/docs/development/BRANCH_ARCHIVE_20261126.md) and exact commit SHA. Restore historical work only when needed; new tasks branch from live main. No runtime/artwork change, issue closure, release, tag or owner installation. The existing native 111/111 and CI 169/169 remain the validated baseline; Windows GUI, multiplayer and UPS remain unverified.

# Branch archive — 2026-11-26

Owner approved repository cleanup after merge of PR #91. Snapshot main: `c8a3d4843062446bb03d1fd66658629c3c57fe0b`, version 0.1.103. This is a retention archive, NOT a gameplay merge or approval of rejected experiments. 135 old branch names: 93 already reachable in main, 42 preserved through archive-only parents. The archive branch must remain; never merge it into main. All original commits and trees remain accessible by exact SHA. To recover a branch use `git fetch origin archive/pre-main-0.1.103-20261126`, then `git switch -c recovered/<name> <SHA>`. Old branch-name links may stop resolving; use the permanent commit links in this inventory. No tags, releases, issues or user installation changed.

## Original branch heads

| Original branch | Exact commit (permanent link) | Retention |
|---|---|---|
| `audit/em065-native-multitrain-20261122` | [`718a8011edf38a064364f7ceb9c7e2529b5a6799`](https://github.com/zukera2-stack/Factorio/commit/718a8011edf38a064364f7ceb9c7e2529b5a6799) | archive-only ancestry |
| `docs/blender-unity-skill-20261124` | [`ae441037a0ce0c4ea3bbdbcab2f5d6f3cae32b8f`](https://github.com/zukera2-stack/Factorio/commit/ae441037a0ce0c4ea3bbdbcab2f5d6f3cae32b8f) | archive-only ancestry |
| `docs/em065-audit-20261122-cross-branch` | [`95f55f4ee2134d7a544487477656fcaaef912040`](https://github.com/zukera2-stack/Factorio/commit/95f55f4ee2134d7a544487477656fcaaef912040) | archive-only ancestry |
| `docs/em072-c5-crossbranch-index-20261122` | [`87c826f505fa25f705dc6f907956844762b65ec2`](https://github.com/zukera2-stack/Factorio/commit/87c826f505fa25f705dc6f907956844762b65ec2) | archive-only ancestry |
| `docs/em072-train-bus-current-state-20261122` | [`7c9e98acbc0ddb7b17e4e7cd4667aa36b1b4cefb`](https://github.com/zukera2-stack/Factorio/commit/7c9e98acbc0ddb7b17e4e7cd4667aa36b1b4cefb) | archive-only ancestry |
| `docs/factorio-library-entrypoint-20261123` | [`b25ebc7b9dbbd5506d812751a7ad9bcbeb6fcfb6`](https://github.com/zukera2-stack/Factorio/commit/b25ebc7b9dbbd5506d812751a7ad9bcbeb6fcfb6) | archive-only ancestry |
| `docs/owner-approved-parallel-20mw-20261123` | [`e14864b877dc58bbdf2757008b1fba6a8b2c9fcd`](https://github.com/zukera2-stack/Factorio/commit/e14864b877dc58bbdf2757008b1fba6a8b2c9fcd) | archive-only ancestry |
| `experiment/auto-25kv-028` | [`544465dc5649f5bee60ebb684adeaf9dd64014f6`](https://github.com/zukera2-stack/Factorio/commit/544465dc5649f5bee60ebb684adeaf9dd64014f6) | main ancestry |
| `experiment/buffer-flush-063` | [`4c050e598e19d4bf9607d7670c7972373e4cdce9`](https://github.com/zukera2-stack/Factorio/commit/4c050e598e19d4bf9607d7670c7972373e4cdce9) | main ancestry |
| `experiment/buffer-source-sink-063` | [`e52d59e9ce4225506deb29de312f90224f330a2c`](https://github.com/zukera2-stack/Factorio/commit/e52d59e9ce4225506deb29de312f90224f330a2c) | main ancestry |
| `experiment/catenary-turnout-cosmetic-071` | [`714f271d46a0be0e6ea30c789a2711d837f15ad8`](https://github.com/zukera2-stack/Factorio/commit/714f271d46a0be0e6ea30c789a2711d837f15ad8) | main ancestry |
| `experiment/closed-energy-ledger-065` | [`8497f9a343412281a1160de2e8b3a7e5e921560d`](https://github.com/zukera2-stack/Factorio/commit/8497f9a343412281a1160de2e8b3a7e5e921560d) | main ancestry |
| `experiment/dispatch-cache-067` | [`0215b599c2bc80fbd750190ea19095cc31328183`](https://github.com/zukera2-stack/Factorio/commit/0215b599c2bc80fbd750190ea19095cc31328183) | main ancestry |
| `experiment/eei-buffer-lifecycle-069` | [`5c8f120b24b2a7d3382ac75156f217030c2b31f3`](https://github.com/zukera2-stack/Factorio/commit/5c8f120b24b2a7d3382ac75156f217030c2b31f3) | main ancestry |
| `experiment/eei-disposal-diagnostics-068` | [`064682e4acc4ccb557741dfae3cc206afe816c29`](https://github.com/zukera2-stack/Factorio/commit/064682e4acc4ccb557741dfae3cc206afe816c29) | main ancestry |
| `experiment/em063-fault-matrix-parallel-20261122` | [`cbd5e6c76b7c7d7f43790044427e0ce20b11191b`](https://github.com/zukera2-stack/Factorio/commit/cbd5e6c76b7c7d7f43790044427e0ce20b11191b) | archive-only ancestry |
| `experiment/em063-source-traction-audit-legacy-pole-20261122` | [`eeccfcc9b15cefb808423731e506d4a112c0bbc4`](https://github.com/zukera2-stack/Factorio/commit/eeccfcc9b15cefb808423731e506d4a112c0bbc4) | main ancestry |
| `experiment/em065-source-paid-locomotive-drive-native` | [`053fdd9d528b39db8f57eba5698aebfe9d79c506`](https://github.com/zukera2-stack/Factorio/commit/053fdd9d528b39db8f57eba5698aebfe9d79c506) | main ancestry |
| `experiment/em066-autonomous-fullmod-boundaries-20261122` | [`3c69ed6cc30c29f429ff996eb9e349eb1aceda76`](https://github.com/zukera2-stack/Factorio/commit/3c69ed6cc30c29f429ff996eb9e349eb1aceda76) | main ancestry |
| `experiment/em066-fair-share-fullmod-20261122` | [`29584d1b9dd76ad763a7727e4fd79787eba04526`](https://github.com/zukera2-stack/Factorio/commit/29584d1b9dd76ad763a7727e4fd79787eba04526) | main ancestry |
| `experiment/em067-helper-orphan-native-fullmod-20261122` | [`3cc563677782f6705d23ca009d2641b6828f3300`](https://github.com/zukera2-stack/Factorio/commit/3cc563677782f6705d23ca009d2641b6828f3300) | main ancestry |
| `experiment/em068-native-25kv-consumer-probe-20261122` | [`1b8eb75d3f254c985d5fbc51fe51c4e62c6621bb`](https://github.com/zukera2-stack/Factorio/commit/1b8eb75d3f254c985d5fbc51fe51c4e62c6621bb) | archive-only ancestry |
| `experiment/em068-native-25kv-traction-source-paid-fullmod` | [`147ac491e28da741e27585bc1e6326ee34d7d794`](https://github.com/zukera2-stack/Factorio/commit/147ac491e28da741e27585bc1e6326ee34d7d794) | main ancestry |
| `experiment/em069-local-native-recovery-20261122` | [`3941669ab5b8db3e6cd61cd08ad21b84c33f507a`](https://github.com/zukera2-stack/Factorio/commit/3941669ab5b8db3e6cd61cd08ad21b84c33f507a) | main ancestry |
| `experiment/em072-120mw-native-test-feeder-20261123` | [`aa0240ba77962b14295ce5c9dbbe4ad71b634d49`](https://github.com/zukera2-stack/Factorio/commit/aa0240ba77962b14295ce5c9dbbe4ad71b634d49) | main ancestry |
| `experiment/em072-b10r-compliant-loco-bus` | [`72b86a539dda638becf33591aa8cf39083f86457`](https://github.com/zukera2-stack/Factorio/commit/72b86a539dda638becf33591aa8cf39083f86457) | archive-only ancestry |
| `experiment/em072-c2-maxpower-runtime-api` | [`6fa82b49e07df9285f2937e3f1132fb340a6eaa0`](https://github.com/zukera2-stack/Factorio/commit/6fa82b49e07df9285f2937e3f1132fb340a6eaa0) | archive-only ancestry |
| `experiment/em072-c3-native-zero-length-phantom` | [`7b1f2f89fb0649bf0e65bbf7e3181a11ebf1251b`](https://github.com/zukera2-stack/Factorio/commit/7b1f2f89fb0649bf0e65bbf7e3181a11ebf1251b) | archive-only ancestry |
| `experiment/em072-c4-locomotive-mounted-booster` | [`6e71496bb7972efc989f8b7d9398591335a43f97`](https://github.com/zukera2-stack/Factorio/commit/6e71496bb7972efc989f8b7d9398591335a43f97) | archive-only ancestry |
| `experiment/em072-c5-client-gui-observer` | [`1d68af703ef6f6ab3bb6fa7130a8bbfe90a453d1`](https://github.com/zukera2-stack/Factorio/commit/1d68af703ef6f6ab3bb6fa7130a8bbfe90a453d1) | archive-only ancestry |
| `experiment/em072-c-motor-wagon-native-blocker` | [`07ca502c134fb5843fdbd5d2423953b3e74e579e`](https://github.com/zukera2-stack/Factorio/commit/07ca502c134fb5843fdbd5d2423953b3e74e579e) | archive-only ancestry |
| `experiment/em072-fullmod-player-test-063` | [`2650d44b3caccc63189d6516b14bcd11d4800b8d`](https://github.com/zukera2-stack/Factorio/commit/2650d44b3caccc63189d6516b14bcd11d4800b8d) | main ancestry |
| `experiment/em072-integrated-071-native-giant-dual-20261123` | [`2cdbc63697aa529a3a7538750f1b60692113d605`](https://github.com/zukera2-stack/Factorio/commit/2cdbc63697aa529a3a7538750f1b60692113d605) | main ancestry |
| `experiment/em072-lossy-dismantling-fullmod-20261122` | [`9bb32364dbd2ec3c18cddc6c2d9da42c661daee3`](https://github.com/zukera2-stack/Factorio/commit/9bb32364dbd2ec3c18cddc6c2d9da42c661daee3) | main ancestry |
| `experiment/em072-paid-owner-lifecycle-native-20261122` | [`16980fff7ffb968d09a36ebdc46804e228299f71`](https://github.com/zukera2-stack/Factorio/commit/16980fff7ffb968d09a36ebdc46804e228299f71) | main ancestry |
| `experiment/em072-source-paid-500kw-fullmod-native-20261122` | [`0027132d46d3d077d3f92dcc9def5029d971be97`](https://github.com/zukera2-stack/Factorio/commit/0027132d46d3d077d3f92dcc9def5029d971be97) | main ancestry |
| `experiment/em072a5-buffer-outpost-design` | [`5cb0ec316b540857e3821bba9f26bd0eab069734`](https://github.com/zukera2-stack/Factorio/commit/5cb0ec316b540857e3821bba9f26bd0eab069734) | archive-only ancestry |
| `experiment/em072a5-native-brownout-b6` | [`80f41b04f1299071d263a228f9bf4fcc4779454d`](https://github.com/zukera2-stack/Factorio/commit/80f41b04f1299071d263a228f9bf4fcc4779454d) | archive-only ancestry |
| `experiment/em072a5-native-buffer-b1` | [`8531bf0eb726de98ecdfa534b1d48233ef6b3d3d`](https://github.com/zukera2-stack/Factorio/commit/8531bf0eb726de98ecdfa534b1d48233ef6b3d3d) | archive-only ancestry |
| `experiment/em072a5-native-demand-cache-b7` | [`c5f2cacc4189d04533afac5ac0f9ba05531e8bfd`](https://github.com/zukera2-stack/Factorio/commit/c5f2cacc4189d04533afac5ac0f9ba05531e8bfd) | archive-only ancestry |
| `experiment/em072a5-native-dualcomponent-b5` | [`219edd0d4247986f1beb336761604b02fdf3744c`](https://github.com/zukera2-stack/Factorio/commit/219edd0d4247986f1beb336761604b02fdf3744c) | archive-only ancestry |
| `experiment/em072a5-native-lifecycle-b4` | [`75e8878dc9f2ff3fb0b7d8aa91d409cd7a07f2fb`](https://github.com/zukera2-stack/Factorio/commit/75e8878dc9f2ff3fb0b7d8aa91d409cd7a07f2fb) | archive-only ancestry |
| `experiment/em072a5-native-loco-battery-b9` | [`f1e6b5ee65cb43f638ad5558b8e88cc8b6007c9c`](https://github.com/zukera2-stack/Factorio/commit/f1e6b5ee65cb43f638ad5558b8e88cc8b6007c9c) | archive-only ancestry |
| `experiment/em072a5-native-overload-b0` | [`ba19d1a53ac7d99ed23aed0e021eb7c484f68f76`](https://github.com/zukera2-stack/Factorio/commit/ba19d1a53ac7d99ed23aed0e021eb7c484f68f76) | archive-only ancestry |
| `experiment/em072a5-native-recharge-b3` | [`e2621ef94ae45f914273c86dd590b2934cc8321f`](https://github.com/zukera2-stack/Factorio/commit/e2621ef94ae45f914273c86dd590b2934cc8321f) | archive-only ancestry |
| `experiment/em072a5-native-sharedline-b8` | [`e9c70b2e5d7d788fe686806ea9f4a83090115bcd`](https://github.com/zukera2-stack/Factorio/commit/e9c70b2e5d7d788fe686806ea9f4a83090115bcd) | archive-only ancestry |
| `experiment/em072a5-native-train-bus-b10` | [`f909a7670813699a72ffeb5906942ea87fc73f81`](https://github.com/zukera2-stack/Factorio/commit/f909a7670813699a72ffeb5906942ea87fc73f81) | archive-only ancestry |
| `experiment/em073-native-directional-heads-20261123` | [`5ab81df6c33dc2f03ad3d2176358d7e8abb77ffa`](https://github.com/zukera2-stack/Factorio/commit/5ab81df6c33dc2f03ad3d2176358d7e8abb77ffa) | main ancestry |
| `experiment/em074-native-traction-status-20261123` | [`9d8a45082bf5b485eafbf3b25b0bf0a52af88ecf`](https://github.com/zukera2-stack/Factorio/commit/9d8a45082bf5b485eafbf3b25b0bf0a52af88ecf) | main ancestry |
| `experiment/em077-block-traction-200-native-20261123` | [`651e760323715f7d45890a3bd3760c5c20437b32`](https://github.com/zukera2-stack/Factorio/commit/651e760323715f7d45890a3bd3760c5c20437b32) | main ancestry |
| `experiment/em079-locomotive-v3-visual` | [`22bac7894fb9161df616bd8080072a0a09b39de2`](https://github.com/zukera2-stack/Factorio/commit/22bac7894fb9161df616bd8080072a0a09b39de2) | main ancestry |
| `experiment/em080-locomotive-visual-fix` | [`51312a6e37136d5dd3c559e9f51e9015e92905d4`](https://github.com/zukera2-stack/Factorio/commit/51312a6e37136d5dd3c559e9f51e9015e92905d4) | main ancestry |
| `experiment/em081-wheel-render` | [`c020f2323fb5cdf9170d2541a929d0aefacecabb`](https://github.com/zukera2-stack/Factorio/commit/c020f2323fb5cdf9170d2541a929d0aefacecabb) | main ancestry |
| `experiment/em082-wheel-visibility` | [`a7304faec2778a0e5e4465110fd6a4db5a65a7b0`](https://github.com/zukera2-stack/Factorio/commit/a7304faec2778a0e5e4465110fd6a4db5a65a7b0) | main ancestry |
| `experiment/em083-pantograph-restore` | [`2ea27efafd5f8bf48bef27f9d780e03a2dfcf7b4`](https://github.com/zukera2-stack/Factorio/commit/2ea27efafd5f8bf48bef27f9d780e03a2dfcf7b4) | main ancestry |
| `experiment/em084-motor-wagon-status` | [`5e95b5a12cf06a200c64180529b04dc6de11efa0`](https://github.com/zukera2-stack/Factorio/commit/5e95b5a12cf06a200c64180529b04dc6de11efa0) | main ancestry |
| `experiment/em085-remove-legacy-factory-pole` | [`5abca4a841f50500234328ed6b2603150a430852`](https://github.com/zukera2-stack/Factorio/commit/5abca4a841f50500234328ed6b2603150a430852) | main ancestry |
| `experiment/em086-maintenance-hidden-helpers` | [`ce9b30eaab9465c71c669dfd545657490cc5301b`](https://github.com/zukera2-stack/Factorio/commit/ce9b30eaab9465c71c669dfd545657490cc5301b) | main ancestry |
| `experiment/em087-performance-r2` | [`6f67adc25132a6a9a81b4e0959d3ac237b12a997`](https://github.com/zukera2-stack/Factorio/commit/6f67adc25132a6a9a81b4e0959d3ac237b12a997) | main ancestry |
| `experiment/em087b-exact-walk-bridge` | [`cf8f637f835096d4d337a8f2762756768e6a66c2`](https://github.com/zukera2-stack/Factorio/commit/cf8f637f835096d4d337a8f2762756768e6a66c2) | main ancestry |
| `experiment/em087c-native-topology` | [`80fe245f122e7cda6306fc7a705e17804d48fe7c`](https://github.com/zukera2-stack/Factorio/commit/80fe245f122e7cda6306fc7a705e17804d48fe7c) | main ancestry |
| `experiment/em087d-native-network-index` | [`f1ca72caf6b2b36cd30cb2cf3e414da7412999bf`](https://github.com/zukera2-stack/Factorio/commit/f1ca72caf6b2b36cd30cb2cf3e414da7412999bf) | main ancestry |
| `experiment/em087e-native-rail-watch` | [`c39ccbffc6abd265c6f0426807c0f30d95ec0f1e`](https://github.com/zukera2-stack/Factorio/commit/c39ccbffc6abd265c6f0426807c0f30d95ec0f1e) | main ancestry |
| `experiment/em087f-local-plan` | [`51eceb442ed7d8fdd487795f9d46e861e427f431`](https://github.com/zukera2-stack/Factorio/commit/51eceb442ed7d8fdd487795f9d46e861e427f431) | main ancestry |
| `experiment/em087g-path-memo` | [`31d903c2a258f671a7d97ff016ccd7d954834c1f`](https://github.com/zukera2-stack/Factorio/commit/31d903c2a258f671a7d97ff016ccd7d954834c1f) | archive-only ancestry |
| `experiment/em087h-native-ports` | [`c1ea587040ddabbcf0bc215700c41ad8a59a09a6`](https://github.com/zukera2-stack/Factorio/commit/c1ea587040ddabbcf0bc215700c41ad8a59a09a6) | main ancestry |
| `experiment/em087i-native-audit` | [`063d87a6cb491759f45fa9a63e27a00926e26339`](https://github.com/zukera2-stack/Factorio/commit/063d87a6cb491759f45fa9a63e27a00926e26339) | main ancestry |
| `experiment/em087j-native-negative` | [`4096f3e3cc1295a4cc4ab95ec5f640c28191460b`](https://github.com/zukera2-stack/Factorio/commit/4096f3e3cc1295a4cc4ab95ec5f640c28191460b) | main ancestry |
| `experiment/em087k-steady-phase` | [`1559c6fc3a3d467808a7a46c69138be7f20b0860`](https://github.com/zukera2-stack/Factorio/commit/1559c6fc3a3d467808a7a46c69138be7f20b0860) | main ancestry |
| `experiment/em087l-active-idle-demand` | [`08b1791b41c5dcc323f32ad634a49abab47ee5e3`](https://github.com/zukera2-stack/Factorio/commit/08b1791b41c5dcc323f32ad634a49abab47ee5e3) | main ancestry |
| `experiment/em088-train-energy` | [`7c93659c523c460a494309883ac5a06190b1ceef`](https://github.com/zukera2-stack/Factorio/commit/7c93659c523c460a494309883ac5a06190b1ceef) | main ancestry |
| `experiment/em089-onboard-storage` | [`6bea9d6c7549cf269efd5c2df18707e34752ff44`](https://github.com/zukera2-stack/Factorio/commit/6bea9d6c7549cf269efd5c2df18707e34752ff44) | main ancestry |
| `experiment/em091-onboard-regen` | [`adedb5a8a5342ae831d7d95c387d14db89fdfd34`](https://github.com/zukera2-stack/Factorio/commit/adedb5a8a5342ae831d7d95c387d14db89fdfd34) | main ancestry |
| `experiment/em094d2-bridge-output-capacity` | [`ae5d032dab8db9ed5e5250f5fd6eb017edb63834`](https://github.com/zukera2-stack/Factorio/commit/ae5d032dab8db9ed5e5250f5fd6eb017edb63834) | main ancestry |
| `experiment/em094d4-anchor-settlement` | [`949a99f2f281fc226356d5f6e247a84dce12b4f8`](https://github.com/zukera2-stack/Factorio/commit/949a99f2f281fc226356d5f6e247a84dce12b4f8) | main ancestry |
| `experiment/em094d-automatic-terminals-blocked` | [`54328ab506622adc6e9c0eb051868ee629225084`](https://github.com/zukera2-stack/Factorio/commit/54328ab506622adc6e9c0eb051868ee629225084) | main ancestry |
| `experiment/native-25kv-wire-026` | [`ffabf34d19c6e956f14fccf081a3bda2cdcf667f`](https://github.com/zukera2-stack/Factorio/commit/ffabf34d19c6e956f14fccf081a3bda2cdcf667f) | main ancestry |
| `experiment/native-25kv-wire-027` | [`faae5d354e760e740dda486e8b2b3d7bad75160e`](https://github.com/zukera2-stack/Factorio/commit/faae5d354e760e740dda486e8b2b3d7bad75160e) | main ancestry |
| `experiment/native-35kv-auto-wire-028` | [`1d3e7a6f818942b5b3b91bf0285a72211236f6b5`](https://github.com/zukera2-stack/Factorio/commit/1d3e7a6f818942b5b3b91bf0285a72211236f6b5) | archive-only ancestry |
| `experiment/native-accumulator-gateway-061` | [`96e5fdfced96677f8f2a0e635039e6e32d381a55`](https://github.com/zukera2-stack/Factorio/commit/96e5fdfced96677f8f2a0e635039e6e32d381a55) | archive-only ancestry |
| `experiment/native-burner-traction-072a` | [`10859a93571d816762964113e84af3d87996ab07`](https://github.com/zukera2-stack/Factorio/commit/10859a93571d816762964113e84af3d87996ab07) | archive-only ancestry |
| `experiment/native-dynamic-eei-070` | [`5a2d7861e87eb4723ce461aff832bc98b5a422db`](https://github.com/zukera2-stack/Factorio/commit/5a2d7861e87eb4723ce461aff832bc98b5a422db) | main ancestry |
| `experiment/native-em070-auto-demand-072a3` | [`c8618aaf7ba419873350df21b1185e5493a72054`](https://github.com/zukera2-stack/Factorio/commit/c8618aaf7ba419873350df21b1185e5493a72054) | archive-only ancestry |
| `experiment/native-em070-burner-debit-072a2` | [`04e70e365d5d69d1d47ae47b1b8f26c864dbe4cf`](https://github.com/zukera2-stack/Factorio/commit/04e70e365d5d69d1d47ae47b1b8f26c864dbe4cf) | archive-only ancestry |
| `experiment/native-em070-multitrain-cache-072a4` | [`e200614daddb70915193071b65476b3fd5c554c1`](https://github.com/zukera2-stack/Factorio/commit/e200614daddb70915193071b65476b3fd5c554c1) | archive-only ancestry |
| `experiment/network-fair-share-062` | [`08b8b656983705619c4cc511e62f13e535baa79f`](https://github.com/zukera2-stack/Factorio/commit/08b8b656983705619c4cc511e62f13e535baa79f) | main ancestry |
| `experiment/network-fair-share-opt-062` | [`6f8a8d8fe8fe142e39ff602b910b2ca1d251100c`](https://github.com/zukera2-stack/Factorio/commit/6f8a8d8fe8fe142e39ff602b910b2ca1d251100c) | main ancestry |
| `experiment/switching-dissipation-policy-066` | [`9042dd6b3e7c56ad05a4f37f6f4ca1f611306136`](https://github.com/zukera2-stack/Factorio/commit/9042dd6b3e7c56ad05a4f37f6f4ca1f611306136) | main ancestry |
| `experiment/topology-lifecycle-064` | [`305d0dd93d811dc714b6b1c20632a9f49782a73e`](https://github.com/zukera2-stack/Factorio/commit/305d0dd93d811dc714b6b1c20632a9f49782a73e) | main ancestry |
| `experiment/25kv-catenary-031` | [`5f4ead5badb689f0282c80ba124e11659c8188f8`](https://github.com/zukera2-stack/Factorio/commit/5f4ead5badb689f0282c80ba124e11659c8188f8) | main ancestry |
| `experiment/25kv-catenary-art-030` | [`b3cf14560905d62e8387264e212e7d2e96b9ec85`](https://github.com/zukera2-stack/Factorio/commit/b3cf14560905d62e8387264e212e7d2e96b9ec85) | main ancestry |
| `experiment/25kv-south-art-032` | [`7f69c99c58958586c70a3ab51345fcfc14669ae7`](https://github.com/zukera2-stack/Factorio/commit/7f69c99c58958586c70a3ab51345fcfc14669ae7) | main ancestry |
| `experiment/25kv-span-029` | [`802fbe63dba243238c70d590d779b7195b026b3d`](https://github.com/zukera2-stack/Factorio/commit/802fbe63dba243238c70d590d779b7195b026b3d) | main ancestry |
| `feature/catenary-corridor-preview-017` | [`e1b7d7fee177580841ce87efa6853e73116008a5`](https://github.com/zukera2-stack/Factorio/commit/e1b7d7fee177580841ce87efa6853e73116008a5) | main ancestry |
| `feature/catenary-facing-geometry-022` | [`3d17febec3676ad34728f22b09100f13dd8a8a14`](https://github.com/zukera2-stack/Factorio/commit/3d17febec3676ad34728f22b09100f13dd8a8a14) | main ancestry |
| `feature/catenary-geometry-016` | [`76d2c9daaf3bc6474198a86e075a4e6412954d0f`](https://github.com/zukera2-stack/Factorio/commit/76d2c9daaf3bc6474198a86e075a4e6412954d0f) | main ancestry |
| `feature/catenary-item-click-probe-020` | [`5f8600d00e5ae6a2ec6918ee946ea7bb5f9a6f2e`](https://github.com/zukera2-stack/Factorio/commit/5f8600d00e5ae6a2ec6918ee946ea7bb5f9a6f2e) | archive-only ancestry |
| `feature/catenary-mast-art-plan-021` | [`d481797d8366174c64237ddeda3fdfa3fb7d7099`](https://github.com/zukera2-stack/Factorio/commit/d481797d8366174c64237ddeda3fdfa3fb7d7099) | main ancestry |
| `feature/catenary-native-mast-body-024` | [`a3f5c9b62385710b81ba27638c868a87495457e6`](https://github.com/zukera2-stack/Factorio/commit/a3f5c9b62385710b81ba27638c868a87495457e6) | main ancestry |
| `feature/catenary-native-player-build-018` | [`8883b8990663349bbd0cae60b7e00d08e3460c25`](https://github.com/zukera2-stack/Factorio/commit/8883b8990663349bbd0cae60b7e00d08e3460c25) | main ancestry |
| `feature/catenary-snap-research-017` | [`91f1120dbceca10ecae996b3247816a127361648`](https://github.com/zukera2-stack/Factorio/commit/91f1120dbceca10ecae996b3247816a127361648) | main ancestry |
| `feature/catenary-visual-polish-023` | [`7883b74d1ef59171d25214d4ab42b2009a40d7d3`](https://github.com/zukera2-stack/Factorio/commit/7883b74d1ef59171d25214d4ab42b2009a40d7d3) | main ancestry |
| `feature/catenary-wire-visual-025` | [`fdf0a4f071bab1834bfd7658e018971b1f813189`](https://github.com/zukera2-stack/Factorio/commit/fdf0a4f071bab1834bfd7658e018971b1f813189) | archive-only ancestry |
| `feature/direct-patch-standard-20261125` | [`ff9e04938e5b57f8df2f01d5818d5b3647fed0c8`](https://github.com/zukera2-stack/Factorio/commit/ff9e04938e5b57f8df2f01d5818d5b3647fed0c8) | archive-only ancestry |
| `feature/factorio-assets-from-reference-20261125` | [`0da3f4d8c24ae65f3c58b048fe36179358d60256`](https://github.com/zukera2-stack/Factorio/commit/0da3f4d8c24ae65f3c58b048fe36179358d60256) | archive-only ancestry |
| `feature/frozen-runtime-assets-060` | [`022f43148e4655efdf95d22c91e3efbb9619b347`](https://github.com/zukera2-stack/Factorio/commit/022f43148e4655efdf95d22c91e3efbb9619b347) | archive-only ancestry |
| `feature/git-updater-060` | [`da7e1417086c9a3626fbc5c9801207a41be3dbe3`](https://github.com/zukera2-stack/Factorio/commit/da7e1417086c9a3626fbc5c9801207a41be3dbe3) | archive-only ancestry |
| `feature/handoff-061-patcher-promotion` | [`c0f0a3692f008a063ed691e6ced665fb28e02d06`](https://github.com/zukera2-stack/Factorio/commit/c0f0a3692f008a063ed691e6ced665fb28e02d06) | archive-only ancestry |
| `feature/handoff-skills-audit-20261121` | [`325d089d3a03f2191bc0766147af196225b1b809`](https://github.com/zukera2-stack/Factorio/commit/325d089d3a03f2191bc0766147af196225b1b809) | main ancestry |
| `feature/hsr-icons-balance-057` | [`ecc890fb1c65a1766d8752861b45cb59e284757c`](https://github.com/zukera2-stack/Factorio/commit/ecc890fb1c65a1766d8752861b45cb59e284757c) | main ancestry |
| `feature/local-qa-library-061` | [`ae2fb16f83779fe7f5ecd6aaa7a0515a737571b8`](https://github.com/zukera2-stack/Factorio/commit/ae2fb16f83779fe7f5ecd6aaa7a0515a737571b8) | archive-only ancestry |
| `feature/updater-061-candidate` | [`c8a1feddddfb3f160eae5f63cd1b0231e2136ce3`](https://github.com/zukera2-stack/Factorio/commit/c8a1feddddfb3f160eae5f63cd1b0231e2136ce3) | main ancestry |
| `feature/25kv-auto-bidirectional-059` | [`f523decc8828e0d7f1e51e8db2b73002fce86346`](https://github.com/zukera2-stack/Factorio/commit/f523decc8828e0d7f1e51e8db2b73002fce86346) | main ancestry |
| `feature/25kv-dispatch-recovery-060` | [`cd7fd7a43dfb5031f069b947b47b4729ad863ad7`](https://github.com/zukera2-stack/Factorio/commit/cd7fd7a43dfb5031f069b947b47b4729ad863ad7) | main ancestry |
| `feature/25kv-power-bridge-058` | [`dc84724a0d5bd80421fac34f3e5d41f307a6e534`](https://github.com/zukera2-stack/Factorio/commit/dc84724a0d5bd80421fac34f3e5d41f307a6e534) | main ancestry |
| `fix/em074-20mw-parallel-only-20261123` | [`21114f065828432274604054c0bfc80afd61ee92`](https://github.com/zukera2-stack/Factorio/commit/21114f065828432274604054c0bfc80afd61ee92) | main ancestry |
| `fix/em076-traction-power-status-20261123` | [`adcf849ddcafafbaa4e4369f389cdb726d455280`](https://github.com/zukera2-stack/Factorio/commit/adcf849ddcafafbaa4e4369f389cdb726d455280) | main ancestry |
| `fix/em078-hide-technical-no-path-icons-20261123` | [`b9e494c4963483269265b4eff4c9d3ba5cc093e9`](https://github.com/zukera2-stack/Factorio/commit/b9e494c4963483269265b4eff4c9d3ba5cc093e9) | main ancestry |
| `integration/em072-em075-20mw-20261123` | [`33c6b3a389f16cb52da918604f3f70fb031b3515`](https://github.com/zukera2-stack/Factorio/commit/33c6b3a389f16cb52da918604f3f70fb031b3515) | main ancestry |
| `integration/em085-main-candidate` | [`4016f69f1a9c77a2e5e86927ef2a3a97560ca61d`](https://github.com/zukera2-stack/Factorio/commit/4016f69f1a9c77a2e5e86927ef2a3a97560ca61d) | main ancestry |
| `integration/em094d4-main-candidate` | [`ed8639230112668b3c8dd9a12e565988bfde3656`](https://github.com/zukera2-stack/Factorio/commit/ed8639230112668b3c8dd9a12e565988bfde3656) | main ancestry |
| `release/0.1.62-main-integration` | [`d5bee5e7e93313bd601b4ede33ef561fda9a1d5f`](https://github.com/zukera2-stack/Factorio/commit/d5bee5e7e93313bd601b4ede33ef561fda9a1d5f) | main ancestry |
| `research/native-signal-mast-probe-019` | [`1e5b86964557e114dc9012c21ba7944c71f3863a`](https://github.com/zukera2-stack/Factorio/commit/1e5b86964557e114dc9012c21ba7944c71f3863a) | archive-only ancestry |
| `test/em087-full-regression-20261125` | [`bd5168d0ede652b64890f3a4007d78407e844cd5`](https://github.com/zukera2-stack/Factorio/commit/bd5168d0ede652b64890f3a4007d78407e844cd5) | main ancestry |
| `test/em087m-mixed-outposts` | [`464737717489a88c8c5782dc10613617a9921153`](https://github.com/zukera2-stack/Factorio/commit/464737717489a88c8c5782dc10613617a9921153) | main ancestry |
| `test/em087n-parallel-stress` | [`4b50b0e9d8a485d142d857b0ae1be4e3374c444e`](https://github.com/zukera2-stack/Factorio/commit/4b50b0e9d8a485d142d857b0ae1be4e3374c444e) | main ancestry |
| `test/em087o-continuous-profile` | [`f000495098980ae15c6338fbbe2e5db948f94c49`](https://github.com/zukera2-stack/Factorio/commit/f000495098980ae15c6338fbbe2e5db948f94c49) | main ancestry |
| `test/em087p-sync-profile` | [`9ef3f4c13fe5cad27119fdf3aa8be842bcfe56c7`](https://github.com/zukera2-stack/Factorio/commit/9ef3f4c13fe5cad27119fdf3aa8be842bcfe56c7) | main ancestry |
| `test/em090-native-brake` | [`c02e48e6f82ff7fc9887fe357b05c88c231cc8ad`](https://github.com/zukera2-stack/Factorio/commit/c02e48e6f82ff7fc9887fe357b05c88c231cc8ad) | main ancestry |
| `test/em090b-brake-calibration` | [`e933b542c2fc314d9a6123f974839ff81882210d`](https://github.com/zukera2-stack/Factorio/commit/e933b542c2fc314d9a6123f974839ff81882210d) | main ancestry |
| `test/em092-093-native-exchange` | [`0cb10f4f97672f8f7992205682d5b9ff5b049038`](https://github.com/zukera2-stack/Factorio/commit/0cb10f4f97672f8f7992205682d5b9ff5b049038) | main ancestry |
| `test/em094a-terminal-integration` | [`89f6d3d21863f2fe82cf8235e02c52e68ac880be`](https://github.com/zukera2-stack/Factorio/commit/89f6d3d21863f2fe82cf8235e02c52e68ac880be) | main ancestry |
| `test/em094c-topology-pending` | [`06529e7fedde4176b966d9d17f2ded738260f33e`](https://github.com/zukera2-stack/Factorio/commit/06529e7fedde4176b966d9d17f2ded738260f33e) | main ancestry |
| `test/em094d3-full-regression` | [`44d129087d976a7f599f5045e331a2a45eccb939`](https://github.com/zukera2-stack/Factorio/commit/44d129087d976a7f599f5045e331a2a45eccb939) | main ancestry |
| `test/updater-approved` | [`c8a1feddddfb3f160eae5f63cd1b0231e2136ce3`](https://github.com/zukera2-stack/Factorio/commit/c8a1feddddfb3f160eae5f63cd1b0231e2136ce3) | main ancestry |

## Original open PRs at snapshot

All are historical/superseded by PR #91 or archived research, not a new gameplay merge. The original PR discussions remain. Actual issue tickets are not closed by this cleanup.

| PR | Branch | Exact head | Retention |
|---|---|---|---|
| [#90](https://github.com/zukera2-stack/Factorio/pull/90) | `experiment/em094d4-anchor-settlement` | `949a99f2f281fc226356d5f6e247a84dce12b4f8` | main ancestry |
| [#89](https://github.com/zukera2-stack/Factorio/pull/89) | `test/em094d3-full-regression` | `44d129087d976a7f599f5045e331a2a45eccb939` | main ancestry |
| [#88](https://github.com/zukera2-stack/Factorio/pull/88) | `experiment/em094d2-bridge-output-capacity` | `ae5d032dab8db9ed5e5250f5fd6eb017edb63834` | main ancestry |
| [#87](https://github.com/zukera2-stack/Factorio/pull/87) | `docs/blender-unity-skill-20261124` | `ae441037a0ce0c4ea3bbdbcab2f5d6f3cae32b8f` | archive-only ancestry |
| [#86](https://github.com/zukera2-stack/Factorio/pull/86) | `fix/em078-hide-technical-no-path-icons-20261123` | `b9e494c4963483269265b4eff4c9d3ba5cc093e9` | main ancestry |
| [#85](https://github.com/zukera2-stack/Factorio/pull/85) | `experiment/em077-block-traction-200-native-20261123` | `651e760323715f7d45890a3bd3760c5c20437b32` | main ancestry |
| [#84](https://github.com/zukera2-stack/Factorio/pull/84) | `fix/em076-traction-power-status-20261123` | `adcf849ddcafafbaa4e4369f389cdb726d455280` | main ancestry |
| [#83](https://github.com/zukera2-stack/Factorio/pull/83) | `fix/em074-20mw-parallel-only-20261123` | `21114f065828432274604054c0bfc80afd61ee92` | main ancestry |
| [#82](https://github.com/zukera2-stack/Factorio/pull/82) | `docs/factorio-library-entrypoint-20261123` | `b25ebc7b9dbbd5506d812751a7ad9bcbeb6fcfb6` | archive-only ancestry |
| [#81](https://github.com/zukera2-stack/Factorio/pull/81) | `docs/owner-approved-parallel-20mw-20261123` | `e14864b877dc58bbdf2757008b1fba6a8b2c9fcd` | archive-only ancestry |
| [#80](https://github.com/zukera2-stack/Factorio/pull/80) | `docs/em065-audit-20261122-cross-branch` | `95f55f4ee2134d7a544487477656fcaaef912040` | archive-only ancestry |
| [#79](https://github.com/zukera2-stack/Factorio/pull/79) | `audit/em065-native-multitrain-20261122` | `718a8011edf38a064364f7ceb9c7e2529b5a6799` | archive-only ancestry |
| [#76](https://github.com/zukera2-stack/Factorio/pull/76) | `experiment/em065-source-paid-locomotive-drive-native` | `053fdd9d528b39db8f57eba5698aebfe9d79c506` | main ancestry |
| [#75](https://github.com/zukera2-stack/Factorio/pull/75) | `experiment/em063-source-traction-audit-legacy-pole-20261122` | `eeccfcc9b15cefb808423731e506d4a112c0bbc4` | main ancestry |
| [#72](https://github.com/zukera2-stack/Factorio/pull/72) | `experiment/em063-fault-matrix-parallel-20261122` | `cbd5e6c76b7c7d7f43790044427e0ce20b11191b` | archive-only ancestry |
| [#70](https://github.com/zukera2-stack/Factorio/pull/70) | `docs/em072-c5-crossbranch-index-20261122` | `87c826f505fa25f705dc6f907956844762b65ec2` | archive-only ancestry |
| [#69](https://github.com/zukera2-stack/Factorio/pull/69) | `experiment/em072-c5-client-gui-observer` | `1d68af703ef6f6ab3bb6fa7130a8bbfe90a453d1` | archive-only ancestry |
| [#68](https://github.com/zukera2-stack/Factorio/pull/68) | `experiment/em072-c4-locomotive-mounted-booster` | `6e71496bb7972efc989f8b7d9398591335a43f97` | archive-only ancestry |
| [#67](https://github.com/zukera2-stack/Factorio/pull/67) | `experiment/em072-c3-native-zero-length-phantom` | `7b1f2f89fb0649bf0e65bbf7e3181a11ebf1251b` | archive-only ancestry |
| [#66](https://github.com/zukera2-stack/Factorio/pull/66) | `experiment/em072-c2-maxpower-runtime-api` | `6fa82b49e07df9285f2937e3f1132fb340a6eaa0` | archive-only ancestry |
| [#65](https://github.com/zukera2-stack/Factorio/pull/65) | `experiment/em072-c-motor-wagon-native-blocker` | `07ca502c134fb5843fdbd5d2423953b3e74e579e` | archive-only ancestry |
| [#64](https://github.com/zukera2-stack/Factorio/pull/64) | `experiment/em072-b10r-compliant-loco-bus` | `72b86a539dda638becf33591aa8cf39083f86457` | archive-only ancestry |
| [#63](https://github.com/zukera2-stack/Factorio/pull/63) | `docs/em072-train-bus-current-state-20261122` | `7c9e98acbc0ddb7b17e4e7cd4667aa36b1b4cefb` | archive-only ancestry |
| [#62](https://github.com/zukera2-stack/Factorio/pull/62) | `experiment/em072a5-native-train-bus-b10` | `f909a7670813699a72ffeb5906942ea87fc73f81` | archive-only ancestry |
| [#61](https://github.com/zukera2-stack/Factorio/pull/61) | `experiment/em072a5-native-loco-battery-b9` | `f1e6b5ee65cb43f638ad5558b8e88cc8b6007c9c` | archive-only ancestry |
| [#60](https://github.com/zukera2-stack/Factorio/pull/60) | `experiment/em072a5-native-sharedline-b8` | `e9c70b2e5d7d788fe686806ea9f4a83090115bcd` | archive-only ancestry |
| [#59](https://github.com/zukera2-stack/Factorio/pull/59) | `experiment/em072a5-native-demand-cache-b7` | `c5f2cacc4189d04533afac5ac0f9ba05531e8bfd` | archive-only ancestry |
| [#58](https://github.com/zukera2-stack/Factorio/pull/58) | `experiment/em072a5-native-brownout-b6` | `80f41b04f1299071d263a228f9bf4fcc4779454d` | archive-only ancestry |
| [#57](https://github.com/zukera2-stack/Factorio/pull/57) | `experiment/em072a5-native-dualcomponent-b5` | `219edd0d4247986f1beb336761604b02fdf3744c` | archive-only ancestry |
| [#56](https://github.com/zukera2-stack/Factorio/pull/56) | `experiment/em072a5-native-lifecycle-b4` | `75e8878dc9f2ff3fb0b7d8aa91d409cd7a07f2fb` | archive-only ancestry |
| [#55](https://github.com/zukera2-stack/Factorio/pull/55) | `experiment/em072a5-native-recharge-b3` | `e2621ef94ae45f914273c86dd590b2934cc8321f` | archive-only ancestry |
| [#54](https://github.com/zukera2-stack/Factorio/pull/54) | `experiment/em072a5-native-buffer-b1` | `8531bf0eb726de98ecdfa534b1d48233ef6b3d3d` | archive-only ancestry |
| [#53](https://github.com/zukera2-stack/Factorio/pull/53) | `experiment/em072a5-native-overload-b0` | `ba19d1a53ac7d99ed23aed0e021eb7c484f68f76` | archive-only ancestry |
| [#52](https://github.com/zukera2-stack/Factorio/pull/52) | `experiment/em072a5-buffer-outpost-design` | `5cb0ec316b540857e3821bba9f26bd0eab069734` | archive-only ancestry |
| [#51](https://github.com/zukera2-stack/Factorio/pull/51) | `experiment/native-em070-multitrain-cache-072a4` | `e200614daddb70915193071b65476b3fd5c554c1` | archive-only ancestry |
| [#50](https://github.com/zukera2-stack/Factorio/pull/50) | `experiment/native-em070-auto-demand-072a3` | `c8618aaf7ba419873350df21b1185e5493a72054` | archive-only ancestry |
| [#49](https://github.com/zukera2-stack/Factorio/pull/49) | `experiment/native-em070-burner-debit-072a2` | `04e70e365d5d69d1d47ae47b1b8f26c864dbe4cf` | archive-only ancestry |
| [#48](https://github.com/zukera2-stack/Factorio/pull/48) | `experiment/native-burner-traction-072a` | `10859a93571d816762964113e84af3d87996ab07` | archive-only ancestry |
| [#45](https://github.com/zukera2-stack/Factorio/pull/45) | `experiment/native-dynamic-eei-070` | `5a2d7861e87eb4723ce461aff832bc98b5a422db` | main ancestry |
| [#44](https://github.com/zukera2-stack/Factorio/pull/44) | `experiment/eei-buffer-lifecycle-069` | `5c8f120b24b2a7d3382ac75156f217030c2b31f3` | main ancestry |
| [#43](https://github.com/zukera2-stack/Factorio/pull/43) | `experiment/eei-disposal-diagnostics-068` | `064682e4acc4ccb557741dfae3cc206afe816c29` | main ancestry |
| [#42](https://github.com/zukera2-stack/Factorio/pull/42) | `experiment/dispatch-cache-067` | `0215b599c2bc80fbd750190ea19095cc31328183` | main ancestry |
| [#41](https://github.com/zukera2-stack/Factorio/pull/41) | `experiment/switching-dissipation-policy-066` | `9042dd6b3e7c56ad05a4f37f6f4ca1f611306136` | main ancestry |
| [#40](https://github.com/zukera2-stack/Factorio/pull/40) | `experiment/closed-energy-ledger-065` | `8497f9a343412281a1160de2e8b3a7e5e921560d` | main ancestry |
| [#39](https://github.com/zukera2-stack/Factorio/pull/39) | `experiment/topology-lifecycle-064` | `305d0dd93d811dc714b6b1c20632a9f49782a73e` | main ancestry |
| [#38](https://github.com/zukera2-stack/Factorio/pull/38) | `experiment/buffer-flush-063` | `4c050e598e19d4bf9607d7670c7972373e4cdce9` | main ancestry |
| [#37](https://github.com/zukera2-stack/Factorio/pull/37) | `experiment/buffer-source-sink-063` | `e52d59e9ce4225506deb29de312f90224f330a2c` | main ancestry |
| [#36](https://github.com/zukera2-stack/Factorio/pull/36) | `experiment/network-fair-share-opt-062` | `6f8a8d8fe8fe142e39ff602b910b2ca1d251100c` | main ancestry |
| [#35](https://github.com/zukera2-stack/Factorio/pull/35) | `experiment/network-fair-share-062` | `08b8b656983705619c4cc511e62f13e535baa79f` | main ancestry |
| [#34](https://github.com/zukera2-stack/Factorio/pull/34) | `feature/local-qa-library-061` | `ae2fb16f83779fe7f5ecd6aaa7a0515a737571b8` | archive-only ancestry |
| [#33](https://github.com/zukera2-stack/Factorio/pull/33) | `feature/handoff-061-patcher-promotion` | `c0f0a3692f008a063ed691e6ced665fb28e02d06` | archive-only ancestry |
