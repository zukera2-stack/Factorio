param(
    [ValidateSet('Menu','Update','Verify','Rollback')][string]$Action = 'Menu',
    [string]$ModsPath,
    [switch]$Yes
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Repo = 'https://github.com/zukera2-stack/Factorio.git'
$ApprovedRef = 'refs/heads/test/updater-approved'
$ModName = 'ElectrifiedMainline'
$Git = (Get-Command git.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Run-Git {
    param([string[]]$Arguments)
    $out = & $script:Git -C $script:Cache @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Git failed ($LASTEXITCODE): $($Arguments -join ' ')" }
    return $out
}
function No-Reparse([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Unsafe junction/symlink: $Path" }
}
function Make-Directory([string]$Path) {
    [void][IO.Directory]::CreateDirectory($Path)
    No-Reparse $Path
}
function Assert-Closed {
    if (Get-Process -Name factorio -ErrorAction SilentlyContinue) { throw 'Close Factorio completely before updating or rolling back.' }
}
function Confirm-Action([string]$Message) {
    if ($Yes) { return $true }
    return ((Read-Host "$Message [y/N]") -match '^(y|yes)$')
}
function Safe-Relative([string]$Path) {
    if ($Path -notmatch '^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*$') { throw "Unsafe relative path: $Path" }
    foreach ($part in ($Path -split '/')) {
        if ($part.StartsWith('.') -or $part.EndsWith('.') -or $part -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') { throw "Unsafe file name: $Path" }
    }
}
function Runtime-Path([string]$Path) {
    Safe-Relative $Path
    if ($Path -match '^(info\.json|control\.lua|data\.lua|data-updates\.lua|data-final-fixes\.lua|settings\.lua|settings-updates\.lua|settings-final-fixes\.lua|thumbnail\.png|changelog\.txt)$') { return }
    if ($Path -match '^(scripts|prototypes|compatibility)/.+\.lua$|^migrations/.+\.(lua|json)$|^graphics/.+\.png$|^locale/.+\.cfg$') { return }
    throw "Not an approved runtime file: $Path"
}
function Local-Files([string]$Root) {
    $result = @{}
    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push($Root)
    while ($pending.Count -gt 0) {
        $dir = $pending.Pop()
        No-Reparse $dir
        foreach ($item in Get-ChildItem -LiteralPath $dir -Force) {
            No-Reparse $item.FullName
            if ($item.PSIsContainer) { $pending.Push($item.FullName) }
            else {
                $rel = $item.FullName.Substring($Root.Length+1).Replace('\','/')
                if ($result.ContainsKey($rel)) { throw "Duplicate local file: $rel" }
                $result[$rel] = $item.FullName
            }
        }
    }
    return $result
}
function Read-Info([string]$Root) {
    $p = Join-Path $Root 'info.json'
    if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw "Missing info.json: $Root" }
    No-Reparse $p
    $i = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($i.name -cne $ModName -or $i.version -notmatch '^\d+\.\d+\.\d+$' -or $i.factorio_version -ne '2.1') { throw "Unexpected mod identity: $Root" }
    return $i
}
function Find-Installed {
    $items = @(Get-ChildItem -LiteralPath $ModsPath -Force | Where-Object {
        ($_.PSIsContainer -and $_.Name -match '^ElectrifiedMainline(_\d+\.\d+\.\d+)?$') -or
        (!$_.PSIsContainer -and $_.Name -match '^ElectrifiedMainline(_\d+\.\d+\.\d+)?\.zip$')
    })
    if ($items.Count -gt 1) { throw 'Multiple ElectrifiedMainline copies found. Move old copies out of mods manually; nothing was changed.' }
    if ($items.Count -eq 1) { No-Reparse $items[0].FullName; return $items[0] }
}
function Expand-Installed([string]$Zip,[string]$Dest) {
    Make-Directory $Dest
    $archive = [IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        $seen = @{}
        $total = 0L
        $root = $null
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName.EndsWith('/')) { continue }
            $parts = $entry.FullName.Split('/')
            if ($parts.Count -lt 2 -or $parts[0] -notmatch '^ElectrifiedMainline(_\d+\.\d+\.\d+)?$') { throw "Unexpected ZIP entry: $($entry.FullName)" }
            if ($null -eq $root) { $root = $parts[0] }
            if ($root -cne $parts[0]) { throw 'Multiple ZIP roots.' }
            $rel = ($parts[1..($parts.Count-1)] -join '/')
            Safe-Relative $rel
            if ($seen.ContainsKey($rel)) { throw "Duplicate ZIP entry: $rel" }
            $seen[$rel] = $true
            $total += $entry.Length
            if ($total -gt 536870912) { throw 'Installed mod ZIP exceeds 512 MB safety limit.' }
            $destFile = Join-Path $Dest $rel
            Make-Directory ([IO.Path]::GetDirectoryName($destFile))
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$destFile,$false)
        }
    } finally { $archive.Dispose() }
}
function Init-Cache {
    Make-Directory $Cache
    if (!(Test-Path -LiteralPath (Join-Path $Cache 'HEAD'))) {
        Run-Git @('init','--bare') | Out-Null
        Run-Git @('config','remote.origin.url',$Repo) | Out-Null
        Run-Git @('config','remote.origin.promisor','true') | Out-Null
        Run-Git @('config','remote.origin.partialclonefilter','blob:none') | Out-Null
    }
    if ((Run-Git @('config','--get','remote.origin.url')) -cne $Repo) { throw 'Unexpected cache origin. Stop.' }
    Run-Git @('fetch','--depth=1','--filter=blob:none','--no-tags','origin',"+${ApprovedRef}:refs/heads/approved") | Out-Null
    $commit = [string](Run-Git @('rev-parse','refs/heads/approved^{commit}'))
    if ($commit -notmatch '^[a-f0-9]{40}$') { throw 'Invalid approved commit.' }
    return $commit
}
function Read-Tree([string]$Commit) {
    $result = @{}
    foreach ($line in @(Run-Git @('ls-tree','-r',$Commit,'--','ElectrifiedMainline/'))) {
        if ($line -notmatch '^100644 blob ([a-f0-9]{40})\tElectrifiedMainline/(.+)$') { throw "Unsafe Git entry: $line" }
        $hash = $Matches[1]; $rel = $Matches[2]
        Runtime-Path $rel
        if ($result.ContainsKey($rel)) { throw "Duplicate runtime file: $rel" }
        $result[$rel] = $hash
    }
    foreach ($required in @('info.json','control.lua','data.lua','data-updates.lua','data-final-fixes.lua')) {
        if (!$result.ContainsKey($required)) { throw "Approved tree incomplete: $required" }
    }
    if (@($result.Keys | Where-Object { $_ -like 'graphics/*.png' }).Count -lt 83) { throw 'Approved tree has incomplete artwork.' }
    return $result
}
function File-Hash([string]$File) {
    return [string](Run-Git @('hash-object','--no-filters','--',$File))
}
function Write-Blob([string]$Hash,[string]$Destination) {
    if ($Hash -notmatch '^[a-f0-9]{40}$') { throw 'Invalid blob hash.' }
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $Git
    $psi.WorkingDirectory = $Cache
    $psi.Arguments = "cat-file blob $Hash"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $process = [Diagnostics.Process]::Start($psi)
    try {
        $stream = [IO.File]::Open($Destination,[IO.FileMode]::CreateNew)
        try { $process.StandardOutput.BaseStream.CopyTo($stream) } finally { $stream.Dispose() }
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw "Failed to fetch Git blob $Hash" }
    } finally { $process.Dispose() }
}
function Move-Exact([string]$From,[string]$To) {
    if (Test-Path -LiteralPath $To) { throw "Destination already exists: $To" }
    No-Reparse $From
    if ([IO.Directory]::Exists($From)) { [IO.Directory]::Move($From,$To) }
    else { [IO.File]::Move($From,$To) }
}
function New-BackupDir([string]$Base) {
    $path = Join-Path $Base ((Get-Date -Format 'yyyyMMdd-HHmmss-fffffff')+'-'+[guid]::NewGuid().ToString('N'))
    Make-Directory $path
    return $path
}
function Roll-Back {
    Assert-Closed
    $latest = @(Get-ChildItem -LiteralPath $Backups -Directory | Sort-Object Name -Descending | Select-Object -First 1)
    if (!$latest.Count) { throw 'No backup found.' }
    No-Reparse $latest[0].FullName
    $old = @(Get-ChildItem -LiteralPath $latest[0].FullName -Force)
    if ($old.Count -ne 1 -or $old[0].Name -notmatch '^ElectrifiedMainline(_\d+\.\d+\.\d+)?(\.zip)?$') { throw 'Unexpected backup contents.' }
    No-Reparse $old[0].FullName
    $current = Find-Installed
    if (!(Confirm-Action "Restore $($old[0].Name)? Saves are NOT rolled back.")) { return }
    $displaced = $null
    if ($null -ne $current) {
        $d = New-BackupDir $DisplacedRoot
        $displaced = Join-Path $d $current.Name
        Move-Exact $current.FullName $displaced
    }
    try { Move-Exact $old[0].FullName (Join-Path $ModsPath $old[0].Name) }
    catch { if ($displaced) { Move-Exact $displaced $current.FullName }; throw }
    [IO.Directory]::Delete($latest[0].FullName)
    Write-Host 'ROLLBACK OK. Saves unchanged.' -ForegroundColor Green
}

if (!$ModsPath) {
    $ModsPath = Join-Path $env:APPDATA 'Factorio\mods'
    if (!(Test-Path -LiteralPath $ModsPath -PathType Container)) { $ModsPath = Read-Host 'Enter full Factorio mods folder' }
}
$ModsPath = (Get-Item -LiteralPath $ModsPath -Force).FullName
if (!(Test-Path -LiteralPath $ModsPath -PathType Container)) { throw 'Not a mods directory.' }
No-Reparse $ModsPath
if ($Action -eq 'Menu') {
    Write-Host "Electrified Mainline Updater - $ModsPath"
    Write-Host '1 - Update / install'
    Write-Host '2 - Verify files'
    Write-Host '3 - Rollback previous update'
    $choice = Read-Host 'Select 1, 2 or 3'
    switch ($choice) { '1' {$Action='Update'} '2' {$Action='Verify'} '3' {$Action='Rollback'} default {return} }
}
if ($Action -ne 'Verify') { Assert-Closed }
$Work = Join-Path ([IO.Path]::GetDirectoryName($ModsPath)) ('.em-updater-'+[IO.Path]::GetFileName($ModsPath))
$Cache = Join-Path $Work 'git-cache'
$Backups = Join-Path $Work 'backups'
$DisplacedRoot = Join-Path $Work 'rollback-displaced'
Make-Directory $Work
Make-Directory $Backups
Make-Directory $DisplacedRoot
$lock = [IO.File]::Open((Join-Path $Work 'update.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$temp = $null
try {
    if ($Action -eq 'Rollback') { Roll-Back; return }
    $installed = Find-Installed
    $commit = Init-Cache
    $tree = Read-Tree $commit
    $temp = Join-Path $Work ('stage-'+[guid]::NewGuid().ToString('N'))
    Make-Directory $temp
    $stage = Join-Path $temp $ModName
    Make-Directory $stage
    $local = @{}
    if ($null -ne $installed) {
        $root = $installed.FullName
        if (!$installed.PSIsContainer) {
            $root = Join-Path $temp 'old-zip'
            Expand-Installed $installed.FullName $root
        }
        $info = Read-Info $root
        Write-Host "Installed: $($info.version)"
        $local = Local-Files $root
    } else { Write-Host 'Installed: none' }
    $reuse = @{}; $need = @()
    foreach ($rel in @($tree.Keys | Sort-Object)) {
        if ($local.ContainsKey($rel) -and (File-Hash $local[$rel]) -ceq $tree[$rel]) { $reuse[$rel] = $true }
        else { $need += $rel }
    }
    $extra = @($local.Keys | Where-Object { !$tree.ContainsKey($_) })
    Write-Host "Approved commit: $commit"
    Write-Host "Identical: $($reuse.Count); changed/missing: $($need.Count); obsolete/local extra: $($extra.Count)"
    if ($Action -eq 'Verify') {
        if ($need.Count -or $extra.Count) { throw 'VERIFY FAILED: installed mod differs from approved tree.' }
        Write-Host 'VERIFY OK - all installed files match.' -ForegroundColor Green
        return
    }
    if ($null -ne $installed -and $installed.PSIsContainer -and !$need.Count -and !$extra.Count) {
        Write-Host 'Already up to date.' -ForegroundColor Green
        return
    }
    if (!(Confirm-Action 'Update now? The old mod will be kept outside mods.')) { return }
    # Copy matching local files byte-for-byte; request only changed/missing Git blobs.
    foreach ($rel in @($tree.Keys | Sort-Object)) {
        $target = Join-Path $stage $rel
        Make-Directory ([IO.Path]::GetDirectoryName($target))
        if ($reuse.ContainsKey($rel)) { [IO.File]::Copy($local[$rel],$target,$false) }
        else { Write-Blob $tree[$rel] $target }
        if ((File-Hash $target) -cne $tree[$rel]) { throw "Hash mismatch: $rel" }
    }
    $newInfo = Read-Info $stage
    Write-Host "Verified target: $($newInfo.version)"
    # Recheck process and installed slot after networking. Never overwrite another copy.
    Assert-Closed
    $now = Find-Installed
    if (($null -eq $now) -ne ($null -eq $installed) -or ($null -ne $now -and $now.FullName -cne $installed.FullName)) { throw 'Installed mod changed during update; retry.' }
    $destination = Join-Path $ModsPath $ModName
    $saved = $null
    if ($null -ne $installed) {
        $backup = New-BackupDir $Backups
        $saved = Join-Path $backup $installed.Name
        Move-Exact $installed.FullName $saved
    }
    try { Move-Exact $stage $destination }
    catch { if ($saved) { Move-Exact $saved $installed.FullName }; throw }
    Write-Host "UPDATE OK: $($newInfo.version); reused $($reuse.Count); fetched $($need.Count)." -ForegroundColor Green
    if ($saved) { Write-Host "Backup: $saved" }
    Write-Host 'Saves and mod-list.json unchanged.'
} finally {
    if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Recurse -Force }
    $lock.Dispose()
}
