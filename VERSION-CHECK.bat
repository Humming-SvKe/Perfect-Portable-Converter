@echo off
REM ========================================
REM  VERSION CHECK
REM  Shows which GUI files are present
REM ========================================

echo ========================================
echo  Professional Portable Converter
echo  Version Check
echo ========================================
echo.

echo Current directory:
echo %CD%
echo.

echo Checking for GUI files...
echo.

set FOUND_OLD=0
set FOUND_CURRENT=0

REM Check for current version
if exist "PPC-GUI-Complete.ps1" (
    echo [CURRENT] PPC-GUI-Complete.ps1 - THIS IS THE MAIN FILE
    set FOUND_CURRENT=1
) else (
    echo [MISSING] PPC-GUI-Complete.ps1 - NOT FOUND!
)

echo.
echo Checking for old versions...
echo.

REM Check for old versions
if exist "PPC-GUI.ps1" (
    echo [OLD] PPC-GUI.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "PPC-GUI-Modern.ps1" (
    echo [OLD] PPC-GUI-Modern.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "PPC-GUI-Modern-v2.ps1" (
    echo [OLD] PPC-GUI-Modern-v2.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "PPC-GUI-Modern-v3.ps1" (
    echo [OLD] PPC-GUI-Modern-v3.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "PPC-GUI-Ultimate.ps1" (
    echo [OLD] PPC-GUI-Ultimate.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "PPC-GUI-Ultimate-v2.ps1" (
    echo [OLD] PPC-GUI-Ultimate-v2.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "PPC-GUI-Ultimate-v3.ps1" (
    echo [OLD] PPC-GUI-Ultimate-v3.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "PPC-GUI-Final.ps1" (
    echo [OLD] PPC-GUI-Final.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "PPC-GUI-Modern-Clean.ps1" (
    echo [OLD] PPC-GUI-Modern-Clean.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "TEST-ULTIMATE-V2.ps1" (
    echo [OLD] TEST-ULTIMATE-V2.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)
if exist "VERIFY-VERSION.ps1" (
    echo [OLD] VERIFY-VERSION.ps1 - SHOULD BE DELETED
    set FOUND_OLD=1
)

echo.
echo ========================================
echo  RESULTS
echo ========================================

if %FOUND_CURRENT%==1 (
    echo [OK] Current version found
) else (
    echo [ERROR] Current version NOT found!
    echo Download fresh copy from GitHub
)

if %FOUND_OLD%==1 (
    echo [WARNING] Old versions detected!
    echo.
    echo To remove them, run: CLEANUP-OLD-FILES.bat
) else (
    echo [OK] No old versions found
)

echo.
echo ========================================
pause
