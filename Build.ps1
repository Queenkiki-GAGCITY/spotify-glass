$ErrorActionPreference='Stop'
$manifestPath=Join-Path $PSScriptRoot 'manifest.json'
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$assetRoot=Join-Path $PSScriptRoot 'assets'
$manifest.assets=@(Get-ChildItem -LiteralPath $assetRoot -File -Recurse | Sort-Object FullName | ForEach-Object {
    @{path=$_.FullName.Substring($assetRoot.Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
})
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
$dist=Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$zip=Join-Path $dist ("Spotify-Glass-v"+$manifest.version+'.zip')
Add-Type -AssemblyName System.IO.Compression
$stream=[IO.File]::Open($zip,[IO.FileMode]::Create)
$archive=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in (Get-ChildItem -LiteralPath $PSScriptRoot -File -Recurse -Force)) {
        $relative=$file.FullName.Substring($PSScriptRoot.Length+1).Replace('\','/')
        if ($relative -match '^(dist/|\.git/|tests/\.test-)') { continue }
        $entry=$archive.CreateEntry($relative,[IO.Compression.CompressionLevel]::Optimal)
        $input=[IO.File]::OpenRead($file.FullName)
        $output=$entry.Open()
        try { $input.CopyTo($output) } finally { $input.Dispose(); $output.Dispose() }
    }
} finally { $archive.Dispose(); $stream.Dispose() }
Get-FileHash -LiteralPath $zip -Algorithm SHA256 | ForEach-Object { ($_.Hash.ToLowerInvariant()+'  '+[IO.Path]::GetFileName($zip)) | Set-Content -LiteralPath ($zip+'.sha256') -Encoding ASCII }
Write-Host "Built: $zip"
