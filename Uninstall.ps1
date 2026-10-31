param([string]$ConfigRoot, [switch]$SkipApply)
. (Join-Path $PSScriptRoot 'Common.ps1')
if (!$SkipApply) { Assert-GlassEnvironment }
$root=Get-GlassRoot $ConfigRoot
$receipt=Get-SafeTarget $root 'GlassUI-install.json'
if (!(Test-Path -LiteralPath $receipt)) { throw 'No Spotify Glass installation receipt found.' }
$state=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
$backup=Get-SafeTarget $root $state.backup
$config=Get-SafeTarget $root 'config-xpui.ini'
$text=[IO.File]::ReadAllText($config)
foreach ($setting in $state.settings) {
    $current=Get-IniValue $text $setting.section $setting.key
    if ($setting.key -in @('extensions','custom_apps')) {
        $remaining=@($current -split '\|' | Where-Object { $_ -and $_ -notin @($setting.added) }) -join '|'
        if ($remaining -eq '' -and $null -eq $setting.before) { $remaining=$null }
        $text=Set-IniValue $text $setting.section $setting.key $remaining
    } elseif ($current -eq $setting.installed) {
        $text=Set-IniValue $text $setting.section $setting.key $setting.before
    } else { Write-Warning "Keeping your newer configuration: $($setting.key)" }
}
$conflicts=@()
foreach ($entry in $state.files) {
    $target=Get-SafeTarget $root $entry.path
    if (Test-Path -LiteralPath $target) {
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $entry.installed) {
            $conflicts+=$entry.path;Write-Warning "Keeping modified file: $($entry.path)";continue
        }
    }
    if ($entry.existed) { Copy-Item -LiteralPath (Get-SafeTarget $backup $entry.path) -Destination $target -Force }
    elseif (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
}
Write-GlassText $config $text
if (!$SkipApply) {
    spicetify apply
    if ($LASTEXITCODE -ne 0) { throw 'Files restored, but apply failed. Backup and receipt retained. Retry after fixing Spicetify.' }
}
Copy-Item -LiteralPath $receipt -Destination (Join-Path $backup 'uninstalled-receipt.json') -Force
Remove-Item -LiteralPath $receipt -Force
Write-Host "Spotify Glass removed. Original backups retained at: $backup"
if ($conflicts.Count) { Write-Warning 'Some files were changed after installation and kept. Their original copies remain in the backup folder.' }
