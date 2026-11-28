# EM139 — electric sound mixing and level calibration, 0.2.5
Base: exact EM138 0.2.4 (PR #97, commit 1b009d82308bded6ea681cbf2ba34093875bf613). Owner approved native two-engine-layer mixing with volume calibrated to vanilla. Existing drive/start/stop OGGs and pitch range 0.80–1.45 preserved byte-for-byte; new noise-free 8 s stereo idle loop at 44100 Hz. Native volume-to-activity curves, context modifiers, wheel layer and mechanical triggers copied; hidden 256 boosters remain silent. No energy or graphical changes.

## Numeric calibration
Reference: previous read-only PCM measurements from owner's Factorio 2.1.25. For each clip gain = native_gain * 10^((native_RMS - custom_RMS)/20). Nominal RMS matched within 0.01 dB before dynamic mixing. This is not equal perceived loudness (spectra differ). Values below are not in-game measurements.

| Clip | Native gain | New gain | Reference RMS with gain, dBFS | New RMS with gain, dBFS |
|---|---:|---:|---:|---:|
| drive-loop | 0.70 | 0.86587 | -21.710 | -21.710 |
| idle-loop | 0.35 | 0.34847 | -25.546 | -25.546 |
| start | 0.35 | 0.73462 | -25.627 | -25.627 |
| stop | 0.35 | 0.68456 | -27.246 | -27.246 |

Initial idle OGG seam step exceeded 1.5x adjacent P99; a 5 ms edge taper at both ends reduced decoded seam step to 0.001715 vs P99 0.003800. No audible seam certification. Native Factorio 2.1.24 with Space Age loaded exact package and isolated data-stage assertions PASS, map creation PASS. Actual sound output is disabled in headless; timing of idle/drive switching and perceived volume in client remain unverified. No full gameplay regression, owner installation, merge or publication.

Package: 508 files, 428 PNG unchanged. Four delta files (metadata, changelog, audio prototype, new idle OGG). Full ZIP SHA256 `e46cf4445dfdacdf4867b14d745652e4884e58d8a1e95c181fe59547d9292429`; payload tree `8bbdd6b97942d420b578e5e7b4728329c90603def3bdd1b3a4a35c81a455791b`. Direct patch SHA256 `17dff70fba6810284bb95c375e7bb3a429bacacfdf87109dffa0d5bff57ff30c`.
