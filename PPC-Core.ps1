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
# HandBrake-inspired Advanced Functions

# 2-Pass encoding for better quality
function Convert-Video2Pass {
    param(
        [string]$input,
        [string]$output,
        [string]$vcodec = "libx264",
        [string]$preset = "medium",
        [int]$targetBitrate = 2000,
        [string]$acodec = "aac",
        [string]$audioBitrate = "160k",
        [string]$scale = ""
    )
    
    if (-not (Test-Path $input)) {
        Write-Log "ERROR: Input file not found: $input"
        return $false
    }
    
    $logFile = "$env:TEMP\ffmpeg2pass-$(Get-Random).log"
    $scaleFilter = if ($scale) { "-vf scale=$scale" } else { "" }
    
    try {
        # Pass 1
        Write-Log "INFO: Starting 2-pass encoding - Pass 1/2"
        $pass1Args = "-y -i `"$input`" -c:v $vcodec -preset $preset -b:v ${targetBitrate}k $scaleFilter -pass 1 -passlogfile `"$logFile`" -an -f null NUL"
        $process = Start-Process -FilePath $global:FFMPEG -ArgumentList $pass1Args -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -ne 0) {
            Write-Log "ERROR: 2-pass encoding failed at pass 1"
            return $false
        }
        
        # Pass 2
        Write-Log "INFO: Starting 2-pass encoding - Pass 2/2"
        $pass2Args = "-y -i `"$input`" -c:v $vcodec -preset $preset -b:v ${targetBitrate}k $scaleFilter -pass 2 -passlogfile `"$logFile`" -c:a $acodec -b:a $audioBitrate `"$output`""
        $process = Start-Process -FilePath $global:FFMPEG -ArgumentList $pass2Args -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "SUCCESS: 2-pass encoding completed: $output"
            return $true
        }
    } catch {
        Write-Log "ERROR: 2-pass encoding exception: $($_.Exception.Message)"
    } finally {
        # Cleanup pass log files
        Remove-Item -Path "$logFile*" -Force -ErrorAction SilentlyContinue
    }
    
    return $false
}

# Advanced video filters
function Apply-VideoFilters {
    param(
        [string]$input,
        [string]$output,
        [hashtable]$filters
    )
    
    $filterChain = @()
    
    if ($filters.deinterlace) { $filterChain += "yadif=0:-1:0" }
    if ($filters.denoise) { $filterChain += "hqdn3d=4:3:6:4.5" }
    if ($filters.sharpen) { $filterChain += "unsharp=5:5:1.0:5:5:0.0" }
    if ($filters.deblock) { $filterChain += "deblock=filter=strong" }
    if ($filters.brightness -ne 0) { $filterChain += "eq=brightness=$($filters.brightness)" }
    if ($filters.contrast -ne 0) { $filterChain += "eq=contrast=$($filters.contrast)" }
    if ($filters.saturation -ne 0) { $filterChain += "eq=saturation=$($filters.saturation)" }
    if ($filters.rotate) { 
        switch ($filters.rotate) {
            90 { $filterChain += "transpose=1" }
            180 { $filterChain += "transpose=2,transpose=2" }
            270 { $filterChain += "transpose=2" }
        }
    }
    
    if ($filterChain.Count -eq 0) {
        Write-Log "WARN: No filters specified"
        return $false
    }
    
    $vf = $filterChain -join ","
    
    try {
        $args = "-y -i `"$input`" -vf `"$vf`" -c:a copy `"$output`""
        $process = Start-Process -FilePath $global:FFMPEG -ArgumentList $args -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "SUCCESS: Filters applied: $output"
            return $true
        }
    } catch {
        Write-Log "ERROR: Filter application failed: $($_.Exception.Message)"
    }
    
    return $false
}

# Audio processing functions
function Process-Audio {
    param(
        [string]$input,
        [string]$output,
        [hashtable]$settings
    )
    
    $audioFilters = @()
    
    # Volume adjustment (in dB)
    if ($settings.volume) {
        $audioFilters += "volume=$($settings.volume)dB"
    }
    
    # Audio speed
    if ($settings.speed -and $settings.speed -ne 1.0) {
        $audioFilters += "atempo=$($settings.speed)"
    }
    
    # Normalize audio
    if ($settings.normalize) {
        $audioFilters += "loudnorm=I=-16:TP=-1.5:LRA=11"
    }
    
    # Bass/treble boost
    if ($settings.bass) {
        $audioFilters += "bass=g=$($settings.bass)"
    }
    if ($settings.treble) {
        $audioFilters += "treble=g=$($settings.treble)"
    }
    
    $af = if ($audioFilters.Count -gt 0) { 
        $filterString = $audioFilters -join ','
        "-af `"$filterString`""
    } else { 
        ""
    }
    
    try {
        $args = "-y -i `"$input`" $af -c:v copy `"$output`""
        $process = Start-Process -FilePath $global:FFMPEG -ArgumentList $args -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "SUCCESS: Audio processed: $output"
            return $true
        }
    } catch {
        Write-Log "ERROR: Audio processing failed: $($_.Exception.Message)"
    }
    
    return $false
}

# File size predictor
function Predict-FileSize {
    param(
        [string]$input,
        [int]$targetBitrate,  # in kbps
        [int]$audioBitrate = 160  # in kbps
    )
    
    $info = Get-VideoInfo -path $input
    if (-not $info) { return 0 }
    
    $durationSeconds = $info.duration
    $totalBitrate = $targetBitrate + $audioBitrate
    
    # Size in MB = (bitrate in kbps × duration in seconds) / (8 × 1024)
    $predictedSizeMB = ($totalBitrate * $durationSeconds) / (8 * 1024)
    
    return [math]::Round($predictedSizeMB, 2)
}

# Calculate optimal bitrate for target file size
function Get-OptimalBitrate {
    param(
        [string]$input,
        [double]$targetSizeMB,
        [int]$audioBitrate = 160  # in kbps
    )
    
    $info = Get-VideoInfo -path $input
    if (-not $info) { return 0 }
    
    $durationSeconds = $info.duration
    
    # Calculate total bitrate needed
    # bitrate (kbps) = (size in MB × 8 × 1024) / duration in seconds
    $totalBitrateKbps = ($targetSizeMB * 8 * 1024) / $durationSeconds
    
    # Subtract audio bitrate to get video bitrate
    $videoBitrateKbps = $totalBitrateKbps - $audioBitrate
    
    return [math]::Max(100, [int]$videoBitrateKbps)
}

# Batch template system
function Apply-BatchTemplate {
    param(
        [string[]]$inputFiles,
        [hashtable]$template,
        [string]$outputDir
    )
    
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    }
    
    $results = @()
    $index = 1
    $total = $inputFiles.Count
    
    foreach ($file in $inputFiles) {
        Write-Log "INFO: Processing file $index/$total : $(Split-Path $file -Leaf)"
        
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file) + "_converted." + $template.format
        $outputPath = Join-Path $outputDir $outputName
        
        $success = $false
        
        # Apply template settings
        if ($template.twopass) {
            $success = Convert-Video2Pass -input $file -output $outputPath `
                -vcodec $template.vcodec -preset $template.preset `
                -targetBitrate $template.bitrate -acodec $template.acodec `
                -audioBitrate $template.audiobitrate -scale $template.scale
        } else {
            # Standard single-pass conversion
            $args = @(
                "-y",
                "-i", "`"$file`"",
                "-c:v", $template.vcodec,
                "-preset", $template.preset
            )
            
            if ($template.crf) {
                $args += "-crf", $template.crf
            } elseif ($template.bitrate) {
                $args += "-b:v", "$($template.bitrate)k"
            }
            
            if ($template.scale) {
                $args += "-vf", "scale=$($template.scale)"
            }
            
            $args += "-c:a", $template.acodec, "-b:a", $template.audiobitrate, "`"$outputPath`""
            
            try {
                $process = Start-Process -FilePath $global:FFMPEG -ArgumentList ($args -join " ") -Wait -NoNewWindow -PassThru
                $success = ($process.ExitCode -eq 0)
            } catch {
                Write-Log "ERROR: Conversion failed: $($_.Exception.Message)"
            }
        }
        
        $results += @{
            input = $file
            output = $outputPath
            success = $success
        }
        
        $index++
    }
    
    return $results
}

# Chapter management for MKV
function Add-ChapterMarkers {
    param(
        [string]$input,
        [string]$output,
        [hashtable[]]$chapters  # Array of @{ time = "00:00:00"; title = "Chapter 1" }
    )
    
    $chapterFile = "$env:TEMP\chapters-$(Get-Random).txt"
    
    try {
        # Create chapter file in FFmpeg metadata format
        $content = ";FFMETADATA1`n"
        foreach ($chapter in $chapters) {
            $timeMs = ([TimeSpan]::Parse($chapter.time)).TotalMilliseconds
            $content += "[CHAPTER]`n"
            $content += "TIMEBASE=1/1000`n"
            $content += "START=$([int]$timeMs)`n"
            $content += "END=$([int]($timeMs + 1000))`n"  # 1 second duration
            $content += "title=$($chapter.title)`n`n"
        }
        
        $content | Out-File -FilePath $chapterFile -Encoding UTF8
        
        $args = "-y -i `"$input`" -i `"$chapterFile`" -map_metadata 1 -codec copy `"$output`""
        $process = Start-Process -FilePath $global:FFMPEG -ArgumentList $args -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "SUCCESS: Chapter markers added: $output"
            return $true
        }
    } catch {
        Write-Log "ERROR: Failed to add chapters: $($_.Exception.Message)"
    } finally {
        Remove-Item -Path $chapterFile -Force -ErrorAction SilentlyContinue
    }
    
    return $false
}

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
    'Normalize-Audio',
    'Convert-Video2Pass',
    'Apply-VideoFilters',
    'Process-Audio',
    'Predict-FileSize',
    'Get-OptimalBitrate',
    'Apply-BatchTemplate',
    'Add-ChapterMarkers'
)
