<#
  PPC-GUI-Dark.ps1
  Apowersoft-style dark theme video converter
  Design: https://i.ibb.co/hxH50sFf/Screenshot-07-31-2025-11-30-21.png
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
@($Out, $Subs, $Ovls) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }

# State
$script:files = @()
$script:currentTab = 'Convert'

# WinForms + Advanced Graphics
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable Visual Styles and Text Rendering
[Windows.Forms.Application]::EnableVisualStyles()
[Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Apowersoft Dark Palette
$c = @{
    Bg = [Drawing.Color]::FromArgb(45,47,56)           # #2D2F38
    Panel = [Drawing.Color]::FromArgb(58,60,69)        # #3A3C45
    Panel2 = [Drawing.Color]::FromArgb(64,66,75)       # #40424B
    Text = [Drawing.Color]::White
    TextMuted = [Drawing.Color]::FromArgb(160,160,168) # #A0A0A8
    Accent = [Drawing.Color]::FromArgb(47,169,224)     # #2FA9E0
    AccentHover = [Drawing.Color]::FromArgb(54,179,232) # #36B3E8
    Border = [Drawing.Color]::FromArgb(76,78,87)       # #4C4E57
    Input = [Drawing.Color]::FromArgb(34,36,43)        # #22242B
    Green = [Drawing.Color]::FromArgb(46,204,113)
}

# ===================================
# MAIN FORM
# ===================================
$form = New-Object Windows.Forms.Form
$form.Text = 'Apowersoft Video Converter Studio'
$form.ClientSize = New-Object Drawing.Size(1600, 900)
$form.MinimumSize = New-Object Drawing.Size(1400, 800)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $c.Bg
$form.ForeColor = $c.Text
$form.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Regular)
$form.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Font

# ===================================
# TOP TABS (Convert, Split, MV, Download, Record)
# ===================================
$tabPanel = New-Object Windows.Forms.Panel
$tabPanel.Height = 50
$tabPanel.Dock = 'Top'
$tabPanel.BackColor = $c.Panel
$form.Controls.Add($tabPanel)

# Tab buttons
$tabs = @(
    @{label='Convert'; icon='↻'; active=$true},
    @{label='Split Screen'; icon=''; active=$false},
    @{label='Make MV'; icon=''; active=$false},
    @{label='Download'; icon=''; active=$false},
    @{label='Record'; icon=''; active=$false}
)

$tabX = 20
foreach($tab in $tabs) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = "$($tab.icon) $($tab.label)"
    $btn.Location = New-Object Drawing.Point($tabX, 10)
    $btn.Size = New-Object Drawing.Size(160, 36)
    $btn.FlatStyle = 'Flat'
    $btn.Font = New-Object Drawing.Font('Segoe UI', 10)
    
    if($tab.active) {
        $btn.BackColor = [Drawing.Color]::FromArgb(57,65,75)
        $btn.ForeColor = $c.Text
        $btn.FlatAppearance.BorderColor = $c.Border
    } else {
        $btn.BackColor = [Drawing.Color]::Transparent
        $btn.ForeColor = $c.TextMuted
        $btn.FlatAppearance.BorderSize = 0
    }
    
    $btn.FlatAppearance.BorderSize = 1
    $btn.Cursor = [Windows.Forms.Cursors]::Hand
    $tabPanel.Controls.Add($btn)
    $tabX += 170
}

# ===================================
# MAIN CONTENT AREA
# ===================================
$mainPanel = New-Object Windows.Forms.Panel
$mainPanel.Dock = 'Fill'
$mainPanel.BackColor = $c.Bg
$mainPanel.Padding = New-Object Windows.Forms.Padding(16)
$form.Controls.Add($mainPanel)

# Task List Header
$listHeader = New-Object Windows.Forms.Label
$listHeader.Text = 'Task List'
$listHeader.Location = New-Object Drawing.Point(20, 10)
$listHeader.Size = New-Object Drawing.Size(200, 25)
$listHeader.Font = New-Object Drawing.Font('Segoe UI', 11, [Drawing.FontStyle]::Bold)
$listHeader.ForeColor = $c.Text
$mainPanel.Controls.Add($listHeader)

# Add Files Button (top left of task area)
$btnAdd = New-Object Windows.Forms.Button
$btnAdd.Text = '+ Add Files'
$btnAdd.Location = New-Object Drawing.Point(20, 40)
$btnAdd.Size = New-Object Drawing.Size(140, 40)
$btnAdd.BackColor = $c.Accent
$btnAdd.ForeColor = $c.Text
$btnAdd.FlatStyle = 'Flat'
$btnAdd.FlatAppearance.BorderSize = 0
$btnAdd.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
$btnAdd.Cursor = [Windows.Forms.Cursors]::Hand
$mainPanel.Controls.Add($btnAdd)

# ListView (Task List) - Dark styled
$lv = New-Object Windows.Forms.ListView
$lv.Location = New-Object Drawing.Point(20, 90)
$lv.Size = New-Object Drawing.Size(1540, 520)
$lv.Anchor = 'Top,Left,Right,Bottom'
$lv.View = 'Details'
$lv.FullRowSelect = $true
$lv.GridLines = $false
$lv.MultiSelect = $true
$lv.AllowDrop = $true
$lv.BackColor = $c.Panel
$lv.ForeColor = $c.Text
$lv.BorderStyle = 'FixedSingle'
$lv.HeaderStyle = 'Nonclickable'
$lv.Font = New-Object Drawing.Font('Segoe UI', 10)

# Columns
$lv.Columns.Add('File Name', 400) | Out-Null
$lv.Columns.Add('Size', 120) | Out-Null
$lv.Columns.Add('Duration', 120) | Out-Null
$lv.Columns.Add('Resolution', 140) | Out-Null
$lv.Columns.Add('Format', 110) | Out-Null
$lv.Columns.Add('Output Format', 220) | Out-Null
$lv.Columns.Add('Status', 160) | Out-Null

$mainPanel.Controls.Add($lv)

# Hint label (drag and drop)
$lblHint = New-Object Windows.Forms.Label
$lblHint.Text = "Drag and drop video files here or click '+ Add Files' to get started"
$lblHint.Location = New-Object Drawing.Point(600, 360)
$lblHint.Size = New-Object Drawing.Size(500, 50)
$lblHint.TextAlign = 'MiddleCenter'
$lblHint.ForeColor = $c.TextMuted
$lblHint.Font = New-Object Drawing.Font('Segoe UI', 11, [Drawing.FontStyle]::Italic)
$lblHint.BackColor = [Drawing.Color]::Transparent
$mainPanel.Controls.Add($lblHint)
$lblHint.BringToFront()

# ===================================
# BOTTOM BAR (Controls)
# ===================================
$bottomBar = New-Object Windows.Forms.Panel
$bottomBar.Height = 160
$bottomBar.Dock = 'Bottom'
$bottomBar.BackColor = [Drawing.Color]::FromArgb(48,50,58)
$bottomBar.Padding = New-Object Windows.Forms.Padding(16)
$form.Controls.Add($bottomBar)

# Clear task list button
$btnClear = New-Object Windows.Forms.Button
$btnClear.Text = 'Clear task list'
$btnClear.Location = New-Object Drawing.Point(20, 15)
$btnClear.Size = New-Object Drawing.Size(110, 30)
$btnClear.BackColor = [Drawing.Color]::Transparent
$btnClear.ForeColor = $c.TextMuted
$btnClear.FlatStyle = 'Flat'
$btnClear.FlatAppearance.BorderColor = $c.Border
$btnClear.Cursor = [Windows.Forms.Cursors]::Hand
$bottomBar.Controls.Add($btnClear)

# Remove selected button
$btnRemove = New-Object Windows.Forms.Button
$btnRemove.Text = 'Remove selected'
$btnRemove.Location = New-Object Drawing.Point(140, 15)
$btnRemove.Size = New-Object Drawing.Size(120, 30)
$btnRemove.BackColor = [Drawing.Color]::Transparent
$btnRemove.ForeColor = $c.TextMuted
$btnRemove.FlatStyle = 'Flat'
$btnRemove.FlatAppearance.BorderColor = $c.Border
$btnRemove.Cursor = [Windows.Forms.Cursors]::Hand
$bottomBar.Controls.Add($btnRemove)

# Merge checkbox
$chkMerge = New-Object Windows.Forms.CheckBox
$chkMerge.Text = 'Merge into one file'
$chkMerge.Location = New-Object Drawing.Point(280, 18)
$chkMerge.Size = New-Object Drawing.Size(150, 25)
$chkMerge.ForeColor = $c.Text
$bottomBar.Controls.Add($chkMerge)

# Profile label
$lblProfile = New-Object Windows.Forms.Label
$lblProfile.Text = 'Profile:'
$lblProfile.Location = New-Object Drawing.Point(20, 60)
$lblProfile.Size = New-Object Drawing.Size(60, 25)
$lblProfile.ForeColor = $c.Text
$bottomBar.Controls.Add($lblProfile)

# Profile ComboBox
$cmbProfile = New-Object Windows.Forms.ComboBox
$cmbProfile.Location = New-Object Drawing.Point(80, 58)
$cmbProfile.Size = New-Object Drawing.Size(500, 28)
$cmbProfile.DropDownStyle = 'DropDownList'
$cmbProfile.BackColor = $c.Input
$cmbProfile.ForeColor = $c.Text
$cmbProfile.FlatStyle = 'Flat'
$cmbProfile.Font = New-Object Drawing.Font('Segoe UI', 10)
@(
    'MP4 - Same as source (H.264; AAC; 128Kbps Stereo)',
    'MP4 - 1080p High Quality (H.264; AAC; 160Kbps)',
    'MP4 - 720p Optimized (H.264; AAC; 128Kbps)',
    'MKV - High Quality (H.265; AAC; 160Kbps)',
    'AVI - Compatible (MPEG4; MP3; 128Kbps)'
) | ForEach-Object { $cmbProfile.Items.Add($_) | Out-Null }
$cmbProfile.SelectedIndex = 0
$bottomBar.Controls.Add($cmbProfile)

# Output folder label
$lblOutput = New-Object Windows.Forms.Label
$lblOutput.Text = 'Output:'
$lblOutput.Location = New-Object Drawing.Point(20, 95)
$lblOutput.Size = New-Object Drawing.Size(60, 25)
$lblOutput.ForeColor = $c.Text
$bottomBar.Controls.Add($lblOutput)

# Output path TextBox
$txtOutput = New-Object Windows.Forms.TextBox
$txtOutput.Text = $Out
$txtOutput.Location = New-Object Drawing.Point(80, 93)
$txtOutput.Size = New-Object Drawing.Size(420, 28)
$txtOutput.BackColor = $c.Input
$txtOutput.ForeColor = $c.Text
$txtOutput.BorderStyle = 'FixedSingle'
$txtOutput.ReadOnly = $true
$txtOutput.Font = New-Object Drawing.Font('Segoe UI', 10)
$bottomBar.Controls.Add($txtOutput)

# Browse button
$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = 'Browse...'
$btnBrowse.Location = New-Object Drawing.Point(490, 91)
$btnBrowse.Size = New-Object Drawing.Size(70, 28)
$btnBrowse.BackColor = $c.Panel2
$btnBrowse.ForeColor = $c.Text
$btnBrowse.FlatStyle = 'Flat'
$btnBrowse.FlatAppearance.BorderColor = $c.Border
$btnBrowse.Cursor = [Windows.Forms.Cursors]::Hand
$bottomBar.Controls.Add($btnBrowse)

# Settings button
$btnSettings = New-Object Windows.Forms.Button
$btnSettings.Text = 'Settings'
$btnSettings.Location = New-Object Drawing.Point(580, 91)
$btnSettings.Size = New-Object Drawing.Size(80, 28)
$btnSettings.BackColor = $c.Panel2
$btnSettings.ForeColor = $c.Text
$btnSettings.FlatStyle = 'Flat'
$btnSettings.FlatAppearance.BorderColor = $c.Border
$btnSettings.Cursor = [Windows.Forms.Cursors]::Hand
$bottomBar.Controls.Add($btnSettings)

# Open folder button
$btnOpen = New-Object Windows.Forms.Button
$btnOpen.Text = 'Open'
$btnOpen.Location = New-Object Drawing.Point(670, 91)
$btnOpen.Size = New-Object Drawing.Size(70, 28)
$btnOpen.BackColor = $c.Panel2
$btnOpen.ForeColor = $c.Text
$btnOpen.FlatStyle = 'Flat'
$btnOpen.FlatAppearance.BorderColor = $c.Border
$btnOpen.Cursor = [Windows.Forms.Cursors]::Hand
$bottomBar.Controls.Add($btnOpen)

# Shutdown checkbox
$chkShutdown = New-Object Windows.Forms.CheckBox
$chkShutdown.Text = 'Shutdown computer after conversion'
$chkShutdown.Location = New-Object Drawing.Point(20, 130)
$chkShutdown.Size = New-Object Drawing.Size(280, 25)
$chkShutdown.ForeColor = $c.TextMuted
$bottomBar.Controls.Add($chkShutdown)

# CONVERT BUTTON (Main action - big orange/blue button)
$btnConvert = New-Object Windows.Forms.Button
$btnConvert.Text = 'CONVERT'
$btnConvert.Location = New-Object Drawing.Point(1120, 20)
$btnConvert.Size = New-Object Drawing.Size(420, 130)
$btnConvert.Anchor = 'Right,Bottom'
$btnConvert.BackColor = $c.Accent
$btnConvert.ForeColor = $c.Text
$btnConvert.FlatStyle = 'Flat'
$btnConvert.FlatAppearance.BorderSize = 0
$btnConvert.Font = New-Object Drawing.Font('Segoe UI', 22, [Drawing.FontStyle]::Bold)
$btnConvert.Cursor = [Windows.Forms.Cursors]::Hand
$bottomBar.Controls.Add($btnConvert)

# Status label (bottom left)
$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = 'Ready'
$lblStatus.Location = New-Object Drawing.Point(20, 520)
$lblStatus.Size = New-Object Drawing.Size(600, 20)
$lblStatus.Anchor = 'Left,Bottom'
$lblStatus.ForeColor = $c.TextMuted
$lblStatus.Font = New-Object Drawing.Font('Segoe UI', 9)
$mainPanel.Controls.Add($lblStatus)

# ===================================
# EVENT HANDLERS
# ===================================

# Add Files Button
$btnAdd.Add_Click({
    try {
        $ofd = New-Object Windows.Forms.OpenFileDialog
        $ofd.Filter = 'Video Files|*.mp4;*.avi;*.mkv;*.mov;*.wmv;*.flv;*.webm;*.m4v;*.mpg;*.mpeg;*.ts;*.mts;*.m2ts|All Files|*.*'
        $ofd.Multiselect = $true
        $ofd.Title = 'Select Video Files'
        
        if($ofd.ShowDialog($form) -eq [Windows.Forms.DialogResult]::OK) {
            $addedCount = 0
            
            foreach($filePath in $ofd.FileNames) {
                if(-not (Test-Path $filePath)) {
                    [Windows.Forms.MessageBox]::Show("File not found:`n$filePath", 'Error', 'OK', 'Error')
                    continue
                }
                
                # Skip duplicates
                if($script:files -contains $filePath) {
                    continue
                }
                
                # Add to ListView
                $fileInfo = Get-Item $filePath
                $listItem = New-Object Windows.Forms.ListViewItem($fileInfo.Name)
                $listItem.SubItems.Add(('{0:N2} MB' -f ($fileInfo.Length/1MB)))
                $listItem.SubItems.Add('-')
                $listItem.SubItems.Add('-')
                $listItem.SubItems.Add($fileInfo.Extension.TrimStart('.').ToUpper())
                $listItem.SubItems.Add('MP4 (H.264)')
                $listItem.SubItems.Add('Ready')
                $listItem.Tag = @{ Path = $filePath; Watermark = $null; Subtitle = $null }
                
                $lv.Items.Add($listItem) | Out-Null
                $script:files += $filePath
                $addedCount++
                
                # Hide hint
                if($lv.Items.Count -ge 1) { 
                    $lblHint.Visible = $false 
                }
            }
            
            # Update status
            if($addedCount -gt 0) {
                $lblStatus.Text = "Added $addedCount file(s) - Ready to convert"
                $lblStatus.ForeColor = $c.Green
            }
        }
    } catch {
        [Windows.Forms.MessageBox]::Show("Error:`n$($_.Exception.Message)", 'Error', 'OK', 'Error')
    }
})

# Clear task list
$btnClear.Add_Click({
    $lv.Items.Clear()
    $script:files = @()
    $lblHint.Visible = $true
    $lblStatus.Text = 'Ready'
    $lblStatus.ForeColor = $c.TextMuted
})

# Remove selected
$btnRemove.Add_Click({
    $selected = $lv.SelectedItems
    if($selected.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show('No files selected', 'Info', 'OK', 'Information')
        return
    }
    
    foreach($item in $selected) {
        $path = $item.Tag.Path
        $script:files = $script:files | Where-Object { $_ -ne $path }
        $lv.Items.Remove($item)
    }
    
    if($lv.Items.Count -eq 0) {
        $lblHint.Visible = $true
    }
    
    $lblStatus.Text = "Removed $($selected.Count) file(s)"
    $lblStatus.ForeColor = $c.Green
})

# Browse output folder
$btnBrowse.Add_Click({
    $fbd = New-Object Windows.Forms.FolderBrowserDialog
    $fbd.SelectedPath = $txtOutput.Text
    $fbd.Description = 'Select Output Folder'
    
    if($fbd.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
        $txtOutput.Text = $fbd.SelectedPath
    }
})

# Open output folder
$btnOpen.Add_Click({
    if(Test-Path $txtOutput.Text) {
        Start-Process explorer $txtOutput.Text
    }
})

# Convert button (placeholder - FFmpeg integration needed)
$btnConvert.Add_Click({
    if($lv.Items.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show('No files to convert. Add videos first.', 'Info', 'OK', 'Information')
        return
    }
    
    $msg = "Ready to convert $($lv.Items.Count) file(s)`n`n"
    $msg += "Format: $($cmbProfile.Text)`n"
    $msg += "Resolution: Same as source`n"
    $msg += "Output: $($txtOutput.Text)`n`n"
    $msg += "NEXT STEPS:`n"
    $msg += "1. HandBrake will be downloaded (~15 MB)`n"
    $msg += "2. Installation takes ~2-3 minutes`n"
    $msg += "3. Conversion will start automatically`n`n"
    $msg += "(HandBrake integration coming in next update)"
    
    [Windows.Forms.MessageBox]::Show($msg, 'Conversion Ready', 'OK', 'Information')
})

# Drag and Drop
$lv.Add_DragEnter({
    param($sender, $e)
    if($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = 'Copy'
    }
})

$lv.Add_DragDrop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    foreach($file in $files) {
        if((Test-Path $file) -and ($file -match '\.(mp4|avi|mkv|mov|wmv|flv|webm|m4v|mpg|mpeg|ts|mts|m2ts)$')) {
            if($script:files -notcontains $file) {
                $fileInfo = Get-Item $file
                $listItem = New-Object Windows.Forms.ListViewItem($fileInfo.Name)
                $listItem.SubItems.Add(('{0:N2} MB' -f ($fileInfo.Length/1MB)))
                $listItem.SubItems.Add('-')
                $listItem.SubItems.Add('-')
                $listItem.SubItems.Add($fileInfo.Extension.TrimStart('.').ToUpper())
                $listItem.SubItems.Add('MP4 (H.264)')
                $listItem.SubItems.Add('Ready')
                $listItem.Tag = @{ Path = $file; Watermark = $null; Subtitle = $null }
                
                [void]$lv.Items.Add($listItem)
                $script:files += $file
                $lblHint.Visible = $false
            }
        }
    }
    
    if($lv.Items.Count -gt 0) {
        $lblStatus.Text = "Files added via drag & drop"
        $lblStatus.ForeColor = $c.Green
    }
})

# ===================================
# SHOW FORM
# ===================================
[Windows.Forms.Application]::Run($form)
