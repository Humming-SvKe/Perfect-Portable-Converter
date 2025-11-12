@echo off
set "GUI=%~dp0PPC-GUI-Complete.ps1"
taskkill /F /IM powershell.exe >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI%"
