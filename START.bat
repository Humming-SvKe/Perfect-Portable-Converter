@echo off
setlocal EnableExtensions
REM Professional Portable Converter - Ultimate Edition v3
REM Responsive Design: Works from 800x600 to 8K

set "SCRIPT_DIR=%~dp0"
set "GUI=%SCRIPT_DIR%PPC-GUI-Ultimate-v3.ps1"

echo.
echo ========================================
echo  Professional Portable Converter
echo  Ultimate Edition v3 (Build v3.0.0)
echo  Responsive: 800x600 to 8K
echo ========================================
echo.

REM Check if script exists
if not exist "%GUI%" (
    echo [ERROR] PPC-GUI-Ultimate-v3.ps1 not found!
    echo.
    echo Expected location: %GUI%
    echo.
    echo Please ensure you have downloaded the complete package from:
    echo https://github.com/Humming-SvKe/Perfect-Portable-Converter
    echo.
    pause
    exit /b 1
)

REM Kill any running PowerShell instances to prevent caching
taskkill /F /IM powershell.exe >nul 2>&1

echo Launching GUI...
echo.

REM Launch with clean slate
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI%"
