@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Perfect Portable Converter - Diagnostic Report generator
rem Creates: logs\REPORT-YYYYMMDD-HHMMSS.txt

set "ROOT=%~dp0"
set "LOGS=%ROOT%logs"
if not exist "%LOGS%" mkdir "%LOGS%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%I"
set "REPORT=%LOGS%\REPORT-%STAMP%.txt"

rem Initialize report (UTF-8)
powershell -NoProfile -Command ^
  "$p='%REPORT%';" ^
  "'Perfect Portable Converter - Diagnostic Report' | Out-File -Encoding UTF8 $p;" ^
  "('Generated: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ssK')) | Out-File -Encoding UTF8 -Append $p;" ^
  "'-'*80 | Out-File -Encoding UTF8 -Append $p"

call :Header "BASIC INFO"
>>"%REPORT%" echo ScriptDir: %ROOT%
>>"%REPORT%" echo User: %USERNAME%   Computer: %COMPUTERNAME%
>>"%REPORT%" echo Process Arch: %PROCESSOR_ARCHITECTURE%   CPU: %PROCESSOR_IDENTIFIER%
>>"%REPORT%" echo PATH (first 5 dirs):
for /f "tokens=1-5 delims=;" %%a in ("%PATH%") do >>"%REPORT%" echo    %%a;%%b;%%c;%%d;%%e

call :Header "OS"
powershell -NoProfile -Command ^
  "(Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber, OSArchitecture, CSName, LastBootUpTime) | Format-List * | Out-File -Append -Encoding UTF8 '%REPORT%';" ^
  "(Get-Culture).Name | ForEach-Object { 'Culture: ' + $_ } | Out-File -Append -Encoding UTF8 '%REPORT%';" ^
  "(Get-UICulture).Name | ForEach-Object { 'UI Culture: ' + $_ } | Out-File -Append -Encoding UTF8 '%REPORT%'"

call :Header "POWERSHELL"
powershell -NoProfile -Command ^
  "$t=$PSVersionTable; $t.GetEnumerator() | Sort-Object Name | Format-Table -AutoSize | Out-String | Out-File -Append -Encoding UTF8 '%REPORT%';" ^
  "'ExecutionPolicy:' | Out-File -Append -Encoding UTF8 '%REPORT%';" ^
  "Get-ExecutionPolicy -List | Format-Table -AutoSize | Out-String | Out-File -Append -Encoding UTF8 '%REPORT%'"

call :Header "DIRECTORIES (root)"
powershell -NoProfile -Command ^
  "Get-ChildItem -LiteralPath '%ROOT%' -Force | Sort-Object Name | Select-Object Mode,Length,Name | Format-Table -AutoSize | Out-String | Out-File -Append -Encoding UTF8 '%REPORT%'"

for %%D in (binaries config input output subtitles overlays thumbnails logs temp) do (
  if exist "%ROOT%%%D" (
    call :Header "CONTENTS (%%D)"
    powershell -NoProfile -Command ^
      "Get-ChildItem -LiteralPath '%ROOT%%%D' -Force | Select-Object Mode,Length,Name | Format-Table -AutoSize | Out-String | Out-File -Append -Encoding UTF8 '%REPORT%'" 
  )
)

call :Header "FILES HASHES"
powershell -NoProfile -Command ^
  "foreach($p in @('%ROOT%PPC.ps1','%ROOT%START.bat','%ROOT%config\\defaults.json','%ROOT%binaries\\ffmpeg.exe','%ROOT%binaries\\ffprobe.exe')){" ^
  " if(Test-Path $p){ Get-FileHash -Algorithm SHA256 -LiteralPath $p | Select-Object Algorithm,Hash,Path } else { [pscustomobject]@{ Algorithm='SHA256'; Hash='(missing)'; Path=$p } }" ^
  " | Format-Table -AutoSize | Out-String | Out-File -Append -Encoding UTF8 '%REPORT%'"

call :Header "FFMPEG/FFPROBE"
if exist "%ROOT%binaries\ffmpeg.exe" (
  powershell -NoProfile -Command "& '%ROOT%binaries\ffmpeg.exe' -version 2^^>^^&1 | Out-File -Append -Encoding UTF8 '%REPORT%'"
) else (
  >>"%REPORT%" echo binaries\ffmpeg.exe NOT FOUND
)
if exist "%ROOT%binaries\ffprobe.exe" (
  powershell -NoProfile -Command "& '%ROOT%binaries\ffprobe.exe' -version 2^^>^^&1 | Out-File -Append -Encoding UTF8 '%REPORT%'"
) else (
  >>"%REPORT%" echo binaries\ffprobe.exe NOT FOUND
)

call :Header "PPC.ps1 SYNTAX CHECK"
powershell -NoProfile -Command ^
  "$e=$null;" ^
  "$raw = if(Test-Path '%ROOT%PPC.ps1'){ Get-Content -LiteralPath '%ROOT%PPC.ps1' -Raw } else { $null };" ^
  "if($null -eq $raw){ 'PPC.ps1 not found' | Out-File -Append -Encoding UTF8 '%REPORT%' }" ^
  "else { [void][System.Management.Automation.PSParser]::Tokenize($raw,[ref]$e);" ^
  " if($e -and $e.Count -gt 0){ 'Errors:' | Out-File -Append -Encoding UTF8 '%REPORT%'; $e | Format-List * | Out-String | Out-File -Append -Encoding UTF8 '%REPORT%' }" ^
  " else { 'OK (no parser errors)' | Out-File -Append -Encoding UTF8 '%REPORT%' } }"

call :Header "LOGS (tails)"
if exist "%LOGS%\ppc.log" (
  >>"%REPORT%" echo -- logs\ppc.log (last 200 lines) --
  powershell -NoProfile -Command "Get-Content -LiteralPath '%LOGS%\ppc.log' -Tail 200 | Out-File -Append -Encoding UTF8 '%REPORT%'"
) else (
  >>"%REPORT%" echo logs\ppc.log not found
)
if exist "%LOGS%\ffmpeg.log" (
  >>"%REPORT%" echo -- logs\ffmpeg.log (last 200 lines) --
  powershell -NoProfile -Command "Get-Content -LiteralPath '%LOGS%\ffmpeg.log' -Tail 200 | Out-File -Append -Encoding UTF8 '%REPORT%'"
) else (
  >>"%REPORT%" echo logs\ffmpeg.log not found
)

call :Header "GIT (optional)"
if exist "%ROOT%.git" (
  git --version >> "%REPORT%" 2>&1
  git -C "%ROOT%" rev-parse HEAD >> "%REPORT%" 2>&1
) else (
  >>"%REPORT%" echo .git folder not present
)

call :Header "ENVIRONMENT (selected)"
>>"%REPORT%" echo ComSpec=%ComSpec%
>>"%REPORT%" echo TEMP=%TEMP%
>>"%REPORT%" echo TMP=%TMP%
>>"%REPORT%" echo Number of processors: %NUMBER_OF_PROCESSORS%
>>"%REPORT%" echo PROCESSOR_ARCHITEW6432=%PROCESSOR_ARCHITEW6432%

call :Header "HINTS"
>>"%REPORT%" echo Please attach this report when reporting a bug. Also include reproduction steps and details about the input files.

echo.
echo Report generated:
echo   %REPORT%
echo.
pause
exit /b 0

:Header
set "H=%~1"
>>"%REPORT%" echo.
>>"%REPORT%" echo ================= %H% =================
exit /b
