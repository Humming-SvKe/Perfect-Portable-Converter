<#
  PPC-GUI-Ultimate-v3.ps1
  RESPONSIVE DESIGN - Works from 800x600 to 8K (7680x4320)
  Build: v3.0.0
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Relaunch in STA if needed
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile','-ExecutionPolicy','Bypass','-STA','-File', $PSCommandPath) -WindowStyle Normal
    return
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
$LogFile = Join-Path $Logs 'ppc-ultimate-v3.log'

function Write-Log([string]$m){
  $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); "$ts | $m" | Out-File -Append -Encoding UTF8 $LogFile
}

# Config with all properties
$Config = @{
  default_format = 'mp4';
  profiles = @(
    @{ 
      name='Fast 1080p - H264'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='128k'; 
      channels='2';
      args='-c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k -ac 2' 
    },
    @{ 
      name='High Quality - 1080p H264'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='160k'; 
      channels='2';
      args='-c:v libx264 -preset medium -crf 20 -c:a aac -b:a 160k -ac 2' 
    },
    @{ 
      name='Small Size - 720p H264'; 
      engine='ffmpeg'; 
      format='mp4'; 
      vcodec='libx264'; 
      acodec='aac'; 
      ab='128k'; 
      channels='2';
      args='-vf scale=1280:-2 -c:v libx264 -preset veryfast -crf 25 -c:a aac -b:a 128k -ac 2' 
    },
    @{ 
      name='HEVC/H265 - MKV'; 
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
    $loaded = Get-Content $Cfg -Raw | ConvertFrom-Json
    # Ensure engine property exists
    foreach($prof in $loaded.profiles) {
        if (-not $prof.PSObject.Properties['engine']) {
            Add-Member -InputObject $prof -MemberType NoteProperty -Name 'engine' -Value 'ffmpeg' -Force
        }
    }
    $Config = $loaded
  } catch { 
    Write-Log 'Config load failed, using defaults.' 
  } 
}

# WinForms + DPI Awareness
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# DPI Awareness
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class DpiAwareness {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@
[DpiAwareness]::SetProcessDPIAware() | Out-Null

# Get screen resolution for scaling
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$screenWidth = $screen.Width
$screenHeight = $screen.Height

# Calculate base scale factor (1.0 = 1920x1080 baseline)
$scaleX = $screenWidth / 1920.0
$scaleY = $screenHeight / 1080.0
$scale = [Math]::Min($scaleX, $scaleY)

# Clamp scale (0.6 for 800x600, 4.0 for 8K)
if ($scale -lt 0.6) { $scale = 0.6 }
if ($scale -gt 4.0) { $scale = 4.0 }

# Responsive sizing helper
function Get-Scaled([int]$baseSize) {
    return [int]([Math]::Round($baseSize * $scale))
}

# Dark theme colors
$ColorBg = [System.Drawing.Color]::FromArgb(30, 30, 30)
$ColorPanel = [System.Drawing.Color]::FromArgb(45, 45, 48)
$ColorText = [System.Drawing.Color]::FromArgb(241, 241, 241)
$ColorTextDim = [System.Drawing.Color]::FromArgb(170, 170, 170)
$ColorAccent = [System.Drawing.Color]::FromArgb(0, 122, 204)
$ColorAccentHover = [System.Drawing.Color]::FromArgb(28, 151, 234)
$ColorSuccess = [System.Drawing.Color]::FromArgb(73, 190, 170)
$ColorError = [System.Drawing.Color]::FromArgb(244, 71, 71)

# Modern flat button
function New-Button {
    param([string]$Text, [bool]$Primary = $false)
    
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.FlatStyle = 'Flat'
    $btn.BackColor = if($Primary) { $ColorAccent } else { $ColorPanel }
    $btn.ForeColor = $ColorText
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = 'Hand'
    $btn.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 9), [System.Drawing.FontStyle]::Regular)
    
    # Hover effect
    $btn.Add_MouseEnter({ 
        $this.BackColor = if($Primary) { $ColorAccentHover } else { [System.Drawing.Color]::FromArgb(55, 55, 58) }
    })
    $btn.Add_MouseLeave({ 
        $this.BackColor = if($Primary) { $ColorAccent } else { $ColorPanel }
    })
    
    return $btn
}

# Modern ComboBox
function New-ComboBox {
    $cmb = New-Object System.Windows.Forms.ComboBox
    $cmb.DropDownStyle = 'DropDownList'
    $cmb.FlatStyle = 'Flat'
    $cmb.BackColor = $ColorPanel
    $cmb.ForeColor = $ColorText
    $cmb.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 9))
    return $cmb
}

# Modern TextBox
function New-TextBox {
    param([string]$Text = '')
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Text = $Text
    $txt.BackColor = $ColorPanel
    $txt.ForeColor = $ColorText
    $txt.BorderStyle = 'FixedSingle'
    $txt.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 9))
    return $txt
}

# ===================================
# MAIN FORM with responsive sizing
# ===================================
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Professional Portable Converter - Ultimate v3 (Build v3.0.0)'
$form.BackColor = $ColorBg
$form.ForeColor = $ColorText
$form.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 9))

# Responsive window size (80% of screen, clamped)
$formWidth = [Math]::Min([Math]::Max((Get-Scaled 1280), 800), $screenWidth * 0.9)
$formHeight = [Math]::Min([Math]::Max((Get-Scaled 720), 600), $screenHeight * 0.9)
$form.ClientSize = New-Object System.Drawing.Size($formWidth, $formHeight)
$form.MinimumSize = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = 'CenterScreen'

# ===================================
# LAYOUT: TableLayoutPanel (responsive)
# ===================================
$mainLayout = New-Object System.Windows.Forms.TableLayoutPanel
$mainLayout.Dock = 'Fill'
$mainLayout.ColumnCount = 1
$mainLayout.RowCount = 3
$mainLayout.BackColor = $ColorBg

# Row heights (percentages)
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute', (Get-Scaled 60)))) | Out-Null  # Toolbar
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 100))) | Out-Null              # ListView (fills)
$mainLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Absolute', (Get-Scaled 180)))) | Out-Null # Bottom panel

$form.Controls.Add($mainLayout)

# ===================================
# ROW 0: TOOLBAR
# ===================================
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.Dock = 'Fill'
$toolbar.BackColor = $ColorPanel
$toolbar.Padding = New-Object System.Windows.Forms.Padding((Get-Scaled 10))

$btnAdd = New-Button -Text '+ Add Files' -Primary $true
$btnAdd.Location = New-Object System.Drawing.Point((Get-Scaled 10), (Get-Scaled 15))
$btnAdd.Size = New-Object System.Drawing.Size((Get-Scaled 120), (Get-Scaled 35))
$toolbar.Controls.Add($btnAdd)

$btnRemove = New-Button -Text 'Remove'
$btnRemove.Location = New-Object System.Drawing.Point((Get-Scaled 140), (Get-Scaled 15))
$btnRemove.Size = New-Object System.Drawing.Size((Get-Scaled 100), (Get-Scaled 35))
$toolbar.Controls.Add($btnRemove)

$btnClear = New-Button -Text 'Clear All'
$btnClear.Location = New-Object System.Drawing.Point((Get-Scaled 250), (Get-Scaled 15))
$btnClear.Size = New-Object System.Drawing.Size((Get-Scaled 100), (Get-Scaled 35))
$toolbar.Controls.Add($btnClear)

$mainLayout.Controls.Add($toolbar, 0, 0)

# ===================================
# ROW 1: LISTVIEW (fills available space)
# ===================================
$lvTasks = New-Object System.Windows.Forms.ListView
$lvTasks.Dock = 'Fill'
$lvTasks.View = 'Details'
$lvTasks.FullRowSelect = $true
$lvTasks.GridLines = $false
$lvTasks.BackColor = $ColorBg
$lvTasks.ForeColor = $ColorText
$lvTasks.BorderStyle = 'None'
$lvTasks.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 9))
$lvTasks.HeaderStyle = 'Nonclickable'

# Responsive column widths (percentages of form width)
$colFile = [int]($formWidth * 0.30)
$colFormat = [int]($formWidth * 0.08)
$colDuration = [int]($formWidth * 0.10)
$colResolution = [int]($formWidth * 0.12)
$colSize = [int]($formWidth * 0.10)
$colAudio = [int]($formWidth * 0.12)
$colProfile = [int]($formWidth * 0.18)

$lvTasks.Columns.Add("File", $colFile) | Out-Null
$lvTasks.Columns.Add("Format", $colFormat) | Out-Null
$lvTasks.Columns.Add("Duration", $colDuration) | Out-Null
$lvTasks.Columns.Add("Resolution", $colResolution) | Out-Null
$lvTasks.Columns.Add("Size", $colSize) | Out-Null
$lvTasks.Columns.Add("Audio", $colAudio) | Out-Null
$lvTasks.Columns.Add("Profile", $colProfile) | Out-Null

$lvTasks.AllowDrop = $true

# Hint label
$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Click '+ Add Files' or drag & drop videos here"
$lblHint.AutoSize = $false
$lblHint.TextAlign = 'MiddleCenter'
$lblHint.Dock = 'Fill'
$lblHint.ForeColor = $ColorTextDim
$lblHint.BackColor = [System.Drawing.Color]::Transparent
$lblHint.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 11), [System.Drawing.FontStyle]::Italic)
$lvTasks.Controls.Add($lblHint)

$mainLayout.Controls.Add($lvTasks, 0, 1)

# ===================================
# ROW 2: BOTTOM PANEL (responsive grid)
# ===================================
$bottomPanel = New-Object System.Windows.Forms.TableLayoutPanel
$bottomPanel.Dock = 'Fill'
$bottomPanel.BackColor = $ColorPanel
$bottomPanel.ColumnCount = 3
$bottomPanel.RowCount = 3
$bottomPanel.Padding = New-Object System.Windows.Forms.Padding((Get-Scaled 15))

# Column widths: [Labels 15%] [Controls 60%] [Button 25%]
$bottomPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 15))) | Out-Null
$bottomPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 60))) | Out-Null
$bottomPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 25))) | Out-Null

# Row 0: Profile
$lblProfile = New-Object System.Windows.Forms.Label
$lblProfile.Text = 'Conversion Profile:'
$lblProfile.TextAlign = 'MiddleLeft'
$lblProfile.Dock = 'Fill'
$lblProfile.ForeColor = $ColorTextDim
$lblProfile.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 9))
$bottomPanel.Controls.Add($lblProfile, 0, 0)

$cmbProfile = New-ComboBox
$cmbProfile.Dock = 'Fill'
$cmbProfile.Margin = New-Object System.Windows.Forms.Padding(0, (Get-Scaled 5), (Get-Scaled 10), (Get-Scaled 5))
$bottomPanel.Controls.Add($cmbProfile, 1, 0)

# Row 1: Output
$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = 'Output Folder:'
$lblOutput.TextAlign = 'MiddleLeft'
$lblOutput.Dock = 'Fill'
$lblOutput.ForeColor = $ColorTextDim
$lblOutput.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 9))
$bottomPanel.Controls.Add($lblOutput, 0, 1)

$txtOutput = New-TextBox -Text $Out
$txtOutput.Dock = 'Fill'
$txtOutput.Margin = New-Object System.Windows.Forms.Padding(0, (Get-Scaled 5), (Get-Scaled 10), (Get-Scaled 5))
$bottomPanel.Controls.Add($txtOutput, 1, 1)

# Row 2: Buttons
$btnBrowseOutput = New-Button -Text 'Browse...'
$btnBrowseOutput.Dock = 'Fill'
$btnBrowseOutput.Margin = New-Object System.Windows.Forms.Padding(0, (Get-Scaled 5), (Get-Scaled 10), (Get-Scaled 5))
$bottomPanel.Controls.Add($btnBrowseOutput, 1, 2)

# BIG CONVERT BUTTON (spans all 3 rows in column 2)
$btnConvert = New-Button -Text 'CONVERT' -Primary $true
$btnConvert.Dock = 'Fill'
$btnConvert.Font = New-Object System.Drawing.Font('Segoe UI', (Get-Scaled 14), [System.Drawing.FontStyle]::Bold)
$bottomPanel.SetRowSpan($btnConvert, 3)
$bottomPanel.Controls.Add($btnConvert, 2, 0)

$mainLayout.Controls.Add($bottomPanel, 0, 2)

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
        Duration = "-"
        Resolution = "-"
        Size = "$fileSize MB"
        Audio = "-"
        Profile = if($cmbProfile.SelectedItem){$cmbProfile.SelectedItem}else{"Default"}
        Status = "Queued"
        Watermark = ""
        Subtitle = ""
    }
    
    $item = New-Object System.Windows.Forms.ListViewItem($fileName)
    $item.SubItems.Add($task.Format) | Out-Null
    $item.SubItems.Add($task.Duration) | Out-Null
    $item.SubItems.Add($task.Resolution) | Out-Null
    $item.SubItems.Add($task.Size) | Out-Null
    $item.SubItems.Add($task.Audio) | Out-Null
    $item.SubItems.Add($task.Profile) | Out-Null
    $item.Tag = $task
    $item.ForeColor = $ColorText
    
    $lvTasks.Items.Add($item) | Out-Null
    $script:Tasks += $task
    
    Write-Log "Added: $fileName"
}

# ===================================
# EVENT HANDLERS
# ===================================

# Add Files
$btnAdd.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Video Files|*.mp4;*.avi;*.mkv;*.mov;*.wmv;*.flv;*.webm;*.m4v;*.mpg;*.mpeg|All Files|*.*"
    $ofd.Multiselect = $true
    
    if($ofd.ShowDialog() -eq 'OK'){
        foreach($file in $ofd.FileNames){
            Add-Task $file
        }
    }
})

# Remove Selected
$btnRemove.Add_Click({
    if($lvTasks.SelectedItems.Count -gt 0){
        $toRemove = @($lvTasks.SelectedItems)
        foreach($item in $toRemove){
            $script:Tasks = $script:Tasks | Where-Object { $_.FilePath -ne $item.Tag.FilePath }
            $lvTasks.Items.Remove($item)
        }
        Write-Log "Removed $($toRemove.Count) item(s)"
    }
    
    if($lvTasks.Items.Count -eq 0 -and $lblHint){
        $lblHint.Visible = $true
    }
})

# Clear All
$btnClear.Add_Click({
    $lvTasks.Items.Clear()
    $script:Tasks = @()
    Write-Log "Cleared all tasks"
    
    if($lblHint){
        $lblHint.Visible = $true
    }
})

# Browse Output
$btnBrowseOutput.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $txtOutput.Text
    
    if($fbd.ShowDialog() -eq 'OK'){
        $txtOutput.Text = $fbd.SelectedPath
        $script:OutputPath = $fbd.SelectedPath
    }
})

# Drag & Drop
$lvTasks.Add_DragEnter({
    param($sender, $e)
    if($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)){
        $e.Effect = 'Copy'
    }
})

$lvTasks.Add_DragDrop({
    param($sender, $e)
    $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    foreach($file in $files){
        if(Test-Path $file -PathType Leaf){
            Add-Task $file
        }
    }
})

# CONVERT button
$btnConvert.Add_Click({
    if($script:Tasks.Count -eq 0){
        [System.Windows.Forms.MessageBox]::Show('No files to convert!', 'Error', 'OK', 'Warning')
        return
    }
    
    # Placeholder - actual conversion logic would go here
    [System.Windows.Forms.MessageBox]::Show("Conversion feature coming soon!`n`nFiles ready: $($script:Tasks.Count)", 'Info', 'OK', 'Information')
})

# ===================================
# POPULATE PROFILES
# ===================================
foreach($prof in $Config.profiles){
    $cmbProfile.Items.Add($prof.name) | Out-Null
}
if($cmbProfile.Items.Count -gt 0){
    $cmbProfile.SelectedIndex = 0
}

# ===================================
# SHOW FORM
# ===================================
Write-Log "GUI v3 started (Scale: $scale, Screen: ${screenWidth}x${screenHeight})"
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
