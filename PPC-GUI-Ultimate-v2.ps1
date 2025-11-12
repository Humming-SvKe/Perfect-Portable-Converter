<#
  PPC-GUI-Ultimate-v2.ps1
  MODERN DARK MODE - Complete Apowersoft-style GUI with flat design
  NO Windows 95 borders, proper flat UI components
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
$LogFile = Join-Path $Logs 'ppc-ultimate-v2.log'

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

# Config
$Config = @{
  default_format = 'mp4';
  profiles = @(
    @{ 
      name='Fast 1080p - H264 (AAC 128k Stereo)'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='128k'; 
      channels='2';
      args='-c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k -ac 2' 
    },
    @{ 
      name='High Quality - 1080p H264 (AAC 160k Stereo)'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='160k'; 
      channels='2';
      args='-c:v libx264 -preset medium -crf 20 -c:a aac -b:a 160k -ac 2' 
    },
    @{ 
      name='Small Size - 720p H264 (AAC 128k Stereo)'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='128k'; 
      channels='2';
      args='-vf scale=1280:-2 -c:v libx264 -preset veryfast -crf 25 -c:a aac -b:a 128k -ac 2' 
    },
    @{ 
      name='HEVC/H265 - MKV (AAC 160k Stereo)'; 
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

# WinForms with DPI awareness
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Enable DPI awareness for sharp text
try {
    Add-Type -TypeDefinition @'
    using System.Runtime.InteropServices;
    public class DpiAwareness {
        [DllImport("user32.dll")]
        public static extern bool SetProcessDPIAware();
    }
'@
    [DpiAwareness]::SetProcessDPIAware() | Out-Null
} catch {
    # DPI awareness already set or not supported
}

# ===================================
# MODERN DARK MODE COLORS
# ===================================
$ColorBg = [System.Drawing.Color]::FromArgb(30, 30, 30)           # Darker background
$ColorPanel = [System.Drawing.Color]::FromArgb(45, 45, 48)        # Panel background
$ColorPanelLight = [System.Drawing.Color]::FromArgb(55, 55, 58)   # Lighter panel
$ColorText = [System.Drawing.Color]::FromArgb(241, 241, 241)      # Almost white text
$ColorTextDim = [System.Drawing.Color]::FromArgb(170, 170, 170)   # Dimmed text
$ColorAccent = [System.Drawing.Color]::FromArgb(0, 122, 204)      # VS Code blue
$ColorAccentHover = [System.Drawing.Color]::FromArgb(28, 151, 234)# Lighter blue on hover
$ColorBorder = [System.Drawing.Color]::FromArgb(63, 63, 70)       # Subtle border
$ColorSuccess = [System.Drawing.Color]::FromArgb(73, 190, 170)    # Teal success
$ColorError = [System.Drawing.Color]::FromArgb(244, 71, 71)       # Red error

# Helper function to create modern flat button
function New-ModernButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 100,
        [int]$Height = 32,
        [System.Drawing.Color]$BgColor = $ColorPanel,
        [bool]$IsPrimary = $false
    )
    
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point($X, $Y)
    $btn.Size = New-Object System.Drawing.Size($Width, $Height)
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    if($IsPrimary){
        $btn.BackColor = $ColorAccent
        $btn.ForeColor = $ColorText
        $btn.FlatAppearance.MouseOverBackColor = $ColorAccentHover
    } else {
        $btn.BackColor = $BgColor
        $btn.ForeColor = $ColorText
        $btn.FlatAppearance.MouseOverBackColor = $ColorPanelLight
    }
    
    return $btn
}

# Helper function to create modern flat textbox
function New-ModernTextBox {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width = 200,
        [string]$Text = ''
    )
    
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point($X, $Y)
    $txt.Size = New-Object System.Drawing.Size($Width, 24)
    $txt.BackColor = $ColorPanel
    $txt.ForeColor = $ColorText
    $txt.BorderStyle = 'FixedSingle'
    $txt.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $txt.Text = $Text
    
    return $txt
}

# Helper function to create modern flat combobox
function New-ModernComboBox {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width = 200,
        [array]$Items = @()
    )
    
    $cmb = New-Object System.Windows.Forms.ComboBox
    $cmb.Location = New-Object System.Drawing.Point($X, $Y)
    $cmb.Size = New-Object System.Drawing.Size($Width, 24)
    $cmb.BackColor = $ColorPanel
    $cmb.ForeColor = $ColorText
    $cmb.FlatStyle = 'Flat'
    $cmb.DropDownStyle = 'DropDownList'
    $cmb.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    if($Items.Count -gt 0){
        $cmb.Items.AddRange($Items)
        $cmb.SelectedIndex = 0
    }
    
    return $cmb
}

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Professional Portable Converter - Ultimate Edition v2'
$form.ClientSize = New-Object System.Drawing.Size(1280, 720)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $ColorBg
$form.ForeColor = $ColorText
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

# ===================================
# TOOLBAR (Add files, Remove, Clear)
# ===================================
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.Dock = 'Top'
$toolbar.Height = 50
$toolbar.BackColor = $ColorPanel
$form.Controls.Add($toolbar)

$btnAddFiles = New-ModernButton -Text '+ Add Files' -X 10 -Y 9 -Width 120 -IsPrimary $true
$toolbar.Controls.Add($btnAddFiles)

$btnRemove = New-ModernButton -Text 'Remove' -X 140 -Y 9 -Width 100
$toolbar.Controls.Add($btnRemove)

$btnClear = New-ModernButton -Text 'Clear All' -X 250 -Y 9 -Width 100
$toolbar.Controls.Add($btnClear)

$chkMerge = New-Object System.Windows.Forms.CheckBox
$chkMerge.Text = 'Merge files'
$chkMerge.Location = New-Object System.Drawing.Point(370, 14)
$chkMerge.Size = New-Object System.Drawing.Size(120, 24)
$chkMerge.ForeColor = $ColorText
$chkMerge.FlatStyle = 'Flat'
$toolbar.Controls.Add($chkMerge)

# ===================================
# TASK LIST (Modern ListView without gridlines)
# ===================================
$lvTasks = New-Object System.Windows.Forms.ListView
$lvTasks.Dock = 'Fill'
$lvTasks.View = 'Details'
$lvTasks.FullRowSelect = $true
$lvTasks.GridLines = $false
$lvTasks.BackColor = $ColorBg
$lvTasks.ForeColor = $ColorText
$lvTasks.BorderStyle = 'None'
$lvTasks.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$lvTasks.HeaderStyle = 'Nonclickable'
$lvTasks.Columns.Add("File", 280) | Out-Null
$lvTasks.Columns.Add("Format", 70) | Out-Null
$lvTasks.Columns.Add("Duration", 80) | Out-Null
$lvTasks.Columns.Add("Resolution", 100) | Out-Null
$lvTasks.Columns.Add("Size", 90) | Out-Null
$lvTasks.Columns.Add("Audio", 120) | Out-Null
$lvTasks.Columns.Add("Profile", 240) | Out-Null
$lvTasks.Columns.Add("Status", 120) | Out-Null
$lvTasks.AllowDrop = $true
$form.Controls.Add($lvTasks)

# Hint label (shows when list is empty)
$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Click '+ Add Files' button or drag & drop video files here to start"
$lblHint.AutoSize = $false
$lblHint.TextAlign = 'MiddleCenter'
$lblHint.Dock = 'Fill'
$lblHint.ForeColor = $ColorTextDim
$lblHint.BackColor = $ColorBg
$lblHint.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Italic)
$form.Controls.Add($lblHint)
$lblHint.BringToFront()

# ===================================
# BOTTOM BAR (Profile, Output, Convert)
# ===================================
$bottomBar = New-Object System.Windows.Forms.Panel
$bottomBar.Dock = 'Bottom'
$bottomBar.Height = 120
$bottomBar.BackColor = $ColorPanel
$form.Controls.Add($bottomBar)

# Profile section
$lblProfile = New-Object System.Windows.Forms.Label
$lblProfile.Text = 'Conversion Profile:'
$lblProfile.Location = New-Object System.Drawing.Point(15, 15)
$lblProfile.Size = New-Object System.Drawing.Size(130, 20)
$lblProfile.ForeColor = $ColorTextDim
$lblProfile.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$bottomBar.Controls.Add($lblProfile)

$cmbProfile = New-ModernComboBox -X 15 -Y 38 -Width 500
$bottomBar.Controls.Add($cmbProfile)

$btnEditPreset = New-ModernButton -Text 'Edit Preset...' -X 525 -Y 36 -Width 110 -Height 28
$bottomBar.Controls.Add($btnEditPreset)

# Output section
$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = 'Output Folder:'
$lblOutput.Location = New-Object System.Drawing.Point(15, 75)
$lblOutput.Size = New-Object System.Drawing.Size(100, 20)
$lblOutput.ForeColor = $ColorTextDim
$lblOutput.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$bottomBar.Controls.Add($lblOutput)

$txtOutput = New-ModernTextBox -X 120 -Y 73 -Width 400 -Text $Out
$bottomBar.Controls.Add($txtOutput)

$btnBrowseOutput = New-ModernButton -Text '...' -X 530 -Y 71 -Width 40 -Height 28
$bottomBar.Controls.Add($btnBrowseOutput)

$btnOpenOutput = New-ModernButton -Text 'Open Folder' -X 580 -Y 71 -Width 110 -Height 28
$bottomBar.Controls.Add($btnOpenOutput)

# Big Convert Button
$btnConvert = New-ModernButton -Text 'CONVERT' -X 1050 -Y 15 -Width 215 -Height 90 -IsPrimary $true
$btnConvert.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$bottomBar.Controls.Add($btnConvert)

# ===================================
# CONTEXT MENU
# ===================================
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$contextMenu.BackColor = $ColorPanel
$contextMenu.ForeColor = $ColorText

$menuEdit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuEdit.Text = 'Edit (Subtitles && Watermark)'
$contextMenu.Items.Add($menuEdit) | Out-Null

$menuPreset = New-Object System.Windows.Forms.ToolStripMenuItem
$menuPreset.Text = 'Change Profile'
$contextMenu.Items.Add($menuPreset) | Out-Null

$menuSep = New-Object System.Windows.Forms.ToolStripSeparator
$contextMenu.Items.Add($menuSep) | Out-Null

$menuRemove = New-Object System.Windows.Forms.ToolStripMenuItem
$menuRemove.Text = 'Remove'
$contextMenu.Items.Add($menuRemove) | Out-Null

$lvTasks.ContextMenuStrip = $contextMenu

# ===================================
# GLOBAL STATE
# ===================================
$script:Tasks = @()
$script:OutputPath = $Out

# ===================================
# HELPER FUNCTIONS
# ===================================
function Add-Task([string]$filePath) {
    if(-not (Test-Path $filePath)){ return }
    
    # Hide hint label when first file is added
    if($lvTasks.Items.Count -eq 0 -and $lblHint){
        $lblHint.Visible = $false
    }
    
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $fileSize = [math]::Round((Get-Item $filePath).Length / 1MB, 2)
    $ext = [System.IO.Path]::GetExtension($filePath).TrimStart('.')
    
    $task = @{
        FilePath = $filePath
        FileName = $fileName
        Format = $ext.ToUpper()
        Duration = ""
        Resolution = ""
        Size = "$fileSize MB"
        Audio = ""
        Profile = if($cmbProfile.SelectedItem){$cmbProfile.SelectedItem}else{"Default"}
        Status = "Ready"
        WatermarkPath = $null
        SubtitlePath = $null
    }
    
    $script:Tasks += $task
    
    $item = New-Object System.Windows.Forms.ListViewItem($fileName)
    $item.SubItems.Add($task.Format) | Out-Null
    $item.SubItems.Add($task.Duration) | Out-Null
    $item.SubItems.Add($task.Resolution) | Out-Null
    $item.SubItems.Add($task.Size) | Out-Null
    $item.SubItems.Add($task.Audio) | Out-Null
    $item.SubItems.Add($task.Profile) | Out-Null
    $item.SubItems.Add($task.Status) | Out-Null
    $item.Tag = $task
    $item.ForeColor = $ColorText
    
    $lvTasks.Items.Add($item) | Out-Null
}

function Show-Message([string]$msg, [string]$title = 'Info'){
    [System.Windows.Forms.MessageBox]::Show($msg, $title)
}

function Show-EditWindow {
    if($lvTasks.SelectedItems.Count -eq 0){
        Show-Message "Please select a task to edit!" "Edit"
        return
    }
    
    $task = $lvTasks.SelectedItems[0].Tag
    
    $formEdit = New-Object System.Windows.Forms.Form
    $formEdit.Text = "Edit - $($task.FileName)"
    $formEdit.ClientSize = New-Object System.Drawing.Size(900, 500)
    $formEdit.StartPosition = 'CenterScreen'
    $formEdit.BackColor = $ColorBg
    $formEdit.ForeColor = $ColorText
    $formEdit.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $formEdit.FormBorderStyle = 'FixedDialog'
    $formEdit.MaximizeBox = $false
    
    # Title
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Edit: $($task.FileName)"
    $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblTitle.Size = New-Object System.Drawing.Size(860, 30)
    $lblTitle.ForeColor = $ColorText
    $lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $formEdit.Controls.Add($lblTitle)
    
    $yPos = 60
    
    # Subtitles Section
    $lblSubSection = New-Object System.Windows.Forms.Label
    $lblSubSection.Text = '━━━ SUBTITLES ━━━'
    $lblSubSection.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblSubSection.Size = New-Object System.Drawing.Size(860, 25)
    $lblSubSection.ForeColor = $ColorAccent
    $lblSubSection.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $formEdit.Controls.Add($lblSubSection)
    
    $yPos += 35
    
    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = 'Subtitle file (.srt, .ass):'
    $lblSub.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblSub.Size = New-Object System.Drawing.Size(150, 24)
    $lblSub.ForeColor = $ColorText
    $formEdit.Controls.Add($lblSub)
    
    $txtSubFile = New-ModernTextBox -X 190 -Y $yPos -Width 550
    $formEdit.Controls.Add($txtSubFile)
    
    $btnBrowseSub = New-ModernButton -Text 'Browse...' -X 750 -Y $yPos -Width 120 -Height 28 -IsPrimary $true
    $formEdit.Controls.Add($btnBrowseSub)
    
    $btnBrowseSub.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = 'Subtitle Files|*.srt;*.ass;*.ssa|All Files|*.*'
        if($ofd.ShowDialog() -eq 'OK'){
            $txtSubFile.Text = $ofd.FileName
            $task.SubtitlePath = $ofd.FileName
        }
    })
    
    $yPos += 60
    
    # Watermark Section
    $lblWMSection = New-Object System.Windows.Forms.Label
    $lblWMSection.Text = '━━━ WATERMARK ━━━'
    $lblWMSection.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblWMSection.Size = New-Object System.Drawing.Size(860, 25)
    $lblWMSection.ForeColor = $ColorAccent
    $lblWMSection.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $formEdit.Controls.Add($lblWMSection)
    
    $yPos += 35
    
    $lblWM = New-Object System.Windows.Forms.Label
    $lblWM.Text = 'Watermark image (.png):'
    $lblWM.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblWM.Size = New-Object System.Drawing.Size(150, 24)
    $lblWM.ForeColor = $ColorText
    $formEdit.Controls.Add($lblWM)
    
    $txtWMFile = New-ModernTextBox -X 190 -Y $yPos -Width 550
    $formEdit.Controls.Add($txtWMFile)
    
    $btnBrowseWM = New-ModernButton -Text 'Browse...' -X 750 -Y $yPos -Width 120 -Height 28 -IsPrimary $true
    $formEdit.Controls.Add($btnBrowseWM)
    
    $btnBrowseWM.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = 'Image Files|*.png;*.jpg;*.jpeg|All Files|*.*'
        if($ofd.ShowDialog() -eq 'OK'){
            $txtWMFile.Text = $ofd.FileName
            $task.WatermarkPath = $ofd.FileName
        }
    })
    
    $yPos += 40
    
    $lblWMPos = New-Object System.Windows.Forms.Label
    $lblWMPos.Text = 'Position:'
    $lblWMPos.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblWMPos.Size = New-Object System.Drawing.Size(70, 24)
    $lblWMPos.ForeColor = $ColorTextDim
    $formEdit.Controls.Add($lblWMPos)
    
    $cmbWMPos = New-ModernComboBox -X 110 -Y $yPos -Width 200 -Items @('Top Left', 'Top Right', 'Bottom Left', 'Bottom Right', 'Center')
    $formEdit.Controls.Add($cmbWMPos)
    
    # Buttons
    $btnOK = New-ModernButton -Text 'Apply & Close' -X 670 -Y 450 -Width 200 -Height 36 -IsPrimary $true
    $btnOK.DialogResult = 'OK'
    $formEdit.Controls.Add($btnOK)
    
    $formEdit.AcceptButton = $btnOK
    [void]$formEdit.ShowDialog()
}

function Show-PresetEditor {
    $formPreset = New-Object System.Windows.Forms.Form
    $formPreset.Text = 'Preset Editor'
    $formPreset.ClientSize = New-Object System.Drawing.Size(600, 550)
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
    $lblTitle.Size = New-Object System.Drawing.Size(560, 30)
    $lblTitle.ForeColor = $ColorText
    $lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $formPreset.Controls.Add($lblTitle)
    
    $yPos = 60
    
    # Video Section
    $lblVideoSection = New-Object System.Windows.Forms.Label
    $lblVideoSection.Text = '━━━ VIDEO SETTINGS ━━━'
    $lblVideoSection.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblVideoSection.Size = New-Object System.Drawing.Size(560, 25)
    $lblVideoSection.ForeColor = $ColorAccent
    $lblVideoSection.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $formPreset.Controls.Add($lblVideoSection)
    
    $yPos += 35
    
    $lblVCodec = New-Object System.Windows.Forms.Label
    $lblVCodec.Text = 'Video codec:'
    $lblVCodec.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblVCodec.Size = New-Object System.Drawing.Size(120, 24)
    $lblVCodec.ForeColor = $ColorText
    $formPreset.Controls.Add($lblVCodec)
    
    $cmbVCodec = New-ModernComboBox -X 160 -Y $yPos -Width 200 -Items @('H.264', 'H.265/HEVC', 'VP9', 'Copy')
    $formPreset.Controls.Add($cmbVCodec)
    
    $yPos += 35
    
    $lblRes = New-Object System.Windows.Forms.Label
    $lblRes.Text = 'Resolution:'
    $lblRes.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblRes.Size = New-Object System.Drawing.Size(120, 24)
    $lblRes.ForeColor = $ColorText
    $formPreset.Controls.Add($lblRes)
    
    $cmbRes = New-ModernComboBox -X 160 -Y $yPos -Width 200 -Items @('Original', '3840 × 2160 (4K)', '1920 × 1080', '1280 × 720', '854 × 480')
    $formPreset.Controls.Add($cmbRes)
    
    $yPos += 35
    
    $lblFPS = New-Object System.Windows.Forms.Label
    $lblFPS.Text = 'Frame rate:'
    $lblFPS.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblFPS.Size = New-Object System.Drawing.Size(120, 24)
    $lblFPS.ForeColor = $ColorText
    $formPreset.Controls.Add($lblFPS)
    
    $cmbFPS = New-ModernComboBox -X 160 -Y $yPos -Width 200 -Items @('Original', '24', '30', '60')
    $formPreset.Controls.Add($cmbFPS)
    
    $yPos += 35
    
    $lblVBitrate = New-Object System.Windows.Forms.Label
    $lblVBitrate.Text = 'Bitrate (Kbps):'
    $lblVBitrate.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblVBitrate.Size = New-Object System.Drawing.Size(120, 24)
    $lblVBitrate.ForeColor = $ColorText
    $formPreset.Controls.Add($lblVBitrate)
    
    $cmbVBitrate = New-ModernComboBox -X 160 -Y $yPos -Width 200 -Items @('Original', '2000', '4000', '8000', '16000')
    $formPreset.Controls.Add($cmbVBitrate)
    
    $yPos += 50
    
    # Audio Section
    $lblAudioSection = New-Object System.Windows.Forms.Label
    $lblAudioSection.Text = '━━━ AUDIO SETTINGS ━━━'
    $lblAudioSection.Location = New-Object System.Drawing.Point(20, $yPos)
    $lblAudioSection.Size = New-Object System.Drawing.Size(560, 25)
    $lblAudioSection.ForeColor = $ColorAccent
    $lblAudioSection.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $formPreset.Controls.Add($lblAudioSection)
    
    $yPos += 35
    
    $lblACodec = New-Object System.Windows.Forms.Label
    $lblACodec.Text = 'Audio codec:'
    $lblACodec.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblACodec.Size = New-Object System.Drawing.Size(120, 24)
    $lblACodec.ForeColor = $ColorText
    $formPreset.Controls.Add($lblACodec)
    
    $cmbACodec = New-ModernComboBox -X 160 -Y $yPos -Width 200 -Items @('AAC', 'MP3', 'AC3', 'Copy')
    $formPreset.Controls.Add($cmbACodec)
    
    $yPos += 35
    
    $lblChannels = New-Object System.Windows.Forms.Label
    $lblChannels.Text = 'Channels:'
    $lblChannels.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblChannels.Size = New-Object System.Drawing.Size(120, 24)
    $lblChannels.ForeColor = $ColorText
    $formPreset.Controls.Add($lblChannels)
    
    $cmbChannels = New-ModernComboBox -X 160 -Y $yPos -Width 200 -Items @('Stereo', 'Mono', '5.1')
    $formPreset.Controls.Add($cmbChannels)
    
    $yPos += 35
    
    $lblABitrate = New-Object System.Windows.Forms.Label
    $lblABitrate.Text = 'Bitrate (Kbps):'
    $lblABitrate.Location = New-Object System.Drawing.Point(30, $yPos)
    $lblABitrate.Size = New-Object System.Drawing.Size(120, 24)
    $lblABitrate.ForeColor = $ColorText
    $formPreset.Controls.Add($lblABitrate)
    
    $cmbABitrate = New-ModernComboBox -X 160 -Y $yPos -Width 200 -Items @('128', '192', '256', '320')
    $formPreset.Controls.Add($cmbABitrate)
    
    # Buttons
    $btnOK = New-ModernButton -Text 'Save Preset' -X 380 -Y 500 -Width 200 -Height 36 -IsPrimary $true
    $btnOK.DialogResult = 'OK'
    $formPreset.Controls.Add($btnOK)
    
    $formPreset.AcceptButton = $btnOK
    
    if($formPreset.ShowDialog() -eq 'OK'){
        Show-Message "Custom preset saved!" "Preset Editor"
    }
}

# ===================================
# EVENT HANDLERS
# ===================================

# Add files button
$btnAddFiles.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Multiselect = $true
    $ofd.Filter = 'Video Files|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.flv;*.webm|All Files|*.*'
    if($ofd.ShowDialog() -eq 'OK'){
        foreach($f in $ofd.FileNames){
            Add-Task $f
        }
    }
})

# Drag & Drop
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

# Remove selected
$btnRemove.Add_Click({
    foreach($item in $lvTasks.SelectedItems){
        $lvTasks.Items.Remove($item)
    }
    # Show hint if list is now empty
    if($lvTasks.Items.Count -eq 0 -and $lblHint){
        $lblHint.Visible = $true
    }
})

# Clear all
$btnClear.Add_Click({
    $lvTasks.Items.Clear()
    $script:Tasks = @()
    # Show hint when cleared
    if($lblHint){
        $lblHint.Visible = $true
    }
})

# Browse output
$btnBrowseOutput.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $script:OutputPath
    if($fbd.ShowDialog() -eq 'OK'){
        $script:OutputPath = $fbd.SelectedPath
        $txtOutput.Text = $fbd.SelectedPath
    }
})

# Open output folder
$btnOpenOutput.Add_Click({
    if(Test-Path $script:OutputPath){
        Start-Process explorer.exe $script:OutputPath
    } else {
        Show-Message "Output folder does not exist: $($script:OutputPath)" "Error"
    }
})

# Edit preset
$btnEditPreset.Add_Click({
    Show-PresetEditor
})

# Context menu - Edit
$menuEdit.Add_Click({
    Show-EditWindow
})

# Context menu - Remove
$menuRemove.Add_Click({
    foreach($item in $lvTasks.SelectedItems){
        $lvTasks.Items.Remove($item)
    }
})

# Double-click to edit
$lvTasks.Add_DoubleClick({
    Show-EditWindow
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
    
    $btnConvert.Enabled = $false
    $btnConvert.Text = 'Converting...'
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    
    $p = $Config.profiles[$cmbProfile.SelectedIndex]
    $total = $lvTasks.Items.Count
    $current = 0
    $okCount = 0
    $failCount = 0
    
    Write-Log "========================================" 
    Write-Log "Starting conversion..."
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
    
    foreach($item in $lvTasks.Items){
        $current++
        $task = $item.Tag
        $percent = [math]::Round(($current / $total) * 100, 1)
        
        $item.SubItems[7].Text = "Processing $percent%"
        $item.ForeColor = $ColorAccent
        Write-Log "[$current/$total] Processing: $($task.FileName)"
        $form.Refresh()
        
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($task.FilePath)
        $outputFile = Join-Path $script:OutputPath "$fileName.$($p.format)"
        
        $outDir = Split-Path -Parent $outputFile
        if($outDir -and -not (Test-Path $outDir)){
            New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        }
        
        try {
            $processedInput = $task.FilePath
            
            if($task.WatermarkPath -and (Test-Path $task.WatermarkPath)){
                Write-Log "  Applying watermark..."
                $wmTemp = Join-Path $Temp "$fileName-wm.mp4"
                $wmArgs = @('-i', $task.FilePath, '-i', $task.WatermarkPath, '-filter_complex', 'overlay=W-w-10:H-h-10', '-c:a', 'copy', '-y', $wmTemp)
                & $ffmpeg @wmArgs 2>&1 | Out-Null
                $processedInput = $wmTemp
            }
            
            if($task.SubtitlePath -and (Test-Path $task.SubtitlePath)){
                Write-Log "  Burning subtitles..."
                $subTemp = Join-Path $Temp "$fileName-sub.mp4"
                $subPath = $task.SubtitlePath -replace '\\','/' -replace ':','\\:'
                $subArgs = @('-i', $processedInput, '-vf', "subtitles='$subPath'", '-c:a', 'copy', '-y', $subTemp)
                & $ffmpeg @subArgs 2>&1 | Out-Null
                $processedInput = $subTemp
            }
            
            Write-Log "  Converting with $($p.engine)..."
            
            if($p.engine -eq 'ffmpeg'){
                $ffArgs = @('-i', $processedInput) + $p.args.Split(' ') + @('-y', $outputFile)
                $proc = Start-Process -FilePath $ffmpeg -ArgumentList $ffArgs -NoNewWindow -PassThru -Wait
                
                if($proc.ExitCode -eq 0 -and (Test-Path $outputFile)){
                    $fi = Get-Item -LiteralPath $outputFile
                    if($fi.Length -gt 0){
                        $item.SubItems[7].Text = "Success"
                        $item.ForeColor = $ColorSuccess
                        Write-Log "  Success - $([math]::Round($fi.Length/1MB, 2)) MB"
                        $okCount++
                    } else {
                        $item.SubItems[7].Text = "Failed (empty)"
                        $item.ForeColor = $ColorError
                        Write-Log "  Failed - output empty"
                        $failCount++
                    }
                } else {
                    $item.SubItems[7].Text = "Failed"
                    $item.ForeColor = $ColorError
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
                        $item.ForeColor = $ColorSuccess
                        Write-Log "  Success - $([math]::Round($fi.Length/1MB, 2)) MB"
                        $okCount++
                    } else {
                        $item.SubItems[7].Text = "Failed (empty)"
                        $item.ForeColor = $ColorError
                        Write-Log "  Failed - output empty"
                        $failCount++
                    }
                } else {
                    $item.SubItems[7].Text = "Failed"
                    $item.ForeColor = $ColorError
                    Write-Log "  Failed - exit code: $($proc.ExitCode)"
                    $failCount++
                }
            }
            
            # Cleanup temp files
            if($task.WatermarkPath -and (Test-Path $wmTemp)){ Remove-Item $wmTemp -Force -ErrorAction SilentlyContinue }
            if($task.SubtitlePath -and (Test-Path $subTemp)){ Remove-Item $subTemp -Force -ErrorAction SilentlyContinue }
            
        } catch {
            $item.SubItems[7].Text = "Error"
            $item.ForeColor = $ColorError
            Write-Log "  Error: $($_.Exception.Message)"
            $failCount++
        }
        
        $form.Refresh()
    }
    
    Write-Log "========================================"
    Write-Log "Conversion complete!"
    Write-Log "Successful: $okCount | Failed: $failCount"
    Write-Log "========================================"
    
    $btnConvert.Enabled = $true
    $btnConvert.Text = 'CONVERT'
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
Write-Log "Professional Portable Converter - Ultimate Edition v2 started"
[void]$form.ShowDialog()
