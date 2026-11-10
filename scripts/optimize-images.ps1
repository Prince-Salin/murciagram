<#
.SYNOPSIS
    Genera las versiones optimizadas de las fotografías de MurciaGram.

.DESCRIPTION
    Lee las imágenes originales de assets/raw y exporta cuatro variantes por foto
    en assets/img:

        <nombre>-mobile.jpg     400 px de ancho, calidad 82
        <nombre>-mobile.webp    400 px de ancho, calidad 80
        <nombre>-desktop.jpg   1000 px de ancho, calidad 82
        <nombre>-desktop.webp  1000 px de ancho, calidad 80

    Todas las variantes se generan con -auto-orient (respeta la orientación EXIF),
    -strip (elimina metadatos) y espacio de color sRGB.

.PARAMETER RawDir
    Carpeta con las imágenes originales. Por defecto: assets/raw

.PARAMETER OutDir
    Carpeta de salida. Por defecto: assets/img

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\optimize-images.ps1

.EXAMPLE
    .\scripts\optimize-images.ps1 -MobileWidth 480 -JpgQuality 78
#>
[CmdletBinding()]
param(
    [string] $RawDir,
    [string] $OutDir,
    [int]    $MobileWidth = 400,
    [int]    $DesktopWidth = 1000,
    [int]    $JpgQuality = 82,
    [int]    $WebpQuality = 80
)

$ErrorActionPreference = "Stop"

# Windows PowerShell 5.1 usa la página de códigos del sistema en la consola.
# Forzar UTF-8 evita que los acentos salgan como caracteres extraños.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ruta del propio script (compatible con Windows PowerShell 5.1 al usar -File)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $RawDir) { $RawDir = Join-Path $scriptDir "..\assets\raw" }
if (-not $OutDir) { $OutDir = Join-Path $scriptDir "..\assets\img" }

# --- Localizar ImageMagick -------------------------------------------------
function Resolve-Magick {
    $cmd = Get-Command magick -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $found = Get-ChildItem "C:\Program Files\ImageMagick-*\magick.exe" -ErrorAction SilentlyContinue |
             Sort-Object FullName -Descending |
             Select-Object -First 1
    if ($found) { return $found.FullName }

    throw "No se ha encontrado ImageMagick. Instálalo con 'winget install ImageMagick.ImageMagick' y vuelve a ejecutar la tarea."
}

$magick = Resolve-Magick
if (-not (Test-Path -Path $RawDir -PathType Container)) {
    throw "No existe la carpeta de originales '$RawDir'. Créala y copia allí las fotos originales antes de ejecutar la tarea."
}
$RawDir = (Resolve-Path $RawDir).Path
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

Write-Host ""
Write-Host "MurciaGram - optimización de imágenes" -ForegroundColor Magenta
Write-Host "ImageMagick : $magick"
Write-Host "Origen      : $RawDir"
Write-Host "Destino     : $OutDir"
Write-Host ""

# --- Procesar --------------------------------------------------------------
$extensions = @(".jpg", ".jpeg", ".png", ".tif", ".tiff", ".webp", ".bmp")
$sources = Get-ChildItem -Path $RawDir -File | Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() }

if (-not $sources) {
    Write-Warning "No hay imágenes en $RawDir. Copia las fotos originales y vuelve a ejecutar la tarea."
    exit 0
}

$sizes = @(
    @{ Suffix = "mobile";  Width = $MobileWidth },
    @{ Suffix = "desktop"; Width = $DesktopWidth }
)

$rows = @()
$totalRaw = 0
$totalOut = 0
$failed = 0

foreach ($src in $sources) {
    $base = $src.BaseName.ToLowerInvariant() -replace "[^a-z0-9]+", "-"
    $totalRaw += $src.Length

    foreach ($size in $sizes) {
        $jpg  = Join-Path $OutDir ("{0}-{1}.jpg"  -f $base, $size.Suffix)
        $webp = Join-Path $OutDir ("{0}-{1}.webp" -f $base, $size.Suffix)
        $resize = "{0}x>" -f $size.Width

        & $magick $src.FullName -auto-orient -strip -colorspace sRGB `
            -resize $resize -interlace Plane -sampling-factor 4:2:0 `
            -quality $JpgQuality $jpg
        if ($LASTEXITCODE -ne 0) { $failed++; Write-Warning "Error generando $jpg"; continue }

        & $magick $src.FullName -auto-orient -strip -colorspace sRGB `
            -resize $resize -quality $WebpQuality -define webp:method=6 $webp
        if ($LASTEXITCODE -ne 0) { $failed++; Write-Warning "Error generando $webp"; continue }

        $jpgInfo  = Get-Item $jpg
        $webpInfo = Get-Item $webp
        $totalOut += $jpgInfo.Length + $webpInfo.Length

        $rows += [pscustomobject]@{
            Archivo = $webpInfo.Name
            "WebP"  = "{0:N0} KB" -f ($webpInfo.Length / 1KB)
            "JPG"   = "{0:N0} KB" -f ($jpgInfo.Length / 1KB)
        }
        $rows += [pscustomobject]@{
            Archivo = $jpgInfo.Name
            "WebP"  = "-"
            "JPG"   = "{0:N0} KB" -f ($jpgInfo.Length / 1KB)
        }
    }
}

# --- Resumen ---------------------------------------------------------------
$rows | Format-Table -AutoSize

$average = if ($rows.Count -gt 0) { $totalOut / $rows.Count } else { 0 }
Write-Host ("Fotografías procesadas    : {0}" -f $sources.Count)
Write-Host ("Archivos generados        : {0}" -f $rows.Count)
Write-Host ("Peso de los originales    : {0:N0} KB" -f ($totalRaw / 1KB))
Write-Host ("Peso de las variantes     : {0:N0} KB" -f ($totalOut / 1KB))
Write-Host ("Peso medio por variante   : {0:N0} KB" -f ($average / 1KB)) -ForegroundColor Green

if ($failed -gt 0) {
    Write-Warning ("{0} archivo(s) no se pudieron generar." -f $failed)
    exit 1
}
