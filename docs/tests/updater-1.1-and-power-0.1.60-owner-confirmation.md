# Owner confirmation — Updater 1.1 and ElectrifiedMainline 0.1.60

Date: 2026-11-20. Evidence type: owner conversation plus earlier measured logs and CI. No new raw log was provided with the final confirmation.

2026-11-20 owner confirmation: Updater 1.1 installed 0.1.60 successfully on the owner's Windows PC after the previous 1.0 clean-install connection failure. Owner reported energy transfer restored after configuring editor EEIs as primary_output/secondary_input using the previously verified console commands. This is owner chat confirmation, not a new measured log; prior 060 log factorio-current(20261120-155649).log lines 685–718 independently established sustained 20 MW. Scoped acceptance: updater installation and configured automatic transfer PASS. Not full release acceptance: arbitrary/tertiary EEI modes, ordinary generators, Bob's battery integration, owner accumulator reversal, live rail-break recovery, larger grids, actual retry after connection interruption and owner rollback remain open. 0.1.61 next: research all EEI modes and native ordinary loads, fix dispatch, localized substation GUI (actual signed MW, planned MW, mode, connectivity, idle reason), expanded native headless tests. Preserve frozen 83 PNGs and native isolation. Distribute subsequent test builds via explicitly promoted test/updater-approved only after CI and relevant engine QA; keep CI ZIP fallback. Main 0.1.56 unchanged; no merge approval.

## Reproduction
1. Close Factorio, run Updater 1.1, select installation. Owner message: «патчер загрузил мод, только я опять источники не могу настроить».
2. In a disposable test save configure the two native editor EEIs: source `primary_output`, production and output limit `20000000/60` J/tick, zero input/usage; sink `secondary_input`, usage and input limit `20000000/60` J/tick, zero generation/output. Both buffers 10 MJ; sink starts empty. Use `/em-25kv-mode status` on stations after settling. `/c` may disable achievements.
3. Following the instructions, owner replied «есть». Interpreted within the exchange as restored transfer, not as a fresh quantified 20 MW measurement.

## Provenance
- [Windows updater QA](https://github.com/zukera2-stack/Factorio/actions/runs/44783774432), [artifact](https://github.com/zukera2-stack/Factorio/actions/runs/44783774432/artifacts/14650879317), source `e834a839fee5982e7ec7409945017ce1cd2321db`.
- Approved ref `test/updater-approved` at `ea9366a9798cd78efec4b675c81d086c09170c28`; [byte-identical fast package](https://github.com/zukera2-stack/Factorio/actions/runs/44772684519), 129 files / 83 PNGs, inner ZIP SHA256 `10b00013e66ed1d63ec901449fb166ab9a80fa391c2afb0d0f0c0910901fcbf9`.
- [Native 2.1.24 headless QA](https://github.com/zukera2-stack/Factorio/actions/runs/44762226742), vanilla accumulator charge/reverse confirmed in controlled fixture only.
- Previous owner measured log `factorio-current(20261120-155649).log`, lines 685–718: sustained 20 MW after explicit interface configuration. Unconfigured tertiary case remains unresolved.

## Decision
Do not merge main or change approved ref here. Next work 0.1.61 remains planned. No runtime changes in this documentation update.
