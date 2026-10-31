. (Join-Path (Split-Path $PSScriptRoot) 'Common.ps1')
$package=Split-Path $PSScriptRoot
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('SpotifyGlass-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'Extensions') | Out-Null
$config=Join-Path $fixture 'config-xpui.ini'
$initial="[Setting]`r`nspotify_path = C:\Example\Spotify`r`ncurrent_theme = ExistingTheme`r`ninject_css = 0`r`n[AdditionalOptions]`r`nextensions = existing.js|fullAppDisplay.js`r`ncustom_apps = existing-app`r`n[Preprocesses]`r`nexpose_apis = 0`r`n"
Write-GlassText $config $initial
Write-GlassText (Join-Path $fixture 'Extensions/fullAppDisplay.js') 'original extension'
& (Join-Path $package 'Install.ps1') -ConfigRoot $fixture -SkipApply
$installed=[IO.File]::ReadAllText($config)
if ((Get-IniValue $installed 'Setting' 'spotify_path') -ne 'C:\Example\Spotify') { throw 'Spotify path was overwritten.' }
if ((Get-IniValue $installed 'AdditionalOptions' 'extensions') -notmatch 'existing.js') { throw 'Existing extension lost.' }
$failed=$false
try { & (Join-Path $package 'Install.ps1') -ConfigRoot $fixture -SkipApply } catch { $failed=$true }
if (!$failed) { throw 'Duplicate install was not rejected.' }
$installed=Set-IniValue $installed 'AdditionalOptions' 'extensions' ((Get-IniValue $installed 'AdditionalOptions' 'extensions')+'|new.js')
$installed=Set-IniValue $installed 'Setting' 'inject_css' '0'
Write-GlassText $config $installed
$modified=Join-Path $fixture 'Extensions/fadQueueOverlay.js'
[IO.File]::AppendAllText($modified,"`n// changed after install")
& (Join-Path $package 'Uninstall.ps1') -ConfigRoot $fixture -SkipApply
$restored=[IO.File]::ReadAllText($config)
if ((Get-IniValue $restored 'Setting' 'current_theme') -ne 'ExistingTheme') { throw 'Previous theme not restored.' }
if ((Get-IniValue $restored 'Setting' 'inject_css') -ne '0') { throw 'Later setting overwritten.' }
if ((Get-IniValue $restored 'AdditionalOptions' 'extensions') -ne 'existing.js|fullAppDisplay.js|new.js') { throw 'Extension merge restoration failed.' }
if ([IO.File]::ReadAllText((Join-Path $fixture 'Extensions/fullAppDisplay.js')) -ne 'original extension') { throw 'Original file not restored.' }
if (!(Test-Path -LiteralPath $modified)) { throw 'Later file modifications were deleted.' }
if (Test-Path -LiteralPath (Join-Path $fixture 'GlassUI-install.json')) { throw 'Installation receipt not removed.' }
$escaped=$false
try { Get-SafeTarget $fixture '..\outside' | Out-Null } catch { $escaped=$true }
if (!$escaped) { throw 'Path traversal not rejected.' }
Write-Host 'PASS: install/uninstall, merge preservation, existing file backup, later edits, duplicate install, and path containment.'
Write-Host "Isolated fixture retained for inspection: $fixture"
