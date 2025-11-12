<#
  PPC-GUI-Ultimate.ps1
  Complete Dark Mode GUI inspired by Apowersoft Video Converter Studio
  All features: Task List, Preset Editor, Edit Window, Subtitles, Watermark
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
$LogFile = Join-Path $Logs 'ppc-ultimate.log'

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
  Write-Log "Installing FFmpeg..."
  $urls = @(
    'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip',
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
      if ($ff) { 
        Copy-Item -LiteralPath $ff.FullName -Destination (Join-Path $Bins "ffmpeg.exe") -Force 
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "FFmpeg installed!"
        return (Join-Path $Bins "ffmpeg.exe")
      }
    } catch {
      Write-Log "Download failed: $($_.Exception.Message)"
    }
  }
  return $null
}

function Install-HandBrake {
  Write-Log "Installing HandBrake..."
  $urls = @(
    'https://github.com/HandBrake/HandBrake/releases/download/1.10.2/HandBrakeCLI-1.10.2-win-x86_64.zip',
    'https://github.com/HandBrake/HandBrake/releases/download/1.10.1/HandBrakeCLI-1.10.1-win-x86_64.zip'
  )
  foreach ($url in $urls) {
    try {
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
        Write-Log "HandBrake installed!"
        return $true
      }
    } catch {
      Write-Log "Download failed: $($_.Exception.Message)"
    }
  }
  return $false
}

# Config with detailed profiles
$Config = @{
  default_format = 'mp4';
  profiles = @(
    @{ 
      name='MP4 - Same as source (H.264; AAC; 128Kbps; Stereo)'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='128k'; 
      channels='2';
      args='-c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k -ac 2' 
    },
    @{ 
      name='MP4 - High Quality 1080p (H.264; AAC; 160Kbps; Stereo)'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='160k'; 
      channels='2';
      args='-c:v libx264 -preset medium -crf 20 -c:a aac -b:a 160k -ac 2' 
    },
    @{ 
      name='MP4 - Small 720p (H.264; AAC; 128Kbps; Stereo)'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='128k'; 
      channels='2';
      args='-vf scale=1280:-2 -c:v libx264 -preset veryfast -crf 25 -c:a aac -b:a 128k -ac 2' 
    },
    @{ 
      name='MKV - H.265/HEVC (AAC; 160Kbps; Stereo)'; 
      engine='handbrake'; 
      format='mkv'; 
      vcodec='x265'; 
      acodec='aac'; 
      ab='160k'; 
      channels='2';
      args='-e x265 -q 26 -E av_aac -B 160' 
    }
  )
}
if (Test-Path $Cfg) { 
  try { 
    $Config = Get-Content $Cfg -Raw | ConvertFrom-Json 
  } catch { 
    Write-Log 'Config load failed, using defaults.' 
  } 
}

# WinForms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Dark Mode Color Scheme (Apowersoft style)
$ColorBg = [System.Drawing.Color]::FromArgb(45, 47, 56)           # #2D2F38
$ColorPanel = [System.Drawing.Color]::FromArgb(58, 60, 69)        # #3A3C45
$ColorText = [System.Drawing.Color]::White                        # #FFFFFF
$ColorAccent = [System.Drawing.Color]::FromArgb(47, 169, 224)     # #2FA9E0
$ColorInactive = [System.Drawing.Color]::FromArgb(160, 160, 160)  # #A0A0A0
$ColorBorder = [System.Drawing.Color]::FromArgb(70, 70, 70)       # #464646

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Professional Portable Converter - Ultimate Edition'
$form.Width = 1280
$form.Height = 720
$form.StartPosition = 'CenterScreen'
$form.BackColor = $ColorBg
$form.ForeColor = $ColorText
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$form.FormBorderStyle = 'Sizable'

# ============================================
# TOP TABS (Custom painted for modern look)
# ============================================
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(0, 0)
$tabControl.Size = New-Object System.Drawing.Size(1264, 680)
$tabControl.Appearance = 'FlatButtons'
$tabControl.BackColor = $ColorBg
$tabControl.ForeColor = $ColorText
$tabControl.DrawMode = 'OwnerDrawFixed'
$tabControl.ItemSize = New-Object System.Drawing.Size(100, 40)
$tabControl.SizeMode = 'Fixed'
$tabControl.Padding = New-Object System.Drawing.Point(20, 5)

# Custom paint for modern tabs
$tabControl.Add_DrawItem({
    param($sender, $e)
    $tabPage = $sender.TabPages[$e.Index]
    $tabRect = $sender.GetTabRect($e.Index)
    
    # Background
    if($e.Index -eq $sender.SelectedIndex){
        $brush = New-Object System.Drawing.SolidBrush($ColorAccent)
    } else {
        $brush = New-Object System.Drawing.SolidBrush($ColorPanel)
    }
    $e.Graphics.FillRectangle($brush, $tabRect)
    $brush.Dispose()
    
    # Text
    $textBrush = New-Object System.Drawing.SolidBrush($ColorText)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $e.Graphics.DrawString($tabPage.Text, $sender.Font, $textBrush, $tabRect, $sf)
    $textBrush.Dispose()
    $sf.Dispose()
})

$form.Controls.Add($tabControl)

$tabConvert = New-Object System.Windows.Forms.TabPage
$tabConvert.Text = '⟳ Convert'
$tabConvert.BackColor = $ColorBg
$tabConvert.ForeColor = $ColorText
$tabControl.Controls.Add($tabConvert)

$tabSplitScreen = New-Object System.Windows.Forms.TabPage
$tabSplitScreen.Text = '▦ Split Screen'
$tabSplitScreen.BackColor = $ColorBg
$tabSplitScreen.ForeColor = $ColorText
$tabControl.Controls.Add($tabSplitScreen)

$tabMakeMV = New-Object System.Windows.Forms.TabPage
$tabMakeMV.Text = '🎬 Make MV'
$tabMakeMV.BackColor = $ColorBg
$tabMakeMV.ForeColor = $ColorText
$tabControl.Controls.Add($tabMakeMV)

$tabDownload = New-Object System.Windows.Forms.TabPage
$tabDownload.Text = '⬇ Download'
$tabDownload.BackColor = $ColorBg
$tabDownload.ForeColor = $ColorText
$tabControl.Controls.Add($tabDownload)

$tabRecord = New-Object System.Windows.Forms.TabPage
$tabRecord.Text = '⏺ Record'
$tabRecord.BackColor = $ColorBg
$tabRecord.ForeColor = $ColorText
$tabControl.Controls.Add($tabRecord)

# ============================================
# CONVERT TAB - TASK LIST
# ============================================
$lvTasks = New-Object System.Windows.Forms.ListView
$lvTasks.Location = New-Object System.Drawing.Point(20, 15)
$lvTasks.Size = New-Object System.Drawing.Size(1220, 470)
$lvTasks.View = 'Details'
$lvTasks.FullRowSelect = $true
$lvTasks.GridLines = $false
$lvTasks.BackColor = $ColorPanel
$lvTasks.ForeColor = $ColorText
$lvTasks.BorderStyle = 'None'
$lvTasks.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$lvTasks.HeaderStyle = 'Nonclickable'
$lvTasks.OwnerDraw = $true

# Custom header drawing
$lvTasks.Add_DrawColumnHeader({
    param($sender, $e)
    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush($ColorBg)), $e.Bounds)
    $textBrush = New-Object System.Drawing.SolidBrush($ColorInactive)
    $sf = New-Object System.Drawing.StringFormat
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textRect = New-Object System.Drawing.Rectangle($e.Bounds.X + 5, $e.Bounds.Y, $e.Bounds.Width - 5, $e.Bounds.Height)
    $e.Graphics.DrawString($e.Header.Text, $sender.Font, $textBrush, $textRect, $sf)
    $textBrush.Dispose()
    $sf.Dispose()
})

# Custom item drawing
$lvTasks.Add_DrawItem({
    param($sender, $e)
    $e.DrawDefault = $true
})

$lvTasks.Add_DrawSubItem({
    param($sender, $e)
    if($e.Item.Selected){
        $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 70, 80))), $e.Bounds)
    }
    $textBrush = New-Object System.Drawing.SolidBrush($ColorText)
    $sf = New-Object System.Drawing.StringFormat
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textRect = New-Object System.Drawing.Rectangle($e.Bounds.X + 5, $e.Bounds.Y, $e.Bounds.Width - 5, $e.Bounds.Height)
    $e.Graphics.DrawString($e.SubItem.Text, $sender.Font, $textBrush, $textRect, $sf)
    $textBrush.Dispose()
    $sf.Dispose()
})

$lvTasks.Columns.Add("File", 250) | Out-Null
$lvTasks.Columns.Add("Format", 80) | Out-Null
$lvTasks.Columns.Add("Duration", 80) | Out-Null
$lvTasks.Columns.Add("Resolution", 100) | Out-Null
$lvTasks.Columns.Add("Size", 80) | Out-Null
$lvTasks.Columns.Add("Audio", 150) | Out-Null
$lvTasks.Columns.Add("Target", 200) | Out-Null
$lvTasks.Columns.Add("Status", 100) | Out-Null
$tabConvert.Controls.Add($lvTasks)

# ============================================
# BOTTOM BAR
# ============================================
$panelBottom = New-Object System.Windows.Forms.Panel
$panelBottom.Location = New-Object System.Drawing.Point(0, 500)
$panelBottom.Size = New-Object System.Drawing.Size(1264, 140)
$panelBottom.BackColor = $ColorBg
$tabConvert.Controls.Add($panelBottom)

# Row 1: Buttons
$btnClearAll = New-Object System.Windows.Forms.Button
$btnClearAll.Text = 'Clear task list'
$btnClearAll.Location = New-Object System.Drawing.Point(20, 15)
$btnClearAll.Size = New-Object System.Drawing.Size(130, 35)
$btnClearAll.BackColor = $ColorPanel
$btnClearAll.ForeColor = $ColorText
$btnClearAll.FlatStyle = 'Flat'
$btnClearAll.FlatAppearance.BorderSize = 0
$btnClearAll.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(70, 70, 80)
$btnClearAll.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$btnClearAll.Cursor = [System.Windows.Forms.Cursors]::Hand
$panelBottom.Controls.Add($btnClearAll)

$btnRemoveSelected = New-Object System.Windows.Forms.Button
$btnRemoveSelected.Text = 'Remove selected'
$btnRemoveSelected.Location = New-Object System.Drawing.Point(160, 15)
$btnRemoveSelected.Size = New-Object System.Drawing.Size(130, 35)
$btnRemoveSelected.BackColor = $ColorPanel
$btnRemoveSelected.ForeColor = $ColorText
$btnRemoveSelected.FlatStyle = 'Flat'
$btnRemoveSelected.FlatAppearance.BorderSize = 0
$btnRemoveSelected.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(70, 70, 80)
$btnRemoveSelected.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$btnRemoveSelected.Cursor = [System.Windows.Forms.Cursors]::Hand
$panelBottom.Controls.Add($btnRemoveSelected)

$chkMerge = New-Object System.Windows.Forms.CheckBox
$chkMerge.Text = 'Merge into one file'
$chkMerge.Location = New-Object System.Drawing.Point(300, 20)
$chkMerge.Size = New-Object System.Drawing.Size(170, 25)
$chkMerge.ForeColor = $ColorText
$chkMerge.FlatStyle = 'Flat'
$chkMerge.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$panelBottom.Controls.Add($chkMerge)

# Row 2: Profile selector and output path
$lblProfile = New-Object System.Windows.Forms.Label
$lblProfile.Text = 'Profile:'
$lblProfile.Location = New-Object System.Drawing.Point(20, 65)
$lblProfile.Size = New-Object System.Drawing.Size(60, 25)
$lblProfile.ForeColor = $ColorInactive
$lblProfile.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$lblProfile.TextAlign = 'MiddleLeft'
$panelBottom.Controls.Add($lblProfile)

$cmbProfile = New-Object System.Windows.Forms.ComboBox
$cmbProfile.Location = New-Object System.Drawing.Point(85, 63)
$cmbProfile.Size = New-Object System.Drawing.Size(450, 30)
$cmbProfile.DropDownStyle = 'DropDownList'
$cmbProfile.BackColor = $ColorPanel
$cmbProfile.ForeColor = $ColorText
$cmbProfile.FlatStyle = 'Flat'
$cmbProfile.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$panelBottom.Controls.Add($cmbProfile)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(545, 63)
$txtOutput.Size = New-Object System.Drawing.Size(350, 30)
$txtOutput.Text = $Out
$txtOutput.BackColor = $ColorPanel
$txtOutput.ForeColor = $ColorText
$txtOutput.BorderStyle = 'FixedSingle'
$txtOutput.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$panelBottom.Controls.Add($txtOutput)

$btnBrowseOutput = New-Object System.Windows.Forms.Button
$btnBrowseOutput.Text = '...'
$btnBrowseOutput.Location = New-Object System.Drawing.Point(905, 63)
$btnBrowseOutput.Size = New-Object System.Drawing.Size(40, 30)
$btnBrowseOutput.BackColor = $ColorPanel
$btnBrowseOutput.ForeColor = $ColorText
$btnBrowseOutput.FlatStyle = 'Flat'
$btnBrowseOutput.FlatAppearance.BorderSize = 0
$btnBrowseOutput.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(70, 70, 80)
$btnBrowseOutput.Cursor = [System.Windows.Forms.Cursors]::Hand
$panelBottom.Controls.Add($btnBrowseOutput)

$btnSettings = New-Object System.Windows.Forms.Button
$btnSettings.Text = 'Settings'
$btnSettings.Location = New-Object System.Drawing.Point(955, 63)
$btnSettings.Size = New-Object System.Drawing.Size(90, 30)
$btnSettings.BackColor = $ColorPanel
$btnSettings.ForeColor = $ColorText
$btnSettings.FlatStyle = 'Flat'
$btnSettings.FlatAppearance.BorderSize = 0
$btnSettings.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(70, 70, 80)
$btnSettings.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$btnSettings.Cursor = [System.Windows.Forms.Cursors]::Hand
$panelBottom.Controls.Add($btnSettings)

$btnOpenFolder = New-Object System.Windows.Forms.Button
$btnOpenFolder.Text = 'Open'
$btnOpenFolder.Location = New-Object System.Drawing.Point(1055, 63)
$btnOpenFolder.Size = New-Object System.Drawing.Size(90, 30)
$btnOpenFolder.BackColor = $ColorPanel
$btnOpenFolder.ForeColor = $ColorText
$btnOpenFolder.FlatStyle = 'Flat'
$btnOpenFolder.FlatAppearance.BorderSize = 0
$btnOpenFolder.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(70, 70, 80)
$btnOpenFolder.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$btnOpenFolder.Cursor = [System.Windows.Forms.Cursors]::Hand
$panelBottom.Controls.Add($btnOpenFolder)

$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = 'Convert'
$btnConvert.Location = New-Object System.Drawing.Point(1055, 15)
$btnConvert.Size = New-Object System.Drawing.Size(190, 78)
$btnConvert.BackColor = $ColorAccent
$btnConvert.ForeColor = $ColorText
$btnConvert.FlatStyle = 'Flat'
$btnConvert.FlatAppearance.BorderSize = 0
$btnConvert.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(60, 185, 235)
$btnConvert.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$btnConvert.Cursor = [System.Windows.Forms.Cursors]::Hand
$panelBottom.Controls.Add($btnConvert)

# ============================================
# CONTEXT MENU (Right-click on task)
# ============================================
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuEdit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuEdit.Text = 'Edit'
$contextMenu.Items.Add($menuEdit) | Out-Null

$menuPreset = New-Object System.Windows.Forms.ToolStripMenuItem
$menuPreset.Text = 'Preset Editor'
$contextMenu.Items.Add($menuPreset) | Out-Null

$menuRemove = New-Object System.Windows.Forms.ToolStripMenuItem
$menuRemove.Text = 'Remove'
$contextMenu.Items.Add($menuRemove) | Out-Null

$lvTasks.ContextMenuStrip = $contextMenu

# Global variables
$script:Tasks = @()
$script:OutputPath = $Out
$script:CurrentPreset = $null

# ============================================
# HELPER FUNCTIONS
# ============================================
function Add-Task([string]$filePath) {
    if(-not (Test-Path $filePath)){ return }
    
    # Get file info using ffprobe (if available)
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $fileSize = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
    $ext = [System.IO.Path]::GetExtension($filePath).TrimStart('.')
    
    $task = @{
        FilePath = $filePath
        FileName = $fileName
        Format = $ext.ToUpper()
        Duration = "Unknown"
        Resolution = "Unknown"
        Size = "$fileSize MB"
        Audio = "Unknown"
        Target = $cmbProfile.SelectedItem
        Status = "Ready"
        WatermarkPath = $null
        SubtitlePath = $null
    }
    
    $script:Tasks += $task
    
    # Add to ListView
    $item = New-Object System.Windows.Forms.ListViewItem($fileName)
    $item.SubItems.Add($task.Format) | Out-Null
    $item.SubItems.Add($task.Duration) | Out-Null
    $item.SubItems.Add($task.Resolution) | Out-Null
    $item.SubItems.Add($task.Size) | Out-Null
    $item.SubItems.Add($task.Audio) | Out-Null
    $item.SubItems.Add($task.Target) | Out-Null
    $item.SubItems.Add($task.Status) | Out-Null
    $item.Tag = $task
    
    $lvTasks.Items.Add($item) | Out-Null
}

function Show-Message([string]$msg, [string]$title = 'Info'){
    [System.Windows.Forms.MessageBox]::Show($msg, $title)
}

function Show-PresetEditor {
    $formPreset = New-Object System.Windows.Forms.Form
    $formPreset.Text = 'Preset Editor'
    $formPreset.Width = 650
    $formPreset.Height = 550
    $formPreset.StartPosition = 'CenterScreen'
    $formPreset.BackColor = $ColorBg
    $formPreset.ForeColor = $ColorText
    $formPreset.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $formPreset.FormBorderStyle = 'FixedDialog'
    $formPreset.MaximizeBox = $false
    
    # Title
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = 'Custom Preset Editor'
    $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblTitle.Size = New-Object System.Drawing.Size(600, 30)
    $lblTitle.ForeColor = $ColorText
    $lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $formPreset.Controls.Add($lblTitle)
    
    $yPos = 60
    
    $yPos = 60
    
    # Video Section Header
    $lblVideoSection = New-Object System.Windows.Forms.Label
    $lblVideoSection.Text = '━━━ VIDEO SETTINGS ━━━'
    $lblVideoSection.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblVideoSection.Size = New-Object System.Drawing.Size(600, 25)
    $lblVideoSection.ForeColor = $ColorAccent
    $lblVideoSection.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $formPreset.Controls.Add($lblVideoSection)
    
    $yPos += 35
    
    $lblVCodec = New-Object System.Windows.Forms.Label
    $lblVCodec.Text = 'Video codec:'
    $lblVCodec.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblVCodec.Size = New-Object System.Drawing.Size(140, 25)
    $lblVCodec.ForeColor = $ColorText
    $formPreset.Controls.Add($lblVCodec)
    
    $cmbVCodec = New-Object System.Windows.Forms.ComboBox
    $cmbVCodec.Location = New-Object System.Drawing.Point(180, $yPos)
    $cmbVCodec.Size = New-Object System.Drawing.Size(250, 25)
    $cmbVCodec.Items.AddRange(@('H.264', 'H.265/HEVC', 'VP9', 'Copy'))
    $cmbVCodec.SelectedIndex = 0
    $cmbVCodec.BackColor = $ColorPanel
    $cmbVCodec.ForeColor = $ColorText
    $cmbVCodec.FlatStyle = 'Flat'
    $formPreset.Controls.Add($cmbVCodec)
    
    $yPos += 40
    $lblFPS = New-Object System.Windows.Forms.Label
    $lblFPS.Text = 'Frame rate (fps):'
    $lblFPS.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblFPS.Size = New-Object System.Drawing.Size(120, 20)
    $tabCustom.Controls.Add($lblFPS)
    
    $cmbFPS = New-Object System.Windows.Forms.ComboBox
    $cmbFPS.Location = New-Object System.Drawing.Point(150, $yPos)
    $cmbFPS.Size = New-Object System.Drawing.Size(200, 25)
    $cmbFPS.Items.AddRange(@('Original', '24', '30', '60'))
    $cmbFPS.SelectedIndex = 0
    $cmbFPS.BackColor = $ColorPanel
    $cmbFPS.ForeColor = $ColorText
    $tabCustom.Controls.Add($cmbFPS)
    
    $yPos += 40
    $lblRes = New-Object System.Windows.Forms.Label
    $lblRes.Text = 'Resolution:'
    $lblRes.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblRes.Size = New-Object System.Drawing.Size(120, 20)
    $tabCustom.Controls.Add($lblRes)
    
    $cmbRes = New-Object System.Windows.Forms.ComboBox
    $cmbRes.Location = New-Object System.Drawing.Point(150, $yPos)
    $cmbRes.Size = New-Object System.Drawing.Size(200, 25)
    $cmbRes.Items.AddRange(@('Original', '3840 × 2160 (4K)', '1920 × 1080', '1280 × 720', '854 × 480'))
    $cmbRes.SelectedIndex = 0
    $cmbRes.BackColor = $ColorPanel
    $cmbRes.ForeColor = $ColorText
    $tabCustom.Controls.Add($cmbRes)
    
    $yPos += 40
    $lblVBitrate = New-Object System.Windows.Forms.Label
    $lblVBitrate.Text = 'Bitrate (Kbps):'
    $lblVBitrate.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblVBitrate.Size = New-Object System.Drawing.Size(120, 20)
    $tabCustom.Controls.Add($lblVBitrate)
    
    $cmbVBitrate = New-Object System.Windows.Forms.ComboBox
    $cmbVBitrate.Location = New-Object System.Drawing.Point(150, $yPos)
    $cmbVBitrate.Size = New-Object System.Drawing.Size(200, 25)
    $cmbVBitrate.Items.AddRange(@('Original', '2000', '4000', '8000', '16000'))
    $cmbVBitrate.SelectedIndex = 0
    $cmbVBitrate.BackColor = $ColorPanel
    $cmbVBitrate.ForeColor = $ColorText
    $tabCustom.Controls.Add($cmbVBitrate)
    
    # Audio Settings
    $yPos += 50
    $lblACodec = New-Object System.Windows.Forms.Label
    $lblACodec.Text = 'Audio codec:'
    $lblACodec.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblACodec.Size = New-Object System.Drawing.Size(120, 20)
    $tabCustom.Controls.Add($lblACodec)
    
    $cmbACodec = New-Object System.Windows.Forms.ComboBox
    $cmbACodec.Location = New-Object System.Drawing.Point(150, $yPos)
    $cmbACodec.Size = New-Object System.Drawing.Size(200, 25)
    $cmbACodec.Items.AddRange(@('AAC', 'MP3', 'AC3', 'Copy'))
    $cmbACodec.SelectedIndex = 0
    $cmbACodec.BackColor = $ColorPanel
    $cmbACodec.ForeColor = $ColorText
    $tabCustom.Controls.Add($cmbACodec)
    
    $yPos += 40
    $lblSampleRate = New-Object System.Windows.Forms.Label
    $lblSampleRate.Text = 'Sample rate (Hz):'
    $lblSampleRate.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblSampleRate.Size = New-Object System.Drawing.Size(120, 20)
    $tabCustom.Controls.Add($lblSampleRate)
    
    $cmbSampleRate = New-Object System.Windows.Forms.ComboBox
    $cmbSampleRate.Location = New-Object System.Drawing.Point(150, $yPos)
    $cmbSampleRate.Size = New-Object System.Drawing.Size(200, 25)
    $cmbSampleRate.Items.AddRange(@('44100', '48000'))
    $cmbSampleRate.SelectedIndex = 1
    $cmbSampleRate.BackColor = $ColorPanel
    $cmbSampleRate.ForeColor = $ColorText
    $tabCustom.Controls.Add($cmbSampleRate)
    
    $yPos += 40
    $lblChannels = New-Object System.Windows.Forms.Label
    $lblChannels.Text = 'Channels:'
    $lblChannels.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblChannels.Size = New-Object System.Drawing.Size(120, 20)
    $tabCustom.Controls.Add($lblChannels)
    
    $cmbChannels = New-Object System.Windows.Forms.ComboBox
    $cmbChannels.Location = New-Object System.Drawing.Point(150, $yPos)
    $cmbChannels.Size = New-Object System.Drawing.Size(200, 25)
    $cmbChannels.Items.AddRange(@('Stereo', 'Mono', '5.1'))
    $cmbChannels.SelectedIndex = 0
    $cmbChannels.BackColor = $ColorPanel
    $cmbChannels.ForeColor = $ColorText
    $tabCustom.Controls.Add($cmbChannels)
    
    $yPos += 40
    $lblABitrate = New-Object System.Windows.Forms.Label
    $lblABitrate.Text = 'Bitrate (Kbps):'
    $lblABitrate.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblABitrate.Size = New-Object System.Drawing.Size(120, 20)
    $tabCustom.Controls.Add($lblABitrate)
    
    $cmbABitrate = New-Object System.Windows.Forms.ComboBox
    $cmbABitrate.Location = New-Object System.Drawing.Point(150, $yPos)
    $cmbABitrate.Size = New-Object System.Drawing.Size(200, 25)
    $cmbABitrate.Items.AddRange(@('128', '192', '256', '320'))
    $cmbABitrate.SelectedIndex = 0
    $cmbABitrate.BackColor = $ColorPanel
    $cmbABitrate.ForeColor = $ColorText
    $tabCustom.Controls.Add($cmbABitrate)
    
    # Buttons
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = 'OK'
    $btnOK.Location = New-Object System.Drawing.Point(380, 410)
    $btnOK.Size = New-Object System.Drawing.Size(80, 30)
    $btnOK.BackColor = $ColorAccent
    $btnOK.ForeColor = $ColorText
    $btnOK.FlatStyle = 'Flat'
    $btnOK.DialogResult = 'OK'
    $formPreset.Controls.Add($btnOK)
    
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.Location = New-Object System.Drawing.Point(470, 410)
    $btnCancel.Size = New-Object System.Drawing.Size(80, 30)
    $btnCancel.BackColor = $ColorPanel
    $btnCancel.ForeColor = $ColorText
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.DialogResult = 'Cancel'
    $formPreset.Controls.Add($btnCancel)
    
    $formPreset.AcceptButton = $btnOK
    $formPreset.CancelButton = $btnCancel
    
    if($formPreset.ShowDialog() -eq 'OK'){
        Show-Message "Custom preset saved!" "Preset Editor"
    }
}

function Show-EditWindow {
    if($lvTasks.SelectedItems.Count -eq 0){
        Show-Message "Please select a task to edit!" "Edit"
        return
    }
    
    $task = $lvTasks.SelectedItems[0].Tag
    
    $formEdit = New-Object System.Windows.Forms.Form
    $formEdit.Text = "Edit - $($task.FileName)"
    $formEdit.Width = 1024
    $formEdit.Height = 600
    $formEdit.StartPosition = 'CenterScreen'
    $formEdit.BackColor = $ColorBg
    $formEdit.ForeColor = $ColorText
    $formEdit.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    
    # Tool Tabs
    $tabTools = New-Object System.Windows.Forms.TabControl
    $tabTools.Location = New-Object System.Drawing.Point(10, 10)
    $tabTools.Size = New-Object System.Drawing.Size(990, 530)
    $tabTools.BackColor = $ColorPanel
    $tabTools.ForeColor = $ColorText
    $formEdit.Controls.Add($tabTools)
    
    # Subtitles Tab
    $tabSubs = New-Object System.Windows.Forms.TabPage
    $tabSubs.Text = '🅰 Subtitles'
    $tabSubs.BackColor = $ColorBg
    $tabSubs.ForeColor = $ColorText
    $tabTools.Controls.Add($tabSubs)
    
    $lblSubFile = New-Object System.Windows.Forms.Label
    $lblSubFile.Text = 'Subtitle file:'
    $lblSubFile.Location = New-Object System.Drawing.Point(20, 20)
    $lblSubFile.Size = New-Object System.Drawing.Size(100, 20)
    $tabSubs.Controls.Add($lblSubFile)
    
    $txtSubFile = New-Object System.Windows.Forms.TextBox
    $txtSubFile.Location = New-Object System.Drawing.Point(120, 17)
    $txtSubFile.Size = New-Object System.Drawing.Size(600, 25)
    $txtSubFile.BackColor = $ColorPanel
    $txtSubFile.ForeColor = $ColorText
    $txtSubFile.BorderStyle = 'FixedSingle'
    $tabSubs.Controls.Add($txtSubFile)
    
    $btnBrowseSub = New-Object System.Windows.Forms.Button
    $btnBrowseSub.Text = 'Browse'
    $btnBrowseSub.Location = New-Object System.Drawing.Point(730, 15)
    $btnBrowseSub.Size = New-Object System.Drawing.Size(80, 27)
    $btnBrowseSub.BackColor = $ColorAccent
    $btnBrowseSub.ForeColor = $ColorText
    $btnBrowseSub.FlatStyle = 'Flat'
    $tabSubs.Controls.Add($btnBrowseSub)
    
    $btnBrowseSub.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = 'Subtitle Files|*.srt;*.ass;*.ssa|All Files|*.*'
        if($ofd.ShowDialog() -eq 'OK'){
            $txtSubFile.Text = $ofd.FileName
            $task.SubtitlePath = $ofd.FileName
        }
    })
    
    # Style Presets
    $lblStyles = New-Object System.Windows.Forms.Label
    $lblStyles.Text = 'Style presets:'
    $lblStyles.Location = New-Object System.Drawing.Point(20, 60)
    $lblStyles.Size = New-Object System.Drawing.Size(100, 20)
    $tabSubs.Controls.Add($lblStyles)
    
    $panelStyles = New-Object System.Windows.Forms.FlowLayoutPanel
    $panelStyles.Location = New-Object System.Drawing.Point(120, 55)
    $panelStyles.Size = New-Object System.Drawing.Size(700, 40)
    $panelStyles.BackColor = $ColorBg
    $tabSubs.Controls.Add($panelStyles)
    
    $styles = @(
        @{Color='White'; Shadow='Black'},
        @{Color='Lime'; Shadow=''},
        @{Color='Cyan'; Shadow=''},
        @{Color='Yellow'; Shadow=''},
        @{Color='Red'; Shadow=''}
    )
    
    foreach($style in $styles){
        $btnStyle = New-Object System.Windows.Forms.Button
        $btnStyle.Text = 'Sample'
        $btnStyle.Size = New-Object System.Drawing.Size(80, 30)
        $btnStyle.ForeColor = [System.Drawing.Color]::FromName($style.Color)
        $btnStyle.BackColor = $ColorPanel
        $btnStyle.FlatStyle = 'Flat'
        $panelStyles.Controls.Add($btnStyle)
    }
    
    # Transparency slider
    $lblTrans = New-Object System.Windows.Forms.Label
    $lblTrans.Text = 'Transparency:'
    $lblTrans.Location = New-Object System.Drawing.Point(20, 110)
    $lblTrans.Size = New-Object System.Drawing.Size(100, 20)
    $tabSubs.Controls.Add($lblTrans)
    
    $trackTrans = New-Object System.Windows.Forms.TrackBar
    $trackTrans.Location = New-Object System.Drawing.Point(120, 105)
    $trackTrans.Size = New-Object System.Drawing.Size(400, 45)
    $trackTrans.Minimum = 0
    $trackTrans.Maximum = 100
    $trackTrans.Value = 0
    $trackTrans.TickFrequency = 10
    $trackTrans.BackColor = $ColorBg
    $tabSubs.Controls.Add($trackTrans)
    
    # Position slider
    $lblPos = New-Object System.Windows.Forms.Label
    $lblPos.Text = 'Position:'
    $lblPos.Location = New-Object System.Drawing.Point(20, 160)
    $lblPos.Size = New-Object System.Drawing.Size(100, 20)
    $tabSubs.Controls.Add($lblPos)
    
    $trackPos = New-Object System.Windows.Forms.TrackBar
    $trackPos.Location = New-Object System.Drawing.Point(120, 155)
    $trackPos.Size = New-Object System.Drawing.Size(400, 45)
    $trackPos.Minimum = 0
    $trackPos.Maximum = 100
    $trackPos.Value = 17
    $trackPos.TickFrequency = 10
    $trackPos.BackColor = $ColorBg
    $tabSubs.Controls.Add($trackPos)
    
    $btnTop = New-Object System.Windows.Forms.Button
    $btnTop.Text = 'Top'
    $btnTop.Location = New-Object System.Drawing.Point(120, 200)
    $btnTop.Size = New-Object System.Drawing.Size(70, 25)
    $btnTop.BackColor = $ColorPanel
    $btnTop.ForeColor = $ColorText
    $btnTop.FlatStyle = 'Flat'
    $tabSubs.Controls.Add($btnTop)
    
    $btnMiddle = New-Object System.Windows.Forms.Button
    $btnMiddle.Text = 'Middle'
    $btnMiddle.Location = New-Object System.Drawing.Point(200, 200)
    $btnMiddle.Size = New-Object System.Drawing.Size(70, 25)
    $btnMiddle.BackColor = $ColorPanel
    $btnMiddle.ForeColor = $ColorText
    $btnMiddle.FlatStyle = 'Flat'
    $tabSubs.Controls.Add($btnMiddle)
    
    $btnBottom = New-Object System.Windows.Forms.Button
    $btnBottom.Text = 'Bottom'
    $btnBottom.Location = New-Object System.Drawing.Point(280, 200)
    $btnBottom.Size = New-Object System.Drawing.Size(70, 25)
    $btnBottom.BackColor = $ColorPanel
    $btnBottom.ForeColor = $ColorText
    $btnBottom.FlatStyle = 'Flat'
    $tabSubs.Controls.Add($btnBottom)
    
    $btnReset = New-Object System.Windows.Forms.Button
    $btnReset.Text = 'Reset'
    $btnReset.Location = New-Object System.Drawing.Point(360, 200)
    $btnReset.Size = New-Object System.Drawing.Size(70, 25)
    $btnReset.BackColor = $ColorPanel
    $btnReset.ForeColor = $ColorText
    $btnReset.FlatStyle = 'Flat'
    $tabSubs.Controls.Add($btnReset)
    
    # Watermark Tab
    $tabWatermark = New-Object System.Windows.Forms.TabPage
    $tabWatermark.Text = '🖼 Watermark'
    $tabWatermark.BackColor = $ColorBg
    $tabWatermark.ForeColor = $ColorText
    $tabTools.Controls.Add($tabWatermark)
    
    $lblWMFile = New-Object System.Windows.Forms.Label
    $lblWMFile.Text = 'Watermark (PNG):'
    $lblWMFile.Location = New-Object System.Drawing.Point(20, 20)
    $lblWMFile.Size = New-Object System.Drawing.Size(120, 20)
    $tabWatermark.Controls.Add($lblWMFile)
    
    $txtWMFile = New-Object System.Windows.Forms.TextBox
    $txtWMFile.Location = New-Object System.Drawing.Point(140, 17)
    $txtWMFile.Size = New-Object System.Drawing.Size(580, 25)
    $txtWMFile.BackColor = $ColorPanel
    $txtWMFile.ForeColor = $ColorText
    $txtWMFile.BorderStyle = 'FixedSingle'
    $tabWatermark.Controls.Add($txtWMFile)
    
    $btnBrowseWM = New-Object System.Windows.Forms.Button
    $btnBrowseWM.Text = 'Browse'
    $btnBrowseWM.Location = New-Object System.Drawing.Point(730, 15)
    $btnBrowseWM.Size = New-Object System.Drawing.Size(80, 27)
    $btnBrowseWM.BackColor = $ColorAccent
    $btnBrowseWM.ForeColor = $ColorText
    $btnBrowseWM.FlatStyle = 'Flat'
    $tabWatermark.Controls.Add($btnBrowseWM)
    
    $btnBrowseWM.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = 'Image Files|*.png;*.jpg;*.jpeg|All Files|*.*'
        if($ofd.ShowDialog() -eq 'OK'){
            $txtWMFile.Text = $ofd.FileName
            $task.WatermarkPath = $ofd.FileName
        }
    })
    
    # Position coordinates
    $lblCoords = New-Object System.Windows.Forms.Label
    $lblCoords.Text = 'Position:'
    $lblCoords.Location = New-Object System.Drawing.Point(20, 60)
    $lblCoords.Size = New-Object System.Drawing.Size(100, 20)
    $tabWatermark.Controls.Add($lblCoords)
    
    $txtX = New-Object System.Windows.Forms.TextBox
    $txtX.Location = New-Object System.Drawing.Point(140, 57)
    $txtX.Size = New-Object System.Drawing.Size(60, 25)
    $txtX.Text = '10'
    $txtX.BackColor = $ColorPanel
    $txtX.ForeColor = $ColorText
    $txtX.BorderStyle = 'FixedSingle'
    $tabWatermark.Controls.Add($txtX)
    
    $lblXLabel = New-Object System.Windows.Forms.Label
    $lblXLabel.Text = 'X'
    $lblXLabel.Location = New-Object System.Drawing.Point(120, 60)
    $lblXLabel.Size = New-Object System.Drawing.Size(15, 20)
    $tabWatermark.Controls.Add($lblXLabel)
    
    $txtY = New-Object System.Windows.Forms.TextBox
    $txtY.Location = New-Object System.Drawing.Point(230, 57)
    $txtY.Size = New-Object System.Drawing.Size(60, 25)
    $txtY.Text = '10'
    $txtY.BackColor = $ColorPanel
    $txtY.ForeColor = $ColorText
    $txtY.BorderStyle = 'FixedSingle'
    $tabWatermark.Controls.Add($txtY)
    
    $lblYLabel = New-Object System.Windows.Forms.Label
    $lblYLabel.Text = 'Y'
    $lblYLabel.Location = New-Object System.Drawing.Point(210, 60)
    $lblYLabel.Size = New-Object System.Drawing.Size(15, 20)
    $tabWatermark.Controls.Add($lblYLabel)
    
    $txtW = New-Object System.Windows.Forms.TextBox
    $txtW.Location = New-Object System.Drawing.Point(320, 57)
    $txtW.Size = New-Object System.Drawing.Size(60, 25)
    $txtW.Text = '200'
    $txtW.BackColor = $ColorPanel
    $txtW.ForeColor = $ColorText
    $txtW.BorderStyle = 'FixedSingle'
    $tabWatermark.Controls.Add($txtW)
    
    $lblWLabel = New-Object System.Windows.Forms.Label
    $lblWLabel.Text = 'W'
    $lblWLabel.Location = New-Object System.Drawing.Point(300, 60)
    $lblWLabel.Size = New-Object System.Drawing.Size(15, 20)
    $tabWatermark.Controls.Add($lblWLabel)
    
    $txtH = New-Object System.Windows.Forms.TextBox
    $txtH.Location = New-Object System.Drawing.Point(410, 57)
    $txtH.Size = New-Object System.Drawing.Size(60, 25)
    $txtH.Text = '200'
    $txtH.BackColor = $ColorPanel
    $txtH.ForeColor = $ColorText
    $txtH.BorderStyle = 'FixedSingle'
    $tabWatermark.Controls.Add($txtH)
    
    $lblHLabel = New-Object System.Windows.Forms.Label
    $lblHLabel.Text = 'H'
    $lblHLabel.Location = New-Object System.Drawing.Point(390, 60)
    $lblHLabel.Size = New-Object System.Drawing.Size(15, 20)
    $tabWatermark.Controls.Add($lblHLabel)
    
    # Opacity
    $lblOpacity = New-Object System.Windows.Forms.Label
    $lblOpacity.Text = 'Opacity:'
    $lblOpacity.Location = New-Object System.Drawing.Point(20, 100)
    $lblOpacity.Size = New-Object System.Drawing.Size(100, 20)
    $tabWatermark.Controls.Add($lblOpacity)
    
    $trackOpacity = New-Object System.Windows.Forms.TrackBar
    $trackOpacity.Location = New-Object System.Drawing.Point(140, 95)
    $trackOpacity.Size = New-Object System.Drawing.Size(400, 45)
    $trackOpacity.Minimum = 0
    $trackOpacity.Maximum = 100
    $trackOpacity.Value = 80
    $trackOpacity.TickFrequency = 10
    $trackOpacity.BackColor = $ColorBg
    $tabWatermark.Controls.Add($trackOpacity)
    
    # Close button
    $btnCloseEdit = New-Object System.Windows.Forms.Button
    $btnCloseEdit.Text = 'Apply & Close'
    $btnCloseEdit.Location = New-Object System.Drawing.Point(850, 550)
    $btnCloseEdit.Size = New-Object System.Drawing.Size(140, 35)
    $btnCloseEdit.BackColor = $ColorAccent
    $btnCloseEdit.ForeColor = $ColorText
    $btnCloseEdit.FlatStyle = 'Flat'
    $btnCloseEdit.DialogResult = 'OK'
    $formEdit.Controls.Add($btnCloseEdit)
    
    $formEdit.AcceptButton = $btnCloseEdit
    [void]$formEdit.ShowDialog()
}

# ============================================
# EVENT HANDLERS
# ============================================

# Add files (Drag & Drop or Browse)
$lvTasks.AllowDrop = $true
$lvTasks.Add_DragEnter({
    param($sender, $e)
    if($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)){
        $e.Effect = 'Copy'
    }
})

$lvTasks.Add_DragDrop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    foreach($file in $files){
        Add-Task $file
    }
})

$lvTasks.Add_DoubleClick({
    Show-EditWindow
})

# Browse for files (right-click on empty space)
$lvTasks.Add_KeyDown({
    param($sender, $e)
    if($e.KeyCode -eq 'Insert'){
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Multiselect = $true
        $ofd.Filter = 'Video Files|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.flv;*.webm|All Files|*.*'
        if($ofd.ShowDialog() -eq 'OK'){
            foreach($f in $ofd.FileNames){
                Add-Task $f
            }
        }
    }
})

# Clear all tasks
$btnClearAll.Add_Click({
    $lvTasks.Items.Clear()
    $script:Tasks = @()
})

# Remove selected tasks
$btnRemoveSelected.Add_Click({
    foreach($item in $lvTasks.SelectedItems){
        $lvTasks.Items.Remove($item)
    }
})

# Browse output folder
$btnBrowseOutput.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $script:OutputPath
    if($fbd.ShowDialog() -eq 'OK'){
        $script:OutputPath = $fbd.SelectedPath
        $txtOutput.Text = $fbd.SelectedPath
    }
})

# Open output folder
$btnOpenFolder.Add_Click({
    if(Test-Path $script:OutputPath){
        Start-Process explorer.exe $script:OutputPath
    } else {
        Show-Message "Output folder does not exist: $($script:OutputPath)" "Error"
    }
})

# Settings button
$btnSettings.Add_Click({
    Show-PresetEditor
})

# Context menu - Edit
$menuEdit.Add_Click({
    Show-EditWindow
})

# Context menu - Preset Editor
$menuPreset.Add_Click({
    Show-PresetEditor
})

# Context menu - Remove
$menuRemove.Add_Click({
    foreach($item in $lvTasks.SelectedItems){
        $lvTasks.Items.Remove($item)
    }
})

# Convert button
$btnConvert.Add_Click({
    if($lvTasks.Items.Count -eq 0){
        Show-Message 'Please add at least one file!' 'No Files'
        return
    }
    if($cmbProfile.SelectedIndex -lt 0){
        Show-Message 'Please select a conversion profile!' 'No Profile'
        return
    }
    
    # Disable UI
    $btnConvert.Enabled = $false
    $btnClearAll.Enabled = $false
    $btnRemoveSelected.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    
    $p = $Config.profiles[$cmbProfile.SelectedIndex]
    $total = $lvTasks.Items.Count
    $current = 0
    $okCount = 0
    $failCount = 0
    
    Write-Log "========================================" Write-Log "Starting conversion..."
    Write-Log "Profile: $($p.name)"
    Write-Log "Total files: $total"
    Write-Log "========================================"
    
    # Install binaries if needed
    $ffmpeg = Join-Path $Bins "ffmpeg.exe"
    $handbrake = Join-Path $Bins "HandBrakeCLI.exe"
    
    if(-not (Test-Path $ffmpeg)){
        Write-Log "Installing FFmpeg..."
        $ffmpeg = Install-FFTools
    }
    
    if($p.engine -eq 'handbrake' -and -not (Test-Path $handbrake)){
        Write-Log "Installing HandBrake..."
        Install-HandBrake
    }
    
    # Process each task
    foreach($item in $lvTasks.Items){
        $current++
        $task = $item.Tag
        $percent = [math]::Round(($current / $total) * 100, 1)
        
        $item.SubItems[7].Text = "Processing... $percent%"
        Write-Log "[$current/$total] Processing: $($task.FileName)"
        $form.Refresh()
        
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($task.FilePath)
        $outputFile = Join-Path $script:OutputPath "$fileName.$($p.format)"
        
        # Ensure output directory exists
        $outDir = Split-Path -Parent $outputFile
        if($outDir -and -not (Test-Path $outDir)){
            New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        }
        
        try {
            # Apply watermark if set
            $processedInput = $task.FilePath
            if($task.WatermarkPath){
                Write-Log "  Applying watermark..."
                $wmTemp = Join-Path $Temp "$fileName-wm.mp4"
                $wmArgs = @(
                    '-i', $task.FilePath,
                    '-i', $task.WatermarkPath,
                    '-filter_complex', 'overlay=W-w-10:H-h-10',
                    '-c:a', 'copy',
                    '-y', $wmTemp
                )
                & $ffmpeg @wmArgs 2>&1 | Out-Null
                $processedInput = $wmTemp
            }
            
            # Apply subtitles if set
            if($task.SubtitlePath){
                Write-Log "  Burning subtitles..."
                $subTemp = Join-Path $Temp "$fileName-sub.mp4"
                $subArgs = @(
                    '-i', $processedInput,
                    '-vf', "subtitles='$($task.SubtitlePath -replace '\\','/')'",
                    '-c:a', 'copy',
                    '-y', $subTemp
                )
                & $ffmpeg @subArgs 2>&1 | Out-Null
                $processedInput = $subTemp
            }
            
            # Main conversion
            Write-Log "  Converting with $($p.engine)..."
            
            if($p.engine -eq 'ffmpeg'){
                $ffArgs = @('-i', $processedInput) + $p.args.Split(' ') + @('-y', $outputFile)
                $proc = Start-Process -FilePath $ffmpeg -ArgumentList $ffArgs -NoNewWindow -PassThru -Wait
                
                if($proc.ExitCode -eq 0 -and (Test-Path $outputFile)){
                    $fi = Get-Item -LiteralPath $outputFile
                    if($fi.Length -gt 0){
                        $item.SubItems[7].Text = "Success"
                        Write-Log "  Success - $([math]::Round($fi.Length/1MB, 2)) MB"
                        $okCount++
                    } else {
                        $item.SubItems[7].Text = "Failed (empty)"
                        Write-Log "  Failed - output empty"
                        $failCount++
                    }
                } else {
                    $item.SubItems[7].Text = "Failed"
                    Write-Log "  Failed - exit code: $($proc.ExitCode)"
                    $failCount++
                }
            } elseif($p.engine -eq 'handbrake'){
                $hbArgs = @('-i', $processedInput, '-o', $outputFile) + $p.args.Split(' ')
                $proc = Start-Process -FilePath $handbrake -ArgumentList $hbArgs -NoNewWindow -PassThru -Wait
                
                if($proc.ExitCode -eq 0 -and (Test-Path $outputFile)){
                    $fi = Get-Item -LiteralPath $outputFile
                    if($fi.Length -gt 0){
                        $item.SubItems[7].Text = "Success"
                        Write-Log "  Success - $([math]::Round($fi.Length/1MB, 2)) MB"
                        $okCount++
                    } else {
                        $item.SubItems[7].Text = "Failed (empty)"
                        Write-Log "  Failed - output empty"
                        $failCount++
                    }
                } else {
                    $item.SubItems[7].Text = "Failed"
                    Write-Log "  Failed - exit code: $($proc.ExitCode)"
                    $failCount++
                }
            }
            
            # Cleanup temp files
            if($task.WatermarkPath -and (Test-Path $wmTemp)){ Remove-Item $wmTemp -Force }
            if($task.SubtitlePath -and (Test-Path $subTemp)){ Remove-Item $subTemp -Force }
            
        } catch {
            $item.SubItems[7].Text = "Error"
            Write-Log "  Error: $($_.Exception.Message)"
            $failCount++
        }
        
        $form.Refresh()
    }
    
    Write-Log "========================================"
    Write-Log "Conversion complete!"
    Write-Log "Successful: $okCount | Failed: $failCount"
    Write-Log "========================================"
    
    # Re-enable UI
    $btnConvert.Enabled = $true
    $btnClearAll.Enabled = $true
    $btnRemoveSelected.Enabled = $true
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
    
    Show-Message "Conversion complete!`n`nSuccessful: $okCount`nFailed: $failCount" "Done"
})

# Populate profiles
foreach($p in $Config.profiles){ 
    [void]$cmbProfile.Items.Add($p.name) 
}
if($cmbProfile.Items.Count -gt 0){ 
    $cmbProfile.SelectedIndex = 0 
}

# Show form
Write-Log "Professional Portable Converter - Ultimate Edition started"
[void]$form.ShowDialog()
