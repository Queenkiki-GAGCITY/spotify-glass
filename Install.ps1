param([string]$ConfigRoot, [switch]$SkipApply)
. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$SkipApply) { Assert-GlassEnvironment }
$root=Get-GlassRoot $ConfigRoot
$config=Get-SafeTarget $root 'config-xpui.ini'
if (!(Test-Path -LiteralPath $config)) { throw 'Spicetify configuration not found. Initialize Spicetify first.' }
$receipt=Get-SafeTarget $root 'GlassUI-install.json'
if (Test-Path -LiteralPath $receipt) { throw 'Spotify Glass is already installed. Uninstall it before installing this release again.' }
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest.assets) {
    $source=Join-Path $PSScriptRoot ('assets\'+$entry.path)
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Package integrity check failed: $($entry.path)" }
}
$backupRelative='GlassUI-backups\'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
$backup=Get-SafeTarget $root $backupRelative
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Copy-Item -LiteralPath $config -Destination (Join-Path $backup 'config-before.ini')
$before=[IO.File]::ReadAllText($config); $text=$before
$settings=@(
    @{section='Setting';key='current_theme';value='QuietLyrics'},
    @{section='Setting';key='inject_css';value='1'},
    @{section='Setting';key='replace_colors';value='0'},
    @{section='Preprocesses';key='expose_apis';value='1'}
)
foreach ($item in @(
    @{key='extensions';entries=@('fadQueueOverlay.js','fitFadTitle.js','fullAppDisplay.js')},
    @{key='custom_apps';entries=@('lyrics-plus')}
)) {
    $old=Get-IniValue $before 'AdditionalOptions' $item.key
    $existing=@($old -split '\|' | Where-Object { $_ })
    $merged=@($existing)+@($item.entries | Where-Object { $_ -notin $existing })
    $settings+=@{section='AdditionalOptions';key=$item.key;value=($merged -join '|');added=@($item.entries | Where-Object { $_ -notin $existing })}
}
$state=[ordered]@{version='0.1.0';backup=$backupRelative;files=@();settings=@()}
foreach ($setting in $settings) {
    $state.settings+=@{section=$setting.section;key=$setting.key;before=(Get-IniValue $before $setting.section $setting.key);installed=$setting.value;added=$setting.added}
    $text=Set-IniValue $text $setting.section $setting.key $setting.value
}
try {
    foreach ($entry in $manifest.assets) {
        $target=Get-SafeTarget $root $entry.path
        $exists=Test-Path -LiteralPath $target
        if ($exists) {
            $saved=Join-Path $backup $entry.path
            New-Item -ItemType Directory -Force -Path (Split-Path $saved) | Out-Null
            Copy-Item -LiteralPath $target -Destination $saved
        }
        $state.files+=@{path=$entry.path;existed=$exists;installed=$entry.sha256}
        New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot ('assets\'+$entry.path)) -Destination $target -Force
    }
    Write-GlassText $config $text
    Write-GlassText (Join-Path $backup 'state.json') ($state | ConvertTo-Json -Depth 8)
    if (!$SkipApply) {
        spicetify apply
        if ($LASTEXITCODE -ne 0) { throw 'Spicetify apply failed; restoring pre-install files.' }
    }
    Write-GlassText $receipt ($state | ConvertTo-Json -Depth 8)
} catch {
    Write-GlassText $config $before
    foreach ($entry in $state.files) {
        $target=Get-SafeTarget $root $entry.path
        if ($entry.existed) { Copy-Item -LiteralPath (Join-Path $backup $entry.path) -Destination $target -Force }
        elseif (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
    }
    throw
}
Write-Host 'Spotify Glass installed. Run: spicetify auto'
