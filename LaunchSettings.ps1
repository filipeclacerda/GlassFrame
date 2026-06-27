$ErrorActionPreference = 'Stop'
$settingsPath = Join-Path $PSScriptRoot 'Settings.ps1'
$env:GLASSFRAME_ROOT = $PSScriptRoot
$code = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
Invoke-Expression $code
