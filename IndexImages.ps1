param(
    [Parameter(Mandatory = $true)][string]$FolderPath,
    [string]$CatalogPath = (Join-Path $PSScriptRoot 'ImageCatalog.txt')
)

$ErrorActionPreference = 'Stop'
$extensions = @('.png', '.jpg', '.jpeg', '.bmp', '.gif', '.webp')

if (-not (Test-Path -LiteralPath $FolderPath -PathType Container)) {
    throw "Folder not found: $FolderPath"
}

$images = @(
    Get-ChildItem -LiteralPath $FolderPath -File -ErrorAction Stop |
        Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
        Sort-Object Name |
        Select-Object -ExpandProperty FullName
)

$parent = Split-Path -Parent $CatalogPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    [void](New-Item -ItemType Directory -Path $parent)
}

$temp = "$CatalogPath.tmp"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($temp, [string[]]$images, $utf8NoBom)
Move-Item -LiteralPath $temp -Destination $CatalogPath -Force

Write-Output $images.Count
