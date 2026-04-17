@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo FORCE CACHE BUSTING - ALL HTML FILES
echo ========================================
echo.

REM Kreye yon timestamp pou cache busting
set TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=!TIMESTAMP: =0!

echo Version timestamp: !TIMESTAMP!
echo.

REM Fonksyon pou ranplase nan yon fichye
for /r %%F in (*.html) do (
    echo Processing: %%~nxF
    
    REM Ranplase ?v=2.0 pa ?v=!TIMESTAMP!
    powershell -Command "(Get-Content '%%F') -replace '\?v=2\.0', '?v=!TIMESTAMP!' | Set-Content '%%F' -Encoding UTF8"
    
    REM Ranplase ?v=1.0 pa ?v=!TIMESTAMP!
    powershell -Command "(Get-Content '%%F') -replace '\?v=1\.0', '?v=!TIMESTAMP!' | Set-Content '%%F' -Encoding UTF8"
)

echo.
echo ========================================
echo DONE! All files updated with timestamp
echo ========================================
echo.
echo Clear your browser cache now:
echo 1. Press Ctrl+Shift+Delete
echo 2. Select "Cached images and files"
echo 3. Click "Clear data"
echo 4. Refresh the page with Ctrl+F5
echo.
pause
