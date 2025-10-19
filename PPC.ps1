<# Perfect Portable Converter (PPC) - OFFLINE build (auto FFmpeg download, ASCII-safe) #>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Paths
$Root  = Split-Path -Parent $PSCommandPath
$Bins  = Join-Path $Root "binaries"
$Logs  = Join-Path $Root "logs"
$Temp  = Join-Path $Root "temp"
$In    = Join-Path $Root "input"
$Out   = Join-Path $Root "output"
$Subs  = Join-Path $Root "subtitles"
$Ovls  = Join-Path $Root "overlays"
$Thumb = Join-Path $Root "thumbnails"
$Cfg   = Join-Path $Root "config\defaults.json"

$null = New-Item -ItemType Directory -Force -Path $Bins,$Logs,$Temp,$In,$Out,$Subs,$Ovls,$Thumb | Out-Null
$LogFile = Join-Path $Logs "ppc.log"

function Write-Log([string]$m){
  $ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); "$ts | $m" | Out-File -Append -Encoding UTF8 $LogFile; Write-Host $m
}

# Helpers for downloads
function Ensure-Tls12 { try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {} }
function Download-File([string]$Url,[string]$Dst){ Ensure-Tls12; Write-Log ("Downloading: " + $Url); Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Dst }
function Expand-Zip([string]$Zip,[string]$Dest){
  try { Expand-Archive -Path $Zip -DestinationPath $Dest -Force }
  catch {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($Zip,$Dest)
  }
}

# Default config (overridden by config\defaults.json when present)
$Config = @{
default_format = "mp4";
  profiles = @(
    @{ name="Fast 1080p H264";  vcodec="libx264"; preset="veryfast"; crf=23; acodec="aac"; ab="160k"; scale="" },
    @{ name="Small 720p H264"; vcodec="libx264"; preset="veryfast"; crf=25; acodec="aac"; ab="128k"; scale="1280:-2" },
    @{ name="YouTube 1080p";   vcodec="libx264"; preset="medium";  crf=21; acodec="aac"; ab="192k"; scale="1920:-2" }
  )
}
if (Test-Path $Cfg) { try { $Config = Get-Content $Cfg -Raw | ConvertFrom-Json } catch { Write-Log "WARN: Config load failed, using defaults." } }

$global:FFMPEG=""; $global:FFPROBE=""
function Install-FFTools {
  try {
    $zip = Join-Path $Temp "ffmpeg.zip"
    $dst = Join-Path $Temp "ffmpeg"
    if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    # Use Gyan.dev essentials build for smaller size
    $url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    Download-File -Url $url -Dst $zip
    Expand-Zip -Zip $zip -Dest $dst
    $ff = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    $fp = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffprobe.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ff) { Copy-Item -LiteralPath $ff.FullName -Destination (Join-Path $Bins "ffmpeg.exe") -Force }
    if ($fp) { Copy-Item -LiteralPath $fp.FullName -Destination (Join-Path $Bins "ffprobe.exe") -Force }
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
    return $true
  } catch {
    Write-Log ("ERROR: FFmpeg download/install failed: " + $_.Exception.Message)
    return $false
  }
}

function Resolve-FFTools {
  $ff = Join-Path $Bins "ffmpeg.exe"; $fp = Join-Path $Bins "ffprobe.exe"
  if (Test-Path $ff) { $global:FFMPEG = $ff }
  if (Test-Path $fp) { $global:FFPROBE = $fp }
  if (-not (Test-Path $ff)) {
    Write-Log "WARN: binaries\ffmpeg.exe not found, attempting auto-download..."
    if (Install-FFTools) {
      if (Test-Path $ff) { $global:FFMPEG = $ff }
      if (Test-Path $fp) { $global:FFPROBE = $fp }
    }
  }
  if (-not (Test-Path $ff)) { Write-Log "ERROR: FFmpeg is missing. Place ffmpeg.exe into 'binaries' or ensure internet for one-time download."; return $false }
  return $true
}

function Run-FF([string[]]$Args){
  $ffLog = Join-Path $Logs "ffmpeg.log"
  Write-Log ("ffmpeg " + ($Args -join ' '))
  & $FFMPEG @Args 2>&1 | Tee-Object -FilePath $ffLog -Append | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "FFmpeg exited with code $LASTEXITCODE" }
}

function Choose-Profile {
  Write-Host ""; Write-Host "Available profiles:"; for ($i=0; $i -lt $Config.profiles.Count; $i++){ Write-Host ("  [{0}] {1}" -f $i, $Config.profiles[$i].name) }
  $idx = Read-Host "Enter profile index"
  $n=[int]0; if (-not [int]::TryParse($idx,[ref]$n) -or $n -lt 0 -or $n -ge $Config.profiles.Count){ Write-Log "ERROR: Invalid profile index"; return $null }
  return $Config.profiles[$n]
}

function Build-EffectsChain([string[]]$E){
  if (-not $E -or $E.Count -eq 0) { return "" }
  $vf=@()
  foreach($x in $E){ $t=(""+$x).Trim().ToLower(); switch -Regex($t){
    "^denoise$"     { $vf+="hqdn3d" }
    "^sharpen$"     { $vf+="unsharp" }
    "^grayscale$"   { $vf+="format=gray" }
    "^deinterlace$" { $vf+="yadif" }
    "^stabilize$"   { $vf+="deshake" }
    default {}
  } }
  if ($vf.Count -eq 0) { return "" }
  return ([string]::Join(',', $vf))
}

function Convert-Batch {
  if (-not (Resolve-FFTools)) { return }
  $p = Choose-Profile; if ($null -eq $p) { return }

  $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov,*.webm -Recurse
  if (-not $files) { Write-Log "INFO: No input files in 'input'"; return }

  foreach ($f in $files) {
    try {
      $rel = (Resolve-Path -LiteralPath $f.FullName).Path
      $ext = if ($p.PSObject.Properties.Name -contains 'format' -and $p.format) { $p.format } else { $Config.default_format }
      $outPath = Join-Path $Out ("{0}.{1}" -f [IO.Path]::GetFileNameWithoutExtension($f.Name), $ext)

      # Video args
      $vArgs=@(); if ($p.vcodec) { $vArgs += @('-c:v', "$($p.vcodec)") }
      if ($p.preset) { $vArgs += @('-preset', "$($p.preset)") }
      if ($null -ne $p.crf) { $vArgs += @('-crf', "$($p.crf)") }

      # Audio args
      $aArgs=@(); if ($p.acodec) { $aArgs += @('-c:a', "$($p.acodec)") }
      if ($p.ab) { $aArgs += @('-b:a', "$($p.ab)") }

      # Filters
      $filters=@(); if ($p.scale) { $filters += "scale=$($p.scale)" }
      if ($p.effects) { foreach ($ef in $p.effects) { $filters += $ef } }
      $vfArgs=@(); $chain = if ($filters.Count -gt 0) { [string]::Join(',', $filters) } else { '' }
      if ($chain) { $vfArgs = @('-vf', $chain) }

      $args = @('-y','-hide_banner','-loglevel','warning','-i', $rel) + $vfArgs + $vArgs + $aArgs + @($outPath)
      Run-FF $args
      Write-Log ("OK: {0} -> {1}" -f $f.Name, [IO.Path]::GetFileName($outPath))
    }
    catch {
      Write-Log ("FAIL: {0} -> {1}" -f $f.Name, $_.Exception.Message)
    }
  }
}

function Main-Menu {
  Write-Host ""; Write-Host "Perfect Portable Converter"; Write-Host "=========================="
  Write-Host "1) Batch convert"; Write-Host "2) Exit"
  $o = Read-Host "Choice"; switch ($o){ '1' { Convert-Batch } '2' { return $false } default { Write-Host "Invalid choice." } }
  return $true
}

Write-Log "PPC started."; while (Main-Menu){}; Write-Log "End."