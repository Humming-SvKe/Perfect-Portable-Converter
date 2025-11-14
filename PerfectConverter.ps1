# Perfect Portable Converter - HandBrake Style GUI
# PowerShell + Windows Forms - No compilation required
# Version 2.0 - Complete interface with 5 tabs
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# Global variables
$script:sourceFile = ""
$script:destinationFile = ""
$form = New-Object System.Windows.Forms.Form
$form.Text = "Perfect Portable Converter - HandBrake Style"
$form.Size = New-Object System.Drawing.Size(1200, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 38)
# Toolbar
$toolbar = New-Object System.Windows.Forms.ToolStrip
$toolbar.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$btnOpen = New-Object System.Windows.Forms.ToolStripButton
$btnOpen.Text = "Open Source"
$btnOpen.ForeColor = [System.Drawing.Color]::White
$btnOpen.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Video Files|*.mp4;*.mkv;*.avi;*.mov|All Files|*.*"
    if ($dialog.ShowDialog() -eq "OK") {
        $script:sourceFile = $dialog.FileName
        [System.Windows.Forms.MessageBox]::Show("Selected: $($script:sourceFile)", "File Selected")
    }
})
$toolbar.Items.Add($btnOpen) | Out-Null
$btnSave = New-Object System.Windows.Forms.ToolStripButton
$btnSave.Text = "Save As"
$btnSave.ForeColor = [System.Drawing.Color]::White
$btnSave.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "MP4 Video|*.mp4|MKV Video|*.mkv|All Files|*.*"
    if ($dialog.ShowDialog() -eq "OK") { $script:destinationFile = $dialog.FileName }
})
$toolbar.Items.Add($btnSave) | Out-Null
$form.Controls.Add($toolbar)
# Tab control
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(10, 40)
$tabs.Size = New-Object System.Drawing.Size(1160, 650)
$tabs.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
# Summary tab
$tabSummary = New-Object System.Windows.Forms.TabPage
$tabSummary.Text = "Summary"
$tabSummary.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$lblSummary = New-Object System.Windows.Forms.Label
$lblSummary.Text = "HandBrake-Style Video Converter`n`nSelect video file to begin."
$lblSummary.ForeColor = [System.Drawing.Color]::White
$lblSummary.Location = New-Object System.Drawing.Point(20, 20)
$lblSummary.Size = New-Object System.Drawing.Size(700, 500)
$lblSummary.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$tabSummary.Controls.Add($lblSummary)
$tabs.Controls.Add($tabSummary)
# Video tab
$tabVideo = New-Object System.Windows.Forms.TabPage
$tabVideo.Text = "Video"
$tabVideo.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$lblCodec = New-Object System.Windows.Forms.Label
$lblCodec.Text = "Video Codec:"
$lblCodec.ForeColor = [System.Drawing.Color]::White
$lblCodec.Location = New-Object System.Drawing.Point(20, 20)
$lblCodec.Size = New-Object System.Drawing.Size(150, 20)
$tabVideo.Controls.Add($lblCodec)

$comboCodec = New-Object System.Windows.Forms.ComboBox
$comboCodec.Location = New-Object System.Drawing.Point(20, 45)
$comboCodec.Size = New-Object System.Drawing.Size(300, 25)
$comboCodec.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboCodec.ForeColor = [System.Drawing.Color]::White
$comboCodec.Items.AddRange(@("H.264 (x264)", "H.265 (x265)", "VP9", "AV1", "MPEG-4", "MPEG-2"))
$comboCodec.SelectedIndex = 0
$tabVideo.Controls.Add($comboCodec)
$lblQuality = New-Object System.Windows.Forms.Label
$lblQuality.Text = "Quality (CRF): 22"
$lblQuality.ForeColor = [System.Drawing.Color]::White
$lblQuality.Location = New-Object System.Drawing.Point(20, 90)
$lblQuality.Size = New-Object System.Drawing.Size(300, 20)
$tabVideo.Controls.Add($lblQuality)

$trackQuality = New-Object System.Windows.Forms.TrackBar
$trackQuality.Location = New-Object System.Drawing.Point(20, 115)
$trackQuality.Size = New-Object System.Drawing.Size(400, 45)
$trackQuality.Minimum = 0
$trackQuality.Maximum = 51
$trackQuality.Value = 22
$trackQuality.TickFrequency = 5
$trackQuality.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$trackQuality.Add_ValueChanged({
    $lblQuality.Text = "Quality (CRF): $($trackQuality.Value)"
})
$tabVideo.Controls.Add($trackQuality)
$lblPreset = New-Object System.Windows.Forms.Label
$lblPreset.Text = "Encoding Preset:"
$lblPreset.ForeColor = [System.Drawing.Color]::White
$lblPreset.Location = New-Object System.Drawing.Point(20, 175)
$lblPreset.Size = New-Object System.Drawing.Size(150, 20)
$tabVideo.Controls.Add($lblPreset)

$comboPreset = New-Object System.Windows.Forms.ComboBox
$comboPreset.Location = New-Object System.Drawing.Point(20, 200)
$comboPreset.Size = New-Object System.Drawing.Size(300, 25)
$comboPreset.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboPreset.ForeColor = [System.Drawing.Color]::White
$comboPreset.Items.AddRange(@("ultrafast", "superfast", "veryfast", "faster", "fast", "medium", "slow", "slower", "veryslow"))
$comboPreset.SelectedIndex = 5
$tabVideo.Controls.Add($comboPreset)
$lblFramerate = New-Object System.Windows.Forms.Label
$lblFramerate.Text = "Framerate (FPS):"
$lblFramerate.ForeColor = [System.Drawing.Color]::White
$lblFramerate.Location = New-Object System.Drawing.Point(20, 245)
$lblFramerate.Size = New-Object System.Drawing.Size(150, 20)
$tabVideo.Controls.Add($lblFramerate)

$comboFramerate = New-Object System.Windows.Forms.ComboBox
$comboFramerate.Location = New-Object System.Drawing.Point(20, 270)
$comboFramerate.Size = New-Object System.Drawing.Size(300, 25)
$comboFramerate.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboFramerate.ForeColor = [System.Drawing.Color]::White
$comboFramerate.Items.AddRange(@("Same as source", "23.976", "24", "25", "29.97", "30", "50", "59.94", "60"))
$comboFramerate.SelectedIndex = 0
$tabVideo.Controls.Add($comboFramerate)
$tabs.Controls.Add($tabVideo)
# Audio tab
$tabAudio = New-Object System.Windows.Forms.TabPage
$tabAudio.Text = "Audio"
$tabAudio.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$lblAudio = New-Object System.Windows.Forms.Label
$lblAudio.Text = "Audio Codec:"
$lblAudio.ForeColor = [System.Drawing.Color]::White
$lblAudio.Location = New-Object System.Drawing.Point(20, 20)
$lblAudio.Size = New-Object System.Drawing.Size(150, 20)
$tabAudio.Controls.Add($lblAudio)

$comboAudio = New-Object System.Windows.Forms.ComboBox
$comboAudio.Location = New-Object System.Drawing.Point(20, 45)
$comboAudio.Size = New-Object System.Drawing.Size(300, 25)
$comboAudio.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboAudio.ForeColor = [System.Drawing.Color]::White
$comboAudio.Items.AddRange(@("AAC", "MP3", "Opus", "Vorbis", "AC3", "FLAC"))
$comboAudio.SelectedIndex = 0
$tabAudio.Controls.Add($comboAudio)
$tabs.Controls.Add($tabAudio)
# Subtitles tab
$tabSubtitles = New-Object System.Windows.Forms.TabPage
$tabSubtitles.Text = "Subtitles"
$tabSubtitles.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Add External Subtitles (SRT/ASS)"
$lblSub.ForeColor = [System.Drawing.Color]::White
$lblSub.Location = New-Object System.Drawing.Point(20, 20)
$lblSub.Size = New-Object System.Drawing.Size(300, 20)
$tabSubtitles.Controls.Add($lblSub)

$btnBrowseSub = New-Object System.Windows.Forms.Button
$btnBrowseSub.Text = "Browse for subtitle file..."
$btnBrowseSub.Location = New-Object System.Drawing.Point(20, 50)
$btnBrowseSub.Size = New-Object System.Drawing.Size(250, 30)
$btnBrowseSub.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnBrowseSub.ForeColor = [System.Drawing.Color]::White
$tabSubtitles.Controls.Add($btnBrowseSub)

$tabs.Controls.Add($tabSubtitles)

# Filters tab
$tabFilters = New-Object System.Windows.Forms.TabPage
$tabFilters.Text = "Filters"
$tabFilters.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)

$chkWatermark = New-Object System.Windows.Forms.CheckBox
$chkWatermark.Text = "Enable Watermark"
$chkWatermark.ForeColor = [System.Drawing.Color]::White
$chkWatermark.Location = New-Object System.Drawing.Point(20, 20)
$chkWatermark.Size = New-Object System.Drawing.Size(200, 25)
$tabFilters.Controls.Add($chkWatermark)

$lblOpacity = New-Object System.Windows.Forms.Label
$lblOpacity.Text = "Opacity: 100%"
$lblOpacity.ForeColor = [System.Drawing.Color]::White
$lblOpacity.Location = New-Object System.Drawing.Point(20, 60)
$lblOpacity.Size = New-Object System.Drawing.Size(200, 20)
$tabFilters.Controls.Add($lblOpacity)

$trackOpacity = New-Object System.Windows.Forms.TrackBar
$trackOpacity.Location = New-Object System.Drawing.Point(20, 85)
$trackOpacity.Size = New-Object System.Drawing.Size(400, 45)
$trackOpacity.Minimum = 0
$trackOpacity.Maximum = 100
$trackOpacity.Value = 100
$trackOpacity.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$trackOpacity.Add_ValueChanged({
    $lblOpacity.Text = "Opacity: $($trackOpacity.Value)%"
})
$tabFilters.Controls.Add($trackOpacity)

$tabs.Controls.Add($tabFilters)

$form.Controls.Add($tabs)

# Bottom buttons
$btnEncode = New-Object System.Windows.Forms.Button
$btnEncode.Text = "START ENCODE"
$btnEncode.Location = New-Object System.Drawing.Point(950, 710)
$btnEncode.Size = New-Object System.Drawing.Size(200, 35)
$btnEncode.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
$btnEncode.ForeColor = [System.Drawing.Color]::White
$btnEncode.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnEncode.Add_Click({
    if ([string]::IsNullOrEmpty($script:sourceFile)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a source file first!", "Error")
        return
    }
    
    $codec = $comboCodec.SelectedItem
    $quality = $trackQuality.Value
    $audioCodec = $comboAudio.SelectedItem
    
    $cmd = "ffmpeg -i `"$($script:sourceFile)`" -c:v libx264 -crf $quality -c:a aac output.mp4"
    
    [System.Windows.Forms.Clipboard]::SetText($cmd)
    [System.Windows.Forms.MessageBox]::Show("FFmpeg command copied to clipboard!`n`n$cmd", "Success")
})
$form.Controls.Add($btnEncode)

# Show form
[void]$form.ShowDialog()
