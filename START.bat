@echo off
setlocal EnableDelayedExpansion
REM Perfect Portable Converter - START
set "SCRIPT_DIR=%~dp0"
set "PPC_PS=%SCRIPT_DIR%PPC.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PPC_PS%"
pause