<# Perfect Portable Converter (PPC) - Enhanced Edition
   Full-featured offline video converter with advanced processing capabilities
   Features: Hardware acceleration, watermarks, subtitles, MKV management, batch processing
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
$Thumb = Join-Path $Root "thumbnails"
$Cfg   = Join-Path $Root "config\defaults.json"
$CoreModule = Join-Path $Root "PPC-Core.ps1"
$ThemeModule = Join-Path $Root "PPC-Themes.ps1"

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

# Load configuration
$Config = @{
  default_format = "mp4"
  hardware_acceleration = @{ enabled = $true; prefer = "auto" }
  profiles = @(
    @{ name="Fast 1080p H264";  vcodec="libx264"; preset="veryfast"; crf=23; acodec="aac"; ab="160k"; scale=""; format="mp4" }
  )
  filters = @{}
}
if (Test-Path $Cfg) { 
  try { 
    $loadedConfig = Get-Content $Cfg -Raw | ConvertFrom-Json
    # Convert JSON to hashtable recursively
    function ConvertTo-Hashtable($obj) {
      $hash = @{}
      $obj.PSObject.Properties | ForEach-Object {
        if ($_.Value -is [System.Management.Automation.PSCustomObject]) {
          $hash[$_.Name] = ConvertTo-Hashtable $_.Value
        } elseif ($_.Value -is [Array]) {
          $hash[$_.Name] = @($_.Value | ForEach-Object {
            if ($_ -is [System.Management.Automation.PSCustomObject]) {
              ConvertTo-Hashtable $_
            } else { $_ }
          })
        } else {
          $hash[$_.Name] = $_.Value
        }
      }
      return $hash
    }
    $Config = ConvertTo-Hashtable $loadedConfig
  } catch { 
    Write-Log "WARN: Config load failed, using defaults." 
  } 
}

# Load core module if available
if (Test-Path $CoreModule) {
  try {
    . $CoreModule
    $script:CoreModuleLoaded = $true
  } catch {
    Write-Log "WARN: Core module load failed: $($_.Exception.Message)"
    $script:CoreModuleLoaded = $false
  }
} else {
  $script:CoreModuleLoaded = $false
}

# Load theme module if available
if (Test-Path $ThemeModule) {
  try {
    . $ThemeModule
    $script:ThemeModuleLoaded = $true
  } catch {
    Write-Log "WARN: Theme module load failed: $($_.Exception.Message)"
    $script:ThemeModuleLoaded = $false
  }
} else {
  $script:ThemeModuleLoaded = $false
}

$global:FFMPEG=""; $global:FFPROBE=""
function Install-FFTools {
  $urls = @(
    # Latest nightly (master) build with many fixes (zip)
    'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip',
    # Stable release fallback
    'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
  )
  foreach ($url in $urls) {
    try {
      $zip = Join-Path $Temp "ffmpeg.zip"
      $dst = Join-Path $Temp "ffmpeg"
      if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
      if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
      New-Item -ItemType Directory -Force -Path $dst | Out-Null
      Download-File -Url $url -Dst $zip
      Expand-Zip -Zip $zip -Dest $dst
      $ff = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
      $fp = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffprobe.exe -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($ff) { Copy-Item -LiteralPath $ff.FullName -Destination (Join-Path $Bins "ffmpeg.exe") -Force }
      if ($fp) { Copy-Item -LiteralPath $fp.FullName -Destination (Join-Path $Bins "ffprobe.exe") -Force }
      Remove-Item $zip -Force -ErrorAction SilentlyContinue
      Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
      Write-Log ("FFmpeg installed from: " + $url)
      return $true
    } catch {
      Write-Log ("WARN: FFmpeg install attempt failed from " + $url + ": " + $_.Exception.Message)
    }
  }
  Write-Log "ERROR: All FFmpeg install attempts failed."
  return $false
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

function Run-FF([string[]]$Args, [switch]$ShowProgress){
  $ffLog = Join-Path $Logs "ffmpeg.log"
  Write-Log ("ffmpeg " + ($Args -join ' '))
  
  if ($ShowProgress) {
    & $FFMPEG @Args 2>&1 | Tee-Object -FilePath $ffLog -Append
  } else {
    & $FFMPEG @Args 2>&1 | Tee-Object -FilePath $ffLog -Append | Out-Null
  }
  return $LASTEXITCODE
}

function Get-HWAccelArgs([hashtable]$profile) {
  $args = @()
  
  if (-not $Config.hardware_acceleration.enabled) { return $args }
  if (-not $profile.ContainsKey('hwaccel')) { return $args }
  
  $hwType = $profile.hwaccel
  
  switch ($hwType) {
    'nvenc' {
      # NVIDIA hardware acceleration
      if ($profile.vcodec -match 'nvenc') {
        $args += @('-hwaccel', 'cuda', '-hwaccel_output_format', 'cuda')
      }
    }
    'qsv' {
      # Intel Quick Sync
      if ($profile.vcodec -match 'qsv') {
        $args += @('-hwaccel', 'qsv', '-hwaccel_output_format', 'qsv')
      }
    }
    'amf' {
      # AMD hardware acceleration
      if ($profile.vcodec -match 'amf') {
        $args += @('-hwaccel', 'd3d11va')
      }
    }
  }
  
  return $args
}

function Choose-Profile {
  Write-Host ""; Write-Host "Available profiles:"; for ($i=0; $i -lt $Config.profiles.Count; $i++){ Write-Host ("  [{0}] {1}" -f $i, $Config.profiles[$i].name) }
  $idx = Read-Host "Enter profile index"
  $n=[int]0; if (-not [int]::TryParse($idx,[ref]$n) -or $n -lt 0 -or $n -ge $Config.profiles.Count){ Write-Log "ERROR: Invalid profile index"; return $null }
  return $Config.profiles[$n]
}

function Convert-Batch {
  if (-not (Resolve-FFTools)) { return }
  $p = Choose-Profile; if ($null -eq $p) { return }

  $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov,*.webm,*.flv,*.wmv -Recurse
  if (-not $files) { Write-Log "INFO: No input files in 'input'"; Write-Host "No video files found in 'input' folder" -ForegroundColor Yellow; return }

  Write-Host "`nFound $($files.Count) file(s) to process" -ForegroundColor Green
  Write-Host "Profile: $($p.name)" -ForegroundColor Cyan
  
  $okCount = 0
  $failCount = 0
  $startTime = Get-Date
  
  foreach ($f in $files) {
    try {
      Write-Host "`n[$(($okCount + $failCount + 1))/$($files.Count)] Processing: $($f.Name)" -ForegroundColor White
      
      $rel = (Resolve-Path -LiteralPath $f.FullName).Path
      $ext = if ($p.ContainsKey('format') -and $p.format) { $p.format } else { $Config.default_format }
      $outPath = Join-Path $Out ("{0}.{1}" -f [IO.Path]::GetFileNameWithoutExtension($f.Name), $ext)
      
      if (Test-Path $outPath) { 
        Write-Host "  Output exists, removing old file..." -ForegroundColor Yellow
        Remove-Item -LiteralPath $outPath -Force -ErrorAction SilentlyContinue 
      }

      # Hardware acceleration args
      $hwArgs = Get-HWAccelArgs -profile $p
      
      # Video args
      $vArgs=@()
      if ($p.ContainsKey('vcodec') -and $p.vcodec -ne 'none') { 
        $vArgs += @('-c:v', "$($p.vcodec)") 
        
        if ($p.ContainsKey('preset') -and $p.preset) { $vArgs += @('-preset', "$($p.preset)") }
        
        # CRF mode (quality-based)
        if ($p.ContainsKey('crf') -and $null -ne $p.crf) { 
          $vArgs += @('-crf', "$($p.crf)") 
        }
        
        # Bitrate mode (for hardware encoders or specific profiles)
        if ($p.ContainsKey('vb') -and $p.vb) {
          $vArgs += @('-b:v', "$($p.vb)")
        }
        
        # Profile and level (for H.264/H.265)
        if ($p.ContainsKey('profile') -and $p.profile) {
          $vArgs += @('-profile:v', "$($p.profile)")
        }
        if ($p.ContainsKey('level') -and $p.level) {
          $vArgs += @('-level', "$($p.level)")
        }
        
        # Quality mode for AMF
        if ($p.ContainsKey('quality') -and $p.quality) {
          $vArgs += @('-quality', "$($p.quality)")
        }
      } elseif ($p.vcodec -eq 'none') {
        $vArgs += @('-vn')  # No video
      }

      # Audio args
      $aArgs=@()
      if ($p.ContainsKey('acodec') -and $p.acodec -ne 'none') { 
        $aArgs += @('-c:a', "$($p.acodec)") 
        if ($p.ContainsKey('ab') -and $p.ab) { $aArgs += @('-b:a', "$($p.ab)") }
      } elseif ($p.acodec -eq 'none') {
        $aArgs += @('-an')  # No audio
      }

      # Filters
      $filters=@()
      if ($p.ContainsKey('scale') -and $p.scale) { $filters += "scale=$($p.scale)" }
      if ($p.ContainsKey('effects') -and $p.effects) { 
        foreach ($ef in $p.effects) { $filters += $ef } 
      }
      if ($p.ContainsKey('deinterlace') -and $p.deinterlace) {
        $filters += if ($Config.filters.ContainsKey('deinterlace')) { $Config.filters.deinterlace } else { "yadif" }
      }
      if ($p.ContainsKey('denoise') -and $p.denoise) {
        $filters += if ($Config.filters.ContainsKey('denoise')) { $Config.filters.denoise } else { "hqdn3d" }
      }
      
      $vfArgs=@()
      $chain = if ($filters.Count -gt 0) { [string]::Join(',', $filters) } else { '' }
      if ($chain) { $vfArgs = @('-vf', $chain) }
      
      # Max duration (for WhatsApp, etc.)
      $maxDurArgs = @()
      if ($p.ContainsKey('maxdur') -and $p.maxdur -gt 0) {
        $maxDurArgs = @('-t', [string]$p.maxdur)
      }

      $args = @('-y','-nostdin','-hide_banner','-loglevel','info','-stats') + $hwArgs + @('-i', $rel) + $maxDurArgs + $vfArgs + $vArgs + $aArgs + @($outPath)
      
      Write-Host "  Encoding..." -ForegroundColor Green
      $code = Run-FF $args -ShowProgress
      
      if ($code -ne 0) { throw "FFmpeg exited with code $code" }
      if (-not (Test-Path -LiteralPath $outPath)) { throw "Output not created" }
      
      $fi = Get-Item -LiteralPath $outPath -ErrorAction SilentlyContinue
      if ($null -eq $fi -or [int64]$fi.Length -le 0) { throw "Output is empty" }
      
      $inputSize = [Math]::Round($f.Length / 1MB, 2)
      $outputSize = [Math]::Round($fi.Length / 1MB, 2)
      $reduction = if ($inputSize -gt 0) { [Math]::Round((1 - ($outputSize / $inputSize)) * 100, 1) } else { 0 }
      
      Write-Host "  SUCCESS: $($f.Name) -> $([IO.Path]::GetFileName($outPath))" -ForegroundColor Green
      Write-Host "  Size: $inputSize MB -> $outputSize MB ($reduction% reduction)" -ForegroundColor Cyan
      Write-Log ("OK: {0} -> {1} (${inputSize}MB -> ${outputSize}MB)" -f $f.Name, [IO.Path]::GetFileName($outPath))
      $okCount++
    }
    catch {
      Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
      Write-Log ("FAIL: {0} -> {1}" -f $f.Name, $_.Exception.Message)
      $failCount++
      
      if (Test-Path -LiteralPath $outPath) { 
        try { 
          $sz=(Get-Item -LiteralPath $outPath).Length
          if ($sz -eq 0) { 
            Remove-Item -LiteralPath $outPath -Force -ErrorAction SilentlyContinue 
          } 
        } catch {} 
      }
    }
  }
  
  $elapsed = (Get-Date) - $startTime
  Write-Host "`n" + ("="*50) -ForegroundColor Cyan
  Write-Host "Batch conversion completed!" -ForegroundColor Green
  Write-Host "Success: $okCount, Failed: $failCount" -ForegroundColor White
  Write-Host "Total time: $([Math]::Floor($elapsed.TotalMinutes))m $($elapsed.Seconds)s" -ForegroundColor White
  Write-Host ("="*50) -ForegroundColor Cyan
}

function Show-VideoInfo {
  Write-Host "`n=== Video Information ===" -ForegroundColor Cyan
  $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov,*.webm -Recurse
  if (-not $files) { Write-Host "No video files in 'input'" -ForegroundColor Yellow; return }
  
  $choice = $files | ForEach-Object { $_.Name }
  for ($i = 0; $i -lt $choice.Count; $i++) { Write-Host "  [$i] $($choice[$i])" }
  $idx = Read-Host "Select file index"
  $n = [int]0
  if (-not [int]::TryParse($idx, [ref]$n) -or $n -lt 0 -or $n -ge $files.Count) {
    Write-Host "Invalid index" -ForegroundColor Red
    return
  }
  
  if (-not (Resolve-FFTools)) { return }
  
  $file = $files[$n]
  Write-Host "`nAnalyzing: $($file.Name)..." -ForegroundColor Green
  
  if ($script:CoreModuleLoaded) {
    $info = Get-VideoInfo -path $file.FullName
    if ($info) {
      Write-Host "`nFormat: $($info.format)"
      Write-Host "Duration: $([Math]::Round($info.duration, 2)) seconds"
      Write-Host "Size: $([Math]::Round($info.size / 1MB, 2)) MB"
      Write-Host "Bitrate: $([Math]::Round($info.bitrate / 1000, 0)) kbps"
      Write-Host "`nVideo:"
      Write-Host "  Codec: $($info.video.codec)"
      Write-Host "  Resolution: $($info.video.width)x$($info.video.height)"
      Write-Host "  FPS: $([Math]::Round($info.video.fps, 2))"
      Write-Host "`nAudio Tracks: $($info.audio.Count)"
      foreach ($a in $info.audio) {
        Write-Host "  Track $($a.index): $($a.codec), $($a.channels) ch, $($a.sample_rate) Hz, Language: $($a.language)"
      }
      Write-Host "`nSubtitle Tracks: $($info.subtitles.Count)"
      foreach ($s in $info.subtitles) {
        Write-Host "  Track $($s.index): $($s.codec), Language: $($s.language)"
      }
    }
  } else {
    & $global:FFPROBE -hide_banner $file.FullName
  }
}

function MKV-Manager {
  Write-Host "`n=== MKV Manager ===" -ForegroundColor Cyan
  Write-Host "1) Extract tracks from MKV"
  Write-Host "2) Merge tracks to MKV"
  Write-Host "3) Back"
  
  $choice = Read-Host "Choice"
  switch ($choice) {
    '1' {
      if (-not $script:CoreModuleLoaded) {
        Write-Host "Core module not available" -ForegroundColor Red
        return
      }
      
      $files = Get-ChildItem $In -File -Filter *.mkv
      if (-not $files) { Write-Host "No MKV files in 'input'" -ForegroundColor Yellow; return }
      
      for ($i = 0; $i -lt $files.Count; $i++) { Write-Host "  [$i] $($files[$i].Name)" }
      $idx = Read-Host "Select file index"
      $n = [int]0
      if (-not [int]::TryParse($idx, [ref]$n) -or $n -lt 0 -or $n -ge $files.Count) {
        Write-Host "Invalid index" -ForegroundColor Red
        return
      }
      
      Write-Host "Extract: [A]udio, [V]ideo, [S]ubtitles, or [All]"
      $extractType = Read-Host "Choice"
      
      $types = @()
      switch ($extractType.ToLower()) {
        'a' { $types = @('audio') }
        'v' { $types = @('video') }
        's' { $types = @('subtitles') }
        'all' { $types = @('audio', 'video', 'subtitles') }
        default { Write-Host "Invalid choice" -ForegroundColor Red; return }
      }
      
      $outputDir = Join-Path $Out "extracted"
      if (Resolve-FFTools) {
        Write-Host "Extracting..." -ForegroundColor Green
        $result = Extract-MKVTracks -input $files[$n].FullName -outputDir $outputDir -trackTypes $types
        if ($result) {
          Write-Host "SUCCESS: Tracks extracted to '$outputDir'" -ForegroundColor Green
        } else {
          Write-Host "FAILED: Check logs for details" -ForegroundColor Red
        }
      }
    }
    '2' {
      Write-Host "Merge functionality - place input files in 'input' folder" -ForegroundColor Yellow
      Write-Host "Files will be merged in alphabetical order" -ForegroundColor Yellow
      $files = Get-ChildItem $In -File
      if ($files.Count -lt 2) {
        Write-Host "Need at least 2 files to merge" -ForegroundColor Yellow
        return
      }
      
      $output = Join-Path $Out "merged.mkv"
      if ($script:CoreModuleLoaded -and (Resolve-FFTools)) {
        $inputs = $files | ForEach-Object { $_.FullName }
        Write-Host "Merging $($inputs.Count) files..." -ForegroundColor Green
        $result = Merge-MKVTracks -inputs $inputs -output $output
        if ($result) {
          Write-Host "SUCCESS: Merged to '$output'" -ForegroundColor Green
        } else {
          Write-Host "FAILED: Check logs for details" -ForegroundColor Red
        }
      }
    }
  }
}

function Watermark-Tool {
  Write-Host "`n=== Watermark Tool ===" -ForegroundColor Cyan
  Write-Host "1) Add image watermark"
  Write-Host "2) Add text watermark"
  Write-Host "3) Back"
  
  $choice = Read-Host "Choice"
  
  if ($choice -eq '3') { return }
  
  if (-not $script:CoreModuleLoaded) {
    Write-Host "Core module not available" -ForegroundColor Red
    return
  }
  
  if (-not (Resolve-FFTools)) { return }
  
  $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov
  if (-not $files) { Write-Host "No video files in 'input'" -ForegroundColor Yellow; return }
  
  for ($i = 0; $i -lt $files.Count; $i++) { Write-Host "  [$i] $($files[$i].Name)" }
  $idx = Read-Host "Select video file"
  $n = [int]0
  if (-not [int]::TryParse($idx, [ref]$n) -or $n -lt 0 -or $n -ge $files.Count) {
    Write-Host "Invalid index" -ForegroundColor Red
    return
  }
  
  $input = $files[$n].FullName
  $output = Join-Path $Out "$($files[$n].BaseName)_watermarked$($files[$n].Extension)"
  
  switch ($choice) {
    '1' {
      $wmFiles = Get-ChildItem $Ovls -File -Include *.png,*.jpg
      if (-not $wmFiles) { Write-Host "No watermark images in 'overlays'" -ForegroundColor Yellow; return }
      
      for ($i = 0; $i -lt $wmFiles.Count; $i++) { Write-Host "  [$i] $($wmFiles[$i].Name)" }
      $wmIdx = Read-Host "Select watermark"
      $wmN = [int]0
      if (-not [int]::TryParse($wmIdx, [ref]$wmN) -or $wmN -lt 0 -or $wmN -ge $wmFiles.Count) {
        Write-Host "Invalid index" -ForegroundColor Red
        return
      }
      
      Write-Host "Position: [topleft], [topright], [bottomleft], [bottomright], [center]"
      $pos = Read-Host "Position"
      $opacity = Read-Host "Opacity (0.0-1.0)"
      $opVal = [double]0.7
      [void][double]::TryParse($opacity, [ref]$opVal)
      
      Write-Host "Processing..." -ForegroundColor Green
      $result = Add-ImageWatermark -input $input -output $output -watermarkPath $wmFiles[$wmN].FullName -position $pos -opacity $opVal
      if ($result) {
        Write-Host "SUCCESS: $output" -ForegroundColor Green
      } else {
        Write-Host "FAILED: Check logs" -ForegroundColor Red
      }
    }
    '2' {
      $text = Read-Host "Watermark text"
      Write-Host "Position: [topleft], [topright], [bottomleft], [bottomright], [center]"
      $pos = Read-Host "Position"
      $fontSize = Read-Host "Font size (default: 24)"
      $fsVal = [int]24
      [void][int]::TryParse($fontSize, [ref]$fsVal)
      $color = Read-Host "Color (default: white)"
      if ([string]::IsNullOrWhiteSpace($color)) { $color = "white" }
      $opacity = Read-Host "Opacity (0.0-1.0)"
      $opVal = [double]0.7
      [void][double]::TryParse($opacity, [ref]$opVal)
      
      Write-Host "Processing..." -ForegroundColor Green
      $result = Add-TextWatermark -input $input -output $output -text $text -position $pos -fontSize $fsVal -color $color -opacity $opVal
      if ($result) {
        Write-Host "SUCCESS: $output" -ForegroundColor Green
      } else {
        Write-Host "FAILED: Check logs" -ForegroundColor Red
      }
    }
  }
}

function Subtitle-Tool {
  Write-Host "`n=== Subtitle Tool ===" -ForegroundColor Cyan
  Write-Host "1) Burn subtitles into video"
  Write-Host "2) Convert subtitle format"
  Write-Host "3) Back"
  
  $choice = Read-Host "Choice"
  
  if ($choice -eq '3') { return }
  
  if (-not $script:CoreModuleLoaded) {
    Write-Host "Core module not available" -ForegroundColor Red
    return
  }
  
  if (-not (Resolve-FFTools)) { return }
  
  switch ($choice) {
    '1' {
      $videos = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov
      if (-not $videos) { Write-Host "No video files in 'input'" -ForegroundColor Yellow; return }
      
      $subs = Get-ChildItem $Subs -File -Include *.srt,*.ass,*.vtt
      if (-not $subs) { Write-Host "No subtitle files in 'subtitles'" -ForegroundColor Yellow; return }
      
      Write-Host "`nVideos:"
      for ($i = 0; $i -lt $videos.Count; $i++) { Write-Host "  [$i] $($videos[$i].Name)" }
      $vIdx = Read-Host "Select video"
      $vN = [int]0
      if (-not [int]::TryParse($vIdx, [ref]$vN) -or $vN -lt 0 -or $vN -ge $videos.Count) {
        Write-Host "Invalid index" -ForegroundColor Red
        return
      }
      
      Write-Host "`nSubtitles:"
      for ($i = 0; $i -lt $subs.Count; $i++) { Write-Host "  [$i] $($subs[$i].Name)" }
      $sIdx = Read-Host "Select subtitle"
      $sN = [int]0
      if (-not [int]::TryParse($sIdx, [ref]$sN) -or $sN -lt 0 -or $sN -ge $subs.Count) {
        Write-Host "Invalid index" -ForegroundColor Red
        return
      }
      
      $output = Join-Path $Out "$($videos[$vN].BaseName)_subbed$($videos[$vN].Extension)"
      Write-Host "Processing..." -ForegroundColor Green
      $result = Burn-Subtitle -input $videos[$vN].FullName -output $output -subtitlePath $subs[$sN].FullName
      if ($result) {
        Write-Host "SUCCESS: $output" -ForegroundColor Green
      } else {
        Write-Host "FAILED: Check logs" -ForegroundColor Red
      }
    }
    '2' {
      $subs = Get-ChildItem $Subs -File -Include *.srt,*.ass,*.vtt
      if (-not $subs) { Write-Host "No subtitle files in 'subtitles'" -ForegroundColor Yellow; return }
      
      for ($i = 0; $i -lt $subs.Count; $i++) { Write-Host "  [$i] $($subs[$i].Name)" }
      $sIdx = Read-Host "Select subtitle"
      $sN = [int]0
      if (-not [int]::TryParse($sIdx, [ref]$sN) -or $sN -lt 0 -or $sN -ge $subs.Count) {
        Write-Host "Invalid index" -ForegroundColor Red
        return
      }
      
      $format = Read-Host "Output format [srt/ass/vtt]"
      $output = Join-Path $Out "$($subs[$sN].BaseName).$format"
      
      Write-Host "Converting..." -ForegroundColor Green
      $result = Convert-SubtitleFormat -input $subs[$sN].FullName -output $output -format $format
      if ($result) {
        Write-Host "SUCCESS: $output" -ForegroundColor Green
      } else {
        Write-Host "FAILED: Check logs" -ForegroundColor Red
      }
    }
  }
}

function Video-Tools {
  Write-Host "`n=== Video Tools ===" -ForegroundColor Cyan
  Write-Host "1) Trim/Cut video"
  Write-Host "2) Concatenate videos"
  Write-Host "3) Generate thumbnail"
  Write-Host "4) Back"
  
  $choice = Read-Host "Choice"
  
  if ($choice -eq '4') { return }
  
  if (-not $script:CoreModuleLoaded) {
    Write-Host "Core module not available" -ForegroundColor Red
    return
  }
  
  if (-not (Resolve-FFTools)) { return }
  
  switch ($choice) {
    '1' {
      $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov
      if (-not $files) { Write-Host "No video files in 'input'" -ForegroundColor Yellow; return }
      
      for ($i = 0; $i -lt $files.Count; $i++) { Write-Host "  [$i] $($files[$i].Name)" }
      $idx = Read-Host "Select video"
      $n = [int]0
      if (-not [int]::TryParse($idx, [ref]$n) -or $n -lt 0 -or $n -ge $files.Count) {
        Write-Host "Invalid index" -ForegroundColor Red
        return
      }
      
      $start = Read-Host "Start time (seconds)"
      $duration = Read-Host "Duration (seconds, 0 for rest)"
      $startVal = [double]0
      $durVal = [double]0
      [void][double]::TryParse($start, [ref]$startVal)
      [void][double]::TryParse($duration, [ref]$durVal)
      
      $output = Join-Path $Out "$($files[$n].BaseName)_trimmed$($files[$n].Extension)"
      Write-Host "Trimming..." -ForegroundColor Green
      $result = Trim-Video -input $files[$n].FullName -output $output -startTime $startVal -duration $durVal
      if ($result) {
        Write-Host "SUCCESS: $output" -ForegroundColor Green
      } else {
        Write-Host "FAILED: Check logs" -ForegroundColor Red
      }
    }
    '2' {
      $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov
      if ($files.Count -lt 2) {
        Write-Host "Need at least 2 video files in 'input'" -ForegroundColor Yellow
        return
      }
      
      Write-Host "Will concatenate all videos in 'input' folder in alphabetical order"
      $inputs = $files | Sort-Object Name | ForEach-Object { $_.FullName }
      $output = Join-Path $Out "concatenated.mp4"
      
      Write-Host "Concatenating $($inputs.Count) files..." -ForegroundColor Green
      $result = Concatenate-Videos -inputs $inputs -output $output
      if ($result) {
        Write-Host "SUCCESS: $output" -ForegroundColor Green
      } else {
        Write-Host "FAILED: Check logs" -ForegroundColor Red
      }
    }
    '3' {
      $files = Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov
      if (-not $files) { Write-Host "No video files in 'input'" -ForegroundColor Yellow; return }
      
      for ($i = 0; $i -lt $files.Count; $i++) { Write-Host "  [$i] $($files[$i].Name)" }
      $idx = Read-Host "Select video"
      $n = [int]0
      if (-not [int]::TryParse($idx, [ref]$n) -or $n -lt 0 -or $n -ge $files.Count) {
        Write-Host "Invalid index" -ForegroundColor Red
        return
      }
      
      $time = Read-Host "Time position (seconds)"
      $timeVal = [double]5
      [void][double]::TryParse($time, [ref]$timeVal)
      
      $output = Join-Path $Thumb "$($files[$n].BaseName)_thumb.jpg"
      Write-Host "Generating..." -ForegroundColor Green
      $result = Generate-Thumbnail -input $files[$n].FullName -output $output -timeSeconds $timeVal
      if ($result) {
        Write-Host "SUCCESS: $output" -ForegroundColor Green
      } else {
        Write-Host "FAILED: Check logs" -ForegroundColor Red
      }
    }
  }
}

function Hardware-Info {
  if (-not (Resolve-FFTools)) { return }
  
  Write-Host "`n=== Hardware Acceleration Status ===" -ForegroundColor Cyan
  
  if ($script:CoreModuleLoaded) {
    $hw = Get-HardwareAcceleration
    Write-Host "NVIDIA NVENC: " -NoNewline
    if ($hw.nvidia) { Write-Host "Available" -ForegroundColor Green } else { Write-Host "Not Available" -ForegroundColor Red }
    
    Write-Host "Intel Quick Sync: " -NoNewline
    if ($hw.intel) { Write-Host "Available" -ForegroundColor Green } else { Write-Host "Not Available" -ForegroundColor Red }
    
    Write-Host "AMD AMF: " -NoNewline
    if ($hw.amd) { Write-Host "Available" -ForegroundColor Green } else { Write-Host "Not Available" -ForegroundColor Red }
    
    if ($hw.available.Count -gt 0) {
      Write-Host "`nAvailable hardware acceleration: $($hw.available -join ', ')" -ForegroundColor Green
      Write-Host "Use profiles with hardware acceleration for faster encoding" -ForegroundColor Yellow
    } else {
      Write-Host "`nNo hardware acceleration available. Using software encoding." -ForegroundColor Yellow
    }
  } else {
    Write-Host "Core module not loaded - hardware detection unavailable" -ForegroundColor Yellow
  }
  
  Write-Host "`nFFmpeg version:"
  & $global:FFMPEG -version | Select-Object -First 1
}

function Advanced-Tools {
  if (-not $script:CoreModuleLoaded) {
    Write-Host "Core module required for advanced tools." -ForegroundColor Red
    Read-Host "Press Enter"
    return
  }
  
  Write-Host ""
  Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║  Advanced Tools                       ║" -ForegroundColor Cyan
  Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""
  Write-Host " [1] 2-Pass Encoding (Better Quality)" -ForegroundColor Green
  Write-Host " [2] Apply Video Filters" -ForegroundColor White
  Write-Host " [3] Process Audio (Volume/Speed/Normalize)" -ForegroundColor White
  Write-Host " [4] File Size Predictor" -ForegroundColor White
  Write-Host " [5] Calculate Optimal Bitrate" -ForegroundColor White
  Write-Host " [6] Add Chapter Markers" -ForegroundColor White
  Write-Host " [0] Back" -ForegroundColor Red
  Write-Host ""
  
  $o = Read-Host "Choice"
  switch ($o) {
    '1' { Tool-2Pass }
    '2' { Tool-VideoFilters }
    '3' { Tool-AudioProcess }
    '4' { Tool-FileSizePredictor }
    '5' { Tool-OptimalBitrate }
    '6' { Tool-ChapterMarkers }
    '0' { return }
    default { Write-Host "Invalid choice." -ForegroundColor Red; Read-Host "Press Enter" }
  }
}

function Tool-2Pass {
  Write-Host "`n2-Pass Encoding Tool" -ForegroundColor Cyan
  Write-Host "Provides better quality at target bitrate`n"
  
  $input = Read-Host "Input file path"
  if (-not (Test-Path $input)) {
    Write-Host "File not found." -ForegroundColor Red
    Read-Host "Press Enter"
    return
  }
  
  $output = Read-Host "Output file path"
  $bitrate = Read-Host "Target video bitrate (kbps, e.g., 2000)"
  
  Write-Host "`nStarting 2-pass encoding..." -ForegroundColor Yellow
  
  if (Convert-Video2Pass -input $input -output $output -targetBitrate ([int]$bitrate)) {
    Write-Host "`n✓ 2-pass encoding completed!" -ForegroundColor Green
  } else {
    Write-Host "`n✗ 2-pass encoding failed." -ForegroundColor Red
  }
  
  Read-Host "`nPress Enter to continue"
}

function Tool-VideoFilters {
  Write-Host "`nVideo Filters Tool" -ForegroundColor Cyan
  Write-Host "Apply filters: brightness, contrast, saturation, rotate, denoise, sharpen`n"
  
  $input = Read-Host "Input file path"
  if (-not (Test-Path $input)) {
    Write-Host "File not found." -ForegroundColor Red
    Read-Host "Press Enter"
    return
  }
  
  $output = Read-Host "Output file path"
  
  $filters = @{}
  
  Write-Host "`nSelect filters to apply:"
  if ((Read-Host "Deinterlace? (y/n)") -eq 'y') { $filters.deinterlace = $true }
  if ((Read-Host "Denoise? (y/n)") -eq 'y') { $filters.denoise = $true }
  if ((Read-Host "Sharpen? (y/n)") -eq 'y') { $filters.sharpen = $true }
  if ((Read-Host "Deblock? (y/n)") -eq 'y') { $filters.deblock = $true }
  
  $brightness = Read-Host "Brightness (-1.0 to 1.0, 0=no change)"
  if ($brightness -and $brightness -ne '0') { $filters.brightness = [double]$brightness }
  
  $contrast = Read-Host "Contrast (0.0 to 2.0, 1=no change)"
  if ($contrast -and $contrast -ne '1') { $filters.contrast = [double]$contrast }
  
  $saturation = Read-Host "Saturation (0.0 to 3.0, 1=no change)"
  if ($saturation -and $saturation -ne '1') { $filters.saturation = [double]$saturation }
  
  $rotate = Read-Host "Rotate (0/90/180/270)"
  if ($rotate -and $rotate -ne '0') { $filters.rotate = [int]$rotate }
  
  if ($filters.Count -eq 0) {
    Write-Host "No filters selected." -ForegroundColor Yellow
    Read-Host "Press Enter"
    return
  }
  
  Write-Host "`nApplying filters..." -ForegroundColor Yellow
  
  if (Apply-VideoFilters -input $input -output $output -filters $filters) {
    Write-Host "`n✓ Filters applied!" -ForegroundColor Green
  } else {
    Write-Host "`n✗ Filter application failed." -ForegroundColor Red
  }
  
  Read-Host "`nPress Enter to continue"
}

function Tool-AudioProcess {
  Write-Host "`nAudio Processing Tool" -ForegroundColor Cyan
  Write-Host "Adjust volume, speed, normalize, bass/treble`n"
  
  $input = Read-Host "Input file path"
  if (-not (Test-Path $input)) {
    Write-Host "File not found." -ForegroundColor Red
    Read-Host "Press Enter"
    return
  }
  
  $output = Read-Host "Output file path"
  
  $settings = @{}
  
  Write-Host "`nAudio settings:"
  $volume = Read-Host "Volume adjustment (dB, e.g., -5, 0, +3)"
  if ($volume -and $volume -ne '0') { $settings.volume = [double]$volume }
  
  $speed = Read-Host "Speed (0.5-2.0, 1.0=normal)"
  if ($speed -and $speed -ne '1' -and $speed -ne '1.0') { $settings.speed = [double]$speed }
  
  if ((Read-Host "Normalize audio? (y/n)") -eq 'y') { $settings.normalize = $true }
  
  $bass = Read-Host "Bass boost (dB, 0=no change)"
  if ($bass -and $bass -ne '0') { $settings.bass = [double]$bass }
  
  $treble = Read-Host "Treble boost (dB, 0=no change)"
  if ($treble -and $treble -ne '0') { $settings.treble = [double]$treble }
  
  if ($settings.Count -eq 0) {
    Write-Host "No audio processing selected." -ForegroundColor Yellow
    Read-Host "Press Enter"
    return
  }
  
  Write-Host "`nProcessing audio..." -ForegroundColor Yellow
  
  if (Process-Audio -input $input -output $output -settings $settings) {
    Write-Host "`n✓ Audio processed!" -ForegroundColor Green
  } else {
    Write-Host "`n✗ Audio processing failed." -ForegroundColor Red
  }
  
  Read-Host "`nPress Enter to continue"
}

function Tool-FileSizePredictor {
  Write-Host "`nFile Size Predictor" -ForegroundColor Cyan
  Write-Host "Predict output file size based on bitrate`n"
  
  $input = Read-Host "Input file path"
  if (-not (Test-Path $input)) {
    Write-Host "File not found." -ForegroundColor Red
    Read-Host "Press Enter"
    return
  }
  
  $videoBitrate = Read-Host "Target video bitrate (kbps)"
  $audioBitrate = Read-Host "Target audio bitrate (kbps, default 160)"
  
  if (-not $audioBitrate) { $audioBitrate = 160 }
  
  $predictedSize = Predict-FileSize -input $input -targetBitrate ([int]$videoBitrate) -audioBitrate ([int]$audioBitrate)
  
  Write-Host "`nPredicted output size: $predictedSize MB" -ForegroundColor Green
  
  Read-Host "`nPress Enter to continue"
}

function Tool-OptimalBitrate {
  Write-Host "`nOptimal Bitrate Calculator" -ForegroundColor Cyan
  Write-Host "Calculate bitrate needed for target file size`n"
  
  $input = Read-Host "Input file path"
  if (-not (Test-Path $input)) {
    Write-Host "File not found." -ForegroundColor Red
    Read-Host "Press Enter"
    return
  }
  
  $targetSize = Read-Host "Target file size (MB)"
  $audioBitrate = Read-Host "Audio bitrate (kbps, default 160)"
  
  if (-not $audioBitrate) { $audioBitrate = 160 }
  
  $optimalBitrate = Get-OptimalBitrate -input $input -targetSizeMB ([double]$targetSize) -audioBitrate ([int]$audioBitrate)
  
  Write-Host "`nOptimal video bitrate: $optimalBitrate kbps" -ForegroundColor Green
  
  Read-Host "`nPress Enter to continue"
}

function Tool-ChapterMarkers {
  Write-Host "`nChapter Markers Tool" -ForegroundColor Cyan
  Write-Host "Add chapter markers to video`n"
  
  $input = Read-Host "Input file path"
  if (-not (Test-Path $input)) {
    Write-Host "File not found." -ForegroundColor Red
    Read-Host "Press Enter"
    return
  }
  
  $output = Read-Host "Output file path"
  
  $chapters = @()
  Write-Host "`nEnter chapters (leave time empty to finish):"
  
  while ($true) {
    $time = Read-Host "Chapter time (HH:MM:SS)"
    if (-not $time) { break }
    
    $title = Read-Host "Chapter title"
    
    $chapters += @{ time = $time; title = $title }
  }
  
  if ($chapters.Count -eq 0) {
    Write-Host "No chapters defined." -ForegroundColor Yellow
    Read-Host "Press Enter"
    return
  }
  
  Write-Host "`nAdding chapters..." -ForegroundColor Yellow
  
  if (Add-ChapterMarkers -input $input -output $output -chapters $chapters) {
    Write-Host "`n✓ Chapters added!" -ForegroundColor Green
  } else {
    Write-Host "`n✗ Failed to add chapters." -ForegroundColor Red
  }
  
  Read-Host "`nPress Enter to continue"
}

function Theme-Settings {
  Write-Host ""
  Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║  Theme Settings                       ║" -ForegroundColor Cyan
  Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""
  
  if (-not $script:ThemeModuleLoaded) {
    Write-Host "Theme module not loaded." -ForegroundColor Yellow
    Read-Host "Press Enter to return"
    return
  }
  
  $themes = Get-AvailableThemes
  $config = Load-ThemeConfig
  
  Write-Host "Current theme: $($config.themes.($config.current_theme).name)" -ForegroundColor Green
  Write-Host ""
  Write-Host "Available themes:" -ForegroundColor White
  
  $index = 1
  foreach ($theme in $themes) {
    $typeColor = if ($theme.type -eq "dark") { "Cyan" } else { "Yellow" }
    Write-Host " [$index] $($theme.name) ($($theme.type))" -ForegroundColor $typeColor
    $index++
  }
  
  Write-Host " [0] Back" -ForegroundColor Red
  Write-Host ""
  
  $choice = Read-Host "Select theme"
  
  if ($choice -eq '0') { return }
  
  $themeIndex = [int]$choice - 1
  if ($themeIndex -ge 0 -and $themeIndex -lt $themes.Count) {
    $selectedTheme = $themes[$themeIndex]
    if (Set-Theme -themeName $selectedTheme.id) {
      Write-Host "Theme changed successfully!" -ForegroundColor Green
      Write-Host "Restart PPC to see full theme changes." -ForegroundColor Yellow
    }
  } else {
    Write-Host "Invalid selection." -ForegroundColor Red
  }
  
  Read-Host "Press Enter to continue"
}

function Main-Menu {
  Write-Host ""
  
  # Use themed colors if available
  $primaryColor = if ($script:ThemeModuleLoaded -and $global:CURRENT_THEME) {
    $global:CURRENT_THEME.cli.primary
  } else { "Cyan" }
  
  $secondaryColor = if ($script:ThemeModuleLoaded -and $global:CURRENT_THEME) {
    $global:CURRENT_THEME.cli.secondary
  } else { "Green" }
  
  Write-Host "╔════════════════════════════════════════╗" -ForegroundColor $primaryColor
  Write-Host "║  Perfect Portable Converter - Enhanced ║" -ForegroundColor $primaryColor
  Write-Host "╚════════════════════════════════════════╝" -ForegroundColor $primaryColor
  Write-Host ""
  Write-Host " [1] Batch Convert Videos" -ForegroundColor $secondaryColor
  Write-Host " [2] Video Information" -ForegroundColor White
  Write-Host " [3] MKV Manager" -ForegroundColor White
  Write-Host " [4] Watermark Tool" -ForegroundColor White
  Write-Host " [5] Subtitle Tool" -ForegroundColor White
  Write-Host " [6] Video Tools (Trim/Concat/Thumbnail)" -ForegroundColor White
  Write-Host " [7] Advanced Tools (2-Pass, Filters, Audio)" -ForegroundColor White
  Write-Host " [8] Hardware Acceleration Info" -ForegroundColor White
  Write-Host " [9] Theme Settings" -ForegroundColor Magenta
  Write-Host " [0] Exit" -ForegroundColor Red
  Write-Host ""
  
  $o = Read-Host "Choice"
  switch ($o) {
    '1' { Convert-Batch }
    '2' { Show-VideoInfo }
    '3' { MKV-Manager }
    '4' { Watermark-Tool }
    '5' { Subtitle-Tool }
    '6' { Video-Tools }
    '7' { Advanced-Tools }
    '8' { Hardware-Info }
    '9' { Theme-Settings }
    '0' { return $false }
    default { Write-Host "Invalid choice." -ForegroundColor Red }
  }
  return $true
}

Write-Log "PPC Enhanced Edition started."
Write-Host "`nPerfect Portable Converter - Enhanced Edition" -ForegroundColor Cyan
Write-Host "Full-featured offline video converter" -ForegroundColor White
Write-Host "Core module: $(if ($script:CoreModuleLoaded) { 'Loaded' } else { 'Not loaded (basic features only)' })" -ForegroundColor $(if ($script:CoreModuleLoaded) { 'Green' } else { 'Yellow' })
Write-Host ""

while (Main-Menu){}
Write-Log "PPC session ended."