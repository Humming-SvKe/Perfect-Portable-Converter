@echo off
REM ========================================
REM  PerfectConverter - HandBrake Style GUI
REM  Simple launcher for PowerShell interface
REM ========================================

echo.
echo ========================================
echo  PerfectConverter - HandBrake Style
echo  Starting GUI...
echo ========================================
echo.

set "GUI=%~dp0PerfectConverter.ps1"

if not exist "%GUI%" (
    echo ERROR: PerfectConverter.ps1 not found!
    echo Expected: %GUI%
    pause
    exit /b 1
)

REM Launch HandBrake-style GUI
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI%"

REM Check exit status
if errorlevel 1 (
    echo.
    echo ========================================
    echo  ERROR: GUI failed to start!
    echo ========================================
    pause
)
