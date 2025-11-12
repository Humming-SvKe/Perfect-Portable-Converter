@echo off
REM Force PowerShell to reload the script (no cache)
set "SCRIPT=%~dp0PPC-GUI-Ultimate-v2.ps1"

echo Starting Professional Portable Converter - Ultimate Edition v2...
echo Script: %SCRIPT%
echo.

REM Kill any running PowerShell instances of this script
taskkill /F /FI "WINDOWTITLE eq Professional Portable Converter*" 2>nul

REM Clear PowerShell script cache by using -NoProfile and random timestamp
powershell -NoProfile -ExecutionPolicy Bypass -STA -Command "& {$Host.UI.RawUI.WindowTitle='PPC-Ultimate-v2 [%RANDOM%]'; & '%SCRIPT%'}"

pause
