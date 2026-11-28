# Electrified Mainline 0.2.7

Bugfix and audiovisual update for Factorio 2.1, cumulative since public 0.2.0.

## Changes
- Corrected battery-wagon cooling fan alignment on straight and curved track, including rolling-stock visual displacement.
- Increased cooling animation from 8 to 16 phases per direction, with continuous phase through orientation and speed changes.
- Added original electric traction sounds, quiet idle loop and native activity-based mixing; retained native wheel and brake sounds and silenced technical boosters.
- Stops cooling animation when the battery is empty; refreshes saved rendering objects on update.

## ???????? / Validation
Owner visually accepted 0.2.7 on 2026-11-28 (Windows Factorio 2.1.25, real graphics scenario). Native graphical fixture: 256/256 orientations, 16 stops, 113 screenshot requests, 9399 consecutive phase checks, 536 speed changes. Owner-installed and release package payload: 508/508 exact hashes. Package unit tests 3/3. No new full energy regression, elevated-rail verification, real save migration, multiplayer or UPS tests; not claimed.

Author: Zukera. All Rights Reserved. Developed with AI assistance (ChatGPT).
