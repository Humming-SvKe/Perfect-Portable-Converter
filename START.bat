@echo off
REM ===============================================
REM Perfect Portable Converter - START
REM Spustí PowerShell GUI aplikáciu
REM ===============================================

echo.
echo ========================================
echo  Perfect Portable Converter
echo  Watermark ^& Subtitle Editor
echo ========================================
echo.
echo Starting GUI...
echo ========================================
echo.

REM Spustí PowerShell skript
powershell.exe -ExecutionPolicy Bypass -File "%~dp0PerfectConverter.ps1"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to start PowerShell GUI
    echo.
    echo Make sure PowerShell is installed and enabled.
    echo.
    pause
)
