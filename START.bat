@echo off
REM ========================================
REM  Perfect Portable Converter
REM  HandBrake-based video converter
REM ========================================

echo.
echo ========================================
echo  Perfect Portable Converter
echo  Starting HandBrake Converter...
echo ========================================
echo.

set "CONVERTER=%~dp0PerfectConverter.ps1"

if not exist "%CONVERTER%" (
    echo ERROR: PerfectConverter.ps1 not found!
    echo Expected: %CONVERTER%
    pause
    exit /b 1
)

REM Kill cached PowerShell instances
taskkill /F /IM powershell.exe >nul 2>&1

REM Launch Perfect Converter
powershell -NoProfile -ExecutionPolicy Bypass -File "%CONVERTER%"

REM Check exit status
if errorlevel 1 (
    echo.
    echo ========================================
    echo  ERROR: Converter failed to start!
    echo ========================================
    echo.
    echo Trying to display error details...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { . '%CONVERTER%' } catch { Write-Host 'ERROR:' $_.Exception.Message -ForegroundColor Red; Write-Host 'LINE:' $_.InvocationInfo.ScriptLineNumber -ForegroundColor Yellow; pause } }"
    pause
) else (
    echo Converter closed normally.
    timeout /t 2 >nul
)
