@echo off
REM ===============================================
REM Perfect Portable Converter - Launcher
REM HandBrake-Style PowerShell GUI
REM ===============================================

echo.
echo ========================================
echo  Perfect Portable Converter
echo  HandBrake Style Interface
echo ========================================
echo.
echo Starting GUI...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0PerfectConverter.ps1"

if errorlevel 1 (
    echo ERROR: Failed to start GUI
    pause
)
