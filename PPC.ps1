<# Perfect Portable Converter (PPC) - OFFLINE build #>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
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
function Write-Log($m){$ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss");"$ts | $m"|Out-File -Append -Encoding UTF8 $LogFile;Write-Host $m}
$Config=@{default_format="mp4";profiles=@(@{name="Fast 1080p H264";vcodec="libx264";preset="veryfast";crf=23;acodec="aac";ab="160k";scale=""},@{name="Small 720p H264";vcodec="libx264";preset="veryfast";crf=26;acodec="aac";ab="128k";scale="1280:-2"},@{name="Device WhatsApp H264";vcodec="libx264";preset="veryfast";crf=24;acodec="aac";ab="128k";scale="1280:-2";maxdur=180})}
if(Test-Path $Cfg){try{$Config=Get-Content $Cfg -Raw|ConvertFrom-Json}catch{Write-Log "WARN: Chyba pri načítaní configu, používam default."}}
$global:FFMPEG="";$global:FFPROBE=""
function Resolve-FFTools{$ff=Join-Path $Bins "ffmpeg.exe";$fp=Join-Path $Bins "ffprobe.exe";if(Test-Path $ff){$global:FFMPEG=$ff}if(Test-Path $fp){$global:FFPROBE=$fp}if(-not $FFMPEG -or -not $FFPROBE){Write-Log "OFFLINE build očakáva ffmpeg.exe a ffprobe.exe v 'binaries/'.";return $false};return $true}
function Run-FF([string]$a){$ffLog=Join-Path $Logs "ffmpeg.log";Write-Log "ffmpeg $a";& $FFMPEG $a 2>&1|Tee-Object -FilePath $ffLog -Append;if($LASTEXITCODE -ne 0){throw "FFmpeg skončil s kódom $LASTEXITCODE"}}
function Build-ScaleArg($s){if([string]::IsNullOrWhiteSpace($s)){""}else{"-vf `"scale=$s`""}}
function Build-SubtitleArgs([string]$M,[string]$P,[switch]$IsMKV){if([string]::IsNullOrWhiteSpace($P)-or -not(Test-Path $P)){" "}elseif($M -eq "hard"){"-vf `"subtitles=$(($P -replace '\\','/'))`""}elseif($IsMKV){"-i `"$P`" -c:s copy -map 0 -map 1:s? "}else{"-i `"$P`" -c:s mov_text -map 0 -map 1:s? "}}
function Build-WatermarkArgs([string]$O,[string]$Pos="10:10"){if([string]::IsNullOrWhiteSpace($O)-or -not(Test-Path $O)){" "}else{"-i `"$O`" -filter_complex `"overlay=$Pos`""}}
function Build-EffectsArgs([string[]]$E){if(-not $E -or $E.Count -eq 0){" "}else{$vf=@();foreach($x in $E){switch -Regex($x){"^denoise$"{$vf+="hqdn3d"}"^sharpen$"{$vf+="unsharp"}"^grayscale$"{$vf+="format=gray"}"^fps=(\\d+)$"{$vf+=$x}"^speed=([\\d\\.]+)$"{$r=[double]$Matches[1];$vf+="setpts=PTS/$r";$a=$r;$af=@();while($a -gt 2.0){$af+="atempo=2.0";$a=$a/2.0};$af+="atempo=$a";return "-filter_complex `"`"$(($vf -join ','))`",$(($af -join ','))`"`""}}};if($vf.Count -gt 0){"-vf `"$($vf -join ',')`""}else{" "}}}
function Choose-Profile {Write-Host "`nDostupné profily:";for($i=0;$i -lt $Config.profiles.Count;$i++){Write-Host ("  [{0}] {1}" -f $i,$Config.profiles[$i].name)};$idx=Read-Host "Zadaj index profilu";if($idx -as [int] -and $idx -ge 0 -and $idx -lt $Config.profiles.Count){$Config.profiles[$idx]}else{$Config.profiles[0]}}
function Convert-Batch {if(-not (Resolve-FFTools)){return};$p=Choose-Profile;$files=Get-ChildItem $In -File -Include *.mp4,*.mkv,*.avi,*.mov,*.webm -Recurse;if(-not $files){Write-Log "INFO: Žiadne vstupné videá v 'input/'";return};$hard=Read-Host "Titulky: hard/soft/none (default: none)";if([string]::IsNullOrWhiteSpace($hard)){$hard="none"};$sub="";if($hard -ne "none"){$nm=Read-Host "Názov titulkov (prázdne = žiadne)";if(-not [string]::IsNullOrWhiteSpace($nm)){$pp=Join-Path $Subs $nm;if(Test-Path $pp){$sub=$pp}else{Write-Log "WARN: '$pp' neexistuje"}}};$ov="";if((Read-Host "Použiť overlay? y/N") -match '^(y|Y)'){$nm=Read-Host "Názov overlay (png/jpg)";if(-not [string]::IsNullOrWhiteSpace($nm)){$pp=Join-Path $Ovls $nm;if(Test-Path $pp){$ov=$pp}else{Write-Log "WARN: '$pp' neexistuje"}}};$fx=@();$ask=Read-Host "Efekty? (denoise,sharpen,grayscale,fps=30,speed=1.25)";if(-not [string]::IsNullOrWhiteSpace($ask)){$fx=$ask.Split(',').ForEach{$_.Trim()}};foreach($f in $files){try{$base=[IO.Path]::GetFileNameWithoutExtension($f.Name);$ext=$Config.default_format;$out=Join-Path $Out "$base.$ext";$scale=Build-ScaleArg($p.scale);$isMKV=($ext -eq "mkv");$subA= if($hard -eq "none"){" "} else { Build-SubtitleArgs ($(if($hard -eq "hard"){"hard"} else {"soft"})) $sub $isMKV };$wm=Build-WatermarkArgs $ov;$fxA=Build-EffectsArgs $fx;$maps= if($subA -like "*-map*"){" "} else { "-map 0:v:0? -map 0:a:0?" };$v=$p.vcodec;$preset=$p.preset;$crf=$p.crf;$a=$p.acodec;$ab=$p.ab;$hw=Read-Host "HW encodér (napr. h264_nvenc) alebo Enter";if(-not [string]::IsNullOrWhiteSpace($hw)){$v=$hw};$args=("-y","-i `"$($f.FullName)`"",$subA,$wm,$fxA,$scale,$maps,"-c:v $v -preset $preset -crf $crf","-c:a $a -b:a $ab","`"$out`"") -join " ";Run-FF $args;Write-Log "OK: $($f.Name) -> $(Split-Path $out -Leaf)"}catch{Write-Log "ERROR: $($f.Name) zlyhalo: $($_.Exception.Message)"}};Write-Log "Dávka dokončená."}
function Main-Menu {Write-Host "";Write-Host "Perfect Portable Converter";Write-Host "==========================";Write-Host "1) Dávková konverzia";Write-Host "2) Koniec";$o=Read-Host "Voľba";switch($o){"1"{Convert-Batch};default{return $false}};return $true}
Write-Log "PPC spustený.";while(Main-Menu){};Write-Log "Koniec."
