@echo off
setlocal EnableExtensions
REM Professional Portable Converter - Modern Clean Design

set "SCRIPT_DIR=%~dp0"
set "GUI=%SCRIPT_DIR%PPC-GUI-Modern-Clean.ps1"

echo.
echo ========================================
echo  Professional Portable Converter
echo  Modern Clean Design
echo ========================================
echo.

REM Check if script exists
if not exist "%GUI%" (
    echo [ERROR] PPC-GUI-Modern-Clean.ps1 not found!
    echo.
    pause
    exit /b 1
)

REM Kill any running PowerShell to prevent caching
taskkill /F /IM powershell.exe >nul 2>&1

echo Launching GUI...
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI%"
