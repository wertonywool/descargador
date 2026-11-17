@echo off
chcp 65001 >nul
title PERSONA 5 // VIDEO HEIST // CMD DOWNLOADER
color 0C
cd /d "%~dp0"

cls
echo  ==================================================================
echo  .______   .______       _______._______   ______   .__   __.      
echo  ^|   _  \  ^|   _  \     /       ^|   ____^| /  __  \  ^|  \ ^|  ^|      
echo  ^|  ^|_)  ) ^|  ^|_)  )   ^|   (----`^|  ^|__   ^|  ^|  ^|  ^| ^|   \^|  ^|  ___ 
echo  ^|   ___/  ^|   ___/     \   \    ^|   __^|  ^|  ^|  ^|  ^| ^|  . `  ^| ^|__ ^|
echo  ^|  ^|      ^|  ^|     .----)   ^|   ^|  ^|____ ^|  `--'  ^| ^|  ^|\   ^|    ^| ^|
echo  ^| _^|      ^| _^|     ^|_______/    ^|_______^| \______/  ^|__^| \__^|    ^|_^|
echo  ==================================================================
echo             ★ PHANTOM THIEVES OF HEARTS - VIDEO HEIST ★
echo  ==================================================================
echo.

:: 1. Verificar e instalar yt-dlp.exe si no existe
if not exist "bin\yt-dlp.exe" (
    echo [MOTOR] yt-dlp.exe no encontrado en bin\.
    echo [DESCARGANDO] Obteniendo la versión más reciente y rápida...
    if not exist "bin" mkdir "bin"
    curl.exe -L -o "bin\yt-dlp.exe" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] No se pudo descargar yt-dlp con curl. Intentando PowerShell...
        powershell -Command "Invoke-WebRequest -Uri 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' -OutFile 'bin\yt-dlp.exe'"
    )
    echo [MOTOR] ¡yt-dlp.exe instalado correctamente!
    echo.
)

:: 2. Crear acceso directo en el Escritorio con icono si no existe
if not exist "%USERPROFILE%\OneDrive\Desktop\Persona 5 - Descargador de Videos.lnk" (
    if not exist "%USERPROFILE%\Desktop\Persona 5 - Descargador de Videos.lnk" (
        echo [ACCESO DIRECTO] Generando icono y acceso directo en el Escritorio...
        powershell -ExecutionPolicy Bypass -File "crear-acceso-directo.ps1"
        echo.
    )
)

:: 3. Abrir navegador en 1 segundo en segundo plano
start "" powershell -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 800; Start-Process 'http://127.0.0.1:5050'"

:: 4. Iniciar servidor (Node.js si está instalado, o PowerShell nativo si no)
where node >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [MODO] Iniciando servidor ultrarrápido con Node.js...
    echo [LISTO] Abriendo interfaz en http://127.0.0.1:5050
    echo [CMD] Presiona CTRL + C para detener el servidor.
    echo.
    node server.js
) else (
    echo [MODO] Node.js no detectado. Usando servidor PowerShell nativo de Windows...
    echo [LISTO] Abriendo interfaz en http://127.0.0.1:5050
    echo [CMD] Presiona CTRL + C para detener el servidor.
    echo.
    powershell -ExecutionPolicy Bypass -File "server.ps1"
)

pause
