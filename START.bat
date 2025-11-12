@echo off
setlocal EnableExtensions
REM Perfect Portable Converter - START (GUI first, fallback to CLI)

set "SCRIPT_DIR=%~dp0"
set "GUI_MODERN_V3=%SCRIPT_DIR%PPC-GUI-Modern-v3.ps1"
set "GUI_MODERN_V2=%SCRIPT_DIR%PPC-GUI-Modern-v2.ps1"
set "GUI_MODERN=%SCRIPT_DIR%PPC-GUI-Modern.ps1"
set "GUI=%SCRIPT_DIR%PPC-GUI.ps1"
set "CLI=%SCRIPT_DIR%PPC.ps1"
set "HB=%SCRIPT_DIR%PPC-HandBrake.ps1"

REM Force CLI if parameter /CLI is supplied
if /I "%~1"=="/CLI" goto CLI
if /I "%~1"=="/HB" goto HB

REM Prefer Modern GUI v3 (Professional style)
if exist "%GUI_MODERN_V3%" goto GUI_MODERN_V3

REM Fallback to Modern GUI v2
if exist "%GUI_MODERN_V2%" goto GUI_MODERN_V2

REM Fallback to Modern GUI v1
if exist "%GUI_MODERN%" goto GUI_MODERN

REM Fallback to classic GUI
if exist "%GUI%" goto GUI

:CLI
powershell -NoProfile -ExecutionPolicy Bypass -File "%CLI%"
goto END

:GUI
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI%"
goto END

:GUI_MODERN
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI_MODERN%"
goto END

:GUI_MODERN_V2
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI_MODERN_V2%"
goto END

:GUI_MODERN_V3
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%GUI_MODERN_V3%"
goto END

:HB
if exist "%HB%" (
	powershell -NoProfile -ExecutionPolicy Bypass -File "%HB%"
) else (
	echo HandBrake script not found: %HB%
	echo Place PPC-HandBrake.ps1 into the same folder to enable HandBrake mode.
)
goto END

:END
pause
