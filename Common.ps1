$ErrorActionPreference = 'Stop'
function Get-GlassRoot([string]$Path) {
    if (!$Path) { $Path = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'spicetify' }
    return [IO.Path]::GetFullPath($Path).TrimEnd('\')
}
function Get-SafeTarget([string]$Root, [string]$Relative) {
    $target = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (!$target.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Target is outside the configuration folder.' }
    return $target
}
function Get-IniValue([string]$Text, [string]$Section, [string]$Key) {
    $inside = $false
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^\s*\[([^\]]+)\]') { $inside = $Matches[1] -eq $Section; continue }
        if ($inside -and $line -match ('^\s*' + [regex]::Escape($Key) + '\s*=\s*(.*)$')) { return $Matches[1].Trim() }
    }
    return $null
}
function Set-IniValue([string]$Text, [string]$Section, [string]$Key, $Value) {
    $lines = [Collections.Generic.List[string]]::new()
    $inside=$false; $foundSection=$false; $written=$false
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^\s*\[([^\]]+)\]') {
            if ($inside -and !$written -and $null -ne $Value) { $lines.Add("$Key = $Value"); $written=$true }
            $inside=$Matches[1] -eq $Section
            if ($inside) { $foundSection=$true }
        }
        if ($inside -and $line -match ('^\s*' + [regex]::Escape($Key) + '\s*=')) {
            if (!$written -and $null -ne $Value) { $lines.Add("$Key = $Value") }
            $written=$true; continue
        }
        $lines.Add($line)
    }
    if (!$written -and $null -ne $Value) {
        if (!$foundSection) { $lines.Add("[$Section]") }
        $lines.Add("$Key = $Value")
    }
    return $lines -join "`r`n"
}
function Write-GlassText([string]$Path,[string]$Text) { [IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false)) }
function Assert-GlassEnvironment {
    if (!(Get-Command spicetify -ErrorAction SilentlyContinue)) { throw 'Install Spicetify, then open a new PowerShell window.' }
    $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
    if ([Security.Principal.WindowsPrincipal]::new($identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Use a normal PowerShell window, not Administrator.' }
    if (Get-Process -Name Spotify -ErrorAction SilentlyContinue) { throw 'Fully close Spotify before continuing.' }
}
