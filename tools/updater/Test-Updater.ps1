$ErrorActionPreference='Stop'
$mods=Join-Path $env:RUNNER_TEMP 'em updater QA\mods'
$updater=Join-Path $PSScriptRoot 'Updater.ps1'
$zip=Join-Path $mods 'ElectrifiedMainline_0.1.60.zip'
$hash=(Get-FileHash $zip).Hash
Set-Content -LiteralPath (Join-Path $mods 'mod-list.json') -Value '{"mods":[]}'
$other=Join-Path $mods 'OtherMod_1.0.0.zip'
Set-Content -LiteralPath $other -Value 'sentinel'
$modListHash=(Get-FileHash (Join-Path $mods 'mod-list.json')).Hash
$otherHash=(Get-FileHash $other).Hash
function Invoke-Update([string]$action) {
    $output = & $updater -Action $action -ModsPath $mods -Yes 6>&1
    $output | Out-Host
    return ($output | Out-String)
}
function Assert([bool]$condition,[string]$message) { if (!$condition) { throw $message } }
$first=Invoke-Update 'Update'
Assert ($first -match 'reused 129; fetched 0') 'Initial ZIP should reuse all bytes'
$root=Join-Path $mods 'ElectrifiedMainline'
Assert (Test-Path (Join-Path $root 'info.json')) 'Unpacked install absent'
Assert (!(Test-Path $zip)) 'Old ZIP should be moved outside mods'
$verify=Invoke-Update 'Verify'
Assert ($verify -match 'VERIFY OK') 'Verification failed'
$script=Join-Path $root 'control.lua'
$original=(Get-FileHash $script).Hash
Add-Content -LiteralPath $script -Value '-- deliberate test modification'
$damaged=(Get-FileHash $script).Hash
$failed=$false
try { & $updater -Action Verify -ModsPath $mods -Yes } catch { $failed=$true }
Assert $failed 'Modified install not detected'
$repair=Invoke-Update 'Update'
Assert ($repair -match 'reused 128; fetched 1') 'Incremental update did not reuse 128 files'
Assert ((Get-FileHash $script).Hash -eq $original) 'Fetched blob differs'
[void](Invoke-Update 'Rollback')
Assert ((Get-FileHash $script).Hash -eq $damaged) 'First rollback failed'
[void](Invoke-Update 'Rollback')
Assert ((Get-FileHash $zip).Hash -eq $hash) 'Second rollback did not restore exact original ZIP'
Assert (!(Test-Path $root)) 'Rollback left duplicate mod'
Assert ((Get-FileHash $other).Hash -eq $otherHash) 'Other mod touched'
Assert ((Get-FileHash (Join-Path $mods 'mod-list.json')).Hash -eq $modListHash) 'mod-list changed'
# Refuse duplicates without modifying either copy.
New-Item -ItemType Directory -Path $root | Out-Null
$failed=$false
try { & $updater -Action Update -ModsPath $mods -Yes } catch { $failed=$true }
Assert $failed 'Multiple copies accepted'
Assert ((Get-FileHash $zip).Hash -eq $hash) 'Duplicate safety check altered ZIP'
Write-Host 'UPDATER WINDOWS PASS: actual Git approved ref, byte-exact initial conversion, one-blob repair, verify, two rollbacks, duplicate refusal and other mod untouched.'
