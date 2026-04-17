@echo off
chcp 65001 >nul
echo ============================================
echo EXPER IMMO - Application du navbar moderne
echo sur toutes les pages
echo ============================================
echo.

REM Liste des pages à mettre à jour
set PAGES=agents.html calculateur.html contact.html login.html inscription.html propriete.html a-propos.html

for %%f in (%PAGES%) do (
    if exist "%%f" (
        echo Traitement de %%f...
        
        REM 1. Remplacer les CSS du navbar
        powershell -Command "(Get-Content '%%f') -replace 'navbar\.css', 'navbar-modern.css' | Set-Content '%%f'"
        powershell -Command "(Get-Content '%%f') -replace 'mobile-nav\.css', 'mobile-nav-modern.css' | Set-Content '%%f'"
        
        REM 2. Ajouter bottom-nav.css si pas présent
        powershell -Command "if (-not (Select-String -Path '%%f' -Pattern 'bottom-nav\.css' -Quiet)) { (Get-Content '%%f') -replace '(mobile-nav-modern\.css)', '`$1`n    <link rel=\"stylesheet\" href=\"css/bottom-nav.css\">' | Set-Content '%%f' }"
        
        REM 3. Remplacer les scripts du navbar
        powershell -Command "(Get-Content '%%f') -replace '<script type=\"module\" src=\"js/navbar\.js\"></script>', '<script src=\"js/load-navbar.js\"></script>`n    <script src=\"js/navbar-controller.js\"></script>' | Set-Content '%%f'"
        
        REM 4. Remplacer le HTML du navbar par le placeholder
        powershell -Command "(Get-Content '%%f') -replace '(?s)<nav class=\"navbar[^\"]*\"[^>]*>.*?</nav>', '<!-- NAVBAR will be loaded by JS -->' | Set-Content '%%f'"
        
        REM 5. Remplacer le mobile sidebar aussi
        powershell -Command "(Get-Content '%%f') -replace '(?s)<div class=\"mobile-sidebar-overlay\"></div>\s*<aside class=\"mobile-sidebar\"[^>]*>.*?</aside>', '' | Set-Content '%%f'"
        
        echo %%f - Terminé.
    ) else (
        echo %%f - Fichier non trouvé, ignoré.
    )
)

echo.
echo ============================================
echo Application terminée!
echo ============================================
pause
