$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$pwa  = '    <!-- PWA -->' + [char]10
$pwa += '    <link rel="manifest" href="/manifest.json">' + [char]10
$pwa += '    <meta name="theme-color" content="#c9a84c">' + [char]10
$pwa += '    <meta name="mobile-web-app-capable" content="yes">' + [char]10
$pwa += '    <meta name="apple-mobile-web-app-capable" content="yes">' + [char]10
$pwa += '    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">' + [char]10
$pwa += '    <meta name="apple-mobile-web-app-title" content="EXPER IMMO">' + [char]10
$pwa += '    <link rel="apple-touch-icon" href="/assets/icons/icon-192.png">' + [char]10
$pwa += '    <link rel="icon" type="image/png" sizes="192x192" href="/assets/icons/icon-192.png">' + [char]10
$pwa += '    <link rel="shortcut icon" href="/assets/icons/icon-192.png">' + [char]10

$sw  = '    <script>' + [char]10
$sw += "    if('serviceWorker' in navigator){" + [char]10
$sw += "        window.addEventListener('load',function(){" + [char]10
$sw += "            navigator.serviceWorker.register('/sw.js')" + [char]10
$sw += "                .then(function(r){console.log('[PWA] SW OK',r.scope);})" + [char]10
$sw += "                .catch(function(e){console.warn('[PWA] SW err',e);});" + [char]10
$sw += '        });' + [char]10
$sw += '    }' + [char]10
$sw += '    </script>' + [char]10

$files = Get-ChildItem -Path $root -Filter '*.html' -Recurse |
    Where-Object { $_.FullName -notlike '*\includes\*' }

$n = 0
foreach ($f in $files) {
    $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $changed = $false

    if ($c -notmatch 'rel="manifest"') {
        $c = $c -replace '(?i)</head>', ($pwa + '</head>')
        $changed = $true
    }

    if ($c -notmatch 'serviceWorker') {
        $c = $c -replace '(?i)</body>', ($sw + '</body>')
        $changed = $true
    }

    if ($changed) {
        [System.IO.File]::WriteAllText($f.FullName, $c, (New-Object System.Text.UTF8Encoding $false))
        $n++
        Write-Host "OK: $($f.Name)"
    }
}

Write-Host "Done: $n HTML files updated with PWA tags."
