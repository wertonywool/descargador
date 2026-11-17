@echo off
title PERSONA 5 - VIDEO HEIST // CMD DOWNLOADER
color 0C
cd /d "%~dp0"

echo ================================================================
echo    [PHANTOM THIEVES OF HEARTS] - CMD VIDEO DOWNLOADER
echo ================================================================
echo.
echo Iniciando servidor local en http://127.0.0.1:5050...
echo.

:: Start the browser after 1 second
start "" powershell -Command "Start-Sleep -Seconds 1; Start-Process 'http://127.0.0.1:5050'"

:: Start the Node.js server
"C:\Program Files\nodejs\node.exe" server.js
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Intentando iniciar con node del sistema...
    node server.js
)

pause
