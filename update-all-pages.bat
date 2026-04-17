@echo off
echo ============================================
echo EXPER IMMO - Mise a jour de toutes les pages
echo ============================================
echo.

REM Liste des pages a mettre a jour
set PAGES=agents.html calculateur.html contact.html login.html inscription.html

for %%f in (%PAGES%) do (
    echo Traitement de %%f...
    
    REM Remplacer navbar.css par navbar-modern.css
    powershell -Command "(Get-Content '%%f') -replace 'navbar\.css', 'navbar-modern.css' | Set-Content '%%f'"
    
    REM Remplacer mobile-nav.css par mobile-nav-modern.css  
    powershell -Command "(Get-Content '%%f') -replace 'mobile-nav\.css', 'mobile-nav-modern.css' | Set-Content '%%f'"
    
    REM Remplacer navbar.js par load-navbar.js + navbar-modern.js
    powershell -Command "(Get-Content '%%f') -replace '<script type=\"module\" src=\"js/navbar\.js\"></script>', '<script src=\"js/load-navbar.js\"></script>\n    <script type=\"module\" src=\"js/navbar-modern.js\"></script>' | Set-Content '%%f'"
    
    echo %%f termine.
)

echo.
echo ============================================
echo Mise a jour terminee!
echo ============================================
pause
