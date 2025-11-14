#Requires -Version 5.1
<#
.SYNOPSIS
    Perfect Portable Converter - HandBrake Style GUI
.DESCRIPTION
    Modern video converter with HandBrake-inspired interface
    Dark theme, drag & drop, batch conversion support
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable visual styles
[System.Windows.Forms.Application]::EnableVisualStyles()

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Perfect Converter"
$form.Size = New-Object System.Drawing.Size(1280, 720)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.MinimumSize = New-Object System.Drawing.Size(800, 600)

# Menu Bar
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$menuStrip.ForeColor = [System.Drawing.Color]::White

$menuConvert = New-Object System.Windows.Forms.ToolStripMenuItem
$menuConvert.Text = "Convert"
$menuStrip.Items.Add($menuConvert) | Out-Null

$menuSplitScreen = New-Object System.Windows.Forms.ToolStripMenuItem
$menuSplitScreen.Text = "Split Screen"
$menuStrip.Items.Add($menuSplitScreen) | Out-Null

$menuMakeMV = New-Object System.Windows.Forms.ToolStripMenuItem
$menuMakeMV.Text = "Make MV"
$menuStrip.Items.Add($menuMakeMV) | Out-Null

$menuDownload = New-Object System.Windows.Forms.ToolStripMenuItem
$menuDownload.Text = "Download"
$menuStrip.Items.Add($menuDownload) | Out-Null

$menuRecord = New-Object System.Windows.Forms.ToolStripMenuItem
$menuRecord.Text = "Record"
$menuStrip.Items.Add($menuRecord) | Out-Null

$form.Controls.Add($menuStrip)

# Toolbar Panel
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$toolbar.Dock = [System.Windows.Forms.DockStyle]::Top
$toolbar.Height = 50
$toolbar.Top = $menuStrip.Height

# Add Files Button
$btnAddFiles = New-Object System.Windows.Forms.Button
$btnAddFiles.Text = "+ Add Files"
$btnAddFiles.Location = New-Object System.Drawing.Point(10, 10)
$btnAddFiles.Size = New-Object System.Drawing.Size(120, 30)
$btnAddFiles.BackColor = [System.Drawing.Color]::FromArgb(78, 182, 255)
$btnAddFiles.ForeColor = [System.Drawing.Color]::White
$btnAddFiles.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnAddFiles.FlatAppearance.BorderSize = 0
$btnAddFiles.Cursor = [System.Windows.Forms.Cursors]::Hand
$toolbar.Controls.Add($btnAddFiles)

# Settings Button
$btnSettings = New-Object System.Windows.Forms.Button
$btnSettings.Text = "⚙"
$btnSettings.Location = New-Object System.Drawing.Point(140, 10)
$btnSettings.Size = New-Object System.Drawing.Size(30, 30)
$btnSettings.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$btnSettings.ForeColor = [System.Drawing.Color]::White
$btnSettings.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSettings.FlatAppearance.BorderSize = 1
$btnSettings.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$btnSettings.Cursor = [System.Windows.Forms.Cursors]::Hand
$toolbar.Controls.Add($btnSettings)

# Open Output Button
$btnOpenOutput = New-Object System.Windows.Forms.Button
$btnOpenOutput.Text = "📁"
$btnOpenOutput.Location = New-Object System.Drawing.Point(180, 10)
$btnOpenOutput.Size = New-Object System.Drawing.Size(30, 30)
$btnOpenOutput.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$btnOpenOutput.ForeColor = [System.Drawing.Color]::White
$btnOpenOutput.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOpenOutput.FlatAppearance.BorderSize = 1
$btnOpenOutput.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$btnOpenOutput.Cursor = [System.Windows.Forms.Cursors]::Hand
$toolbar.Controls.Add($btnOpenOutput)

$form.Controls.Add($toolbar)

# Main Content Panel
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)
$mainPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$mainPanel.Padding = New-Object System.Windows.Forms.Padding(10)

# File List View
$listView = New-Object System.Windows.Forms.ListView
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)
$listView.ForeColor = [System.Drawing.Color]::White
$listView.Location = New-Object System.Drawing.Point(10, 10)
$listView.Size = New-Object System.Drawing.Size(1240, 400)
$listView.AllowDrop = $true

# Add columns
$listView.Columns.Add("File Name", 300) | Out-Null
$listView.Columns.Add("Size", 100) | Out-Null
$listView.Columns.Add("Duration", 100) | Out-Null
$listView.Columns.Add("Resolution", 120) | Out-Null
$listView.Columns.Add("Format", 80) | Out-Null
$listView.Columns.Add("Output Format", 150) | Out-Null
$listView.Columns.Add("Status", 150) | Out-Null

$mainPanel.Controls.Add($listView)

# Drag & Drop Label (shown when list is empty)
$lblDragDrop = New-Object System.Windows.Forms.Label
$lblDragDrop.Text = "Drag and drop video files here or click '+ Add Files' to get started"
$lblDragDrop.Location = New-Object System.Drawing.Point(400, 200)
$lblDragDrop.Size = New-Object System.Drawing.Size(500, 30)
$lblDragDrop.ForeColor = [System.Drawing.Color]::Gray
$lblDragDrop.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblDragDrop.Visible = $true
$mainPanel.Controls.Add($lblDragDrop)

# Profile Selection Panel
$profilePanel = New-Object System.Windows.Forms.Panel
$profilePanel.Location = New-Object System.Drawing.Point(10, 420)
$profilePanel.Size = New-Object System.Drawing.Size(1240, 40)
$profilePanel.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)

$lblProfile = New-Object System.Windows.Forms.Label
$lblProfile.Text = "Profile:"
$lblProfile.Location = New-Object System.Drawing.Point(0, 10)
$lblProfile.Size = New-Object System.Drawing.Size(60, 20)
$lblProfile.ForeColor = [System.Drawing.Color]::White
$profilePanel.Controls.Add($lblProfile)

$cboProfile = New-Object System.Windows.Forms.ComboBox
$cboProfile.Location = New-Object System.Drawing.Point(70, 8)
$cboProfile.Size = New-Object System.Drawing.Size(500, 25)
$cboProfile.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$cboProfile.ForeColor = [System.Drawing.Color]::White
$cboProfile.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

# Add profiles
$profiles = @(
    "MP4 - Same as source (H.264 AAC, 128Kbps Stereo)",
    "MP4 - Fast 1080p (H.264 AAC, 128Kbps Stereo)",
    "MP4 - High Quality (H.264 AAC, 160Kbps Stereo)",
    "MP4 - Small Size 720p (H.264 AAC, 128Kbps Stereo)",
    "MKV - HEVC/H.265 (AAC 160Kbps Stereo)",
    "MP4 - Web Optimized (H.264 AAC, 96Kbps Stereo)",
    "MP4 - 4K Ultra HD (H.264 AAC, 192Kbps Stereo)",
    "AVI - DivX Compatible (MP3 128Kbps Stereo)",
    "MOV - Apple ProRes (AAC 256Kbps Stereo)",
    "WEBM - VP9 (Opus 128Kbps Stereo)"
)

foreach ($profile in $profiles) {
    $cboProfile.Items.Add($profile) | Out-Null
}
$cboProfile.SelectedIndex = 0

$profilePanel.Controls.Add($cboProfile)
$mainPanel.Controls.Add($profilePanel)

# Output Path Panel
$outputPanel = New-Object System.Windows.Forms.Panel
$outputPanel.Location = New-Object System.Drawing.Point(10, 470)
$outputPanel.Size = New-Object System.Drawing.Size(1240, 40)
$outputPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)

$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = "Output:"
$lblOutput.Location = New-Object System.Drawing.Point(0, 10)
$lblOutput.Size = New-Object System.Drawing.Size(60, 20)
$lblOutput.ForeColor = [System.Drawing.Color]::White
$outputPanel.Controls.Add($lblOutput)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(70, 8)
$txtOutput.Size = New-Object System.Drawing.Size(450, 25)
$txtOutput.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$txtOutput.ForeColor = [System.Drawing.Color]::White
$txtOutput.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtOutput.Text = [System.IO.Path]::Combine($PSScriptRoot, "output")
$outputPanel.Controls.Add($txtOutput)

$btnBrowseOutput = New-Object System.Windows.Forms.Button
$btnBrowseOutput.Text = "Browse..."
$btnBrowseOutput.Location = New-Object System.Drawing.Point(530, 7)
$btnBrowseOutput.Size = New-Object System.Drawing.Size(80, 27)
$btnBrowseOutput.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$btnBrowseOutput.ForeColor = [System.Drawing.Color]::White
$btnBrowseOutput.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnBrowseOutput.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$btnBrowseOutput.Cursor = [System.Windows.Forms.Cursors]::Hand
$outputPanel.Controls.Add($btnBrowseOutput)

$mainPanel.Controls.Add($outputPanel)

# Bottom Control Panel
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Location = New-Object System.Drawing.Point(10, 520)
$bottomPanel.Size = New-Object System.Drawing.Size(1240, 40)
$bottomPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)

$btnClearList = New-Object System.Windows.Forms.Button
$btnClearList.Text = "Clear task list"
$btnClearList.Location = New-Object System.Drawing.Point(0, 5)
$btnClearList.Size = New-Object System.Drawing.Size(100, 30)
$btnClearList.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$btnClearList.ForeColor = [System.Drawing.Color]::White
$btnClearList.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearList.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$btnClearList.Cursor = [System.Windows.Forms.Cursors]::Hand
$bottomPanel.Controls.Add($btnClearList)

$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "Remove"
$btnRemove.Location = New-Object System.Drawing.Point(110, 5)
$btnRemove.Size = New-Object System.Drawing.Size(80, 30)
$btnRemove.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$btnRemove.ForeColor = [System.Drawing.Color]::White
$btnRemove.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRemove.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$btnRemove.Cursor = [System.Windows.Forms.Cursors]::Hand
$bottomPanel.Controls.Add($btnRemove)

$chkMerge = New-Object System.Windows.Forms.CheckBox
$chkMerge.Text = "Merge into one file"
$chkMerge.Location = New-Object System.Drawing.Point(200, 10)
$chkMerge.Size = New-Object System.Drawing.Size(150, 20)
$chkMerge.ForeColor = [System.Drawing.Color]::White
$bottomPanel.Controls.Add($chkMerge)

$mainPanel.Controls.Add($bottomPanel)

$form.Controls.Add($mainPanel)

# Status Bar
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$statusStrip.ForeColor = [System.Drawing.Color]::White

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "HandBrake ready - Ready to convert"
$statusLabel.ForeColor = [System.Drawing.Color]::LightGreen
$statusStrip.Items.Add($statusLabel) | Out-Null

$form.Controls.Add($statusStrip)

# Convert Button (floating on right bottom)
$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = "CONVERT"
$btnConvert.Location = New-Object System.Drawing.Point(1120, 620)
$btnConvert.Size = New-Object System.Drawing.Size(140, 40)
$btnConvert.BackColor = [System.Drawing.Color]::FromArgb(78, 182, 255)
$btnConvert.ForeColor = [System.Drawing.Color]::White
$btnConvert.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnConvert.FlatAppearance.BorderSize = 0
$btnConvert.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnConvert.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnConvert)

# Event Handlers

# Add Files Button Click
$btnAddFiles.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Video Files|*.mp4;*.mkv;*.avi;*.mov;*.flv;*.wmv;*.webm;*.m4v|All Files|*.*"
    $openFileDialog.Multiselect = $true
    $openFileDialog.Title = "Select Video Files"
    
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($file in $openFileDialog.FileNames) {
            Add-FileToList $file
        }
        $lblDragDrop.Visible = ($listView.Items.Count -eq 0)
    }
})

# Browse Output Button Click
$btnBrowseOutput.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select output folder"
    $folderBrowser.SelectedPath = $txtOutput.Text
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtOutput.Text = $folderBrowser.SelectedPath
    }
})

# Clear List Button Click
$btnClearList.Add_Click({
    $listView.Items.Clear()
    $lblDragDrop.Visible = $true
    $statusLabel.Text = "Task list cleared - Ready to convert"
})

# Remove Button Click
$btnRemove.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        foreach ($item in $listView.SelectedItems) {
            $listView.Items.Remove($item)
        }
        $lblDragDrop.Visible = ($listView.Items.Count -eq 0)
        $statusLabel.Text = "Selected items removed - Ready to convert"
    }
})

# Open Output Button Click
$btnOpenOutput.Add_Click({
    if (Test-Path $txtOutput.Text) {
        Start-Process "explorer.exe" -ArgumentList $txtOutput.Text
    } else {
        [System.Windows.Forms.MessageBox]::Show("Output folder does not exist yet.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Settings Button Click
$btnSettings.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Settings dialog coming soon!", "Settings", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

# Convert Button Click
$btnConvert.Add_Click({
    if ($listView.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please add files to convert first.", "No Files", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $txtOutput.Text)) {
        New-Item -ItemType Directory -Path $txtOutput.Text -Force | Out-Null
    }
    
    $statusLabel.Text = "Converting... Please wait"
    $statusLabel.ForeColor = [System.Drawing.Color]::Yellow
    $btnConvert.Enabled = $false
    
    # Simulate conversion (in real implementation, call FFmpeg/HandBrake here)
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 2000
    $script:itemIndex = 0
    
    $timer.Add_Tick({
        if ($script:itemIndex -lt $listView.Items.Count) {
            $item = $listView.Items[$script:itemIndex]
            $item.SubItems[6].Text = "Completed"
            $script:itemIndex++
            $statusLabel.Text = "Converting $script:itemIndex of $($listView.Items.Count)..."
        } else {
            $timer.Stop()
            $statusLabel.Text = "Conversion completed - Ready to convert"
            $statusLabel.ForeColor = [System.Drawing.Color]::LightGreen
            $btnConvert.Enabled = $true
            [System.Windows.Forms.MessageBox]::Show("Conversion completed successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    })
    
    $timer.Start()
})

# Drag & Drop Events
$listView.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [Windows.Forms.DragDropEffects]::Copy
    }
})

$listView.Add_DragDrop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    foreach ($file in $files) {
        if (Test-Path $file -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            if ($ext -in @('.mp4', '.mkv', '.avi', '.mov', '.flv', '.wmv', '.webm', '.m4v')) {
                Add-FileToList $file
            }
        }
    }
    $lblDragDrop.Visible = ($listView.Items.Count -eq 0)
})

# Function to add file to list
function Add-FileToList {
    param([string]$filePath)
    
    if (-not (Test-Path $filePath)) { return }
    
    $fileInfo = Get-Item $filePath
    $fileName = $fileInfo.Name
    $fileSize = "{0:N2} MB" -f ($fileInfo.Length / 1MB)
    $fileExt = $fileInfo.Extension.ToUpper().TrimStart('.')
    
    # Check if file already exists in list
    foreach ($item in $listView.Items) {
        if ($item.Tag -eq $filePath) {
            return
        }
    }
    
    $listItem = New-Object System.Windows.Forms.ListViewItem($fileName)
    $listItem.SubItems.Add($fileSize) | Out-Null
    $listItem.SubItems.Add("--:--:--") | Out-Null  # Duration (would need MediaInfo)
    $listItem.SubItems.Add("--") | Out-Null  # Resolution
    $listItem.SubItems.Add($fileExt) | Out-Null
    $listItem.SubItems.Add("MP4") | Out-Null
    $listItem.SubItems.Add("Pending") | Out-Null
    $listItem.Tag = $filePath
    
    $listView.Items.Add($listItem) | Out-Null
}

# Show Form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
