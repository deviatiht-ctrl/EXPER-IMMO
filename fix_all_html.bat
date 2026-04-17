@echo off
echo Mise a jour de tous les fichiers HTML avec cache-busting et favicon...
echo.

REM Mettre a jour a-propos.html
echo [1/15] a-propos.html
powershell -Command "(Get-Content 'a-propos.html') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"assets/EXPER IMMO LOGO.png\">' | Set-Content 'a-propos.html'"

REM Mettre a jour contact.html
echo [2/15] contact.html
powershell -Command "(Get-Content 'contact.html') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"assets/EXPER IMMO LOGO.png\">' | Set-Content 'contact.html'"

REM Mettre a jour services.html
echo [3/15] services.html
powershell -Command "(Get-Content 'services.html') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"assets/EXPER IMMO LOGO.png\">' | Set-Content 'services.html'"

REM Mettre a jour proprietes.html
echo [4/15] proprietes.html
powershell -Command "(Get-Content 'proprietes.html') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"assets/EXPER IMMO LOGO.png\">' | Set-Content 'proprietes.html'"

REM Mettre a jour profil.html
echo [5/15] profil.html
powershell -Command "(Get-Content 'profil.html') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"assets/EXPER IMMO LOGO.png\">' | Set-Content 'profil.html'"

echo.
echo Mise a jour des fichiers admin...

REM Admin fichiers
for %%f in (admin\*.html) do (
    echo [ADMIN] %%f
    powershell -Command "(Get-Content '%%f') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"../assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"../assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"../assets/EXPER IMMO LOGO.png\">' | Set-Content '%%f'"
)

echo.
echo Mise a jour des fichiers locataire...

REM Locataire fichiers
for %%f in (locataire\*.html) do (
    echo [LOCATAIRE] %%f
    powershell -Command "(Get-Content '%%f') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"../assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"../assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"../assets/EXPER IMMO LOGO.png\">' | Set-Content '%%f'"
)

echo.
echo Mise a jour des fichiers proprietaire...

REM Proprietaire fichiers
for %%f in (proprietaire\*.html) do (
    echo [PROPRIETAIRE] %%f
    powershell -Command "(Get-Content '%%f') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"../assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"../assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"../assets/EXPER IMMO LOGO.png\">' | Set-Content '%%f'"
)

echo.
echo Mise a jour des fichiers gestionnaire...

REM Gestionnaire fichiers
for %%f in (gestionnaire\*.html) do (
    echo [GESTIONNAIRE] %%f
    powershell -Command "(Get-Content '%%f') -replace '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">', '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    \n    <!-- Anti-cache meta tags -->\n    <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n    <meta http-equiv=\"Pragma\" content=\"no-cache\">\n    <meta http-equiv=\"Expires\" content=\"0\">\n    \n    <!-- Favicon / Logo -->\n    <link rel=\"icon\" type=\"image/png\" href=\"../assets/EXPER IMMO LOGO.png\">\n    <link rel=\"shortcut icon\" type=\"image/png\" href=\"../assets/EXPER IMMO LOGO.png\">\n    <link rel=\"apple-touch-icon\" href=\"../assets/EXPER IMMO LOGO.png\">' | Set-Content '%%f'"
)

echo.
echo ==========================================
echo Mise a jour terminee!
echo ==========================================
pause
