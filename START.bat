@echo off
REM ========================================
REM  Professional Portable Converter
REM  Clean installation - removes old versions
REM ========================================

echo Cleaning up old GUI versions...

REM Remove all old GUI versions
del /F /Q "%~dp0PPC-GUI.ps1" 2>nul
del /F /Q "%~dp0PPC-GUI-Modern.ps1" 2>nul
del /F /Q "%~dp0PPC-GUI-Modern.ps1.backup" 2>nul
del /F /Q "%~dp0PPC-GUI-Modern-v2.ps1" 2>nul
del /F /Q "%~dp0PPC-GUI-Modern-v3.ps1" 2>nul
del /F /Q "%~dp0PPC-GUI-Ultimate.ps1" 2>nul
del /F /Q "%~dp0PPC-GUI-Ultimate-v2.ps1" 2>nul
del /F /Q "%~dp0PPC-GUI-Ultimate-v3.ps1" 2>nul
del /F /Q "%~dp0PPC-GUI-Final.ps1" 2>nul
del /F /Q "%~dp0PPC-GUI-Modern-Clean.ps1" 2>nul
del /F /Q "%~dp0TEST-ULTIMATE-V2.ps1" 2>nul
del /F /Q "%~dp0VERIFY-VERSION.ps1" 2>nul

echo.
echo ========================================
echo  Perfect Portable Converter
echo  HandBrake-style GUI - Starting...
echo ========================================
echo.

set "GUI=%~dp0PerfectConverter.ps1"

if not exist "%GUI%" (
    echo ERROR: PerfectConverter.ps1 not found!
    echo Expected: %GUI%
    pause
    exit /b 1
)

REM Kill cached PowerShell
taskkill /F /IM powershell.exe >nul 2>&1

:: Launch GUI
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0PerfectConverter.ps1"

REM If we reach here, the GUI exited or failed
if errorlevel 1 (
    echo.
    echo ========================================
    echo  ERROR: GUI failed to start!
    echo ========================================
    echo.
    echo Trying to display error details...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { try { . '%GUI%' } catch { Write-Host 'ERROR:' $_.Exception.Message -ForegroundColor Red; Write-Host 'LINE:' $_.InvocationInfo.ScriptLineNumber -ForegroundColor Yellow; pause } }"
    pause
) else (
    echo GUI closed normally.
    timeout /t 2 >nul
)
