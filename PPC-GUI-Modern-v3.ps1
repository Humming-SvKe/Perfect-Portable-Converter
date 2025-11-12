<#
  PPC-GUI-Modern-v3.ps1
  Professional Style - Based on "Professional Subtitle Translator" color scheme
  Light gray background, blue accents, green primary buttons
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Relaunch in STA if needed
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile','-ExecutionPolicy','Bypass','-STA','-File', $PSCommandPath) -WindowStyle Normal
        return
    } catch {}
}

# Paths
$Root  = Split-Path -Parent $PSCommandPath
$Bins  = Join-Path $Root 'binaries'
$Logs  = Join-Path $Root 'logs'
$Temp  = Join-Path $Root 'temp'
$In    = Join-Path $Root 'input'
$Out   = Join-Path $Root 'output'
$Subs  = Join-Path $Root 'subtitles'
$Ovls  = Join-Path $Root 'overlays'
$Cfg   = Join-Path $Root 'config\defaults.json'

$null = New-Item -ItemType Directory -Force -Path $Bins,$Logs,$Temp,$In,$Out,$Subs,$Ovls | Out-Null
$LogFile = Join-Path $Logs 'ppc-gui-modern-v3.log'

function Write-Log([string]$m){
  $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); "$ts | $m" | Out-File -Append -Encoding UTF8 $LogFile
}

# TLS + download helpers
function Ensure-Tls12 { 
  try { 
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 
  } catch {} 
}

function Download-File([string]$Url, [string]$Dst) {
  Ensure-Tls12
  Write-Log "Downloading: $Url"
  Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Dst
}

function Expand-Zip([string]$Zip, [string]$Dest) {
  try { 
    Expand-Archive -Path $Zip -DestinationPath $Dest -Force 
  } catch { 
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($Zip, $Dest) 
  }
}

function Install-FFTools {
  Write-Log "FFmpeg not found. Starting automatic download..."
  
  $urls = @(
    'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip',
    'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
  )
  foreach ($url in $urls) {
    try {
      Write-Log "Attempting download from: $url"
      
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
        Write-Log "FFmpeg installed successfully!"
        return (Join-Path $Bins "ffmpeg.exe")
      }
    } catch {
      Write-Log "Download attempt failed: $($_.Exception.Message)"
    }
  }
  Write-Log "ERROR: All FFmpeg install attempts failed."
  return $null
}

function Install-HandBrake {
  Write-Log "HandBrakeCLI not found. Starting automatic download..."
  
  $urls = @(
    'https://github.com/HandBrake/HandBrake/releases/download/1.10.2/HandBrakeCLI-1.10.2-win-x86_64.zip',
    'https://github.com/HandBrake/HandBrake/releases/download/1.10.1/HandBrakeCLI-1.10.1-win-x86_64.zip'
  )
  foreach ($url in $urls) {
    try {
      Write-Log "Attempting download from: $url"
      
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
        Write-Log "HandBrakeCLI installed successfully!"
        return $true
      }
    } catch {
      Write-Log "Download attempt failed: $($_.Exception.Message)"
    }
  }
  Write-Log "ERROR: All HandBrake install attempts failed."
  return $false
}

# Config
$Config = @{
  default_format = 'mp4';
  profiles = @(
    @{ name='FFmpeg - Fast 1080p H264'; engine='ffmpeg'; format='mp4'; args='-c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 160k' },
    @{ name='FFmpeg - Small 720p H264'; engine='ffmpeg'; format='mp4'; args='-vf scale=1280:-2 -c:v libx264 -preset veryfast -crf 25 -c:a aac -b:a 128k' },
    @{ name='HandBrake - Fast 1080p x264'; engine='handbrake'; format='mp4'; args='-e x264 -q 22 -E av_aac -B 160' },
    @{ name='HandBrake - Small 720p x264'; engine='handbrake'; format='mp4'; args='-e x264 -q 24 -E av_aac -B 128 -w 1280' },
    @{ name='HandBrake - x265 Medium'; engine='handbrake'; format='mp4'; args='-e x265 -q 26 -E av_aac -B 160' }
  )
}
if (Test-Path $Cfg) { try { $Config = Get-Content $Cfg -Raw | ConvertFrom-Json } catch { Write-Log 'WARN: Config load failed.' } }

# WinForms GUI - Professional Subtitle Translator Style
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Color Scheme (Professional Subtitle Translator)
$ColorBackground = [System.Drawing.Color]::FromArgb(240, 240, 240)
$ColorHeaderText = [System.Drawing.Color]::FromArgb(50, 50, 50)
$ColorPrimaryButton = [System.Drawing.Color]::FromArgb(16, 137, 62)    # Green
$ColorSecondaryButton = [System.Drawing.Color]::FromArgb(255, 152, 0) # Orange
$ColorBlueAccent = [System.Drawing.Color]::FromArgb(0, 120, 215)      # Blue
$ColorGrayButton = [System.Drawing.Color]::FromArgb(192, 192, 192)    # Gray
$ColorLogBackground = [System.Drawing.Color]::FromArgb(43, 62, 80)    # Dark blue-gray
$ColorWhite = [System.Drawing.Color]::White

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Professional Portable Converter - Desktop Application'
$form.Width = 1120
$form.Height = 740
$form.StartPosition = 'CenterScreen'
$form.BackColor = $ColorBackground
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

# Title Label
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = 'Professional Portable Converter'
$lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 20, [System.Drawing.FontStyle]::Regular)
$lblTitle.ForeColor = $ColorHeaderText
$lblTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblTitle.Size = New-Object System.Drawing.Size(800, 40)
$form.Controls.Add($lblTitle)

# TabControl - Professional Style
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(5, 70)
$tabControl.Size = New-Object System.Drawing.Size(1090, 570)
$tabControl.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$form.Controls.Add($tabControl)

# ============================================
# TAB 1: CONVERT
# ============================================
$tabConvert = New-Object System.Windows.Forms.TabPage
$tabConvert.Text = 'Convert'
$tabConvert.BackColor = $ColorWhite
$tabControl.Controls.Add($tabConvert)

# GroupBox: Input Files
$grpInput = New-Object System.Windows.Forms.GroupBox
$grpInput.Text = 'Input Files'
$grpInput.Location = New-Object System.Drawing.Point(15, 10)
$grpInput.Size = New-Object System.Drawing.Size(1050, 150)
$grpInput.ForeColor = $ColorHeaderText
$tabConvert.Controls.Add($grpInput)

$lstFiles = New-Object System.Windows.Forms.ListBox
$lstFiles.Location = New-Object System.Drawing.Point(10, 25)
$lstFiles.Size = New-Object System.Drawing.Size(850, 110)
$lstFiles.Font = New-Object System.Drawing.Font('Consolas', 9)
$lstFiles.BackColor = $ColorWhite
$grpInput.Controls.Add($lstFiles)

$btnAddFiles = New-Object System.Windows.Forms.Button
$btnAddFiles.Text = 'Add Files'
$btnAddFiles.Location = New-Object System.Drawing.Point(870, 25)
$btnAddFiles.Size = New-Object System.Drawing.Size(160, 30)
$btnAddFiles.BackColor = $ColorBlueAccent
$btnAddFiles.ForeColor = $ColorWhite
$btnAddFiles.FlatStyle = 'Flat'
$btnAddFiles.FlatAppearance.BorderSize = 0
$grpInput.Controls.Add($btnAddFiles)

$btnClearFiles = New-Object System.Windows.Forms.Button
$btnClearFiles.Text = 'Clear List'
$btnClearFiles.Location = New-Object System.Drawing.Point(870, 65)
$btnClearFiles.Size = New-Object System.Drawing.Size(160, 30)
$btnClearFiles.BackColor = $ColorGrayButton
$btnClearFiles.FlatStyle = 'Flat'
$btnClearFiles.FlatAppearance.BorderSize = 0
$grpInput.Controls.Add($btnClearFiles)

# GroupBox: Conversion Settings
$grpSettings = New-Object System.Windows.Forms.GroupBox
$grpSettings.Text = 'Conversion Settings'
$grpSettings.Location = New-Object System.Drawing.Point(15, 170)
$grpSettings.Size = New-Object System.Drawing.Size(530, 120)
$grpSettings.ForeColor = $ColorHeaderText
$tabConvert.Controls.Add($grpSettings)

$lblProfile = New-Object System.Windows.Forms.Label
$lblProfile.Text = 'Profile:'
$lblProfile.Location = New-Object System.Drawing.Point(15, 30)
$lblProfile.Size = New-Object System.Drawing.Size(80, 20)
$grpSettings.Controls.Add($lblProfile)

$cmbProfile = New-Object System.Windows.Forms.ComboBox
$cmbProfile.Location = New-Object System.Drawing.Point(100, 27)
$cmbProfile.Size = New-Object System.Drawing.Size(410, 25)
$cmbProfile.DropDownStyle = 'DropDownList'
$cmbProfile.BackColor = $ColorWhite
$grpSettings.Controls.Add($cmbProfile)

$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = 'Output:'
$lblOutput.Location = New-Object System.Drawing.Point(15, 70)
$lblOutput.Size = New-Object System.Drawing.Size(80, 20)
$grpSettings.Controls.Add($lblOutput)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(100, 67)
$txtOutput.Size = New-Object System.Drawing.Size(330, 25)
$txtOutput.Text = $Out
$txtOutput.ReadOnly = $true
$txtOutput.BackColor = $ColorWhite
$grpSettings.Controls.Add($txtOutput)

$btnBrowseOutput = New-Object System.Windows.Forms.Button
$btnBrowseOutput.Text = '...'
$btnBrowseOutput.Location = New-Object System.Drawing.Point(440, 65)
$btnBrowseOutput.Size = New-Object System.Drawing.Size(70, 27)
$btnBrowseOutput.BackColor = $ColorGrayButton
$btnBrowseOutput.FlatStyle = 'Flat'
$grpSettings.Controls.Add($btnBrowseOutput)

# GroupBox: Optional Features
$grpOptional = New-Object System.Windows.Forms.GroupBox
$grpOptional.Text = 'Optional Features'
$grpOptional.Location = New-Object System.Drawing.Point(555, 170)
$grpOptional.Size = New-Object System.Drawing.Size(510, 120)
$grpOptional.ForeColor = $ColorHeaderText
$tabConvert.Controls.Add($grpOptional)

$lblWatermark = New-Object System.Windows.Forms.Label
$lblWatermark.Text = 'Watermark:'
$lblWatermark.Location = New-Object System.Drawing.Point(15, 30)
$lblWatermark.Size = New-Object System.Drawing.Size(80, 20)
$grpOptional.Controls.Add($lblWatermark)

$txtWatermark = New-Object System.Windows.Forms.TextBox
$txtWatermark.Location = New-Object System.Drawing.Point(100, 27)
$txtWatermark.Size = New-Object System.Drawing.Size(300, 25)
$txtWatermark.Text = '(None selected)'
$txtWatermark.ForeColor = [System.Drawing.Color]::Gray
$txtWatermark.BackColor = $ColorWhite
$grpOptional.Controls.Add($txtWatermark)

$btnBrowseWatermark = New-Object System.Windows.Forms.Button
$btnBrowseWatermark.Text = 'Browse'
$btnBrowseWatermark.Location = New-Object System.Drawing.Point(410, 25)
$btnBrowseWatermark.Size = New-Object System.Drawing.Size(80, 27)
$btnBrowseWatermark.BackColor = $ColorGrayButton
$btnBrowseWatermark.FlatStyle = 'Flat'
$grpOptional.Controls.Add($btnBrowseWatermark)

$lblSubtitle = New-Object System.Windows.Forms.Label
$lblSubtitle.Text = 'Subtitles:'
$lblSubtitle.Location = New-Object System.Drawing.Point(15, 70)
$lblSubtitle.Size = New-Object System.Drawing.Size(80, 20)
$grpOptional.Controls.Add($lblSubtitle)

$txtSubtitle = New-Object System.Windows.Forms.TextBox
$txtSubtitle.Location = New-Object System.Drawing.Point(100, 67)
$txtSubtitle.Size = New-Object System.Drawing.Size(300, 25)
$txtSubtitle.Text = '(None selected)'
$txtSubtitle.ForeColor = [System.Drawing.Color]::Gray
$txtSubtitle.BackColor = $ColorWhite
$grpOptional.Controls.Add($txtSubtitle)

$btnBrowseSubtitle = New-Object System.Windows.Forms.Button
$btnBrowseSubtitle.Text = 'Browse'
$btnBrowseSubtitle.Location = New-Object System.Drawing.Point(410, 65)
$btnBrowseSubtitle.Size = New-Object System.Drawing.Size(80, 27)
$btnBrowseSubtitle.BackColor = $ColorGrayButton
$btnBrowseSubtitle.FlatStyle = 'Flat'
$grpOptional.Controls.Add($btnBrowseSubtitle)

# Start Button (GREEN like "Start Download")
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = 'Start Conversion'
$btnStart.Location = New-Object System.Drawing.Point(15, 300)
$btnStart.Size = New-Object System.Drawing.Size(200, 40)
$btnStart.BackColor = $ColorPrimaryButton
$btnStart.ForeColor = $ColorWhite
$btnStart.FlatStyle = 'Flat'
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$tabConvert.Controls.Add($btnStart)

# Test Button (ORANGE like "Test yt-dlp")
$btnTest = New-Object System.Windows.Forms.Button
$btnTest.Text = 'Test FFmpeg'
$btnTest.Location = New-Object System.Drawing.Point(225, 300)
$btnTest.Size = New-Object System.Drawing.Size(150, 40)
$btnTest.BackColor = $ColorSecondaryButton
$btnTest.ForeColor = $ColorWhite
$btnTest.FlatStyle = 'Flat'
$btnTest.FlatAppearance.BorderSize = 0
$btnTest.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$tabConvert.Controls.Add($btnTest)

# Progress Bar
$grpProgress = New-Object System.Windows.Forms.GroupBox
$grpProgress.Text = 'Conversion Progress'
$grpProgress.Location = New-Object System.Drawing.Point(15, 350)
$grpProgress.Size = New-Object System.Drawing.Size(1050, 70)
$grpProgress.ForeColor = $ColorHeaderText
$tabConvert.Controls.Add($grpProgress)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 25)
$progressBar.Size = New-Object System.Drawing.Size(1025, 20)
$progressBar.Style = 'Continuous'
$grpProgress.Controls.Add($progressBar)

$lblProgress = New-Object System.Windows.Forms.Label
$lblProgress.Text = 'Ready for conversion'
$lblProgress.Location = New-Object System.Drawing.Point(10, 50)
$lblProgress.Size = New-Object System.Drawing.Size(1025, 15)
$lblProgress.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$grpProgress.Controls.Add($lblProgress)

# Conversion Log (Dark console like in screenshot)
$grpLog = New-Object System.Windows.Forms.GroupBox
$grpLog.Text = 'Conversion Log'
$grpLog.Location = New-Object System.Drawing.Point(15, 430)
$grpLog.Size = New-Object System.Drawing.Size(1050, 100)
$grpLog.ForeColor = $ColorHeaderText
$tabConvert.Controls.Add($grpLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(10, 20)
$txtLog.Size = New-Object System.Drawing.Size(1025, 70)
$txtLog.Multiline = $true
$txtLog.ScrollBars = 'Vertical'
$txtLog.BackColor = $ColorLogBackground
$txtLog.ForeColor = $ColorWhite
$txtLog.Font = New-Object System.Drawing.Font('Consolas', 8)
$txtLog.ReadOnly = $true
$grpLog.Controls.Add($txtLog)

# ============================================
# TAB 2: PROFILES
# ============================================
$tabProfiles = New-Object System.Windows.Forms.TabPage
$tabProfiles.Text = 'Profiles'
$tabProfiles.BackColor = $ColorWhite
$tabControl.Controls.Add($tabProfiles)

$lblProfileInfo = New-Object System.Windows.Forms.Label
$lblProfileInfo.Text = 'Available conversion profiles:'
$lblProfileInfo.Location = New-Object System.Drawing.Point(20, 20)
$lblProfileInfo.Size = New-Object System.Drawing.Size(500, 20)
$lblProfileInfo.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$lblProfileInfo.ForeColor = $ColorHeaderText
$tabProfiles.Controls.Add($lblProfileInfo)

$lstProfiles = New-Object System.Windows.Forms.ListBox
$lstProfiles.Location = New-Object System.Drawing.Point(20, 50)
$lstProfiles.Size = New-Object System.Drawing.Size(1040, 470)
$lstProfiles.Font = New-Object System.Drawing.Font('Consolas', 9)
$lstProfiles.BackColor = $ColorWhite
$tabProfiles.Controls.Add($lstProfiles)

# ============================================
# TAB 3: SETTINGS
# ============================================
$tabSettings = New-Object System.Windows.Forms.TabPage
$tabSettings.Text = 'Settings'
$tabSettings.BackColor = $ColorWhite
$tabControl.Controls.Add($tabSettings)

$grpBinaries = New-Object System.Windows.Forms.GroupBox
$grpBinaries.Text = 'Binaries Location'
$grpBinaries.Location = New-Object System.Drawing.Point(20, 20)
$grpBinaries.Size = New-Object System.Drawing.Size(1040, 100)
$grpBinaries.ForeColor = $ColorHeaderText
$tabSettings.Controls.Add($grpBinaries)

$lblBinPath = New-Object System.Windows.Forms.Label
$lblBinPath.Text = "Binaries: $Bins"
$lblBinPath.Location = New-Object System.Drawing.Point(15, 30)
$lblBinPath.Size = New-Object System.Drawing.Size(800, 20)
$grpBinaries.Controls.Add($lblBinPath)

$btnInstallFFmpeg = New-Object System.Windows.Forms.Button
$btnInstallFFmpeg.Text = 'Install FFmpeg'
$btnInstallFFmpeg.Location = New-Object System.Drawing.Point(15, 60)
$btnInstallFFmpeg.Size = New-Object System.Drawing.Size(150, 30)
$btnInstallFFmpeg.BackColor = $ColorBlueAccent
$btnInstallFFmpeg.ForeColor = $ColorWhite
$btnInstallFFmpeg.FlatStyle = 'Flat'
$btnInstallFFmpeg.FlatAppearance.BorderSize = 0
$grpBinaries.Controls.Add($btnInstallFFmpeg)

$btnInstallHandBrake = New-Object System.Windows.Forms.Button
$btnInstallHandBrake.Text = 'Install HandBrake'
$btnInstallHandBrake.Location = New-Object System.Drawing.Point(175, 60)
$btnInstallHandBrake.Size = New-Object System.Drawing.Size(150, 30)
$btnInstallHandBrake.BackColor = $ColorBlueAccent
$btnInstallHandBrake.ForeColor = $ColorWhite
$btnInstallHandBrake.FlatStyle = 'Flat'
$btnInstallHandBrake.FlatAppearance.BorderSize = 0
$grpBinaries.Controls.Add($btnInstallHandBrake)

# ============================================
# TAB 4: ABOUT
# ============================================
$tabAbout = New-Object System.Windows.Forms.TabPage
$tabAbout.Text = 'About'
$tabAbout.BackColor = $ColorWhite
$tabControl.Controls.Add($tabAbout)

$lblAboutTitle = New-Object System.Windows.Forms.Label
$lblAboutTitle.Text = 'Professional Portable Converter'
$lblAboutTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblAboutTitle.Size = New-Object System.Drawing.Size(800, 30)
$lblAboutTitle.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$lblAboutTitle.ForeColor = $ColorHeaderText
$tabAbout.Controls.Add($lblAboutTitle)

$lblAboutVersion = New-Object System.Windows.Forms.Label
$lblAboutVersion.Text = 'Version 3.0 - Professional Edition'
$lblAboutVersion.Location = New-Object System.Drawing.Point(20, 60)
$lblAboutVersion.Size = New-Object System.Drawing.Size(800, 20)
$lblAboutVersion.ForeColor = $ColorHeaderText
$tabAbout.Controls.Add($lblAboutVersion)

$lblAboutDesc = New-Object System.Windows.Forms.Label
$lblAboutDesc.Text = @"
Portable video converter with FFmpeg and HandBrake support.

Features:
• Professional Windows 10/11 styled interface
• FFmpeg and HandBrake conversion engines
• Watermark overlay support
• Subtitle burn-in
• Batch processing
• Automatic binary downloads

Color scheme inspired by Professional Subtitle Translator.
Created with PowerShell and Windows Forms.
"@
$lblAboutDesc.Location = New-Object System.Drawing.Point(20, 100)
$lblAboutDesc.Size = New-Object System.Drawing.Size(800, 200)
$lblAboutDesc.ForeColor = $ColorHeaderText
$tabAbout.Controls.Add($lblAboutDesc)

# Status Bar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = 'Ready - Professional Portable Converter'
$statusBar.BackColor = $ColorBackground
$form.Controls.Add($statusBar)

# Global variables
$script:WatermarkPath = $null
$script:SubtitlePath = $null
$script:OutputPath = $Out

# Helper: Add log
function Add-GuiLog {
    param([string]$msg)
    
    $txtLog.AppendText("$msg`r`n")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    Write-Log $msg
}

# Helper: Show message
function Show-Message([string]$msg, [string]$title = 'Info'){
    [System.Windows.Forms.MessageBox]::Show($msg, $title)
}

# Event: Add Files
$btnAddFiles.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Multiselect = $true
    $ofd.Filter = 'Video Files|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.flv;*.webm|All Files|*.*'
    if($ofd.ShowDialog() -eq 'OK'){
        foreach($f in $ofd.FileNames){
            [void]$lstFiles.Items.Add($f)
        }
        Add-GuiLog "Added $($ofd.FileNames.Count) file(s)"
    }
})

# Event: Clear Files
$btnClearFiles.Add_Click({
    $lstFiles.Items.Clear()
    Add-GuiLog "File list cleared"
})

# Event: Browse Output
$btnBrowseOutput.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $script:OutputPath
    if($fbd.ShowDialog() -eq 'OK'){
        $script:OutputPath = $fbd.SelectedPath
        $txtOutput.Text = $fbd.SelectedPath
        Add-GuiLog "Output folder: $($fbd.SelectedPath)"
    }
})

# Event: Browse Watermark
$btnBrowseWatermark.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = 'Image Files|*.png;*.jpg;*.jpeg|All Files|*.*'
    if($ofd.ShowDialog() -eq 'OK'){
        $script:WatermarkPath = $ofd.FileName
        $txtWatermark.Text = [System.IO.Path]::GetFileName($ofd.FileName)
        $txtWatermark.ForeColor = [System.Drawing.Color]::Black
        Add-GuiLog "Watermark: $($ofd.FileName)"
    }
})

# Event: Browse Subtitle
$btnBrowseSubtitle.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = 'Subtitle Files|*.srt;*.ass;*.ssa|All Files|*.*'
    if($ofd.ShowDialog() -eq 'OK'){
        $script:SubtitlePath = $ofd.FileName
        $txtSubtitle.Text = [System.IO.Path]::GetFileName($ofd.FileName)
        $txtSubtitle.ForeColor = [System.Drawing.Color]::Black
        Add-GuiLog "Subtitle: $($ofd.FileName)"
    }
})

# Event: Test FFmpeg
$btnTest.Add_Click({
    Add-GuiLog "Testing FFmpeg installation..."
    $statusBar.Text = 'Testing FFmpeg...'
    
    $ffmpeg = Join-Path $Bins "ffmpeg.exe"
    if(-not (Test-Path $ffmpeg)){
        Add-GuiLog "FFmpeg not found. Installing..."
        $result = Install-FFTools
        $ffmpeg = $result
    }
    
    if(Test-Path $ffmpeg){
        try {
            $ver = & $ffmpeg -version 2>&1 | Select-Object -First 1
            Add-GuiLog "FFmpeg version: $ver"
            Show-Message "FFmpeg is working!`n`n$ver" "Success"
            $statusBar.Text = 'Ready - FFmpeg test successful'
        } catch {
            Add-GuiLog "FFmpeg test failed: $($_.Exception.Message)"
            Show-Message "FFmpeg test failed!`n$($_.Exception.Message)" "Error"
            $statusBar.Text = 'Ready - FFmpeg test failed'
        }
    } else {
        Add-GuiLog "FFmpeg not available"
        Show-Message "FFmpeg not found. Please install it from Settings tab." "Error"
        $statusBar.Text = 'Ready - FFmpeg not found'
    }
})

# Event: Install FFmpeg
$btnInstallFFmpeg.Add_Click({
    Add-GuiLog "Installing FFmpeg..."
    $statusBar.Text = 'Installing FFmpeg...'
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    
    try {
        $result = Install-FFTools
        if($result){
            Show-Message "FFmpeg installed successfully!" "Success"
            $statusBar.Text = 'Ready - FFmpeg installed'
            Add-GuiLog "FFmpeg installation complete"
        } else {
            Show-Message "FFmpeg installation failed. Check the log." "Error"
            $statusBar.Text = 'Ready - FFmpeg installation failed'
        }
    } finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})

# Event: Install HandBrake
$btnInstallHandBrake.Add_Click({
    Add-GuiLog "Installing HandBrake..."
    $statusBar.Text = 'Installing HandBrake...'
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    
    try {
        $result = Install-HandBrake
        if($result){
            Show-Message "HandBrake installed successfully!" "Success"
            $statusBar.Text = 'Ready - HandBrake installed'
            Add-GuiLog "HandBrake installation complete"
        } else {
            Show-Message "HandBrake installation failed. Check the log." "Error"
            $statusBar.Text = 'Ready - HandBrake installation failed'
        }
    } finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
})

# Event: Start Conversion
$btnStart.Add_Click({
    if($lstFiles.Items.Count -eq 0){
        Show-Message 'Please add at least one file!' 'No Files'
        return
    }
    if($cmbProfile.SelectedIndex -lt 0){
        Show-Message 'Please select a conversion profile!' 'No Profile'
        return
    }

    # Disable UI
    $btnAddFiles.Enabled = $false
    $btnClearFiles.Enabled = $false
    $btnStart.Enabled = $false
    $btnTest.Enabled = $false
    $cmbProfile.Enabled = $false
    $btnBrowseWatermark.Enabled = $false
    $btnBrowseSubtitle.Enabled = $false
    $btnBrowseOutput.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    $p = $Config.profiles[$cmbProfile.SelectedIndex]
    $total = $lstFiles.Items.Count
    $current = 0
    $okCount = 0
    $failCount = 0

    Add-GuiLog "========================================"
    Add-GuiLog "Starting batch conversion..."
    Add-GuiLog "Profile: $($p.name)"
    Add-GuiLog "Total files: $total"
    Add-GuiLog "========================================"
    $statusBar.Text = "Converting $total files..."

    # Install binaries if needed
    $ffmpeg = Join-Path $Bins "ffmpeg.exe"
    $handbrake = Join-Path $Bins "HandBrakeCLI.exe"
    
    if(-not (Test-Path $ffmpeg)){
        Add-GuiLog "Installing FFmpeg..."
        $script:FfmpegPath = Install-FFTools
        $ffmpeg = $script:FfmpegPath
    }
    
    if($p.engine -eq 'handbrake' -and -not (Test-Path $handbrake)){
        Add-GuiLog "Installing HandBrake..."
        Install-HandBrake
    }

    # Process each file
    foreach($inputFile in $lstFiles.Items){
        $current++
        $percent = [math]::Round(($current / $total) * 100, 1)
        
        $progressBar.Value = [int]$percent
        $lblProgress.Text = "[$current/$total] ($percent%) Processing: $(Split-Path $inputFile -Leaf)"
        Add-GuiLog ""
        Add-GuiLog "[$current/$total] ($percent%) Processing: $(Split-Path $inputFile -Leaf)"
        $form.Refresh()
        
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
        $outputFile = Join-Path $script:OutputPath "$fileName.$($p.format)"
        
        # Ensure output directory exists
        $outDir = Split-Path -Parent $outputFile
        if($outDir -and -not (Test-Path $outDir)){
            New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        }
        
        try {
            # Apply watermark if set
            $processedInput = $inputFile
            if($script:WatermarkPath){
                Add-GuiLog "  Applying watermark..."
                $wmTemp = Join-Path $Temp "$fileName-wm.mp4"
                $wmArgs = @(
                    '-i', $inputFile,
                    '-i', $script:WatermarkPath,
                    '-filter_complex', 'overlay=W-w-10:H-h-10',
                    '-c:a', 'copy',
                    '-y', $wmTemp
                )
                & $ffmpeg @wmArgs 2>&1 | Out-Null
                $processedInput = $wmTemp
            }
            
            # Apply subtitles if set
            if($script:SubtitlePath){
                Add-GuiLog "  Burning subtitles..."
                $subTemp = Join-Path $Temp "$fileName-sub.mp4"
                $subArgs = @(
                    '-i', $processedInput,
                    '-vf', "subtitles='$($script:SubtitlePath -replace '\\','/')'",
                    '-c:a', 'copy',
                    '-y', $subTemp
                )
                & $ffmpeg @subArgs 2>&1 | Out-Null
                $processedInput = $subTemp
            }
            
            # Main conversion
            Add-GuiLog "  Converting with $($p.engine)..."
            
            if($p.engine -eq 'ffmpeg'){
                $ffArgs = @('-i', $processedInput) + $p.args.Split(' ') + @('-y', $outputFile)
                $proc = Start-Process -FilePath $ffmpeg -ArgumentList $ffArgs -NoNewWindow -PassThru -Wait
                
                # Validate output
                if($proc.ExitCode -eq 0 -and (Test-Path $outputFile)){
                    $fi = Get-Item -LiteralPath $outputFile
                    if($fi.Length -gt 0){
                        Add-GuiLog "  Success - saved to: $(Split-Path $outputFile -Leaf) ($([math]::Round($fi.Length/1MB, 2)) MB)"
                        $okCount++
                    } else {
                        Add-GuiLog "  Failed - output file is empty"
                        $failCount++
                    }
                } else {
                    Add-GuiLog "  Failed - FFmpeg error code: $($proc.ExitCode)"
                    $failCount++
                }
            } elseif($p.engine -eq 'handbrake'){
                $hbArgs = @('-i', $processedInput, '-o', $outputFile) + $p.args.Split(' ')
                $proc = Start-Process -FilePath $handbrake -ArgumentList $hbArgs -NoNewWindow -PassThru -Wait
                
                # Validate output
                if($proc.ExitCode -eq 0 -and (Test-Path $outputFile)){
                    $fi = Get-Item -LiteralPath $outputFile
                    if($fi.Length -gt 0){
                        Add-GuiLog "  Success - saved to: $(Split-Path $outputFile -Leaf) ($([math]::Round($fi.Length/1MB, 2)) MB)"
                        $okCount++
                    } else {
                        Add-GuiLog "  Failed - output file is empty"
                        $failCount++
                    }
                } else {
                    Add-GuiLog "  Failed - HandBrake error code: $($proc.ExitCode)"
                    $failCount++
                }
            }
            
            # Cleanup temp files
            if($script:WatermarkPath -and (Test-Path $wmTemp)){ Remove-Item $wmTemp -Force }
            if($script:SubtitlePath -and (Test-Path $subTemp)){ Remove-Item $subTemp -Force }
            
        } catch {
            Add-GuiLog "  Error: $($_.Exception.Message)"
            $failCount++
        }
    }
    
    $progressBar.Value = 100
    $lblProgress.Text = "Complete! Successful: $okCount | Failed: $failCount"
    Add-GuiLog ""
    Add-GuiLog "========================================"
    Add-GuiLog "Batch conversion complete!"
    Add-GuiLog "Successful: $okCount | Failed: $failCount"
    Add-GuiLog "========================================"
    $statusBar.Text = "Complete - $okCount successful, $failCount failed"
    
    # Re-enable UI
    $btnAddFiles.Enabled = $true
    $btnClearFiles.Enabled = $true
    $btnStart.Enabled = $true
    $btnTest.Enabled = $true
    $cmbProfile.Enabled = $true
    $btnBrowseWatermark.Enabled = $true
    $btnBrowseSubtitle.Enabled = $true
    $btnBrowseOutput.Enabled = $true
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
    
    Show-Message "Conversion complete!`n`nSuccessful: $okCount`nFailed: $failCount" "Done"
})

# Populate profiles
foreach($p in $Config.profiles){ [void]$cmbProfile.Items.Add($p.name) }
if($cmbProfile.Items.Count -gt 0){ $cmbProfile.SelectedIndex = 0 }

# Populate profiles list in Profiles tab
foreach($p in $Config.profiles){
    $lstProfiles.Items.Add("$($p.name)")
    $lstProfiles.Items.Add("  Engine: $($p.engine)")
    $lstProfiles.Items.Add("  Format: $($p.format)")
    $lstProfiles.Items.Add("  Args: $($p.args)")
    $lstProfiles.Items.Add("")
}

# Show window
Add-GuiLog "Professional Portable Converter started"
Add-GuiLog "Ready to convert. Add files and select a profile to begin."
$statusBar.Text = 'Ready - Professional Portable Converter'

[void]$form.ShowDialog()
