@echo off
REM ========================================
REM  DIAGNOSTIC SCRIPT
REM  Tests if PPC-GUI-Complete.ps1 can load
REM ========================================

echo ========================================
echo  Testing GUI Load...
echo ========================================
echo.

if not exist "PPC-GUI-Complete.ps1" (
    echo [ERROR] PPC-GUI-Complete.ps1 not found!
    echo Current directory: %CD%
    pause
    exit /b 1
)

echo [OK] File exists: PPC-GUI-Complete.ps1
echo.
echo Attempting to load GUI...
echo.
echo If you see errors below, copy them and send to developer:
echo ----------------------------------------
echo.

powershell -NoProfile -ExecutionPolicy Bypass -STA -Command "& { try { . '%~dp0PPC-GUI-Complete.ps1' } catch { Write-Host '' ; Write-Host '=== ERROR DETAILS ===' -ForegroundColor Red ; Write-Host $_.Exception.Message -ForegroundColor Yellow ; Write-Host '' ; Write-Host 'Line Number:' $_.InvocationInfo.ScriptLineNumber -ForegroundColor Cyan ; Write-Host 'Position:' $_.InvocationInfo.PositionMessage -ForegroundColor Gray ; pause ; exit 1 } }"

if errorlevel 1 (
    echo.
    echo ========================================
    echo  GUI FAILED TO LOAD
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo  GUI Loaded Successfully!
echo ========================================
timeout /t 3
