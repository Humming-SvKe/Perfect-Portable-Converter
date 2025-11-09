<# Perfect Portable Converter - Enhanced GUI
   Full-featured Windows Forms GUI with tabbed interface
   Features: Batch conversion, MKV tools, watermarks, subtitles, video tools
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Relaunch in STA if needed
try {
  if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile','-ExecutionPolicy','Bypass','-STA','-File', $PSCommandPath) -WindowStyle Normal
    return
  }
} catch {}

# Paths
$Root  = Split-Path -Parent $PSCommandPath
$Bins  = Join-Path $Root 'binaries'
$Logs  = Join-Path $Root 'logs'
$Temp  = Join-Path $Root 'temp'
$In    = Join-Path $Root 'input'
$Out   = Join-Path $Root 'output'
$Subs  = Join-Path $Root 'subtitles'
$Ovls  = Join-Path $Root 'overlays'
$Thumb = Join-Path $Root 'thumbnails'
$Cfg   = Join-Path $Root 'config\defaults.json'
$CoreModule = Join-Path $Root 'PPC-Core.ps1'
$ThemeModule = Join-Path $Root 'PPC-Themes.ps1'

$null = New-Item -ItemType Directory -Force -Path $Bins,$Logs,$Temp,$In,$Out,$Subs,$Ovls,$Thumb | Out-Null
$LogFile = Join-Path $Logs 'ppc-gui.log'
$FFLog  = Join-Path $Logs 'ffmpeg.log'

function Write-Log([string]$m){
  $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); "$ts | $m" | Out-File -Append -Encoding UTF8 $LogFile
}

# TLS + download helpers
function Ensure-Tls12 { try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {} }
function Download-File([string]$Url,[string]$Dst){ Ensure-Tls12; Write-Log ("Downloading: " + $Url); Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Dst }
function Expand-Zip([string]$Zip,[string]$Dest){
  try { Expand-Archive -Path $Zip -DestinationPath $Dest -Force }
  catch { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory($Zip,$Dest) }
}

# Config
$Config = @{
  default_format = 'mp4'
  hardware_acceleration = @{ enabled = $true; prefer = 'auto' }
  profiles = @(
    @{ name='Fast 1080p H264';  vcodec='libx264'; preset='veryfast'; crf=23; acodec='aac'; ab='160k'; scale=''; format='mp4' }
  )
  filters = @{}
}

if (Test-Path $Cfg) { 
  try { 
    $loadedConfig = Get-Content $Cfg -Raw | ConvertFrom-Json
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
    Write-Log 'WARN: Config load failed, using defaults.' 
  } 
}

# Load core module
$script:CoreModuleLoaded = $false
if (Test-Path $CoreModule) {
  try {
    . $CoreModule
    $script:CoreModuleLoaded = $true
  } catch {
    Write-Log "WARN: Core module load failed: $($_.Exception.Message)"
  }
}

$script:ThemeModuleLoaded = $false
if (Test-Path $ThemeModule) {
  try {
    . $ThemeModule
    $script:ThemeModuleLoaded = $true
  } catch {
    Write-Log "WARN: Theme module load failed: $($_.Exception.Message)"
  }
}

$global:FFMPEG=''; $global:FFPROBE=''
function Install-FFTools {
  try {
    $zip = Join-Path $Temp 'ffmpeg.zip'; $dst = Join-Path $Temp 'ffmpeg'
    if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    $url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
    Download-File -Url $url -Dst $zip
    Expand-Zip -Zip $zip -Dest $dst
    $ff = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    $fp = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffprobe.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ff) { Copy-Item -LiteralPath $ff.FullName -Destination (Join-Path $Bins 'ffmpeg.exe') -Force }
    if ($fp) { Copy-Item -LiteralPath $fp.FullName -Destination (Join-Path $Bins 'ffprobe.exe') -Force }
    Remove-Item $zip -Force -ErrorAction SilentlyContinue; Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
    return $true
  } catch { Write-Log ('ERROR: FFmpeg install failed: ' + $_.Exception.Message); return $false }
}

function Resolve-FFTools {
  $ff = Join-Path $Bins 'ffmpeg.exe'; $fp = Join-Path $Bins 'ffprobe.exe'
  if (Test-Path $ff) { $global:FFMPEG = $ff }
  if (Test-Path $fp) { $global:FFPROBE = $fp }
  if (-not (Test-Path $ff)) {
    Write-Log 'WARN: ffmpeg.exe not found, trying auto-download...'
    if (Install-FFTools) { if (Test-Path $ff) { $global:FFMPEG=$ff }; if (Test-Path $fp) { $global:FFPROBE=$fp } }
  }
  if (-not (Test-Path $ff)) { Write-Log "ERROR: FFmpeg missing."; return $false }
  return $true
}

function Get-HWAccelArgs([hashtable]$profile) {
  $args = @()
  if (-not $Config.hardware_acceleration.enabled) { return $args }
  if (-not $profile.ContainsKey('hwaccel')) { return $args }
  
  $hwType = $profile.hwaccel
  switch ($hwType) {
    'nvenc' { if ($profile.vcodec -match 'nvenc') { $args += @('-hwaccel', 'cuda', '-hwaccel_output_format', 'cuda') } }
    'qsv' { if ($profile.vcodec -match 'qsv') { $args += @('-hwaccel', 'qsv', '-hwaccel_output_format', 'qsv') } }
    'amf' { if ($profile.vcodec -match 'amf') { $args += @('-hwaccel', 'd3d11va') } }
  }
  return $args
}

function Convert-One([string]$src,[string]$dst,$p, [System.Windows.Forms.ProgressBar]$progressBar=$null, [System.Windows.Forms.Label]$statusLabel=$null){
  if (-not (Resolve-FFTools)) { return $false }
  
  $outDir = Split-Path -Parent $dst
  if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
  
  # Hardware acceleration
  $hwArgs = Get-HWAccelArgs -profile $p
  
  # Video args
  $vArgs=@()
  if ($p.ContainsKey('vcodec') -and $p.vcodec -ne 'none') { 
    $vArgs += @('-c:v', $p.vcodec)
    if ($p.ContainsKey('preset')) { $vArgs += @('-preset', $p.preset) }
    if ($p.ContainsKey('crf')) { $vArgs += @('-crf', [string]$p.crf) }
    if ($p.ContainsKey('vb')) { $vArgs += @('-b:v', $p.vb) }
    if ($p.ContainsKey('profile')) { $vArgs += @('-profile:v', $p.profile) }
    if ($p.ContainsKey('level')) { $vArgs += @('-level', $p.level) }
    if ($p.ContainsKey('quality')) { $vArgs += @('-quality', $p.quality) }
  } elseif ($p.vcodec -eq 'none') {
    $vArgs += @('-vn')
  }
  
  # Audio args
  $aArgs=@()
  if ($p.ContainsKey('acodec') -and $p.acodec -ne 'none') {
    $aArgs += @('-c:a', $p.acodec)
    if ($p.ContainsKey('ab')) { $aArgs += @('-b:a', $p.ab) }
  } elseif ($p.acodec -eq 'none') {
    $aArgs += @('-an')
  }
  
  # Filters
  $filters=@()
  if ($p.ContainsKey('scale') -and $p.scale) { $filters += "scale=$($p.scale)" }
  if ($p.ContainsKey('effects')) { foreach ($ef in $p.effects) { $filters += $ef } }
  if ($p.ContainsKey('deinterlace') -and $p.deinterlace -and $Config.filters.ContainsKey('deinterlace')) {
    $filters += $Config.filters.deinterlace
  }
  if ($p.ContainsKey('denoise') -and $p.denoise -and $Config.filters.ContainsKey('denoise')) {
    $filters += $Config.filters.denoise
  }
  
  $vfArgs=@()
  if ($filters.Count -gt 0) { $vfArgs = @('-vf', ([string]::Join(',', $filters))) }
  
  # Max duration
  $maxDurArgs = @()
  if ($p.ContainsKey('maxdur') -and $p.maxdur -gt 0) {
    $maxDurArgs = @('-t', [string]$p.maxdur)
  }
  
  $args = @('-y','-hide_banner','-loglevel','warning','-stats') + $hwArgs + @('-i', $src) + $maxDurArgs + $vfArgs + $vArgs + $aArgs + @($dst)
  Write-Log ('ffmpeg ' + ($args -join ' '))
  
  if ($statusLabel) {
    $statusLabel.Text = "Encoding: $(Split-Path -Leaf $src)"
    $statusLabel.Refresh()
  }
  
  & $global:FFMPEG @args 2>&1 | Tee-Object -FilePath $FFLog -Append | Out-Null

  if ($LASTEXITCODE -ne 0) { Write-Log ('FFmpeg failed with code ' + $LASTEXITCODE); return $false }
  if (-not (Test-Path -LiteralPath $dst)) { Write-Log ('FAIL: Output not created: ' + $dst); return $false }
  $fi = Get-Item -LiteralPath $dst -ErrorAction SilentlyContinue
  if ($null -eq $fi -or [int64]$fi.Length -le 0) { Write-Log ('FAIL: Output empty: ' + $dst); return $false }
  return $true
}

# GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Modern font for better appearance
$modernFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$modernFontBold = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

# Function to style buttons with modern flat appearance
function Style-ModernButton([System.Windows.Forms.Button]$btn) {
  $btn.FlatStyle = 'Flat'
  $btn.FlatAppearance.BorderSize = 1
  $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
  $btn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
  $btn.ForeColor = [System.Drawing.Color]::White
  $btn.Font = $modernFontBold
  $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
  $btn.Height = 28
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Perfect Portable Converter v2.2 - Enhanced'
$form.Width = 950
$form.Height = 700
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(900, 650)
$form.Font = $modernFont
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Create TabControl
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = 'Fill'

# === TAB 1: Batch Convert ===
$tabBatch = New-Object System.Windows.Forms.TabPage
$tabBatch.Text = 'Batch Convert'
$tabControl.Controls.Add($tabBatch)

$lblBatchFiles = New-Object System.Windows.Forms.Label
$lblBatchFiles.Text = 'Files to Convert:'
$lblBatchFiles.Left = 10; $lblBatchFiles.Top = 10; $lblBatchFiles.Width = 100

$lstBatchFiles = New-Object System.Windows.Forms.ListBox
$lstBatchFiles.Left = 10; $lstBatchFiles.Top = 35; $lstBatchFiles.Width = 550; $lstBatchFiles.Height = 250
$lstBatchFiles.SelectionMode = 'MultiExtended'

$btnBatchAdd = New-Object System.Windows.Forms.Button
$btnBatchAdd.Text = 'Add Files'
$btnBatchAdd.Left = 570; $btnBatchAdd.Top = 35; $btnBatchAdd.Width = 100

$btnBatchRemove = New-Object System.Windows.Forms.Button
$btnBatchRemove.Text = 'Remove'
$btnBatchRemove.Left = 570; $btnBatchRemove.Top = 70; $btnBatchRemove.Width = 100

$btnBatchClear = New-Object System.Windows.Forms.Button
$btnBatchClear.Text = 'Clear All'
$btnBatchClear.Left = 570; $btnBatchClear.Top = 105; $btnBatchClear.Width = 100

$lblBatchProfile = New-Object System.Windows.Forms.Label
$lblBatchProfile.Text = 'Profile:'
$lblBatchProfile.Left = 10; $lblBatchProfile.Top = 295; $lblBatchProfile.Width = 60

$cmbBatchProfile = New-Object System.Windows.Forms.ComboBox
$cmbBatchProfile.Left = 75; $cmbBatchProfile.Top = 292; $cmbBatchProfile.Width = 300; $cmbBatchProfile.DropDownStyle = 'DropDownList'

$lblBatchOutput = New-Object System.Windows.Forms.Label
$lblBatchOutput.Text = "Output: $Out"
$lblBatchOutput.Left = 10; $lblBatchOutput.Top = 325; $lblBatchOutput.Width = 550

$btnBatchOutputChange = New-Object System.Windows.Forms.Button
$btnBatchOutputChange.Text = 'Change Output...'
$btnBatchOutputChange.Left = 570; $btnBatchOutputChange.Top = 320; $btnBatchOutputChange.Width = 120

$btnBatchStart = New-Object System.Windows.Forms.Button
$btnBatchStart.Text = 'Start Conversion'
$btnBatchStart.Left = 10; $btnBatchStart.Top = 360; $btnBatchStart.Width = 150; $btnBatchStart.Height = 35
$btnBatchStart.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$btnBatchStart.BackColor = [System.Drawing.Color]::LightGreen

$pgBatch = New-Object System.Windows.Forms.ProgressBar
$pgBatch.Left = 10; $pgBatch.Top = 405; $pgBatch.Width = 680; $pgBatch.Height = 25

$txtBatchLog = New-Object System.Windows.Forms.TextBox
$txtBatchLog.Left = 10; $txtBatchLog.Top = 440; $txtBatchLog.Width = 680; $txtBatchLog.Height = 120
$txtBatchLog.Multiline = $true; $txtBatchLog.ScrollBars = 'Vertical'; $txtBatchLog.ReadOnly = $true
$txtBatchLog.Font = New-Object System.Drawing.Font("Consolas", 9)

# Style batch tab buttons
Style-ModernButton $btnBatchAdd
Style-ModernButton $btnBatchRemove
Style-ModernButton $btnBatchClear
Style-ModernButton $btnBatchOutputChange
$btnBatchStart.FlatStyle = 'Flat'
$btnBatchStart.FlatAppearance.BorderSize = 1
$btnBatchStart.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnBatchStart.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnBatchStart.ForeColor = [System.Drawing.Color]::White
$btnBatchStart.Cursor = [System.Windows.Forms.Cursors]::Hand

$tabBatch.Controls.AddRange(@($lblBatchFiles, $lstBatchFiles, $btnBatchAdd, $btnBatchRemove, $btnBatchClear,
  $lblBatchProfile, $cmbBatchProfile, $lblBatchOutput, $btnBatchOutputChange, $btnBatchStart, $pgBatch, $txtBatchLog))

# === TAB 2: MKV Tools ===
$tabMKV = New-Object System.Windows.Forms.TabPage
$tabMKV.Text = 'MKV Tools'
$tabControl.Controls.Add($tabMKV)

$grpMKVExtract = New-Object System.Windows.Forms.GroupBox
$grpMKVExtract.Text = 'Extract Tracks'
$grpMKVExtract.Left = 10; $grpMKVExtract.Top = 10; $grpMKVExtract.Width = 400; $grpMKVExtract.Height = 280

$lblMKVInput = New-Object System.Windows.Forms.Label
$lblMKVInput.Text = 'Input MKV File:'
$lblMKVInput.Left = 10; $lblMKVInput.Top = 25; $lblMKVInput.Width = 100

$txtMKVInput = New-Object System.Windows.Forms.TextBox
$txtMKVInput.Left = 10; $txtMKVInput.Top = 50; $txtMKVInput.Width = 300; $txtMKVInput.ReadOnly = $true

$btnMKVBrowse = New-Object System.Windows.Forms.Button
$btnMKVBrowse.Text = 'Browse...'
$btnMKVBrowse.Left = 320; $btnMKVBrowse.Top = 48; $btnMKVBrowse.Width = 70

$chkExtractVideo = New-Object System.Windows.Forms.CheckBox
$chkExtractVideo.Text = 'Extract Video'
$chkExtractVideo.Left = 10; $chkExtractVideo.Top = 85; $chkExtractVideo.Width = 150

$chkExtractAudio = New-Object System.Windows.Forms.CheckBox
$chkExtractAudio.Text = 'Extract Audio'
$chkExtractAudio.Left = 10; $chkExtractAudio.Top = 110; $chkExtractAudio.Width = 150
$chkExtractAudio.Checked = $true

$chkExtractSubs = New-Object System.Windows.Forms.CheckBox
$chkExtractSubs.Text = 'Extract Subtitles'
$chkExtractSubs.Left = 10; $chkExtractSubs.Top = 135; $chkExtractSubs.Width = 150
$chkExtractSubs.Checked = $true

$btnMKVExtract = New-Object System.Windows.Forms.Button
$btnMKVExtract.Text = 'Extract Tracks'
$btnMKVExtract.Left = 10; $btnMKVExtract.Top = 170; $btnMKVExtract.Width = 120; $btnMKVExtract.Height = 30

$lblMKVStatus = New-Object System.Windows.Forms.Label
$lblMKVStatus.Text = ''
$lblMKVStatus.Left = 10; $lblMKVStatus.Top = 210; $lblMKVStatus.Width = 380; $lblMKVStatus.Height = 60
$lblMKVStatus.Font = New-Object System.Drawing.Font("Arial", 9)

# Style MKV tab buttons
Style-ModernButton $btnMKVBrowse
Style-ModernButton $btnMKVExtract

$grpMKVExtract.Controls.AddRange(@($lblMKVInput, $txtMKVInput, $btnMKVBrowse, $chkExtractVideo, $chkExtractAudio, $chkExtractSubs, $btnMKVExtract, $lblMKVStatus))
$tabMKV.Controls.Add($grpMKVExtract)

# === TAB 3: Watermark ===
$tabWatermark = New-Object System.Windows.Forms.TabPage
$tabWatermark.Text = 'Watermark'
$tabControl.Controls.Add($tabWatermark)

$grpWMType = New-Object System.Windows.Forms.GroupBox
$grpWMType.Text = 'Watermark Type'
$grpWMType.Left = 10; $grpWMType.Top = 10; $grpWMType.Width = 400; $grpWMType.Height = 450

$rbWMImage = New-Object System.Windows.Forms.RadioButton
$rbWMImage.Text = 'Image Watermark'
$rbWMImage.Left = 10; $rbWMImage.Top = 25; $rbWMImage.Width = 150
$rbWMImage.Checked = $true

$rbWMText = New-Object System.Windows.Forms.RadioButton
$rbWMText.Text = 'Text Watermark'
$rbWMText.Left = 170; $rbWMText.Top = 25; $rbWMText.Width = 150

$lblWMVideo = New-Object System.Windows.Forms.Label
$lblWMVideo.Text = 'Input Video:'
$lblWMVideo.Left = 10; $lblWMVideo.Top = 60; $lblWMVideo.Width = 100

$txtWMVideo = New-Object System.Windows.Forms.TextBox
$txtWMVideo.Left = 10; $txtWMVideo.Top = 85; $txtWMVideo.Width = 300; $txtWMVideo.ReadOnly = $true

$btnWMVideoBrowse = New-Object System.Windows.Forms.Button
$btnWMVideoBrowse.Text = 'Browse...'
$btnWMVideoBrowse.Left = 320; $btnWMVideoBrowse.Top = 83; $btnWMVideoBrowse.Width = 70

# Image watermark controls
$lblWMImage = New-Object System.Windows.Forms.Label
$lblWMImage.Text = 'Watermark Image:'
$lblWMImage.Left = 10; $lblWMImage.Top = 120; $lblWMImage.Width = 120

$txtWMImage = New-Object System.Windows.Forms.TextBox
$txtWMImage.Left = 10; $txtWMImage.Top = 145; $txtWMImage.Width = 300; $txtWMImage.ReadOnly = $true

$btnWMImageBrowse = New-Object System.Windows.Forms.Button
$btnWMImageBrowse.Text = 'Browse...'
$btnWMImageBrowse.Left = 320; $btnWMImageBrowse.Top = 143; $btnWMImageBrowse.Width = 70

# Text watermark controls
$lblWMText = New-Object System.Windows.Forms.Label
$lblWMText.Text = 'Watermark Text:'
$lblWMText.Left = 10; $lblWMText.Top = 180; $lblWMText.Width = 120
$lblWMText.Visible = $false

$txtWMText = New-Object System.Windows.Forms.TextBox
$txtWMText.Left = 10; $txtWMText.Top = 205; $txtWMText.Width = 380
$txtWMText.Visible = $false

$lblWMFontSize = New-Object System.Windows.Forms.Label
$lblWMFontSize.Text = 'Font Size:'
$lblWMFontSize.Left = 10; $lblWMFontSize.Top = 235; $lblWMFontSize.Width = 80
$lblWMFontSize.Visible = $false

$numWMFontSize = New-Object System.Windows.Forms.NumericUpDown
$numWMFontSize.Left = 95; $numWMFontSize.Top = 233; $numWMFontSize.Width = 70
$numWMFontSize.Minimum = 10; $numWMFontSize.Maximum = 200; $numWMFontSize.Value = 24
$numWMFontSize.Visible = $false

$lblWMColor = New-Object System.Windows.Forms.Label
$lblWMColor.Text = 'Color:'
$lblWMColor.Left = 180; $lblWMColor.Top = 235; $lblWMColor.Width = 50
$lblWMColor.Visible = $false

$cmbWMColor = New-Object System.Windows.Forms.ComboBox
$cmbWMColor.Left = 235; $cmbWMColor.Top = 233; $cmbWMColor.Width = 100
$cmbWMColor.Items.AddRange(@('white', 'black', 'red', 'green', 'blue', 'yellow'))
$cmbWMColor.SelectedIndex = 0
$cmbWMColor.Visible = $false

# Common controls
$lblWMPosition = New-Object System.Windows.Forms.Label
$lblWMPosition.Text = 'Position:'
$lblWMPosition.Left = 10; $lblWMPosition.Top = 270; $lblWMPosition.Width = 80

$cmbWMPosition = New-Object System.Windows.Forms.ComboBox
$cmbWMPosition.Left = 95; $cmbWMPosition.Top = 268; $cmbWMPosition.Width = 150
$cmbWMPosition.Items.AddRange(@('topleft', 'topright', 'bottomleft', 'bottomright', 'center'))
$cmbWMPosition.SelectedIndex = 3

$lblWMOpacity = New-Object System.Windows.Forms.Label
$lblWMOpacity.Text = 'Opacity:'
$lblWMOpacity.Left = 10; $lblWMOpacity.Top = 305; $lblWMOpacity.Width = 80

$numWMOpacity = New-Object System.Windows.Forms.NumericUpDown
$numWMOpacity.Left = 95; $numWMOpacity.Top = 303; $numWMOpacity.Width = 70
$numWMOpacity.Minimum = 0; $numWMOpacity.Maximum = 100; $numWMOpacity.Value = 70
$numWMOpacity.DecimalPlaces = 0

$btnWMApply = New-Object System.Windows.Forms.Button
$btnWMApply.Text = 'Apply Watermark'
$btnWMApply.Left = 10; $btnWMApply.Top = 350; $btnWMApply.Width = 130; $btnWMApply.Height = 35

$lblWMStatus = New-Object System.Windows.Forms.Label
$lblWMStatus.Text = ''
$lblWMStatus.Left = 10; $lblWMStatus.Top = 395; $lblWMStatus.Width = 380; $lblWMStatus.Height = 40

# Style Watermark tab buttons
Style-ModernButton $btnWMVideoBrowse
Style-ModernButton $btnWMImageBrowse
Style-ModernButton $btnWMApply

$grpWMType.Controls.AddRange(@($rbWMImage, $rbWMText, $lblWMVideo, $txtWMVideo, $btnWMVideoBrowse,
  $lblWMImage, $txtWMImage, $btnWMImageBrowse, $lblWMText, $txtWMText, $lblWMFontSize, $numWMFontSize,
  $lblWMColor, $cmbWMColor, $lblWMPosition, $cmbWMPosition, $lblWMOpacity, $numWMOpacity, $btnWMApply, $lblWMStatus))
$tabWatermark.Controls.Add($grpWMType)

# === TAB 4: Subtitles ===
$tabSubtitle = New-Object System.Windows.Forms.TabPage
$tabSubtitle.Text = 'Subtitles'
$tabControl.Controls.Add($tabSubtitle)

$grpSubBurn = New-Object System.Windows.Forms.GroupBox
$grpSubBurn.Text = 'Burn Subtitles'
$grpSubBurn.Left = 10; $grpSubBurn.Top = 10; $grpSubBurn.Width = 400; $grpSubBurn.Height = 250

$lblSubVideo = New-Object System.Windows.Forms.Label
$lblSubVideo.Text = 'Input Video:'
$lblSubVideo.Left = 10; $lblSubVideo.Top = 25; $lblSubVideo.Width = 100

$txtSubVideo = New-Object System.Windows.Forms.TextBox
$txtSubVideo.Left = 10; $txtSubVideo.Top = 50; $txtSubVideo.Width = 300; $txtSubVideo.ReadOnly = $true

$btnSubVideoBrowse = New-Object System.Windows.Forms.Button
$btnSubVideoBrowse.Text = 'Browse...'
$btnSubVideoBrowse.Left = 320; $btnSubVideoBrowse.Top = 48; $btnSubVideoBrowse.Width = 70

$lblSubFile = New-Object System.Windows.Forms.Label
$lblSubFile.Text = 'Subtitle File:'
$lblSubFile.Left = 10; $lblSubFile.Top = 85; $lblSubFile.Width = 100

$txtSubFile = New-Object System.Windows.Forms.TextBox
$txtSubFile.Left = 10; $txtSubFile.Top = 110; $txtSubFile.Width = 300; $txtSubFile.ReadOnly = $true

$btnSubFileBrowse = New-Object System.Windows.Forms.Button
$btnSubFileBrowse.Text = 'Browse...'
$btnSubFileBrowse.Left = 320; $btnSubFileBrowse.Top = 108; $btnSubFileBrowse.Width = 70

$btnSubBurn = New-Object System.Windows.Forms.Button
$btnSubBurn.Text = 'Burn Subtitles'
$btnSubBurn.Left = 10; $btnSubBurn.Top = 150; $btnSubBurn.Width = 120; $btnSubBurn.Height = 30

$lblSubStatus = New-Object System.Windows.Forms.Label
$lblSubStatus.Text = ''
$lblSubStatus.Left = 10; $lblSubStatus.Top = 190; $lblSubStatus.Width = 380; $lblSubStatus.Height = 50

# Style Subtitle tab buttons
Style-ModernButton $btnSubVideoBrowse
Style-ModernButton $btnSubFileBrowse
Style-ModernButton $btnSubBurn

$grpSubBurn.Controls.AddRange(@($lblSubVideo, $txtSubVideo, $btnSubVideoBrowse, $lblSubFile, $txtSubFile, $btnSubFileBrowse, $btnSubBurn, $lblSubStatus))
$tabSubtitle.Controls.Add($grpSubBurn)

# === TAB 5: Video Tools ===
$tabVideoTools = New-Object System.Windows.Forms.TabPage
$tabVideoTools.Text = 'Video Tools'
$tabControl.Controls.Add($tabVideoTools)

$grpTrim = New-Object System.Windows.Forms.GroupBox
$grpTrim.Text = 'Trim/Cut Video'
$grpTrim.Left = 10; $grpTrim.Top = 10; $grpTrim.Width = 400; $grpTrim.Height = 200

$lblTrimVideo = New-Object System.Windows.Forms.Label
$lblTrimVideo.Text = 'Input Video:'
$lblTrimVideo.Left = 10; $lblTrimVideo.Top = 25; $lblTrimVideo.Width = 100

$txtTrimVideo = New-Object System.Windows.Forms.TextBox
$txtTrimVideo.Left = 10; $txtTrimVideo.Top = 50; $txtTrimVideo.Width = 300; $txtTrimVideo.ReadOnly = $true

$btnTrimVideoBrowse = New-Object System.Windows.Forms.Button
$btnTrimVideoBrowse.Text = 'Browse...'
$btnTrimVideoBrowse.Left = 320; $btnTrimVideoBrowse.Top = 48; $btnTrimVideoBrowse.Width = 70

$lblTrimStart = New-Object System.Windows.Forms.Label
$lblTrimStart.Text = 'Start (sec):'
$lblTrimStart.Left = 10; $lblTrimStart.Top = 85; $lblTrimStart.Width = 80

$numTrimStart = New-Object System.Windows.Forms.NumericUpDown
$numTrimStart.Left = 95; $numTrimStart.Top = 83; $numTrimStart.Width = 80
$numTrimStart.Minimum = 0; $numTrimStart.Maximum = 999999; $numTrimStart.DecimalPlaces = 1

$lblTrimDuration = New-Object System.Windows.Forms.Label
$lblTrimDuration.Text = 'Duration (0=all):'
$lblTrimDuration.Left = 190; $lblTrimDuration.Top = 85; $lblTrimDuration.Width = 100

$numTrimDuration = New-Object System.Windows.Forms.NumericUpDown
$numTrimDuration.Left = 295; $numTrimDuration.Top = 83; $numTrimDuration.Width = 80
$numTrimDuration.Minimum = 0; $numTrimDuration.Maximum = 999999; $numTrimDuration.DecimalPlaces = 1

$btnTrimExecute = New-Object System.Windows.Forms.Button
$btnTrimExecute.Text = 'Trim Video'
$btnTrimExecute.Left = 10; $btnTrimExecute.Top = 120; $btnTrimExecute.Width = 100; $btnTrimExecute.Height = 30

$lblTrimStatus = New-Object System.Windows.Forms.Label
$lblTrimStatus.Text = ''
$lblTrimStatus.Left = 10; $lblTrimStatus.Top = 160; $lblTrimStatus.Width = 380; $lblTrimStatus.Height = 30

# Style Video Tools tab buttons
Style-ModernButton $btnTrimVideoBrowse
Style-ModernButton $btnTrimExecute

$grpTrim.Controls.AddRange(@($lblTrimVideo, $txtTrimVideo, $btnTrimVideoBrowse, $lblTrimStart, $numTrimStart, $lblTrimDuration, $numTrimDuration, $btnTrimExecute, $lblTrimStatus))
$tabVideoTools.Controls.Add($grpTrim)

$grpThumb = New-Object System.Windows.Forms.GroupBox
$grpThumb.Text = 'Generate Thumbnail'
$grpThumb.Left = 10; $grpThumb.Top = 220; $grpThumb.Width = 400; $grpThumb.Height = 150

$lblThumbVideo = New-Object System.Windows.Forms.Label
$lblThumbVideo.Text = 'Input Video:'
$lblThumbVideo.Left = 10; $lblThumbVideo.Top = 25; $lblThumbVideo.Width = 100

$txtThumbVideo = New-Object System.Windows.Forms.TextBox
$txtThumbVideo.Left = 10; $txtThumbVideo.Top = 50; $txtThumbVideo.Width = 300; $txtThumbVideo.ReadOnly = $true

$btnThumbVideoBrowse = New-Object System.Windows.Forms.Button
$btnThumbVideoBrowse.Text = 'Browse...'
$btnThumbVideoBrowse.Left = 320; $btnThumbVideoBrowse.Top = 48; $btnThumbVideoBrowse.Width = 70

$lblThumbTime = New-Object System.Windows.Forms.Label
$lblThumbTime.Text = 'Time (sec):'
$lblThumbTime.Left = 10; $lblThumbTime.Top = 85; $lblThumbTime.Width = 80

$numThumbTime = New-Object System.Windows.Forms.NumericUpDown
$numThumbTime.Left = 95; $numThumbTime.Top = 83; $numThumbTime.Width = 80
$numThumbTime.Minimum = 0; $numThumbTime.Maximum = 999999; $numThumbTime.Value = 5; $numThumbTime.DecimalPlaces = 1

$btnThumbGenerate = New-Object System.Windows.Forms.Button
$btnThumbGenerate.Text = 'Generate'
$btnThumbGenerate.Left = 190; $btnThumbGenerate.Top = 81; $btnThumbGenerate.Width = 100; $btnThumbGenerate.Height = 25

$lblThumbStatus = New-Object System.Windows.Forms.Label
$lblThumbStatus.Text = ''
$lblThumbStatus.Left = 10; $lblThumbStatus.Top = 115; $lblThumbStatus.Width = 380; $lblThumbStatus.Height = 30

Style-ModernButton $btnThumbVideoBrowse
Style-ModernButton $btnThumbGenerate

$grpThumb.Controls.AddRange(@($lblThumbVideo, $txtThumbVideo, $btnThumbVideoBrowse, $lblThumbTime, $numThumbTime, $btnThumbGenerate, $lblThumbStatus))
$tabVideoTools.Controls.Add($grpThumb)

# === TAB 6: Info & Settings ===
$tabInfo = New-Object System.Windows.Forms.TabPage
$tabInfo.Text = 'Info & Settings'
$tabControl.Controls.Add($tabInfo)

$txtInfo = New-Object System.Windows.Forms.TextBox
$txtInfo.Left = 10; $txtInfo.Top = 10; $txtInfo.Width = 680; $txtInfo.Height = 450
$txtInfo.Multiline = $true; $txtInfo.ScrollBars = 'Vertical'; $txtInfo.ReadOnly = $true
$txtInfo.Font = New-Object System.Drawing.Font("Consolas", 9)

$btnRefreshInfo = New-Object System.Windows.Forms.Button
$btnRefreshInfo.Text = 'Refresh Hardware Info'
$btnRefreshInfo.Left = 10; $btnRefreshInfo.Top = 470; $btnRefreshInfo.Width = 150

$lblTheme = New-Object System.Windows.Forms.Label
$lblTheme.Text = 'Theme:'
$lblTheme.Left = 180; $lblTheme.Top = 475; $lblTheme.Width = 60

$cmbTheme = New-Object System.Windows.Forms.ComboBox
$cmbTheme.DropDownStyle = 'DropDownList'
$cmbTheme.Left = 240; $cmbTheme.Top = 470; $cmbTheme.Width = 200

# Populate theme selector  
$script:AvailableThemes = @()
if ($script:ThemeModuleLoaded) {
  try {
    $script:AvailableThemes = Get-AvailableThemes
    if ($script:AvailableThemes.Count -gt 0) {
      foreach ($theme in $script:AvailableThemes) {
        [void]$cmbTheme.Items.Add($theme.displayName)
      }
      
      $config = Load-ThemeConfig
      $currentThemeIndex = 0
      for ($i = 0; $i -lt $script:AvailableThemes.Count; $i++) {
        if ($script:AvailableThemes[$i].id -eq $config.current_theme) {
          $currentThemeIndex = $i
          break
        }
      }
      $cmbTheme.SelectedIndex = $currentThemeIndex
    } else {
      [void]$cmbTheme.Items.Add("No themes available")
      $cmbTheme.Enabled = $false
    }
  } catch {
    Write-Log "WARN: Failed to load themes: $($_.Exception.Message)"
    [void]$cmbTheme.Items.Add("Error loading themes")
    $cmbTheme.Enabled = $false
  }
} else {
  [void]$cmbTheme.Items.Add("Theme module not loaded")
  $cmbTheme.Enabled = $false
}

$btnApplyTheme = New-Object System.Windows.Forms.Button
$btnApplyTheme.Text = 'Apply Theme'
$btnApplyTheme.Left = 450; $btnApplyTheme.Top = 470; $btnApplyTheme.Width = 100

# Style Info tab buttons
Style-ModernButton $btnRefreshInfo
Style-ModernButton $btnApplyTheme

$tabInfo.Controls.AddRange(@($txtInfo, $btnRefreshInfo, $lblTheme, $cmbTheme, $btnApplyTheme))

# Add TabControl to form
$form.Controls.Add($tabControl)

# === Event Handlers ===

# Batch tab handlers
$script:BatchOutputDir = $Out

$btnBatchAdd.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Multiselect = $true
  $ofd.Filter = 'Videos|*.mp4;*.mkv;*.avi;*.mov;*.webm;*.flv;*.wmv|All|*.*'
  if ($ofd.ShowDialog() -eq 'OK') {
    $ofd.FileNames | ForEach-Object { [void]$lstBatchFiles.Items.Add($_) }
  }
})

$btnBatchRemove.Add_Click({
  $selected = @($lstBatchFiles.SelectedItems)
  foreach ($item in $selected) {
    $lstBatchFiles.Items.Remove($item)
  }
})

$btnBatchClear.Add_Click({
  $lstBatchFiles.Items.Clear()
})

$btnBatchOutputChange.Add_Click({
  $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
  $fbd.SelectedPath = $script:BatchOutputDir
  if ($fbd.ShowDialog() -eq 'OK') {
    $script:BatchOutputDir = $fbd.SelectedPath
    $lblBatchOutput.Text = "Output: $($script:BatchOutputDir)"
  }
})

$btnBatchStart.Add_Click({
  if ($lstBatchFiles.Items.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show('Add at least one file.', 'Error')
    return
  }
  if ($cmbBatchProfile.SelectedIndex -lt 0) {
    [System.Windows.Forms.MessageBox]::Show('Select a profile.', 'Error')
    return
  }
  
  if (-not $Config.ContainsKey('profiles') -or -not $Config.profiles -or $cmbBatchProfile.SelectedIndex -lt 0) {
    [System.Windows.Forms.MessageBox]::Show('No profile selected or config error.', 'Error', 'OK', 'Error')
    return
  }
  $p = $Config.profiles[$cmbBatchProfile.SelectedIndex]
  
  # Disable UI
  $btnBatchAdd.Enabled = $false
  $btnBatchRemove.Enabled = $false
  $btnBatchClear.Enabled = $false
  $btnBatchStart.Enabled = $false
  $btnBatchOutputChange.Enabled = $false
  $cmbBatchProfile.Enabled = $false
  $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  
  $pgBatch.Value = 0
  $pgBatch.Maximum = $lstBatchFiles.Items.Count
  $txtBatchLog.Clear()
  
  $okCount = 0
  $failCount = 0
  
  try {
    foreach ($item in $lstBatchFiles.Items) {
      try {
        $src = [string]$item
        $ext = if ($p.ContainsKey('format')) { $p.format } else { $Config.default_format }
        $dst = Join-Path $script:BatchOutputDir ("{0}.{1}" -f [IO.Path]::GetFileNameWithoutExtension($src), $ext)
        
        $txtBatchLog.AppendText("Processing: $(Split-Path -Leaf $src)`r`n")
        $txtBatchLog.Refresh()
        
        $ok = Convert-One -src $src -dst $dst -p $p
        
        if ($ok) {
          $okCount++
          $msg = "OK: $(Split-Path -Leaf $src)`r`n"
          $txtBatchLog.AppendText($msg)
        } else {
          $failCount++
          $msg = "FAIL: $(Split-Path -Leaf $src) - check logs`r`n"
          $txtBatchLog.AppendText($msg)
        }
        
        Write-Log $msg
      } catch {
        $failCount++
        $msg = "ERROR: $($_.Exception.Message)`r`n"
        $txtBatchLog.AppendText($msg)
        Write-Log $msg
      }
      
      $pgBatch.Value = $okCount + $failCount
      $txtBatchLog.Refresh()
    }
  } finally {
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
    $btnBatchAdd.Enabled = $true
    $btnBatchRemove.Enabled = $true
    $btnBatchClear.Enabled = $true
    $btnBatchStart.Enabled = $true
    $btnBatchOutputChange.Enabled = $true
    $cmbBatchProfile.Enabled = $true
  }
  
  $txtBatchLog.AppendText("`r`nCompleted! OK: $okCount, FAIL: $failCount`r`n")
  [System.Windows.Forms.MessageBox]::Show("Conversion completed!`r`nSuccess: $okCount`r`nFailed: $failCount", 'Done')
})

# MKV tab handlers
$btnMKVBrowse.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Filter = 'MKV Files|*.mkv|All|*.*'
  if ($ofd.ShowDialog() -eq 'OK') {
    $txtMKVInput.Text = $ofd.FileName
  }
})

$btnMKVExtract.Add_Click({
  if ([string]::IsNullOrWhiteSpace($txtMKVInput.Text) -or -not (Test-Path $txtMKVInput.Text)) {
    [System.Windows.Forms.MessageBox]::Show('Select a valid MKV file.', 'Error')
    return
  }
  
  if (-not $script:CoreModuleLoaded) {
    [System.Windows.Forms.MessageBox]::Show('Core module not available.', 'Error')
    return
  }
  
  $types = @()
  if ($chkExtractVideo.Checked) { $types += 'video' }
  if ($chkExtractAudio.Checked) { $types += 'audio' }
  if ($chkExtractSubs.Checked) { $types += 'subtitles' }
  
  if ($types.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show('Select at least one track type to extract.', 'Error')
    return
  }
  
  $outputDir = Join-Path $Out 'extracted'
  $lblMKVStatus.Text = 'Extracting tracks...'
  $lblMKVStatus.Refresh()
  $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  
  try {
    $result = Extract-MKVTracks -input $txtMKVInput.Text -outputDir $outputDir -trackTypes $types
    if ($result) {
      $lblMKVStatus.Text = "Success! Tracks extracted to:`r`n$outputDir"
      [System.Windows.Forms.MessageBox]::Show("Tracks extracted successfully to:`r`n$outputDir", 'Success')
    } else {
      $lblMKVStatus.Text = 'Extraction failed. Check logs.'
      [System.Windows.Forms.MessageBox]::Show('Extraction failed. Check logs for details.', 'Error')
    }
  } finally {
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
  }
})

# Watermark tab handlers
$rbWMImage.Add_CheckedChanged({
  $isImage = $rbWMImage.Checked
  $lblWMImage.Visible = $isImage
  $txtWMImage.Visible = $isImage
  $btnWMImageBrowse.Visible = $isImage
  $lblWMText.Visible = -not $isImage
  $txtWMText.Visible = -not $isImage
  $lblWMFontSize.Visible = -not $isImage
  $numWMFontSize.Visible = -not $isImage
  $lblWMColor.Visible = -not $isImage
  $cmbWMColor.Visible = -not $isImage
})

$btnWMVideoBrowse.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Filter = 'Videos|*.mp4;*.mkv;*.avi;*.mov|All|*.*'
  if ($ofd.ShowDialog() -eq 'OK') {
    $txtWMVideo.Text = $ofd.FileName
  }
})

$btnWMImageBrowse.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Filter = 'Images|*.png;*.jpg;*.jpeg;*.bmp|All|*.*'
  if ($ofd.ShowDialog() -eq 'OK') {
    $txtWMImage.Text = $ofd.FileName
  }
})

$btnWMApply.Add_Click({
  if ([string]::IsNullOrWhiteSpace($txtWMVideo.Text) -or -not (Test-Path $txtWMVideo.Text)) {
    [System.Windows.Forms.MessageBox]::Show('Select a valid video file.', 'Error')
    return
  }
  
  if (-not $script:CoreModuleLoaded) {
    [System.Windows.Forms.MessageBox]::Show('Core module not available.', 'Error')
    return
  }
  
  $input = $txtWMVideo.Text
  $output = Join-Path $Out "$([IO.Path]::GetFileNameWithoutExtension($input))_watermarked$([IO.Path]::GetExtension($input))"
  $position = $cmbWMPosition.SelectedItem
  $opacity = [double]$numWMOpacity.Value / 100.0
  
  $lblWMStatus.Text = 'Processing...'
  $lblWMStatus.Refresh()
  $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  
  try {
    $result = $false
    if ($rbWMImage.Checked) {
      if ([string]::IsNullOrWhiteSpace($txtWMImage.Text) -or -not (Test-Path $txtWMImage.Text)) {
        [System.Windows.Forms.MessageBox]::Show('Select a valid watermark image.', 'Error')
        return
      }
      $result = Add-ImageWatermark -input $input -output $output -watermarkPath $txtWMImage.Text -position $position -opacity $opacity
    } else {
      if ([string]::IsNullOrWhiteSpace($txtWMText.Text)) {
        [System.Windows.Forms.MessageBox]::Show('Enter watermark text.', 'Error')
        return
      }
      $text = $txtWMText.Text
      $fontSize = [int]$numWMFontSize.Value
      $color = $cmbWMColor.SelectedItem
      $result = Add-TextWatermark -input $input -output $output -text $text -position $position -fontSize $fontSize -color $color -opacity $opacity
    }
    
    if ($result) {
      $lblWMStatus.Text = "Success! Output: $output"
      [System.Windows.Forms.MessageBox]::Show("Watermark applied successfully!`r`nOutput: $output", 'Success')
    } else {
      $lblWMStatus.Text = 'Failed. Check logs.'
      [System.Windows.Forms.MessageBox]::Show('Watermark failed. Check logs.', 'Error')
    }
  } finally {
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
  }
})

# Subtitle tab handlers
$btnSubVideoBrowse.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Filter = 'Videos|*.mp4;*.mkv;*.avi;*.mov|All|*.*'
  if ($ofd.ShowDialog() -eq 'OK') {
    $txtSubVideo.Text = $ofd.FileName
  }
})

$btnSubFileBrowse.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Filter = 'Subtitles|*.srt;*.ass;*.vtt|All|*.*'
  if ($ofd.ShowDialog() -eq 'OK') {
    $txtSubFile.Text = $ofd.FileName
  }
})

$btnSubBurn.Add_Click({
  if ([string]::IsNullOrWhiteSpace($txtSubVideo.Text) -or -not (Test-Path $txtSubVideo.Text)) {
    [System.Windows.Forms.MessageBox]::Show('Select a valid video file.', 'Error')
    return
  }
  if ([string]::IsNullOrWhiteSpace($txtSubFile.Text) -or -not (Test-Path $txtSubFile.Text)) {
    [System.Windows.Forms.MessageBox]::Show('Select a valid subtitle file.', 'Error')
    return
  }
  
  if (-not $script:CoreModuleLoaded) {
    [System.Windows.Forms.MessageBox]::Show('Core module not available.', 'Error')
    return
  }
  
  $input = $txtSubVideo.Text
  $output = Join-Path $Out "$([IO.Path]::GetFileNameWithoutExtension($input))_subbed$([IO.Path]::GetExtension($input))"
  
  $lblSubStatus.Text = 'Burning subtitles...'
  $lblSubStatus.Refresh()
  $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  
  try {
    $result = Burn-Subtitle -input $input -output $output -subtitlePath $txtSubFile.Text
    if ($result) {
      $lblSubStatus.Text = "Success! Output: $output"
      [System.Windows.Forms.MessageBox]::Show("Subtitles burned successfully!`r`nOutput: $output", 'Success')
    } else {
      $lblSubStatus.Text = 'Failed. Check logs.'
      [System.Windows.Forms.MessageBox]::Show('Subtitle burning failed. Check logs.', 'Error')
    }
  } finally {
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
  }
})

# Video Tools tab handlers
$btnTrimVideoBrowse.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Filter = 'Videos|*.mp4;*.mkv;*.avi;*.mov|All|*.*'
  if ($ofd.ShowDialog() -eq 'OK') {
    $txtTrimVideo.Text = $ofd.FileName
  }
})

$btnTrimExecute.Add_Click({
  if ([string]::IsNullOrWhiteSpace($txtTrimVideo.Text) -or -not (Test-Path $txtTrimVideo.Text)) {
    [System.Windows.Forms.MessageBox]::Show('Select a valid video file.', 'Error')
    return
  }
  
  if (-not $script:CoreModuleLoaded) {
    [System.Windows.Forms.MessageBox]::Show('Core module not available.', 'Error')
    return
  }
  
  $input = $txtTrimVideo.Text
  $output = Join-Path $Out "$([IO.Path]::GetFileNameWithoutExtension($input))_trimmed$([IO.Path]::GetExtension($input))"
  $startTime = [double]$numTrimStart.Value
  $duration = [double]$numTrimDuration.Value
  
  $lblTrimStatus.Text = 'Trimming...'
  $lblTrimStatus.Refresh()
  $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  
  try {
    $result = Trim-Video -input $input -output $output -startTime $startTime -duration $duration
    if ($result) {
      $lblTrimStatus.Text = "Success! Output: $output"
      [System.Windows.Forms.MessageBox]::Show("Video trimmed successfully!`r`nOutput: $output", 'Success')
    } else {
      $lblTrimStatus.Text = 'Failed. Check logs.'
      [System.Windows.Forms.MessageBox]::Show('Trimming failed. Check logs.', 'Error')
    }
  } finally {
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
  }
})

$btnThumbVideoBrowse.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Filter = 'Videos|*.mp4;*.mkv;*.avi;*.mov|All|*.*'
  if ($ofd.ShowDialog() -eq 'OK') {
    $txtThumbVideo.Text = $ofd.FileName
  }
})

$btnThumbGenerate.Add_Click({
  if ([string]::IsNullOrWhiteSpace($txtThumbVideo.Text) -or -not (Test-Path $txtThumbVideo.Text)) {
    [System.Windows.Forms.MessageBox]::Show('Select a valid video file.', 'Error')
    return
  }
  
  if (-not $script:CoreModuleLoaded) {
    [System.Windows.Forms.MessageBox]::Show('Core module not available.', 'Error')
    return
  }
  
  $input = $txtThumbVideo.Text
  $output = Join-Path $Thumb "$([IO.Path]::GetFileNameWithoutExtension($input))_thumb.jpg"
  $time = [double]$numThumbTime.Value
  
  $lblThumbStatus.Text = 'Generating...'
  $lblThumbStatus.Refresh()
  $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  
  try {
    $result = Generate-Thumbnail -input $input -output $output -timeSeconds $time
    if ($result) {
      $lblThumbStatus.Text = "Success! Saved to: $output"
      [System.Windows.Forms.MessageBox]::Show("Thumbnail generated!`r`n$output", 'Success')
    } else {
      $lblThumbStatus.Text = 'Failed. Check logs.'
      [System.Windows.Forms.MessageBox]::Show('Generation failed. Check logs.', 'Error')
    }
  } finally {
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
  }
})

# Info tab
function Update-InfoTab {
  $info = @"
Perfect Portable Converter - Enhanced Edition
==============================================

Version: 2.0 Enhanced
Core Module: $(if ($script:CoreModuleLoaded) { 'Loaded' } else { 'Not Loaded' })

Paths:
------
Root: $Root
Binaries: $Bins
Input: $In
Output: $Out
Subtitles: $Subs
Overlays: $Ovls
Thumbnails: $Thumb
Logs: $Logs

FFmpeg Status:
--------------
FFmpeg: $(if (Test-Path (Join-Path $Bins 'ffmpeg.exe')) { 'Installed' } else { 'Not Found' })
FFprobe: $(if (Test-Path (Join-Path $Bins 'ffprobe.exe')) { 'Installed' } else { 'Not Found' })

Hardware Acceleration:
----------------------
"@

  if ($script:CoreModuleLoaded -and (Resolve-FFTools)) {
    $hw = Get-HardwareAcceleration
    $info += "`nNVIDIA NVENC: $(if ($hw.nvidia) { 'Available' } else { 'Not Available' })"
    $info += "`nIntel Quick Sync: $(if ($hw.intel) { 'Available' } else { 'Not Available' })"
    $info += "`nAMD AMF: $(if ($hw.amd) { 'Available' } else { 'Not Available' })"
    
    if ($hw.available.Count -gt 0) {
      $info += "`n`nAvailable HW Acceleration: $($hw.available -join ', ')"
    } else {
      $info += "`n`nNo hardware acceleration detected. Using software encoding."
    }
  } else {
    $info += "`nHardware detection requires FFmpeg and Core module."
  }
  
  if ($Config.ContainsKey('profiles') -and $Config.profiles) {
    $info += "`n`nProfiles Loaded: $($Config.profiles.Count)"
  } else {
    $info += "`n`nProfiles Loaded: 0 (Error loading config)"
  }
  $info += "`n`nFeatures:"
  $info += "`n- Batch video conversion with multiple profiles"
  $info += "`n- MKV track extraction and merging"
  $info += "`n- Image and text watermarks"
  $info += "`n- Subtitle burning and conversion"
  $info += "`n- Video trimming and concatenation"
  $info += "`n- Thumbnail generation"
  $info += "`n- Hardware acceleration (NVIDIA/Intel/AMD)"
  $info += "`n- Multiple output formats (MP4, MKV, WebM, etc.)"
  $info += "`n`nFor more information, see README.md"
  
  $txtInfo.Text = $info
}

$btnRefreshInfo.Add_Click({
  Update-InfoTab
})

$btnApplyTheme.Add_Click({
  if (-not $script:ThemeModuleLoaded) {
    [System.Windows.Forms.MessageBox]::Show('Theme module not loaded.', 'Error', 'OK', 'Error')
    return
  }
  
  $selectedIndex = $cmbTheme.SelectedIndex
  
  if ($selectedIndex -ge 0 -and $selectedIndex -lt $script:AvailableThemes.Count) {
    $selectedTheme = $script:AvailableThemes[$selectedIndex]
    
    try {
      if (Set-Theme -themeName $selectedTheme.id) {
        # Apply theme to form immediately
        Apply-GuiTheme -form $form
        [System.Windows.Forms.MessageBox]::Show("Theme applied: $($selectedTheme.name)`n`nAll colors and styles have been updated!", 'Success', 'OK', 'Information')
      } else {
        [System.Windows.Forms.MessageBox]::Show('Failed to save theme configuration.', 'Error', 'OK', 'Error')
      }
    } catch {
      [System.Windows.Forms.MessageBox]::Show("Error applying theme: $($_.Exception.Message)", 'Error', 'OK', 'Error')
    }
  } else {
    [System.Windows.Forms.MessageBox]::Show('Please select a valid theme.', 'Warning', 'OK', 'Warning')
  }
})

# Form load
$form.Add_Shown({
  # Load profiles
  $cmbBatchProfile.Items.Clear()
  if ($Config.ContainsKey('profiles') -and $Config.profiles) {
    foreach ($p in $Config.profiles) {
      [void]$cmbBatchProfile.Items.Add($p.name)
    }
  }
  if ($cmbBatchProfile.Items.Count -gt 0) {
    $cmbBatchProfile.SelectedIndex = 0
  } else {
    Write-Log "WARN: No profiles loaded from config"
  }
  
  # Check FFmpeg
  if (-not (Resolve-FFTools)) {
    [System.Windows.Forms.MessageBox]::Show("FFmpeg not found in 'binaries' folder.`r`n`r`nThe application will attempt to download it automatically on first use, or you can manually place ffmpeg.exe and ffprobe.exe in the 'binaries' folder.", 'FFmpeg Not Found', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
  }
  
  # Update info tab
  Update-InfoTab
  
  # Apply theme on startup
  if ($script:ThemeModuleLoaded) {
    try {
      Apply-GuiTheme -form $form
      Write-Log "Theme applied to GUI on startup"
    } catch {
      Write-Log "WARN: Failed to apply theme on startup: $($_.Exception.Message)"
    }
  }
})

# Apply theme to form initially (before show)
if ($script:ThemeModuleLoaded) {
  try {
    Apply-GuiTheme -form $form
    Write-Log "Initial theme applied to GUI"
  } catch {
    Write-Log "WARN: Failed to apply initial theme: $($_.Exception.Message)"
  }
}

Write-Log "PPC-GUI Enhanced started"
[void]$form.ShowDialog()
Write-Log "PPC-GUI Enhanced closed"
