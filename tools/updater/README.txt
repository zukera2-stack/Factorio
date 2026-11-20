# Electrified Mainline Updater (Windows)

1. Close Factorio.
2. Extract these updater files into any folder **outside** Factorio/mods.
3. Run Update.bat. Choose 1 (update), 2 (verify), 3 (rollback).
4. Default mods directory is %APPDATA%\Factorio\mods. If not found, enter your actual mods directory.
   For a custom path even when the default exists:
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Updater.ps1 -Action Update -ModsPath "D:\Games\Factorio\mods"
5. Confirm with y. Open Factorio after UPDATE OK.

Git for Windows and Windows PowerShell 5.1 are required. No Python, admin rights or additional software required.
Only approved test ref test/updater-approved in public zukera2-stack/Factorio is used.
First run reads your current mod ZIP or folder and stages an unpacked mod. Later updates reuse matching local files and request changed Git blobs.
Old mod backups and Git metadata are stored in .em-updater-mods (next to your mods directory).
Rollback restores the most recent previous mod. It does NOT roll back saves. Always back up your test save before loading a changed mod.
If multiple copies of ElectrifiedMainline appear, the updater refuses to choose.
Verify is read-only for installed mod; it may download Git metadata and use a temporary directory.
This tool is not a mod and must not be installed in mods.
