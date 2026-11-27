# EM135 release integration — 2026-11-27

Runtime candidate 0.1.134; no gameplay edits in EM135. Parent main 362c6f22e8174cd2e06141dcbeaba8dce5a2026e (0.1.103). Owner's actual installed 0.1.133 payload tree SHA256 51b373c7b342d1fc661f1fd926c3354c25147478ef729a214e9be1e52d7d46c5, exactly matching retained local 0.1.133. Copied to isolated temporary staging folder; applied only EM134 diff there. Verified 500 files / 427 PNG, tree SHA256 b2038ea54154c929086d39ffe3997bad1b88c01df916a4455c9b5f120bf51f42, matches canonical archive. ZIP SHA256 8cc481f21029fc415f9301e7d924ee3d469860112624fbb11649b7b53d60c8bc; library /Factorio/Working-Mod/ElectrifiedMainline_0.1.134.zip. No changes to owner installation.

All runtime files tracked, no historical sprite overlays for 0.1.134. Exact manifest updated; old historical manifests remain in Git history. Build workflow restricts old EM080/081/083 staging to the historical 0.1.85/103 versions; exact payload gate retained. Git attributes protect byte parity.

Owner-approved standard batteries and regen: docs/decisions/EM130_STANDARD_ENERGY_2026-11-27.md. Projection: docs/ROLLING_STOCK_PROJECTION.md. Prior documentation PRs #92/93 have not been merged to main. Source assets preserved in library /Factorio/Models/Factorio_rolling_stock_source_backup_EM127.zip (SHA256 cc21aca47b94e065d3649e45b15e16025216b8b152e0555c21d4df5f04921c0a), /Factorio_EM127_sources_part1.zip and /Factorio_EM127_sources_part2.zip. Removed developer commands retained in /Factorio/EM134_developer_tools.zip (outside runtime).

Evidence: EM094 111/111 on 0.1.103; EM130 targeted 12/12 and 2 migrations on 0.1.130; EM133 targeted status scenarios and owner acceptance. EM134 static verification previously reported; no new gameplay tests in EM135. Do not equate packaging parity with gameplay verification. CI skipped per user request; Windows EM134 headlight/GUI, full current regression, multiplayer and UPS not established. Old issues #73,74,77,78 not closed here. License, author, thumbnail, changelog, portal description pending EM136 and owner approval.

No main merge, tag, release, game install or upload to Mod Portal.
