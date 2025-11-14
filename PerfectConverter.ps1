<#
  PerfectConverter.ps1
  A HandBrake-based converter that supports optional image watermarks and subtitle burn-in
  Workflow:
   - If a watermark image or subtitle needs burning, use bundled ffmpeg to create a temporary preprocessed input
   - Encode final output with HandBrakeCLI (bundled in `binaries`)

  Drop `HandBrakeCLI.exe` and `ffmpeg.exe` into `binaries` or enable internet for one-time download (best-effort).
#>
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
$Cfg   = Join-Path $Root "config\defaults.json"

$null = New-Item -ItemType Directory -Force -Path $Bins,$Logs,$Temp,$In,$Out,$Subs,$Ovls | Out-Null
$LogFile = Join-Path $Logs "perfectconverter.log"

function Write-Log([string]$m){
  $ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); "$ts | $m" | Out-File -Append -Encoding UTF8 $LogFile; Write-Host $m -ForegroundColor Cyan
}

function Write-Success([string]$m){ Write-Host $m -ForegroundColor Green }
function Write-Error([string]$m){ Write-Host $m -ForegroundColor Red }
function Write-Warning([string]$m){ Write-Host $m -ForegroundColor Yellow }
function Write-Info([string]$m){ Write-Host $m -ForegroundColor White }

# Helpers for downloads
function Ensure-Tls12 { try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {} }

function Download-File([string]$Url,[string]$Dst){ 
  Ensure-Tls12
  Write-Info ("Downloading: " + $Url)
  
  # Download with progress
  try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($Url, $Dst)
    $wc.Dispose()
  } catch {
    # Fallback to Invoke-WebRequest
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Dst
  }
}

function Expand-Zip([string]$Zip,[string]$Dest){
  Write-Info "Extracting archive..."
  try { Expand-Archive -Path $Zip -DestinationPath $Dest -Force }
  catch {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($Zip,$Dest)
  }
}

function Install-HandBrake {
  Write-Warning "`nHandBrakeCLI not found. Starting automatic download...`n"
  
  $urls = @(
    # HandBrake 1.10.2 stable (Windows x64)
    'https://github.com/HandBrake/HandBrake/releases/download/1.10.2/HandBrakeCLI-1.10.2-win-x86_64.zip',
    # Fallback to 1.10.1
    'https://github.com/HandBrake/HandBrake/releases/download/1.10.1/HandBrakeCLI-1.10.1-win-x86_64.zip'
  )
  foreach ($url in $urls) {
    try {
      Write-Info "Attempting download from:"
      Write-Host "  $url" -ForegroundColor DarkGray
      
      $zip = Join-Path $Temp "handbrake.zip"
      $dst = Join-Path $Temp "handbrake"
      if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
      if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
      New-Item -ItemType Directory -Force -Path $dst | Out-Null
      
      Download-File -Url $url -Dst $zip
      Expand-Zip -Zip $zip -Dest $dst
      
      $hb = Get-ChildItem -LiteralPath $dst -Recurse -Filter HandBrakeCLI.exe -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($hb) { 
        Copy-Item -LiteralPath $hb.FullName -Destination (Join-Path $Bins "HandBrakeCLI.exe") -Force 
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "`nHandBrakeCLI installed successfully!`n"
        return $true
      }
    } catch {
      Write-Warning ("Download attempt failed: " + $_.Exception.Message)
    }
  }
  Write-Error "ERROR: All HandBrake install attempts failed."
  return $false
}

function Install-FFTools {
  Write-Warning "`nFFmpeg not found. Starting automatic download...`n"
  
  $urls = @(
    # Latest nightly (master) build with many fixes (zip)
    'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip',
    # Stable release fallback
    'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
  )
  foreach ($url in $urls) {
    try {
      Write-Info "Attempting download from:"
      Write-Host "  $url" -ForegroundColor DarkGray
      
      $zip = Join-Path $Temp "ffmpeg.zip"
      $dst = Join-Path $Temp "ffmpeg"
      if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
      if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
      New-Item -ItemType Directory -Force -Path $dst | Out-Null
      
      Download-File -Url $url -Dst $zip
      Expand-Zip -Zip $zip -Dest $dst
      
      $ff = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($ff) { 
        Copy-Item -LiteralPath $ff.FullName -Destination (Join-Path $Bins "ffmpeg.exe") -Force 
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "`nFFmpeg installed successfully!`n"
        return $true
      }
    } catch {
      Write-Warning ("Download attempt failed: " + $_.Exception.Message)
    }
  }
  Write-Error "ERROR: All FFmpeg install attempts failed."
  return $false
}

function Resolve-FFTools {
  $ff = Join-Path $Bins "ffmpeg.exe"
  if (Test-Path $ff) { return $ff }
  Write-Warning "FFmpeg not found in binaries folder."
  if (Install-FFTools) {
    if (Test-Path $ff) { return $ff }
  }
  Write-Warning "FFmpeg not available. Watermark/subtitle pre-processing will be skipped."
  return $null
}

function Resolve-HandBrake {
  $hb = Join-Path $Bins "HandBrakeCLI.exe"
  if (Test-Path $hb) { return $hb }
  Write-Warning "HandBrakeCLI not found in binaries folder."
  if (Install-HandBrake) {
    if (Test-Path $hb) { return $hb }
  }
  Write-Error "ERROR: HandBrakeCLI is missing and auto-download failed."
  Write-Info "Please manually download HandBrakeCLI.exe and place it in the 'binaries' folder."
  return $null
}

# Default profiles (can be extended via config/defaults.json)
$Config = @{ 
  default_format = 'mp4';
  profiles = @(
    @{ name='HB Fast 1080p (x264)'; encoder='x264'; quality=22; aencoder='av_aac'; abr=160 },
    @{ name='HB Small 720p (x264)'; encoder='x264'; quality=24; aencoder='av_aac'; abr=128 },
    @{ name='HB x265 Medium'; encoder='x265'; quality=26; aencoder='av_aac'; abr=160 }
  )
}
if (Test-Path $Cfg) { try { $Config = Get-Content $Cfg -Raw | ConvertFrom-Json } catch { Write-Log "WARN: Config load failed, using defaults." } }

function Choose-Profile {
  Write-Host ""; Write-Host "Available HandBrake profiles:"; for ($i=0; $i -lt $Config.profiles.Count; $i++){ Write-Host ("  [{0}] {1}" -f $i, $Config.profiles[$i].name) }
  $idx = Read-Host "Enter profile index"
  $n=[int]0; if (-not [int]::TryParse($idx,[ref]$n) -or $n -lt 0 -or $n -ge $Config.profiles.Count){ Write-Log "ERROR: Invalid profile index"; return $null }
  return $Config.profiles[$n]
}

function Run-FF([string[]]$Args){
  $ff = Resolve-FFTools
  if (-not $ff) { throw "ffmpeg not available" }
  $ffLog = Join-Path $Logs "ffmpeg.log"
  Write-Info ("Running: ffmpeg " + ($Args -join ' '))
  
  # Run ffmpeg with live output (shows progress)
  $process = Start-Process -FilePath $ff -ArgumentList $Args -NoNewWindow -PassThru -Wait -RedirectStandardError $ffLog
  return $process.ExitCode
}

function Run-HB([string[]]$Args){
  $hb = Resolve-HandBrake
  if (-not $hb) { throw "HandBrakeCLI not available" }
  
  Write-Info "`n========================================`n  ENCODING IN PROGRESS`n========================================`n"
  Write-Info "HandBrakeCLI is processing your video..."
  Write-Info "You should see progress below (FPS, ETA, %):`n"
  
  # Run HandBrakeCLI with live console output (shows built-in progress)
  & $hb @Args
  
  return $LASTEXITCODE
}

function Preprocess-IfNeeded([string]$inPath,[string]$tmpPath,[string]$wm,[string]$srt){
  # If watermark image or subtitle present, run ffmpeg to produce a temporary preprocessed file
  if ((-not $wm) -and (-not $srt)) { return $inPath }
  $args = @('-y','-nostdin','-hide_banner')
  $args += @('-i', $inPath)

  $filterParts = @()
  if ($wm) {
    # Add watermark as second input
    $args += @('-i', $wm)
    # Default overlay at bottom-right with 10px margin
    $filterParts += "[0:v][1:v]overlay=main_w-overlay_w-10:main_h-overlay_h-10"
  }
  if ($srt) {
    # Use ffmpeg subtitles filter to burn SRT (assumes libass available in FFmpeg build)
    # Need to escape path for filter
    $esc = $srt -replace '\\','\\\\'
    $filterParts += "subtitles=$esc:force_style='FontName=Arial,FontSize=24,PrimaryColour=&H00FFFFFF,BackColour=&H00000000'"
  }

  if ($filterParts.Count -eq 0) { return $inPath }
  $vf = [string]::Join(',', $filterParts)
  $args += @('-map', '0:a?')
  $args += @('-c:v','libx264','-crf','18','-preset','fast')
  $args += @('-vf', $vf)
  $args += @('-c:a','copy')
  $args += @($tmpPath)

  $code = Run-FF $args
  if ($code -ne 0) { throw "ffmpeg preprocessing failed (code $code)" }
  return $tmpPath
}

function Convert-Batch-HandBrake {
  $hb = Resolve-HandBrake; if (-not $hb) { return }
  $p = Choose-Profile; if ($null -eq $p) { return }

  $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov,*.webm -Recurse
  if (-not $files) { Write-Warning "INFO: No input files in 'input'"; return }

  $total = $files.Count
  $current = 0
  
  Write-Info "`n========================================`n  BATCH CONVERSION STARTED`n========================================`n"
  Write-Info "Total files to process: $total"
  Write-Info "Profile: $($p.name)`n"

  foreach ($f in $files) {
    $current++
    $percentOverall = [math]::Round(($current / $total) * 100, 1)
    
    Write-Host "`n" -NoNewline
    Write-Host "[$current/$total] " -ForegroundColor Magenta -NoNewline
    Write-Host "($percentOverall%) " -ForegroundColor Yellow -NoNewline
    Write-Host "Processing: $($f.Name)" -ForegroundColor White
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    
    try {
      $rel = (Resolve-Path -LiteralPath $f.FullName).Path
      $ext = if ($p.PSObject.Properties.Name -contains 'format' -and $p.format) { $p.format } else { $Config.default_format }
      $outPath = Join-Path $Out ("{0}.{1}" -f [IO.Path]::GetFileNameWithoutExtension($f.Name), $ext)
      if (Test-Path $outPath) { Remove-Item -LiteralPath $outPath -Force -ErrorAction SilentlyContinue }

      # Detect overlay and subtitle matching file
      $wm = $null; if (Test-Path (Join-Path $Ovls 'watermark.png')) { $wm = (Join-Path $Ovls 'watermark.png') }
      # Per-file overlay (same basename.png)
      $perWm = Join-Path $Ovls ([IO.Path]::GetFileNameWithoutExtension($f.Name) + '.png')
      if (Test-Path $perWm) { $wm = $perWm }

      $srt = $null; $perSrt = Join-Path $Subs ([IO.Path]::GetFileNameWithoutExtension($f.Name) + '.srt')
      if (Test-Path $perSrt) { $srt = $perSrt }

      $tmpInput = $rel
      $tmpPre = Join-Path $Temp ([IO.Path]::GetFileNameWithoutExtension($f.Name) + '_pre.mp4')
      if ($wm -or $srt) {
        Write-Info ("  [STEP 1/2] Preprocessing (watermark=" + [bool]$wm + ", subtitle=" + [bool]$srt + ")")
        $tmpInput = Preprocess-IfNeeded -inPath $rel -tmpPath $tmpPre -wm $wm -srt $srt
        Write-Success "  Preprocessing complete!"
      }

      # Build HandBrakeCLI args
      Write-Info "  [STEP 2/2] Encoding with HandBrake..."
      $hbArgs = @('-i', $tmpInput, '-o', $outPath)
      if ($p.encoder) { $hbArgs += @('-e', $p.encoder) }
      if ($p.quality -ne $null) { $hbArgs += @('-q', $p.quality) }
      if ($p.aencoder) { $hbArgs += @('-E', $p.aencoder) }
      if ($p.abr) { $hbArgs += @('-B', $p.abr) }

      $code = Run-HB $hbArgs
      if ($code -ne 0) { throw "HandBrakeCLI exited with code $code" }
      if (-not (Test-Path -LiteralPath $outPath)) { throw "Output not created" }
      $fi = Get-Item -LiteralPath $outPath -ErrorAction SilentlyContinue
      if ($null -eq $fi -or [int64]$fi.Length -le 0) { throw "Output is empty" }
      
      $sizeMB = [math]::Round($fi.Length / 1MB, 2)
      Write-Success "`n  SUCCESS: $($f.Name) -> $([IO.Path]::GetFileName($outPath)) ($sizeMB MB)"

      # Cleanup temp
      if (Test-Path $tmpPre) { Remove-Item -LiteralPath $tmpPre -Force -ErrorAction SilentlyContinue }

    } catch {
      Write-Error "`n  FAILED: $($f.Name) -> $($_.Exception.Message)"
      if (Test-Path -LiteralPath $outPath) { try { $sz=(Get-Item -LiteralPath $outPath).Length; if ($sz -eq 0) { Remove-Item -LiteralPath $outPath -Force -ErrorAction SilentlyContinue } } catch {} }
    }
  }
  
  Write-Host "`n" -NoNewline
  Write-Host ("=" * 60) -ForegroundColor Green
  Write-Success "  BATCH CONVERSION COMPLETE!"
  Write-Success "  Processed: $current/$total files"
  Write-Success "  Output folder: $Out"
  Write-Host ("=" * 60) -ForegroundColor Green
}

function Main-Menu {
  Write-Host "`n" -NoNewline
  Write-Host ("=" * 60) -ForegroundColor Cyan
  Write-Host "  PERFECT PORTABLE CONVERTER - HANDBRAKE MODE" -ForegroundColor Cyan
  Write-Host ("=" * 60) -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  [1] " -ForegroundColor Yellow -NoNewline
  Write-Host "Batch Convert Videos" -ForegroundColor White
  Write-Host "  [2] " -ForegroundColor Yellow -NoNewline
  Write-Host "Exit" -ForegroundColor White
  Write-Host ""
  Write-Host ("=" * 60) -ForegroundColor Cyan
  $o = Read-Host "`nYour choice"
  
  switch ($o){ 
    '1' { Convert-Batch-HandBrake } 
    '2' { 
      Write-Success "`nThank you for using Perfect Portable Converter!"
      return $false 
    } 
    default { 
      Write-Warning "Invalid choice. Please enter 1 or 2." 
    } 
  }
  return $true
}

Write-Host "`n"
Write-Success "Perfect Portable Converter started successfully!"
Write-Info "Logs: $LogFile"
Write-Host "`n"

while (Main-Menu){}

Write-Success "`nGoodbye!`n"
