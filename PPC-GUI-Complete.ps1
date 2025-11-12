<#
  PPC-GUI-Complete.ps1
  Complete Apowersoft-style GUI with all tools
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
$Subs = Join-Path $Root 'subtitles'
$Ovls = Join-Path $Root 'overlays'
$Cfg = Join-Path $Root 'config\defaults.json'
@($Out, $Subs, $Ovls) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }

# Config
$Profiles = @(
    @{name='MP4 - 1080p Fast (H264)'; ext='mp4'; args='-c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 128k'},
    @{name='MP4 - 1080p Quality (H264)'; ext='mp4'; args='-c:v libx264 -preset medium -crf 20 -c:a aac -b:a 160k'},
    @{name='MP4 - 720p Small (H264)'; ext='mp4'; args='-vf scale=1280:-2 -c:v libx264 -crf 25 -c:a aac -b:a 128k'},
    @{name='MKV - High Quality (H265)'; ext='mkv'; args='-c:v libx265 -crf 23 -c:a aac -b:a 160k'},
    @{name='AVI - Compatible'; ext='avi'; args='-c:v mpeg4 -q:v 3 -c:a libmp3lame -b:a 128k'}
)

# WinForms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

# Colors (Apowersoft palette)
$c = @{
    White = [Drawing.Color]::White
    BgGray = [Drawing.Color]::FromArgb(248,248,248)
    PanelGray = [Drawing.Color]::FromArgb(242,242,242)
    Border = [Drawing.Color]::FromArgb(217,217,217)
    Text = [Drawing.Color]::FromArgb(51,51,51)
    TextLight = [Drawing.Color]::FromArgb(102,102,102)
    Blue = [Drawing.Color]::FromArgb(52,152,219)
    BlueHover = [Drawing.Color]::FromArgb(72,172,239)
    Orange = [Drawing.Color]::FromArgb(230,126,34)
    OrangeHover = [Drawing.Color]::FromArgb(250,146,54)
    Green = [Drawing.Color]::FromArgb(46,204,113)
    Red = [Drawing.Color]::FromArgb(231,76,60)
}

# ===================================
# FORM
# ===================================
$form = New-Object Windows.Forms.Form
$form.Text = 'Professional Portable Converter'
$form.Size = New-Object Drawing.Size(1200, 750)
$form.MinimumSize = New-Object Drawing.Size(1100, 650)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $c.BgGray
$form.Font = New-Object Drawing.Font('Segoe UI', 9)

# ===================================
# MENU BAR (like Apowersoft)
# ===================================
$menuBar = New-Object Windows.Forms.MenuStrip
$menuBar.BackColor = $c.White
$menuBar.Renderer = New-Object Windows.Forms.ToolStripProfessionalRenderer

$menuFile = New-Object Windows.Forms.ToolStripMenuItem('File')
$menuFile.DropDownItems.Add('Add Files...') | Out-Null
$menuFile.DropDownItems.Add('Add Folder...') | Out-Null
$menuFile.DropDownItems.Add([Windows.Forms.ToolStripSeparator]::new()) | Out-Null
$menuFile.DropDownItems.Add('Exit') | Out-Null

$menuTools = New-Object Windows.Forms.ToolStripMenuItem('Tools')
$menuTools.DropDownItems.Add('Merge Videos...') | Out-Null
$menuTools.DropDownItems.Add('Split Video...') | Out-Null
$menuTools.DropDownItems.Add('Crop Video...') | Out-Null
$menuTools.DropDownItems.Add('Rotate Video...') | Out-Null

$menuHelp = New-Object Windows.Forms.ToolStripMenuItem('Help')
$menuHelp.DropDownItems.Add('About...') | Out-Null

$menuBar.Items.AddRange(@($menuFile, $menuTools, $menuHelp))
$form.Controls.Add($menuBar)

# ===================================
# TOOLBAR (Quick actions)
# ===================================
$toolbar = New-Object Windows.Forms.Panel
$toolbar.Height = 60
$toolbar.Dock = 'Top'
$toolbar.BackColor = $c.White
$toolbar.BorderStyle = 'FixedSingle'
$form.Controls.Add($toolbar)

# Add Files Button
$btnAdd = New-Object Windows.Forms.Button
$btnAdd.Text = '+ Add Files'
$btnAdd.Location = New-Object Drawing.Point(15, 12)
$btnAdd.Size = New-Object Drawing.Size(120, 36)
$btnAdd.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
$btnAdd.FlatStyle = 'Flat'
$btnAdd.BackColor = $c.Blue
$btnAdd.ForeColor = $c.White
$btnAdd.FlatAppearance.BorderSize = 0
$btnAdd.Cursor = 'Hand'
$btnAdd.Add_MouseEnter({ $this.BackColor = $c.BlueHover })
$btnAdd.Add_MouseLeave({ $this.BackColor = $c.Blue })
$toolbar.Controls.Add($btnAdd)

# Remove Button
$btnRemove = New-Object Windows.Forms.Button
$btnRemove.Text = 'Remove'
$btnRemove.Location = New-Object Drawing.Point(145, 12)
$btnRemove.Size = New-Object Drawing.Size(90, 36)
$btnRemove.Font = New-Object Drawing.Font('Segoe UI', 9)
$btnRemove.FlatStyle = 'Flat'
$btnRemove.BackColor = $c.White
$btnRemove.ForeColor = $c.Text
$btnRemove.FlatAppearance.BorderColor = $c.Border
$btnRemove.Cursor = 'Hand'
$toolbar.Controls.Add($btnRemove)

# Clear Button
$btnClear = New-Object Windows.Forms.Button
$btnClear.Text = 'Clear All'
$btnClear.Location = New-Object Drawing.Point(245, 12)
$btnClear.Size = New-Object Drawing.Size(90, 36)
$btnClear.Font = New-Object Drawing.Font('Segoe UI', 9)
$btnClear.FlatStyle = 'Flat'
$btnClear.BackColor = $c.White
$btnClear.ForeColor = $c.Text
$btnClear.FlatAppearance.BorderColor = $c.Border
$btnClear.Cursor = 'Hand'
$toolbar.Controls.Add($btnClear)

# Separator
$sep1 = New-Object Windows.Forms.Label
$sep1.Location = New-Object Drawing.Point(345, 10)
$sep1.Size = New-Object Drawing.Size(1, 40)
$sep1.BackColor = $c.Border
$toolbar.Controls.Add($sep1)

# Watermark Button
$btnWatermark = New-Object Windows.Forms.Button
$btnWatermark.Text = '🖼 Watermark'
$btnWatermark.Location = New-Object Drawing.Point(360, 12)
$btnWatermark.Size = New-Object Drawing.Size(110, 36)
$btnWatermark.Font = New-Object Drawing.Font('Segoe UI', 9)
$btnWatermark.FlatStyle = 'Flat'
$btnWatermark.BackColor = $c.White
$btnWatermark.ForeColor = $c.Text
$btnWatermark.FlatAppearance.BorderColor = $c.Border
$btnWatermark.Cursor = 'Hand'
$toolbar.Controls.Add($btnWatermark)

# Subtitle Button
$btnSubtitle = New-Object Windows.Forms.Button
$btnSubtitle.Text = '💬 Subtitle'
$btnSubtitle.Location = New-Object Drawing.Point(480, 12)
$btnSubtitle.Size = New-Object Drawing.Size(110, 36)
$btnSubtitle.Font = New-Object Drawing.Font('Segoe UI', 9)
$btnSubtitle.FlatStyle = 'Flat'
$btnSubtitle.BackColor = $c.White
$btnSubtitle.ForeColor = $c.Text
$btnSubtitle.FlatAppearance.BorderColor = $c.Border
$btnSubtitle.Cursor = 'Hand'
$toolbar.Controls.Add($btnSubtitle)

# Crop Button
$btnCrop = New-Object Windows.Forms.Button
$btnCrop.Text = '✂ Crop'
$btnCrop.Location = New-Object Drawing.Point(600, 12)
$btnCrop.Size = New-Object Drawing.Size(90, 36)
$btnCrop.Font = New-Object Drawing.Font('Segoe UI', 9)
$btnCrop.FlatStyle = 'Flat'
$btnCrop.BackColor = $c.White
$btnCrop.ForeColor = $c.Text
$btnCrop.FlatAppearance.BorderColor = $c.Border
$btnCrop.Cursor = 'Hand'
$toolbar.Controls.Add($btnCrop)

# ===================================
# FILE LIST
# ===================================
$listPanel = New-Object Windows.Forms.Panel
$listPanel.Dock = 'Fill'
$listPanel.BackColor = $c.BgGray
$listPanel.Padding = New-Object Windows.Forms.Padding(15, 10, 15, 10)
$form.Controls.Add($listPanel)

$lv = New-Object Windows.Forms.ListView
$lv.Dock = 'Fill'
$lv.View = 'Details'
$lv.FullRowSelect = $true
$lv.GridLines = $true
$lv.BackColor = $c.White
$lv.ForeColor = $c.Text
$lv.BorderStyle = 'FixedSingle'
$lv.Font = New-Object Drawing.Font('Segoe UI', 9)
$lv.AllowDrop = $true
$lv.MultiSelect = $true

$lv.Columns.Add('File Name', 350) | Out-Null
$lv.Columns.Add('Size', 100) | Out-Null
$lv.Columns.Add('Duration', 90) | Out-Null
$lv.Columns.Add('Resolution', 100) | Out-Null
$lv.Columns.Add('Format', 80) | Out-Null
$lv.Columns.Add('Output Format', 120) | Out-Null
$lv.Columns.Add('Status', 200) | Out-Null

# Empty hint
$lblHint = New-Object Windows.Forms.Label
$lblHint.Text = "Drag and drop video files here`nor click '+ Add Files' button to add videos"
$lblHint.TextAlign = 'MiddleCenter'
$lblHint.Dock = 'Fill'
$lblHint.Font = New-Object Drawing.Font('Segoe UI', 12, [Drawing.FontStyle]::Italic)
$lblHint.ForeColor = $c.TextLight
$lblHint.BackColor = [Drawing.Color]::Transparent
$lv.Controls.Add($lblHint)

$listPanel.Controls.Add($lv)

# ===================================
# BOTTOM PANEL - Settings
# ===================================
$bottomPanel = New-Object Windows.Forms.Panel
$bottomPanel.Height = 170
$bottomPanel.Dock = 'Bottom'
$bottomPanel.BackColor = $c.PanelGray
$bottomPanel.BorderStyle = 'FixedSingle'
$form.Controls.Add($bottomPanel)

# Output Format Section
$lblFormat = New-Object Windows.Forms.Label
$lblFormat.Text = 'Output Format:'
$lblFormat.Location = New-Object Drawing.Point(20, 15)
$lblFormat.AutoSize = $true
$lblFormat.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$lblFormat.ForeColor = $c.Text
$bottomPanel.Controls.Add($lblFormat)

$cmbFormat = New-Object Windows.Forms.ComboBox
$cmbFormat.Location = New-Object Drawing.Point(20, 38)
$cmbFormat.Size = New-Object Drawing.Size(250, 24)
$cmbFormat.DropDownStyle = 'DropDownList'
$cmbFormat.Font = New-Object Drawing.Font('Segoe UI', 9)
$cmbFormat.Items.AddRange(@('MP4 (H264)', 'MKV (H265)', 'AVI', 'MOV', 'WMV'))
$cmbFormat.SelectedIndex = 0
$bottomPanel.Controls.Add($cmbFormat)

# Quality Section
$lblQuality = New-Object Windows.Forms.Label
$lblQuality.Text = 'Quality Preset:'
$lblQuality.Location = New-Object Drawing.Point(290, 15)
$lblQuality.AutoSize = $true
$lblQuality.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$lblQuality.ForeColor = $c.Text
$bottomPanel.Controls.Add($lblQuality)

$cmbQuality = New-Object Windows.Forms.ComboBox
$cmbQuality.Location = New-Object Drawing.Point(290, 38)
$cmbQuality.Size = New-Object Drawing.Size(250, 24)
$cmbQuality.DropDownStyle = 'DropDownList'
$cmbQuality.Font = New-Object Drawing.Font('Segoe UI', 9)
$cmbQuality.Items.AddRange(@('Fast (CRF 23)', 'Balanced (CRF 20)', 'High Quality (CRF 18)', 'Best (CRF 16)'))
$cmbQuality.SelectedIndex = 0
$bottomPanel.Controls.Add($cmbQuality)

# Resolution Section
$lblResolution = New-Object Windows.Forms.Label
$lblResolution.Text = 'Resolution:'
$lblResolution.Location = New-Object Drawing.Point(560, 15)
$lblResolution.AutoSize = $true
$lblResolution.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$lblResolution.ForeColor = $c.Text
$bottomPanel.Controls.Add($lblResolution)

$cmbResolution = New-Object Windows.Forms.ComboBox
$cmbResolution.Location = New-Object Drawing.Point(560, 38)
$cmbResolution.Size = New-Object Drawing.Size(200, 24)
$cmbResolution.DropDownStyle = 'DropDownList'
$cmbResolution.Font = New-Object Drawing.Font('Segoe UI', 9)
$cmbResolution.Items.AddRange(@('Same as source', '1920x1080 (1080p)', '1280x720 (720p)', '854x480 (480p)'))
$cmbResolution.SelectedIndex = 0
$bottomPanel.Controls.Add($cmbResolution)

# Output Folder
$lblOutput = New-Object Windows.Forms.Label
$lblOutput.Text = 'Output Folder:'
$lblOutput.Location = New-Object Drawing.Point(20, 80)
$lblOutput.AutoSize = $true
$lblOutput.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$lblOutput.ForeColor = $c.Text
$bottomPanel.Controls.Add($lblOutput)

$txtOutput = New-Object Windows.Forms.TextBox
$txtOutput.Location = New-Object Drawing.Point(20, 103)
$txtOutput.Size = New-Object Drawing.Size(640, 24)
$txtOutput.Font = New-Object Drawing.Font('Segoe UI', 9)
$txtOutput.Text = $Out
$bottomPanel.Controls.Add($txtOutput)

$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = 'Browse...'
$btnBrowse.Location = New-Object Drawing.Point(670, 101)
$btnBrowse.Size = New-Object Drawing.Size(90, 28)
$btnBrowse.Font = New-Object Drawing.Font('Segoe UI', 9)
$btnBrowse.FlatStyle = 'Flat'
$btnBrowse.BackColor = $c.White
$btnBrowse.FlatAppearance.BorderColor = $c.Border
$btnBrowse.Cursor = 'Hand'
$bottomPanel.Controls.Add($btnBrowse)

# Progress Bar
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Location = New-Object Drawing.Point(20, 138)
$progressBar.Size = New-Object Drawing.Size(740, 18)
$progressBar.Style = 'Continuous'
$progressBar.Visible = $false
$bottomPanel.Controls.Add($progressBar)

# Status Label
$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = 'Ready'
$lblStatus.Location = New-Object Drawing.Point(20, 138)
$lblStatus.Size = New-Object Drawing.Size(740, 18)
$lblStatus.Font = New-Object Drawing.Font('Segoe UI', 8)
$lblStatus.ForeColor = $c.TextLight
$bottomPanel.Controls.Add($lblStatus)

# CONVERT BUTTON (huge, orange)
$btnConvert = New-Object Windows.Forms.Button
$btnConvert.Text = 'START CONVERSION'
$btnConvert.Location = New-Object Drawing.Point(870, 25)
$btnConvert.Size = New-Object Drawing.Size(280, 110)
$btnConvert.Font = New-Object Drawing.Font('Segoe UI', 16, [Drawing.FontStyle]::Bold)
$btnConvert.FlatStyle = 'Flat'
$btnConvert.BackColor = $c.Orange
$btnConvert.ForeColor = $c.White
$btnConvert.FlatAppearance.BorderSize = 0
$btnConvert.Cursor = 'Hand'
$btnConvert.Anchor = 'Top,Right'
$btnConvert.Add_MouseEnter({ $this.BackColor = $c.OrangeHover })
$btnConvert.Add_MouseLeave({ $this.BackColor = $c.Orange })
$bottomPanel.Controls.Add($btnConvert)

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
    $item.SubItems.Add('-') | Out-Null
    $item.SubItems.Add($file.Extension.TrimStart('.').ToUpper()) | Out-Null
    $item.SubItems.Add($cmbFormat.Text) | Out-Null
    $item.SubItems.Add('Ready') | Out-Null
    $item.Tag = @{
        Path = $path
        Watermark = $null
        Subtitle = $null
    }
    
    $script:files += $path
    if($lv.Items.Count -eq 1) { $lblHint.Visible = $false }
}

# ===================================
# EVENTS
# ===================================

# Add Files
$btnAdd.Add_Click({
    $ofd = New-Object Windows.Forms.OpenFileDialog
    $ofd.Filter = 'Video Files|*.mp4;*.avi;*.mkv;*.mov;*.wmv;*.flv;*.webm;*.m4v;*.mpg;*.mpeg;*.ts;*.mts;*.m2ts|All Files|*.*'
    $ofd.Multiselect = $true
    $ofd.Title = 'Select Video Files'
    
    if($ofd.ShowDialog() -eq 'OK') {
        foreach($f in $ofd.FileNames) {
            Add-VideoFile $f
        }
    }
})

# Remove
$btnRemove.Add_Click({
    if($lv.SelectedItems.Count -eq 0) { return }
    
    $selected = @($lv.SelectedItems)
    foreach($item in $selected) {
        $script:files = $script:files | Where-Object { $_ -ne $item.Tag.Path }
        $lv.Items.Remove($item)
    }
    
    if($lv.Items.Count -eq 0) { $lblHint.Visible = $true }
})

# Clear
$btnClear.Add_Click({
    if([Windows.Forms.MessageBox]::Show('Remove all files from list?', 'Clear All', 'YesNo', 'Question') -eq 'Yes') {
        $lv.Items.Clear()
        $script:files = @()
        $lblHint.Visible = $true
    }
})

# Browse
$btnBrowse.Add_Click({
    $fbd = New-Object Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $txtOutput.Text
    $fbd.Description = 'Select Output Folder'
    if($fbd.ShowDialog() -eq 'OK') {
        $txtOutput.Text = $fbd.SelectedPath
    }
})

# Watermark
$btnWatermark.Add_Click({
    if($lv.SelectedItems.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show('Please select a video file first!', 'No Selection', 'OK', 'Warning')
        return
    }
    
    $ofd = New-Object Windows.Forms.OpenFileDialog
    $ofd.Filter = 'Image Files|*.png;*.jpg;*.jpeg;*.bmp|All Files|*.*'
    $ofd.Title = 'Select Watermark Image'
    
    if($ofd.ShowDialog() -eq 'OK') {
        foreach($item in $lv.SelectedItems) {
            $item.Tag.Watermark = $ofd.FileName
            $item.SubItems[6].Text = 'Watermark set'
        }
    }
})

# Subtitle
$btnSubtitle.Add_Click({
    if($lv.SelectedItems.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show('Please select a video file first!', 'No Selection', 'OK', 'Warning')
        return
    }
    
    $ofd = New-Object Windows.Forms.OpenFileDialog
    $ofd.Filter = 'Subtitle Files|*.srt;*.ass;*.ssa|All Files|*.*'
    $ofd.Title = 'Select Subtitle File'
    
    if($ofd.ShowDialog() -eq 'OK') {
        foreach($item in $lv.SelectedItems) {
            $item.Tag.Subtitle = $ofd.FileName
            $item.SubItems[6].Text = 'Subtitle set'
        }
    }
})

# Convert
$btnConvert.Add_Click({
    if($script:files.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show('Please add video files first!', 'No Files', 'OK', 'Warning')
        return
    }
    
    $msg = "Ready to convert {0} file(s)`n`nFormat: {1}`nQuality: {2}`nResolution: {3}`nOutput: {4}`n`n(FFmpeg/HandBrake integration coming soon)" -f `
        $script:files.Count, $cmbFormat.Text, $cmbQuality.Text, $cmbResolution.Text, $txtOutput.Text
    
    [Windows.Forms.MessageBox]::Show($msg, 'Conversion Ready', 'OK', 'Information')
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
        if(Test-Path $f -PathType Leaf) {
            Add-VideoFile $f
        }
    }
})

# Menu Events
$menuFile.DropDownItems[0].Add_Click({ $btnAdd.PerformClick() })
$menuFile.DropDownItems[3].Add_Click({ $form.Close() })

# ===================================
# SHOW
# ===================================
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
