@echo off
echo ========================================
echo  Perfect Portable Converter
echo  HandBrake Style GUI
echo ========================================
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0PerfectConverter.ps1"
if errorlevel 1 pause
