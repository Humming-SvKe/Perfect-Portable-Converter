Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# Global variables
$global:sourceFile = ""
$global:destinationFile = ""

# Main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Perfect Portable Converter"
$form.Size = New-Object System.Drawing.Size(1200, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 38)
$form.ForeColor = [System.Drawing.Color]::White

# Toolbar panel
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.Dock = "Top"
$toolbar.Height = 60
$toolbar.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

$btnOpenSource = New-Object System.Windows.Forms.Button
$btnOpenSource.Text = "Open Source"
$btnOpenSource.Location = New-Object System.Drawing.Point(10, 15)
$btnOpenSource.Size = New-Object System.Drawing.Size(120, 30)
$btnOpenSource.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$btnOpenSource.ForeColor = [System.Drawing.Color]::White
$btnOpenSource.FlatStyle = "Flat"
$btnOpenSource.Add_Click({
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "Video Files|*.mp4;*.mkv;*.avi;*.mov;*.flv;*.wmv|All Files|*.*"
    if ($openDialog.ShowDialog() -eq "OK") {
        $global:sourceFile = $openDialog.FileName
        $summaryText.Text = "Source: $($global:sourceFile)"
    }
})

$btnSaveAs = New-Object System.Windows.Forms.Button
$btnSaveAs.Text = "Save As"
$btnSaveAs.Location = New-Object System.Drawing.Point(140, 15)
$btnSaveAs.Size = New-Object System.Drawing.Size(120, 30)
$btnSaveAs.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$btnSaveAs.ForeColor = [System.Drawing.Color]::White
$btnSaveAs.FlatStyle = "Flat"
$btnSaveAs.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "MP4 Video|*.mp4|MKV Video|*.mkv|All Files|*.*"
    if ($saveDialog.ShowDialog() -eq "OK") {
        $global:destinationFile = $saveDialog.FileName
    }
})

$toolbar.Controls.Add($btnOpenSource)
$toolbar.Controls.Add($btnSaveAs)

# Tab control
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 70)
$tabControl.Size = New-Object System.Drawing.Size(1160, 600)
$tabControl.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$tabControl.ForeColor = [System.Drawing.Color]::White

$tabSummary = New-Object System.Windows.Forms.TabPage
$tabSummary.Text = "Summary"
$tabSummary.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

$tabVideo = New-Object System.Windows.Forms.TabPage
$tabVideo.Text = "Video"
$tabVideo.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

$tabAudio = New-Object System.Windows.Forms.TabPage
$tabAudio.Text = "Audio"
$tabAudio.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

$tabSubtitles = New-Object System.Windows.Forms.TabPage
$tabSubtitles.Text = "Subtitles"
$tabSubtitles.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

$tabFilters = New-Object System.Windows.Forms.TabPage
$tabFilters.Text = "Filters"
$tabFilters.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

# Summary tab content
$summaryText = New-Object System.Windows.Forms.Label
$summaryText.Location = New-Object System.Drawing.Point(20, 20)
$summaryText.Size = New-Object System.Drawing.Size(1100, 500)
$summaryText.Text = "Welcome to Perfect Portable Converter`n`nClick 'Open Source' to begin."
$summaryText.ForeColor = [System.Drawing.Color]::White
$tabSummary.Controls.Add($summaryText)

# Video tab content
$lblVideoCodec = New-Object System.Windows.Forms.Label
$lblVideoCodec.Text = "Video Codec:"
$lblVideoCodec.Location = New-Object System.Drawing.Point(20, 20)
$lblVideoCodec.Size = New-Object System.Drawing.Size(100, 20)
$lblVideoCodec.ForeColor = [System.Drawing.Color]::White
$tabVideo.Controls.Add($lblVideoCodec)

$cmbVideoCodec = New-Object System.Windows.Forms.ComboBox
$cmbVideoCodec.Location = New-Object System.Drawing.Point(130, 20)
$cmbVideoCodec.Size = New-Object System.Drawing.Size(200, 25)
$cmbVideoCodec.DropDownStyle = "DropDownList"
$cmbVideoCodec.Items.AddRange(@("H.264 (x264)", "H.265 (x265)", "VP9", "AV1", "MPEG-4", "MPEG-2"))
$cmbVideoCodec.SelectedIndex = 0
$tabVideo.Controls.Add($cmbVideoCodec)

$lblQuality = New-Object System.Windows.Forms.Label
$lblQuality.Text = "Quality (CRF):"
$lblQuality.Location = New-Object System.Drawing.Point(20, 60)
$lblQuality.Size = New-Object System.Drawing.Size(100, 20)
$lblQuality.ForeColor = [System.Drawing.Color]::White
$tabVideo.Controls.Add($lblQuality)

$trackQuality = New-Object System.Windows.Forms.TrackBar
$trackQuality.Location = New-Object System.Drawing.Point(130, 60)
$trackQuality.Size = New-Object System.Drawing.Size(400, 45)
$trackQuality.Minimum = 0
$trackQuality.Maximum = 51
$trackQuality.Value = 23
$trackQuality.TickFrequency = 5
$tabVideo.Controls.Add($trackQuality)

# Audio tab content
$lblAudioCodec = New-Object System.Windows.Forms.Label
$lblAudioCodec.Text = "Audio Codec:"
$lblAudioCodec.Location = New-Object System.Drawing.Point(20, 20)
$lblAudioCodec.Size = New-Object System.Drawing.Size(100, 20)
$lblAudioCodec.ForeColor = [System.Drawing.Color]::White
$tabAudio.Controls.Add($lblAudioCodec)

$cmbAudioCodec = New-Object System.Windows.Forms.ComboBox
$cmbAudioCodec.Location = New-Object System.Drawing.Point(130, 20)
$cmbAudioCodec.Size = New-Object System.Drawing.Size(200, 25)
$cmbAudioCodec.DropDownStyle = "DropDownList"
$cmbAudioCodec.Items.AddRange(@("AAC", "MP3", "Opus", "Vorbis", "AC3", "FLAC"))
$cmbAudioCodec.SelectedIndex = 0
$tabAudio.Controls.Add($cmbAudioCodec)

# Subtitles tab content
$lblSubtitles = New-Object System.Windows.Forms.Label
$lblSubtitles.Text = "Subtitle File:"
$lblSubtitles.Location = New-Object System.Drawing.Point(20, 20)
$lblSubtitles.Size = New-Object System.Drawing.Size(100, 20)
$lblSubtitles.ForeColor = [System.Drawing.Color]::White
$tabSubtitles.Controls.Add($lblSubtitles)

$btnBrowseSub = New-Object System.Windows.Forms.Button
$btnBrowseSub.Text = "Browse..."
$btnBrowseSub.Location = New-Object System.Drawing.Point(130, 20)
$btnBrowseSub.Size = New-Object System.Drawing.Size(100, 25)
$btnBrowseSub.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$btnBrowseSub.ForeColor = [System.Drawing.Color]::White
$btnBrowseSub.FlatStyle = "Flat"
$tabSubtitles.Controls.Add($btnBrowseSub)

# Filters tab content
$chkWatermark = New-Object System.Windows.Forms.CheckBox
$chkWatermark.Text = "Enable Watermark"
$chkWatermark.Location = New-Object System.Drawing.Point(20, 20)
$chkWatermark.Size = New-Object System.Drawing.Size(200, 25)
$chkWatermark.ForeColor = [System.Drawing.Color]::White
$tabFilters.Controls.Add($chkWatermark)

$lblOpacity = New-Object System.Windows.Forms.Label
$lblOpacity.Text = "Opacity:"
$lblOpacity.Location = New-Object System.Drawing.Point(20, 60)
$lblOpacity.Size = New-Object System.Drawing.Size(100, 20)
$lblOpacity.ForeColor = [System.Drawing.Color]::White
$tabFilters.Controls.Add($lblOpacity)

$trackOpacity = New-Object System.Windows.Forms.TrackBar
$trackOpacity.Location = New-Object System.Drawing.Point(130, 60)
$trackOpacity.Size = New-Object System.Drawing.Size(400, 45)
$trackOpacity.Minimum = 0
$trackOpacity.Maximum = 100
$trackOpacity.Value = 100
$trackOpacity.TickFrequency = 10
$tabFilters.Controls.Add($trackOpacity)

$tabControl.Controls.Add($tabSummary)
$tabControl.Controls.Add($tabVideo)
$tabControl.Controls.Add($tabAudio)
$tabControl.Controls.Add($tabSubtitles)
$tabControl.Controls.Add($tabFilters)

# Start encode button
$btnEncode = New-Object System.Windows.Forms.Button
$btnEncode.Text = "START ENCODE"
$btnEncode.Location = New-Object System.Drawing.Point(10, 680)
$btnEncode.Size = New-Object System.Drawing.Size(1160, 50)
$btnEncode.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 81)
$btnEncode.ForeColor = [System.Drawing.Color]::White
$btnEncode.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnEncode.FlatStyle = "Flat"
$btnEncode.Add_Click({
    if ($global:sourceFile -eq "" -or $global:destinationFile -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Please select source and destination files.", "Error")
        return
    }
    
    $videoCodec = $cmbVideoCodec.SelectedItem
    $audioCodec = $cmbAudioCodec.SelectedItem
    $quality = $trackQuality.Value
    
    $command = "ffmpeg -i `"$($global:sourceFile)`" -c:v libx264 -crf $quality -c:a aac `"$($global:destinationFile)`""
    [System.Windows.Forms.Clipboard]::SetText($command)
    [System.Windows.Forms.MessageBox]::Show("FFmpeg command copied to clipboard!`n`n$command", "Success")
})

$form.Controls.Add($toolbar)
$form.Controls.Add($tabControl)
$form.Controls.Add($btnEncode)

[void]$form.ShowDialog()
