@echo off
set "GUI=%~dp0PPC-GUI-Final.ps1"
if not exist "%GUI%" (
    echo ERROR: PPC-GUI-Final.ps1 not found!
    pause
    exit /b 1
)
taskkill /F /IM powershell.exe >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI%"
