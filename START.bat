@echo off
setlocal EnableExtensions
REM Perfect Portable Converter - START (GUI first, fallback to CLI)

set "SCRIPT_DIR=%~dp0"
set "GUI=%SCRIPT_DIR%PPC-GUI.ps1"
set "CLI=%SCRIPT_DIR%PPC.ps1"

REM Force CLI if parameter /CLI is supplied
if /I "%~1"=="/CLI" goto CLI

REM Prefer GUI when available
if exist "%GUI%" goto GUI

:CLI
powershell -NoProfile -ExecutionPolicy Bypass -File "%CLI%"
goto END

:GUI
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI%"
goto END

:END
pause
