# ============================================================
# EXPER IMMO - PWA Setup Script
# Génère les icônes + injecte les balises PWA dans tous les HTML
# ============================================================

$root = $PSScriptRoot

# ============================================================
# 1. GÉNÉRATION DES ICÔNES depuis assets/logo.PNG
# ============================================================
$iconsDir = Join-Path $root "assets\icons"
if (-not (Test-Path $iconsDir)) { New-Item -ItemType Directory -Path $iconsDir | Out-Null }

Add-Type -AssemblyName System.Drawing

$logoPath = Join-Path $root "assets\logo.PNG"
$sizes = @(72, 96, 128, 144, 152, 192, 384, 512)

if (Test-Path $logoPath) {
    $src = [System.Drawing.Image]::FromFile($logoPath)
    foreach ($size in $sizes) {
        $bmp = New-Object System.Drawing.Bitmap($size, $size)
        $g   = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.DrawImage($src, 0, 0, $size, $size)
        $g.Dispose()
        $out = Join-Path $iconsDir "icon-$size.png"
        $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Host "✓ icon-$size.png généré" -ForegroundColor Green
    }
    $src.Dispose()
} else {
    Write-Host "⚠ logo.PNG introuvable - icônes non générées" -ForegroundColor Yellow
}

# ============================================================
# 2. INJECTION DES BALISES PWA DANS TOUS LES FICHIERS HTML
# ============================================================

# Balise PWA à injecter juste AVANT </head>
# Les chemins sont absolus depuis la racine du serveur (commencent par /)
$pwaMeta = @'

    <!-- PWA - Application Mobile -->
    <link rel="manifest" href="/manifest.json">
    <meta name="theme-color" content="#c9a84c">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="EXPER IMMO">
    <link rel="apple-touch-icon" href="/assets/icons/icon-192.png">
    <link rel="icon" type="image/png" sizes="192x192" href="/assets/icons/icon-192.png">
    <link rel="icon" type="image/png" sizes="32x32"  href="/assets/icons/icon-96.png">
    <link rel="shortcut icon" href="/assets/icons/icon-192.png">

'@

# Script SW à injecter juste AVANT </body>
$swScript = @'

    <!-- Service Worker PWA -->
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', function() {
                navigator.serviceWorker.register('/sw.js')
                    .then(function(reg) { console.log('[PWA] SW enregistré:', reg.scope); })
                    .catch(function(err) { console.warn('[PWA] SW erreur:', err); });
            });
        }
    </script>

'@

# Liste de tous les fichiers HTML (sauf includes/)
$htmlFiles = Get-ChildItem -Path $root -Filter "*.html" -Recurse |
    Where-Object { $_.FullName -notlike "*\includes\*" }

$count = 0
foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    $changed = $false

    # Ajouter les balises PWA avant </head> si pas déjà présent
    if ($content -notmatch 'rel="manifest"') {
        $content = $content -replace '(?i)(</head>)', "$pwaMeta`$1"
        $changed = $true
    }

    # Ajouter le script SW avant </body> si pas déjà présent
    if ($content -notmatch 'serviceWorker') {
        $content = $content -replace '(?i)(</body>)', "$swScript`$1"
        $changed = $true
    }

    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $count++
        Write-Host "✓ $($file.Name) mis à jour" -ForegroundColor Cyan
    } else {
        Write-Host "  $($file.Name) - déjà à jour" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Yellow
Write-Host " PWA setup terminé ! $count fichiers mis à jour." -ForegroundColor Green
Write-Host " Icônes générées dans assets/icons/" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow
