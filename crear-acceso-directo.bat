@echo off
cd /d "%~dp0"
echo ==========================================================
echo   Creando Acceso Directo de Persona 5 en el Escritorio...
echo ==========================================================
powershell -ExecutionPolicy Bypass -File "crear-acceso-directo.ps1"
echo.
echo Presiona cualquier tecla para salir...
pause >nul
