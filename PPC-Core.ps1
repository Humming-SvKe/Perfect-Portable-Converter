<# Perfect Portable Converter - Core Module
   Advanced video processing functions for PPC
   Includes: hardware acceleration, watermarks, subtitles, MKV management, etc.
#>

# Hardware acceleration detection and configuration
function Get-HardwareAcceleration {
    $hwaccel = @{
        nvidia = $false
        intel = $false
        amd = $false
        available = @()
    }
    
    try {
        # Check NVIDIA
        $nvidiaCheck = & $global:FFMPEG -hide_banner -encoders 2>&1 | Select-String "h264_nvenc|hevc_nvenc"
        if ($nvidiaCheck) {
            $hwaccel.nvidia = $true
            $hwaccel.available += "nvenc"
        }
        
        # Check Intel Quick Sync
        $intelCheck = & $global:FFMPEG -hide_banner -encoders 2>&1 | Select-String "h264_qsv|hevc_qsv"
        if ($intelCheck) {
            $hwaccel.intel = $true
            $hwaccel.available += "qsv"
        }
        
        # Check AMD
        $amdCheck = & $global:FFMPEG -hide_banner -encoders 2>&1 | Select-String "h264_amf|hevc_amf"
        if ($amdCheck) {
            $hwaccel.amd = $true
            $hwaccel.available += "amf"
        }
    } catch {
        Write-Log "WARN: Hardware acceleration detection failed: $($_.Exception.Message)"
    }
    
    return $hwaccel
}

function Get-VideoInfo([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    
    try {
        $json = & $global:FFPROBE -v quiet -print_format json -show_format -show_streams $path 2>&1
        $info = $json | ConvertFrom-Json
        
        $videoStream = $info.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
        $audioStreams = $info.streams | Where-Object { $_.codec_type -eq "audio" }
        $subtitleStreams = $info.streams | Where-Object { $_.codec_type -eq "subtitle" }
        
        return @{
            format = $info.format.format_name
            duration = [double]$info.format.duration
            size = [int64]$info.format.size
            bitrate = [int]$info.format.bit_rate
            video = @{
                codec = $videoStream.codec_name
                width = [int]$videoStream.width
                height = [int]$videoStream.height
                fps = if ($videoStream.r_frame_rate) { 
                    $parts = $videoStream.r_frame_rate -split '/'
                    if ($parts.Count -eq 2) { [double]$parts[0] / [double]$parts[1] } else { 0 }
                } else { 0 }
                bitrate = [int]$videoStream.bit_rate
            }
            audio = @($audioStreams | ForEach-Object {
                @{
                    index = $_.index
                    codec = $_.codec_name
                    channels = $_.channels
                    sample_rate = $_.sample_rate
                    bitrate = [int]$_.bit_rate
                    language = if ($_.tags.language) { $_.tags.language } else { "und" }
                }
            })
            subtitles = @($subtitleStreams | ForEach-Object {
                @{
                    index = $_.index
                    codec = $_.codec_name
                    language = if ($_.tags.language) { $_.tags.language } else { "und" }
                }
            })
        }
    } catch {
        Write-Log "ERROR: Failed to get video info for $path : $($_.Exception.Message)"
        return $null
    }
}

# MKV Management Functions
function Extract-MKVTracks([string]$input, [string]$outputDir, [string[]]$trackTypes) {
    if (-not (Test-Path $input)) { return $false }
    if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Force -Path $outputDir | Out-Null }
    
    $info = Get-VideoInfo -path $input
    if (-not $info) { return $false }
    
    $baseName = [IO.Path]::GetFileNameWithoutExtension($input)
    $success = $true
    
    try {
        # Extract audio tracks
        if ($trackTypes -contains "audio") {
            $audioIdx = 0
            foreach ($audio in $info.audio) {
                $outFile = Join-Path $outputDir "$baseName.audio$audioIdx.$($audio.language).$($audio.codec)"
                $args = @('-y', '-i', $input, '-map', "0:$($audio.index)", '-c', 'copy', $outFile)
                $code = & $global:FFMPEG @args 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { $success = $false }
                $audioIdx++
            }
        }
        
        # Extract subtitle tracks
        if ($trackTypes -contains "subtitles") {
            $subIdx = 0
            foreach ($sub in $info.subtitles) {
                $ext = if ($sub.codec -eq "subrip") { "srt" } elseif ($sub.codec -eq "ass") { "ass" } else { "sub" }
                $outFile = Join-Path $outputDir "$baseName.sub$subIdx.$($sub.language).$ext"
                $args = @('-y', '-i', $input, '-map', "0:$($sub.index)", $outFile)
                $code = & $global:FFMPEG @args 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { $success = $false }
                $subIdx++
            }
        }
        
        # Extract video track
        if ($trackTypes -contains "video") {
            $outFile = Join-Path $outputDir "$baseName.video.$($info.video.codec).mkv"
            $args = @('-y', '-i', $input, '-map', '0:v:0', '-c', 'copy', $outFile)
            $code = & $global:FFMPEG @args 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { $success = $false }
        }
    } catch {
        Write-Log "ERROR: Track extraction failed: $($_.Exception.Message)"
        return $false
    }
    
    return $success
}

function Merge-MKVTracks([string[]]$inputs, [string]$output) {
    if ($inputs.Count -eq 0) { return $false }
    
    try {
        $args = @('-y')
        foreach ($inp in $inputs) {
            if (Test-Path $inp) {
                $args += @('-i', $inp)
            }
        }
        
        # Map all streams
        for ($i = 0; $i -lt $inputs.Count; $i++) {
            $args += @('-map', "$i")
        }
        
        $args += @('-c', 'copy', $output)
        
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Track merging failed: $($_.Exception.Message)"
        return $false
    }
}

# Watermark Functions
function Add-ImageWatermark([string]$input, [string]$output, [string]$watermarkPath, [string]$position, [double]$opacity) {
    if (-not (Test-Path $input) -or -not (Test-Path $watermarkPath)) { return $false }
    
    # Position presets
    $positions = @{
        "topleft" = "10:10"
        "topright" = "W-w-10:10"
        "bottomleft" = "10:H-h-10"
        "bottomright" = "W-w-10:H-h-10"
        "center" = "(W-w)/2:(H-h)/2"
    }
    
    $pos = if ($positions.ContainsKey($position)) { $positions[$position] } else { "10:10" }
    $alpha = [Math]::Max(0, [Math]::Min(1, $opacity))
    
    $filter = "movie='$watermarkPath',format=rgba,colorchannelmixer=aa=$alpha [wm]; [0:v][wm] overlay=$pos"
    
    try {
        $args = @('-y', '-i', $input, '-filter_complex', $filter, '-c:a', 'copy', $output)
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Image watermark failed: $($_.Exception.Message)"
        return $false
    }
}

function Add-TextWatermark([string]$input, [string]$output, [string]$text, [string]$position, [int]$fontSize, [string]$color, [double]$opacity) {
    if (-not (Test-Path $input)) { return $false }
    
    # Escape special characters for FFmpeg
    $escapedText = $text -replace "'", "\\'" -replace ":", "\\:"
    
    # Position presets for text
    $positions = @{
        "topleft" = "x=10:y=10"
        "topright" = "x=w-tw-10:y=10"
        "bottomleft" = "x=10:y=h-th-10"
        "bottomright" = "x=w-tw-10:y=h-th-10"
        "center" = "x=(w-tw)/2:y=(h-th)/2"
    }
    
    $pos = if ($positions.ContainsKey($position)) { $positions[$position] } else { "x=10:y=10" }
    $alpha = [Math]::Max(0, [Math]::Min(1, $opacity))
    
    # Construct drawtext filter
    $filter = "drawtext=text='$escapedText':fontsize=$fontSize:fontcolor=$color@$alpha`:$pos"
    
    try {
        $args = @('-y', '-i', $input, '-vf', $filter, '-c:a', 'copy', $output)
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Text watermark failed: $($_.Exception.Message)"
        return $false
    }
}

# Subtitle Functions
function Burn-Subtitle([string]$input, [string]$output, [string]$subtitlePath) {
    if (-not (Test-Path $input) -or -not (Test-Path $subtitlePath)) { return $false }
    
    # Escape path for FFmpeg filter
    $escapedSub = $subtitlePath -replace '\\', '/' -replace ':', '\\:'
    
    try {
        $filter = "subtitles='$escapedSub'"
        $args = @('-y', '-i', $input, '-vf', $filter, '-c:a', 'copy', $output)
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Subtitle burning failed: $($_.Exception.Message)"
        return $false
    }
}

function Convert-SubtitleFormat([string]$input, [string]$output, [string]$format) {
    if (-not (Test-Path $input)) { return $false }
    
    try {
        $args = @('-y', '-i', $input, $output)
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Subtitle conversion failed: $($_.Exception.Message)"
        return $false
    }
}

# Video Processing Functions
function Trim-Video([string]$input, [string]$output, [double]$startTime, [double]$duration) {
    if (-not (Test-Path $input)) { return $false }
    
    try {
        $args = @('-y', '-ss', $startTime.ToString(), '-i', $input)
        if ($duration -gt 0) {
            $args += @('-t', $duration.ToString())
        }
        $args += @('-c', 'copy', $output)
        
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Video trimming failed: $($_.Exception.Message)"
        return $false
    }
}

function Concatenate-Videos([string[]]$inputs, [string]$output) {
    if ($inputs.Count -eq 0) { return $false }
    
    try {
        # Create concat file
        $concatFile = Join-Path $env:TEMP "concat_$(Get-Random).txt"
        $inputs | ForEach-Object { "file '$_'" } | Out-File -FilePath $concatFile -Encoding UTF8
        
        $args = @('-y', '-f', 'concat', '-safe', '0', '-i', $concatFile, '-c', 'copy', $output)
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        
        Remove-Item $concatFile -Force -ErrorAction SilentlyContinue
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Video concatenation failed: $($_.Exception.Message)"
        return $false
    }
}

function Generate-Thumbnail([string]$input, [string]$output, [double]$timeSeconds) {
    if (-not (Test-Path $input)) { return $false }
    
    try {
        $args = @('-y', '-ss', $timeSeconds.ToString(), '-i', $input, '-vframes', '1', '-q:v', '2', $output)
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Thumbnail generation failed: $($_.Exception.Message)"
        return $false
    }
}

# Audio Processing Functions
function Normalize-Audio([string]$input, [string]$output, [string]$targetLevel) {
    if (-not (Test-Path $input)) { return $false }
    
    try {
        # Two-pass loudnorm
        $filter = "loudnorm=I=-16:TP=-1.5:LRA=11"
        $args = @('-y', '-i', $input, '-af', $filter, '-c:v', 'copy', $output)
        $code = & $global:FFMPEG @args 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Log "ERROR: Audio normalization failed: $($_.Exception.Message)"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-HardwareAcceleration',
    'Get-VideoInfo',
    'Extract-MKVTracks',
    'Merge-MKVTracks',
    'Add-ImageWatermark',
    'Add-TextWatermark',
    'Burn-Subtitle',
    'Convert-SubtitleFormat',
    'Trim-Video',
    'Concatenate-Videos',
    'Generate-Thumbnail',
    'Normalize-Audio'
)
