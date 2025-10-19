<# Perfect Portable Converter (PPC) - OFFLINE build (fixed) #>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Paths
$Root = Split-Path -Parent $PSCommandPath
$Bins = Join-Path $Root "binaries"
$Logs = Join-Path $Root "logs"
$Temp = Join-Path $Root "temp"
$In   = Join-Path $Root "input"
$Out  = Join-Path $Root "output"
$Subs = Join-Path $Root "subtitles"
$Ovls = Join-Path $Root "overlays"
$Thumb= Join-Path $Root "thumbnails"
$Cfg  = Join-Path $Root "config\defaults.json"

$null = New-Item -ItemType Directory -Force -Path $Bins,$Logs,$Temp,$In,$Out,$Subs,$Ovls,$Thumb | Out-Null
$LogFile = Join-Path $Logs "ppc.log"

function Write-Log($m){
    $ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$ts | $m" | Out-File -Append -Encoding UTF8 $LogFile
    Write-Host $m
}

# Default config (overridden by config\defaults.json when present)
$Config = @{
  default_format = "mp4";
  profiles = @(
    @{ name="Fast 1080p H264"; vcodec="libx264"; preset="veryfast"; crf=23; acodec="aac"; ab="160k"; scale="" },
    @{ name="Small 720p H264"; vcodec="libx264"; preset="veryfast"; crf=25; acodec="aac"; ab="128k"; scale="1280:-2" },
    @{ name="YouTube 1080p"; vcodec="libx264"; preset="medium"; crf=21; acodec="aac"; ab="192k"; scale="1920:-2" }
  )
}
if (Test-Path $Cfg) {
  try { $Config = Get-Content $Cfg -Raw | ConvertFrom-Json } catch { Write-Log "WARN: Chyba pri načítaní configu, používam default." }
}

$global:FFMPEG = ""; $global:FFPROBE = ""
function Resolve-FFTools {
  $ff = Join-Path $Bins "ffmpeg.exe"
  $fp = Join-Path $Bins "ffprobe.exe"
  if (Test-Path $ff) { $global:FFMPEG = $ff }
  if (Test-Path $fp) { $global:FFPROBE = $fp }
  if (-not $FFMPEG -or -not (Test-Path $FFMPEG)) { Write-Log "ERROR: Nenájdený binaries\ffmpeg.exe"; return $false }
  if (-not $FFPROBE -or -not (Test-Path $FFPROBE)) { Write-Log "WARN: Nenájdený binaries\ffprobe.exe (pokračujem)" }
  return $true
}

function Run-FF([string]$a){
  $ffLog = Join-Path $Logs "ffmpeg.log"
  Write-Log "ffmpeg $a"
  & $FFMPEG $a 2>&1 | Tee-Object -FilePath $ffLog -Append | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "FFmpeg skončil s kódom $LASTEXITCODE" }
}

function Build-ScaleArg($s){ if ([string]::IsNullOrWhiteSpace($s)) { "" } else { "-vf `"scale=$s`"" } }

function Build-SubtitleArgs([string]$Mode,[string]$Path,[switch]$IsMKV){
  if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) { return " " }
  if ($Mode -eq "hard") {
    return "-vf `"subtitles=$(($Path -replace '\','/'))`"" # burn-in
  } else {
    if ($IsMKV) { return "-i `"$Path`" -c:s copy" } else { return "-i `"$Path`"" }
  }
}

function Build-WatermarkArgs([string]$Overlay,[string]$Pos="10:10"){
  if ([string]::IsNullOrWhiteSpace($Overlay) -or -not (Test-Path $Overlay)) { return " " }
  return "-i `"$Overlay`" -filter_complex `"overlay=$Pos`""
}

# FIXED: previously missing closing brace + quoting correction
function Build-EffectsArgs([string[]]$E) {
  if (-not $E -or $E.Count -eq 0) { return " " }

  $vf = @()
  foreach ($x in $E) {
    $t = ("" + $x).Trim().ToLower()
    switch -Regex ($t) {
      "^denoise$"     { $vf += "hqdn3d" }
      "^sharpen$"     { $vf += "unsharp" }
      "^grayscale$"   { $vf += "format=gray" }
      "^deinterlace$" { $vf += "yadif" }
      "^stabilize$"   { $vf += "deshake" }
      default { }
    }
  }
  if ($vf.Count -eq 0) { return " " }
  $chain = [string]::Join(",", $vf)
  return "-vf `"$chain`""
}

function Choose-Profile {
  Write-Host "`nDostupné profily:"
  for ($i=0; $i -lt $Config.profiles.Count; $i++) { Write-Host ("  [{0}] {1}" -f $i, $Config.profiles[$i].name) }
  $idx = Read-Host "Zadaj index profilu"
  if (-not [int]::TryParse($idx, [ref]([int]$null)) -or $idx -lt 0 -or $idx -ge $Config.profiles.Count) { Write-Log "ERROR: Neplatný výber profilu"; return $null }
  return $Config.profiles[$idx]
}

function Convert-Batch {
  if (-not (Resolve-FFTools)) { return }
  $p = Choose-Profile
  if ($null -eq $p) { return }

  $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov,*.webm -Recurse
  if (-not $files) { Write-Log "INFO: Žiadne vstupné súbory v 'input'"; return }

  foreach ($f in $files) {
    try {
      $rel = (Resolve-Path -LiteralPath $f.FullName).Path
      $destDir = $Out
      $ext = if ($p.format) { $p.format } else { $Config.default_format }
      $outPath = Join-Path $destDir ("{0}.{1}" -f [System.IO.Path]::GetFileNameWithoutExtension($f.Name), $ext)

      $v = @()
      if ($p.vcodec) { $v += "-c:v $($p.vcodec)" }
      if ($p.preset) { $v += "-preset $($p.preset)" }
      if ($p.crf -ne $null) { $v += "-crf $($p.crf)" }

      $a = @()
      if ($p.acodec) { $a += "-c:a $($p.acodec)" }
      if ($p.ab) { $a += "-b:a $($p.ab)" }

      $filters = @()
      if ($p.scale) { $filters += "scale=$($p.scale)" }
      if ($p.effects) { foreach ($ef in $p.effects) { $filters += $ef } }
      $vfArg = if ($filters.Count -gt 0) { "-vf `"$([string]::Join(',', $filters))`"" } else { "" }

      $args = @(
        "-y",
        "-hide_banner",
        "-loglevel warning",
        "-i `"$rel`"",
        $vfArg,
        $v -join ' ',
        $a -join ' ',
        "`"$outPath`"
      ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

      Run-FF ($args -join ' ')
      Write-Log "OK: $($f.Name) -> $([System.IO.Path]::GetFileName($outPath))"
    }
    catch {
      Write-Log "FAIL: $($f.Name) -> $($_.Exception.Message)"
    }
  }
}

function Main-Menu {
  Write-Host ""
  Write-Host "Perfect Portable Converter"
  Write-Host "=========================="
  Write-Host "1) Dávková konverzia"
  Write-Host "2) Koniec"
  $o = Read-Host "Voľba"
  switch ($o) {
    '1' { Convert-Batch }
    '2' { return $false }
    default { Write-Host "Neplatná voľba." }
  }
  return $true
}

Write-Log "PPC spustený."
while (Main-Menu) { }
Write-Log "Koniec."