@echo off
REM ========================================
REM  CLEANUP SCRIPT
REM  Removes all old GUI versions
REM  Run this ONCE after download
REM ========================================

echo ========================================
echo  Cleaning up old GUI versions...
echo ========================================
echo.

del /F /Q "PPC-GUI.ps1" 2>nul && echo Removed: PPC-GUI.ps1
del /F /Q "PPC-GUI-Modern.ps1" 2>nul && echo Removed: PPC-GUI-Modern.ps1
del /F /Q "PPC-GUI-Modern.ps1.backup" 2>nul && echo Removed: PPC-GUI-Modern.ps1.backup
del /F /Q "PPC-GUI-Modern-v2.ps1" 2>nul && echo Removed: PPC-GUI-Modern-v2.ps1
del /F /Q "PPC-GUI-Modern-v3.ps1" 2>nul && echo Removed: PPC-GUI-Modern-v3.ps1
del /F /Q "PPC-GUI-Ultimate.ps1" 2>nul && echo Removed: PPC-GUI-Ultimate.ps1
del /F /Q "PPC-GUI-Ultimate-v2.ps1" 2>nul && echo Removed: PPC-GUI-Ultimate-v2.ps1
del /F /Q "PPC-GUI-Ultimate-v3.ps1" 2>nul && echo Removed: PPC-GUI-Ultimate-v3.ps1
del /F /Q "PPC-GUI-Final.ps1" 2>nul && echo Removed: PPC-GUI-Final.ps1
del /F /Q "PPC-GUI-Modern-Clean.ps1" 2>nul && echo Removed: PPC-GUI-Modern-Clean.ps1
del /F /Q "TEST-ULTIMATE-V2.ps1" 2>nul && echo Removed: TEST-ULTIMATE-V2.ps1
del /F /Q "VERIFY-VERSION.ps1" 2>nul && echo Removed: VERIFY-VERSION.ps1

echo.
echo ========================================
echo  Cleanup complete!
echo  Only PPC-GUI-Complete.ps1 remains.
echo ========================================
echo.
echo Now run START.bat to launch the GUI.
pause
