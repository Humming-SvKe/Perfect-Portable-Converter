<#
  PPC-GUI-Modern-Clean.ps1
  Clean modern design inspired by Apowersoft Video Converter
  Light theme, gradient accents, proper scaling
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Relaunch in STA
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile','-ExecutionPolicy','Bypass','-STA','-File', $PSCommandPath) -WindowStyle Normal
    return
}

# Paths
$Root  = Split-Path -Parent $PSCommandPath
$Bins  = Join-Path $Root 'binaries'
$Logs  = Join-Path $Root 'logs'
$Out   = Join-Path $Root 'output'
$Cfg   = Join-Path $Root 'config\defaults.json'

@($Bins, $Logs, $Out) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }

# Config
$Config = @{
  profiles = @(
    @{ name='Fast 1080p H264'; engine='ffmpeg'; args='-c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k' },
    @{ name='High Quality 1080p'; engine='ffmpeg'; args='-c:v libx264 -preset medium -crf 20 -c:a aac -b:a 160k' },
    @{ name='Small 720p'; engine='ffmpeg'; args='-vf scale=1280:-2 -c:v libx264 -crf 25 -c:a aac -b:a 128k' },
    @{ name='HEVC/H265'; engine='handbrake'; args='-e x265 -q 26 -E av_aac -B 160' }
  )
}
if (Test-Path $Cfg) { 
    try { 
        $Config = Get-Content $Cfg -Raw | ConvertFrom-Json
        foreach($p in $Config.profiles) {
            if(-not $p.PSObject.Properties['engine']) {
                Add-Member -InputObject $p -MemberType NoteProperty -Name 'engine' -Value 'ffmpeg' -Force
            }
        }
    } catch {}
}

# WinForms + DPI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class DpiAwareness {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
[DpiAwareness]::SetProcessDPIAware() | Out-Null

# ===================================
# MODERN LIGHT THEME (Apowersoft style)
# ===================================
$White = [System.Drawing.Color]::White
$LightGray = [System.Drawing.Color]::FromArgb(245, 245, 245)
$BorderGray = [System.Drawing.Color]::FromArgb(220, 220, 220)
$TextDark = [System.Drawing.Color]::FromArgb(50, 50, 50)
$TextGray = [System.Drawing.Color]::FromArgb(100, 100, 100)
$Blue = [System.Drawing.Color]::FromArgb(24, 144, 255)  # Bright blue
$BlueHover = [System.Drawing.Color]::FromArgb(64, 169, 255)
$Green = [System.Drawing.Color]::FromArgb(82, 196, 26)
$Orange = [System.Drawing.Color]::FromArgb(250, 140, 22)

# ===================================
# MAIN FORM
# ===================================
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Professional Portable Converter'
$form.Size = New-Object System.Drawing.Size(1000, 650)
$form.MinimumSize = New-Object System.Drawing.Size(900, 600)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $White
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

# ===================================
# TOP SECTION - Add Files Area
# ===================================
$topPanel = New-Object System.Windows.Forms.Panel
$topPanel.Location = New-Object System.Drawing.Point(0, 0)
$topPanel.Size = New-Object System.Drawing.Size(1000, 200)
$topPanel.BackColor = $LightGray
$topPanel.Anchor = 'Top,Left,Right'
$form.Controls.Add($topPanel)

# Gradient title
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = '📁 Add Video Files'
$lblTitle.Location = New-Object System.Drawing.Point(30, 20)
$lblTitle.Size = New-Object System.Drawing.Size(400, 35)
$lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $TextDark
$lblTitle.BackColor = [System.Drawing.Color]::Transparent
$topPanel.Controls.Add($lblTitle)

# Add Files Button (BIG, centered)
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = '+ Add Files'
$btnAdd.Location = New-Object System.Drawing.Point(350, 80)
$btnAdd.Size = New-Object System.Drawing.Size(300, 80)
$btnAdd.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$btnAdd.FlatStyle = 'Flat'
$btnAdd.BackColor = $Blue
$btnAdd.ForeColor = $White
$btnAdd.FlatAppearance.BorderSize = 0
$btnAdd.Cursor = 'Hand'
$btnAdd.Add_MouseEnter({ $this.BackColor = $BlueHover })
$btnAdd.Add_MouseLeave({ $this.BackColor = $Blue })
$topPanel.Controls.Add($btnAdd)

# ===================================
# FILE LIST SECTION
# ===================================
$listPanel = New-Object System.Windows.Forms.Panel
$listPanel.Location = New-Object System.Drawing.Point(20, 220)
$listPanel.Size = New-Object System.Drawing.Size(940, 250)
$listPanel.BackColor = $White
$listPanel.BorderStyle = 'FixedSingle'
$listPanel.Anchor = 'Top,Left,Right,Bottom'
$form.Controls.Add($listPanel)

$lvFiles = New-Object System.Windows.Forms.ListView
$lvFiles.Dock = 'Fill'
$lvFiles.View = 'Details'
$lvFiles.FullRowSelect = $true
$lvFiles.GridLines = $true
$lvFiles.BackColor = $White
$lvFiles.ForeColor = $TextDark
$lvFiles.BorderStyle = 'None'
$lvFiles.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$lvFiles.AllowDrop = $true

$lvFiles.Columns.Add("File Name", 350) | Out-Null
$lvFiles.Columns.Add("Size", 100) | Out-Null
$lvFiles.Columns.Add("Duration", 100) | Out-Null
$lvFiles.Columns.Add("Format", 80) | Out-Null
$lvFiles.Columns.Add("Status", 200) | Out-Null

# Empty state hint
$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "No files added yet.`nClick '+ Add Files' button above or drag & drop files here."
$lblHint.TextAlign = 'MiddleCenter'
$lblHint.Dock = 'Fill'
$lblHint.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Italic)
$lblHint.ForeColor = $TextGray
$lblHint.BackColor = [System.Drawing.Color]::Transparent
$lvFiles.Controls.Add($lblHint)

$listPanel.Controls.Add($lvFiles)

# ===================================
# BOTTOM CONTROLS
# ===================================
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Location = New-Object System.Drawing.Point(20, 490)
$bottomPanel.Size = New-Object System.Drawing.Size(940, 110)
$bottomPanel.BackColor = $LightGray
$bottomPanel.Anchor = 'Bottom,Left,Right'
$form.Controls.Add($bottomPanel)

# Profile Label
$lblProfile = New-Object System.Windows.Forms.Label
$lblProfile.Text = 'Conversion Profile:'
$lblProfile.Location = New-Object System.Drawing.Point(20, 20)
$lblProfile.Size = New-Object System.Drawing.Size(120, 25)
$lblProfile.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$lblProfile.ForeColor = $TextDark
$bottomPanel.Controls.Add($lblProfile)

# Profile Dropdown
$cmbProfile = New-Object System.Windows.Forms.ComboBox
$cmbProfile.Location = New-Object System.Drawing.Point(150, 18)
$cmbProfile.Size = New-Object System.Drawing.Size(400, 28)
$cmbProfile.DropDownStyle = 'DropDownList'
$cmbProfile.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$cmbProfile.FlatStyle = 'Flat'
$cmbProfile.BackColor = $White
$bottomPanel.Controls.Add($cmbProfile)

# Output Label
$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = 'Output Folder:'
$lblOutput.Location = New-Object System.Drawing.Point(20, 60)
$lblOutput.Size = New-Object System.Drawing.Size(120, 25)
$lblOutput.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$lblOutput.ForeColor = $TextDark
$bottomPanel.Controls.Add($lblOutput)

# Output Path
$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(150, 58)
$txtOutput.Size = New-Object System.Drawing.Size(300, 28)
$txtOutput.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$txtOutput.Text = $Out
$txtOutput.BackColor = $White
$bottomPanel.Controls.Add($txtOutput)

# Browse Button
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = 'Browse...'
$btnBrowse.Location = New-Object System.Drawing.Point(460, 56)
$btnBrowse.Size = New-Object System.Drawing.Size(90, 32)
$btnBrowse.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$btnBrowse.FlatStyle = 'Flat'
$btnBrowse.BackColor = $White
$btnBrowse.FlatAppearance.BorderColor = $BorderGray
$btnBrowse.Cursor = 'Hand'
$bottomPanel.Controls.Add($btnBrowse)

# CONVERT BUTTON (Large, Orange gradient)
$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = 'START CONVERSION'
$btnConvert.Location = New-Object System.Drawing.Point(640, 20)
$btnConvert.Size = New-Object System.Drawing.Size(260, 68)
$btnConvert.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$btnConvert.FlatStyle = 'Flat'
$btnConvert.BackColor = $Orange
$btnConvert.ForeColor = $White
$btnConvert.FlatAppearance.BorderSize = 0
$btnConvert.Cursor = 'Hand'
$btnConvert.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(255, 160, 50) })
$btnConvert.Add_MouseLeave({ $this.BackColor = $Orange })
$bottomPanel.Controls.Add($btnConvert)

# Clear Button
$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = 'Clear All'
$btnClear.Location = New-Object System.Drawing.Point(850, 75)
$btnClear.Size = New-Object System.Drawing.Size(70, 25)
$btnClear.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$btnClear.FlatStyle = 'Flat'
$btnClear.BackColor = $White
$btnClear.ForeColor = $TextGray
$btnClear.FlatAppearance.BorderColor = $BorderGray
$btnClear.Cursor = 'Hand'
$topPanel.Controls.Add($btnClear)

# ===================================
# GLOBAL STATE
# ===================================
$script:Files = @()

# ===================================
# FUNCTIONS
# ===================================
function Add-File([string]$path) {
    if(-not (Test-Path $path)) { return }
    
    if($lvFiles.Items.Count -eq 0) { $lblHint.Visible = $false }
    
    $file = Get-Item $path
    $name = $file.Name
    $size = "{0:N2} MB" -f ($file.Length / 1MB)
    
    $item = $lvFiles.Items.Add($name)
    $item.SubItems.Add($size) | Out-Null
    $item.SubItems.Add("-") | Out-Null
    $item.SubItems.Add($file.Extension.TrimStart('.').ToUpper()) | Out-Null
    $item.SubItems.Add("Ready") | Out-Null
    $item.Tag = $path
    $item.ForeColor = $TextDark
    
    $script:Files += $path
}

# ===================================
# EVENT HANDLERS
# ===================================

$btnAdd.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Video Files|*.mp4;*.avi;*.mkv;*.mov;*.wmv;*.flv;*.webm;*.m4v|All Files|*.*"
    $ofd.Multiselect = $true
    
    if($ofd.ShowDialog() -eq 'OK') {
        foreach($f in $ofd.FileNames) { Add-File $f }
    }
})

$btnClear.Add_Click({
    $lvFiles.Items.Clear()
    $script:Files = @()
    $lblHint.Visible = $true
})

$btnBrowse.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $txtOutput.Text
    if($fbd.ShowDialog() -eq 'OK') {
        $txtOutput.Text = $fbd.SelectedPath
    }
})

$btnConvert.Add_Click({
    if($script:Files.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Please add files first!', 'No Files', 'OK', 'Warning')
        return
    }
    
    [System.Windows.Forms.MessageBox]::Show("Ready to convert $($script:Files.Count) file(s)!`n`n(Conversion engine integration coming soon)", 'Ready', 'OK', 'Information')
})

# Drag & Drop
$lvFiles.Add_DragEnter({
    param($s, $e)
    if($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = 'Copy'
    }
})

$lvFiles.Add_DragDrop({
    param($s, $e)
    $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    foreach($f in $files) {
        if(Test-Path $f -PathType Leaf) { Add-File $f }
    }
})

# Populate profiles
foreach($p in $Config.profiles) {
    $cmbProfile.Items.Add($p.name) | Out-Null
}
if($cmbProfile.Items.Count -gt 0) { $cmbProfile.SelectedIndex = 0 }

# ===================================
# SHOW FORM
# ===================================
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
