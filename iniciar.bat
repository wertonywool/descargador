@echo off
title PERSONA 5 // VIDEO HEIST // CMD DOWNLOADER
color 0C
cd /d "%~dp0"

cls
echo ==================================================================
echo         [PERSONA 5] - PHANTOM THIEVES VIDEO HEIST
echo                DESCARGADOR DE VIDEOS CMD
echo ==================================================================
echo.

REM 1. Verificar e instalar yt-dlp.exe si no existe
if not exist "bin\yt-dlp.exe" (
    echo [MOTOR] yt-dlp.exe no encontrado en bin\
    echo [DESCARGANDO] Obteniendo el motor mas reciente...
    if not exist "bin" mkdir "bin"
    curl.exe -L -o "bin\yt-dlp.exe" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    if errorlevel 1 (
        echo [REINTENTO] Descargando mediante PowerShell...
        powershell -Command "Invoke-WebRequest -Uri 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' -OutFile 'bin\yt-dlp.exe'"
    )
    echo [MOTOR] yt-dlp.exe instalado correctamente.
    echo.
)

REM 2. Crear acceso directo en el Escritorio si no existe
if not exist "%USERPROFILE%\OneDrive\Desktop\Persona 5 - Descargador de Videos.lnk" (
    if not exist "%USERPROFILE%\Desktop\Persona 5 - Descargador de Videos.lnk" (
        echo [ACCESO DIRECTO] Creando icono y acceso directo en el Escritorio...
        powershell -ExecutionPolicy Bypass -File "crear-acceso-directo.ps1"
        echo.
    )
)

REM 3. Iniciar servidor (Node.js si esta disponible, o PowerShell nativo)
where node >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [MODO] Iniciando servidor con Node.js...
    node server.js
) else (
    echo [MODO] Node.js no detectado. Iniciando servidor PowerShell nativo de Windows...
    powershell -ExecutionPolicy Bypass -File "server.ps1"
)

pause
