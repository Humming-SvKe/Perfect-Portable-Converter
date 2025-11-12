<#
  PPC-GUI-Final.ps1
  Final clean design - Perfect layout, no broken text
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$PSCommandPath`"" -WindowStyle Normal
    return
}

# Paths
$Root = Split-Path -Parent $PSCommandPath
$Out = Join-Path $Root 'output'
$Cfg = Join-Path $Root 'config\defaults.json'
New-Item -ItemType Directory -Force -Path $Out | Out-Null

# Config
$Profiles = @(
    @{name='Fast 1080p H264'; args='-c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k'},
    @{name='High Quality 1080p'; args='-c:v libx264 -preset medium -crf 20 -c:a aac -b:a 160k'},
    @{name='Small 720p'; args='-vf scale=1280:-2 -c:v libx264 -crf 25 -c:a aac -b:a 128k'},
    @{name='HEVC H265'; args='-c:v libx265 -crf 26 -c:a aac -b:a 160k'}
)

# WinForms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

# Colors
$c = @{
    White = [Drawing.Color]::White
    Gray = [Drawing.Color]::FromArgb(245,245,245)
    Border = [Drawing.Color]::FromArgb(220,220,220)
    Text = [Drawing.Color]::FromArgb(40,40,40)
    TextGray = [Drawing.Color]::FromArgb(120,120,120)
    Blue = [Drawing.Color]::FromArgb(24,144,255)
    BlueHover = [Drawing.Color]::FromArgb(64,169,255)
    Orange = [Drawing.Color]::FromArgb(250,140,22)
    OrangeHover = [Drawing.Color]::FromArgb(255,165,60)
}

# ===================================
# FORM
# ===================================
$form = New-Object Windows.Forms.Form
$form.Text = 'Professional Portable Converter'
$form.Size = New-Object Drawing.Size(1100, 700)
$form.MinimumSize = New-Object Drawing.Size(1000, 600)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $c.White
$form.Font = New-Object Drawing.Font('Segoe UI', 9)

# ===================================
# TOP PANEL - Add Files
# ===================================
$panelTop = New-Object Windows.Forms.Panel
$panelTop.Height = 180
$panelTop.Dock = 'Top'
$panelTop.BackColor = $c.Gray
$panelTop.Padding = New-Object Windows.Forms.Padding(20)
$form.Controls.Add($panelTop)

# Title
$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text = 'Add Video Files'
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object Drawing.Point(30, 25)
$lblTitle.Font = New-Object Drawing.Font('Segoe UI', 18, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $c.Text
$lblTitle.BackColor = [Drawing.Color]::Transparent
$panelTop.Controls.Add($lblTitle)

# Add Files Button (centered)
$btnAdd = New-Object Windows.Forms.Button
$btnAdd.Text = '+ Add Files'
$btnAdd.Size = New-Object Drawing.Size(350, 75)
$btnAdd.Location = New-Object Drawing.Point(375, 80)
$btnAdd.Font = New-Object Drawing.Font('Segoe UI', 16, [Drawing.FontStyle]::Bold)
$btnAdd.FlatStyle = 'Flat'
$btnAdd.BackColor = $c.Blue
$btnAdd.ForeColor = $c.White
$btnAdd.FlatAppearance.BorderSize = 0
$btnAdd.Cursor = 'Hand'
$btnAdd.Add_MouseEnter({ $this.BackColor = $c.BlueHover })
$btnAdd.Add_MouseLeave({ $this.BackColor = $c.Blue })
$panelTop.Controls.Add($btnAdd)

# Clear button (small, top right)
$btnClear = New-Object Windows.Forms.Button
$btnClear.Text = 'Clear All'
$btnClear.Size = New-Object Drawing.Size(90, 28)
$btnClear.Location = New-Object Drawing.Point(980, 25)
$btnClear.Font = New-Object Drawing.Font('Segoe UI', 9)
$btnClear.FlatStyle = 'Flat'
$btnClear.BackColor = $c.White
$btnClear.ForeColor = $c.TextGray
$btnClear.FlatAppearance.BorderColor = $c.Border
$btnClear.Cursor = 'Hand'
$btnClear.Anchor = 'Top,Right'
$panelTop.Controls.Add($btnClear)

# ===================================
# FILE LIST PANEL
# ===================================
$panelList = New-Object Windows.Forms.Panel
$panelList.Dock = 'Fill'
$panelList.BackColor = $c.White
$panelList.Padding = New-Object Windows.Forms.Padding(25, 15, 25, 15)
$form.Controls.Add($panelList)

# ListView
$lv = New-Object Windows.Forms.ListView
$lv.Dock = 'Fill'
$lv.View = 'Details'
$lv.FullRowSelect = $true
$lv.GridLines = $true
$lv.BackColor = $c.White
$lv.ForeColor = $c.Text
$lv.BorderStyle = 'FixedSingle'
$lv.Font = New-Object Drawing.Font('Segoe UI', 10)
$lv.AllowDrop = $true
$lv.MultiSelect = $true

# Columns
$lv.Columns.Add('File Name', 400) | Out-Null
$lv.Columns.Add('Size', 120) | Out-Null
$lv.Columns.Add('Duration', 100) | Out-Null
$lv.Columns.Add('Format', 100) | Out-Null
$lv.Columns.Add('Status', 200) | Out-Null

# Empty hint
$lblHint = New-Object Windows.Forms.Label
$lblHint.Text = "No files added yet`nClick '+ Add Files' button above or drag & drop files here"
$lblHint.TextAlign = 'MiddleCenter'
$lblHint.Dock = 'Fill'
$lblHint.Font = New-Object Drawing.Font('Segoe UI', 11, [Drawing.FontStyle]::Italic)
$lblHint.ForeColor = $c.TextGray
$lblHint.BackColor = [Drawing.Color]::Transparent
$lv.Controls.Add($lblHint)

$panelList.Controls.Add($lv)

# ===================================
# BOTTOM PANEL - Controls
# ===================================
$panelBottom = New-Object Windows.Forms.Panel
$panelBottom.Height = 150
$panelBottom.Dock = 'Bottom'
$panelBottom.BackColor = $c.Gray
$panelBottom.Padding = New-Object Windows.Forms.Padding(25, 20, 25, 20)
$form.Controls.Add($panelBottom)

# Profile Label
$lblProfile = New-Object Windows.Forms.Label
$lblProfile.Text = 'Conversion Profile:'
$lblProfile.AutoSize = $true
$lblProfile.Location = New-Object Drawing.Point(30, 30)
$lblProfile.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
$lblProfile.ForeColor = $c.Text
$panelBottom.Controls.Add($lblProfile)

# Profile ComboBox
$cmbProfile = New-Object Windows.Forms.ComboBox
$cmbProfile.DropDownStyle = 'DropDownList'
$cmbProfile.Location = New-Object Drawing.Point(30, 55)
$cmbProfile.Size = New-Object Drawing.Size(450, 28)
$cmbProfile.Font = New-Object Drawing.Font('Segoe UI', 10)
$cmbProfile.BackColor = $c.White
$panelBottom.Controls.Add($cmbProfile)

# Output Label
$lblOutput = New-Object Windows.Forms.Label
$lblOutput.Text = 'Output Folder:'
$lblOutput.AutoSize = $true
$lblOutput.Location = New-Object Drawing.Point(30, 95)
$lblOutput.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
$lblOutput.ForeColor = $c.Text
$panelBottom.Controls.Add($lblOutput)

# Output TextBox
$txtOutput = New-Object Windows.Forms.TextBox
$txtOutput.Location = New-Object Drawing.Point(150, 92)
$txtOutput.Size = New-Object Drawing.Size(250, 28)
$txtOutput.Font = New-Object Drawing.Font('Segoe UI', 10)
$txtOutput.Text = $Out
$txtOutput.BackColor = $c.White
$panelBottom.Controls.Add($txtOutput)

# Browse Button
$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = 'Browse...'
$btnBrowse.Location = New-Object Drawing.Point(410, 90)
$btnBrowse.Size = New-Object Drawing.Size(70, 32)
$btnBrowse.Font = New-Object Drawing.Font('Segoe UI', 9)
$btnBrowse.FlatStyle = 'Flat'
$btnBrowse.BackColor = $c.White
$btnBrowse.FlatAppearance.BorderColor = $c.Border
$btnBrowse.Cursor = 'Hand'
$panelBottom.Controls.Add($btnBrowse)

# CONVERT BUTTON (huge, orange, right side)
$btnConvert = New-Object Windows.Forms.Button
$btnConvert.Text = 'START CONVERSION'
$btnConvert.Location = New-Object Drawing.Point(750, 30)
$btnConvert.Size = New-Object Drawing.Size(320, 90)
$btnConvert.Font = New-Object Drawing.Font('Segoe UI', 16, [Drawing.FontStyle]::Bold)
$btnConvert.FlatStyle = 'Flat'
$btnConvert.BackColor = $c.Orange
$btnConvert.ForeColor = $c.White
$btnConvert.FlatAppearance.BorderSize = 0
$btnConvert.Cursor = 'Hand'
$btnConvert.Anchor = 'Top,Right'
$btnConvert.Add_MouseEnter({ $this.BackColor = $c.OrangeHover })
$btnConvert.Add_MouseLeave({ $this.BackColor = $c.Orange })
$panelBottom.Controls.Add($btnConvert)

# ===================================
# STATE
# ===================================
$script:files = @()

# ===================================
# FUNCTIONS
# ===================================
function Add-VideoFile([string]$path) {
    if(-not (Test-Path $path)) { return }
    if($script:files -contains $path) { return }
    
    $file = Get-Item $path
    $item = $lv.Items.Add($file.Name)
    $item.SubItems.Add(('{0:N2} MB' -f ($file.Length/1MB))) | Out-Null
    $item.SubItems.Add('-') | Out-Null
    $item.SubItems.Add($file.Extension.TrimStart('.').ToUpper()) | Out-Null
    $item.SubItems.Add('Ready') | Out-Null
    $item.Tag = $path
    
    $script:files += $path
    
    if($lv.Items.Count -eq 1) { $lblHint.Visible = $false }
}

# ===================================
# EVENTS
# ===================================
$btnAdd.Add_Click({
    $ofd = New-Object Windows.Forms.OpenFileDialog
    $ofd.Filter = 'Video Files|*.mp4;*.avi;*.mkv;*.mov;*.wmv;*.flv;*.webm;*.m4v;*.mpg;*.mpeg|All Files|*.*'
    $ofd.Multiselect = $true
    if($ofd.ShowDialog() -eq 'OK') {
        foreach($f in $ofd.FileNames) { Add-VideoFile $f }
    }
})

$btnClear.Add_Click({
    $lv.Items.Clear()
    $script:files = @()
    $lblHint.Visible = $true
})

$btnBrowse.Add_Click({
    $fbd = New-Object Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $txtOutput.Text
    if($fbd.ShowDialog() -eq 'OK') { $txtOutput.Text = $fbd.SelectedPath }
})

$btnConvert.Add_Click({
    if($script:files.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show('Please add files first!', 'No Files', 'OK', 'Warning')
        return
    }
    
    $msg = "Ready to convert {0} file(s)`n`nProfile: {1}`nOutput: {2}`n`n(Conversion engine integration coming soon)" -f $script:files.Count, $cmbProfile.Text, $txtOutput.Text
    [Windows.Forms.MessageBox]::Show($msg, 'Ready', 'OK', 'Information')
})

# Drag & Drop
$lv.Add_DragEnter({
    if($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = 'Copy'
    }
})

$lv.Add_DragDrop({
    $files = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    foreach($f in $files) {
        if(Test-Path $f -PathType Leaf) { Add-VideoFile $f }
    }
})

# Context menu for selected items
$contextMenu = New-Object Windows.Forms.ContextMenuStrip
$menuRemove = $contextMenu.Items.Add('Remove Selected')
$menuRemove.Add_Click({
    $selected = @($lv.SelectedItems)
    foreach($item in $selected) {
        $script:files = $script:files | Where-Object { $_ -ne $item.Tag }
        $lv.Items.Remove($item)
    }
    if($lv.Items.Count -eq 0) { $lblHint.Visible = $true }
})
$lv.ContextMenuStrip = $contextMenu

# Populate profiles
foreach($p in $Profiles) {
    $cmbProfile.Items.Add($p.name) | Out-Null
}
$cmbProfile.SelectedIndex = 0

# ===================================
# SHOW
# ===================================
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
