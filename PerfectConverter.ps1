# Perfect Portable Converter - HandBrake Style GUI
# Windows PowerShell GUI Application - No Compilation Required
# Version: 2.0 - HandBrake-inspired interface with extended features

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================
# GLOBAL VARIABLES
# ============================================
$script:sourceFile = ""
$script:destinationFile = ""
$script:videoCodec = "H.264 (x264)"
$script:videoQuality = 22
$script:audioCodec = "AAC"
$script:audioBitrate = 160
$script:subtitleFile = ""
$script:watermarkEnabled = $false
$script:watermarkImage = ""
$script:watermarkText = ""
$script:watermarkX = 10
$script:watermarkY = 10
$script:watermarkOpacity = 100

# ============================================
# MAIN FORM
# ============================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Perfect Portable Converter - HandBrake Style"
$form.Size = New-Object System.Drawing.Size(1200, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 38)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# ============================================
# TOP TOOLBAR
# ============================================
$toolbar = New-Object System.Windows.Forms.ToolStrip
$toolbar.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$toolbar.GripStyle = [System.Windows.Forms.ToolStripGripStyle]::Hidden
$toolbar.Padding = New-Object System.Windows.Forms.Padding(5, 2, 5, 2)

$btnOpenSource = New-Object System.Windows.Forms.ToolStripButton
$btnOpenSource.Text = "Open Source"
$btnOpenSource.ForeColor = [System.Drawing.Color]::White
$btnOpenSource.Add_Click({
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "Video Files|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.flv;*.webm|All Files|*.*"
    $openDialog.Title = "Select Source Video"
    if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:sourceFile = $openDialog.FileName
        $txtSource.Text = $script:sourceFile
        
        # Auto-set destination
        $dir = [System.IO.Path]::GetDirectoryName($script:sourceFile)
        $name = [System.IO.Path]::GetFileNameWithoutExtension($script:sourceFile)
        $script:destinationFile = Join-Path $dir "$name-converted.mp4"
        $txtDestination.Text = $script:destinationFile
        
        # Update preview
        $lblPreview.Text = "Source: $([System.IO.Path]::GetFileName($script:sourceFile))`nSize: $([Math]::Round((Get-Item $script:sourceFile).Length / 1MB, 2)) MB"
    }
})
$toolbar.Items.Add($btnOpenSource) | Out-Null

$btnBrowseDest = New-Object System.Windows.Forms.ToolStripButton
$btnBrowseDest.Text = "Save As"
$btnBrowseDest.ForeColor = [System.Drawing.Color]::White
$btnBrowseDest.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "MP4 Video|*.mp4|MKV Video|*.mkv|AVI Video|*.avi|All Files|*.*"
    $saveDialog.Title = "Select Destination"
    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:destinationFile = $saveDialog.FileName
        $txtDestination.Text = $script:destinationFile
    }
})
$toolbar.Items.Add($btnBrowseDest) | Out-Null

$toolbar.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$btnPresets = New-Object System.Windows.Forms.ToolStripButton
$btnPresets.Text = "Presets"
$btnPresets.ForeColor = [System.Drawing.Color]::White
$toolbar.Items.Add($btnPresets) | Out-Null

$btnQueue = New-Object System.Windows.Forms.ToolStripButton
$btnQueue.Text = "Queue"
$btnQueue.ForeColor = [System.Drawing.Color]::White
$toolbar.Items.Add($btnQueue) | Out-Null

$form.Controls.Add($toolbar)

# ============================================
# SOURCE/DESTINATION PANEL
# ============================================
$panelPaths = New-Object System.Windows.Forms.Panel
$panelPaths.Location = New-Object System.Drawing.Point(10, 35)
$panelPaths.Size = New-Object System.Drawing.Size(1160, 90)
$panelPaths.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$form.Controls.Add($panelPaths)

# Source
$lblSource = New-Object System.Windows.Forms.Label
$lblSource.Text = "Source:"
$lblSource.Location = New-Object System.Drawing.Point(10, 15)
$lblSource.Size = New-Object System.Drawing.Size(80, 20)
$lblSource.ForeColor = [System.Drawing.Color]::White
$lblSource.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$panelPaths.Controls.Add($lblSource)

$txtSource = New-Object System.Windows.Forms.TextBox
$txtSource.Location = New-Object System.Drawing.Point(100, 13)
$txtSource.Size = New-Object System.Drawing.Size(1040, 23)
$txtSource.ReadOnly = $true
$txtSource.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtSource.ForeColor = [System.Drawing.Color]::LightGray
$panelPaths.Controls.Add($txtSource)

# Destination
$lblDestination = New-Object System.Windows.Forms.Label
$lblDestination.Text = "Destination:"
$lblDestination.Location = New-Object System.Drawing.Point(10, 50)
$lblDestination.Size = New-Object System.Drawing.Size(80, 20)
$lblDestination.ForeColor = [System.Drawing.Color]::White
$lblDestination.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$panelPaths.Controls.Add($lblDestination)

$txtDestination = New-Object System.Windows.Forms.TextBox
$txtDestination.Location = New-Object System.Drawing.Point(100, 48)
$txtDestination.Size = New-Object System.Drawing.Size(1040, 23)
$txtDestination.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtDestination.ForeColor = [System.Drawing.Color]::LightGray
$panelPaths.Controls.Add($txtDestination)

# ============================================
# MAIN CONTENT AREA - Split Container
# ============================================
$splitContainer = New-Object System.Windows.Forms.SplitContainer
$splitContainer.Location = New-Object System.Drawing.Point(10, 135)
$splitContainer.Size = New-Object System.Drawing.Size(1160, 550)
$splitContainer.SplitterDistance = 750
$splitContainer.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$splitContainer.Orientation = [System.Windows.Forms.Orientation]::Vertical
$form.Controls.Add($splitContainer)

# ============================================
# LEFT PANEL - TAB CONTROL
# ============================================
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabControl.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$splitContainer.Panel1.Controls.Add($tabControl)

# ============================================
# TAB 1: SUMMARY
# ============================================
$tabSummary = New-Object System.Windows.Forms.TabPage
$tabSummary.Text = "Summary"
$tabSummary.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$tabControl.Controls.Add($tabSummary)

$lblSummary = New-Object System.Windows.Forms.Label
$lblSummary.Text = "Video Conversion Summary:`n`nSource: Not selected`nDestination: Not selected`nFormat: MP4`nVideo Codec: H.264 (x264)`nAudio Codec: AAC"
$lblSummary.Location = New-Object System.Drawing.Point(20, 20)
$lblSummary.Size = New-Object System.Drawing.Size(700, 400)
$lblSummary.ForeColor = [System.Drawing.Color]::White
$lblSummary.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$tabSummary.Controls.Add($lblSummary)

# ============================================
# TAB 2: VIDEO
# ============================================
$tabVideo = New-Object System.Windows.Forms.TabPage
$tabVideo.Text = "Video"
$tabVideo.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$tabControl.Controls.Add($tabVideo)

# Video Codec
$lblVideoCodec = New-Object System.Windows.Forms.Label
$lblVideoCodec.Text = "Video Codec:"
$lblVideoCodec.Location = New-Object System.Drawing.Point(20, 20)
$lblVideoCodec.Size = New-Object System.Drawing.Size(150, 20)
$lblVideoCodec.ForeColor = [System.Drawing.Color]::White
$lblVideoCodec.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$tabVideo.Controls.Add($lblVideoCodec)

$comboVideoCodec = New-Object System.Windows.Forms.ComboBox
$comboVideoCodec.Location = New-Object System.Drawing.Point(20, 45)
$comboVideoCodec.Size = New-Object System.Drawing.Size(300, 25)
$comboVideoCodec.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboVideoCodec.Items.AddRange(@("H.264 (x264)", "H.265 (x265)", "VP9", "AV1", "MPEG-4", "MPEG-2"))
$comboVideoCodec.SelectedIndex = 0
$comboVideoCodec.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboVideoCodec.ForeColor = [System.Drawing.Color]::White
$tabVideo.Controls.Add($comboVideoCodec)

# Quality
$lblQuality = New-Object System.Windows.Forms.Label
$lblQuality.Text = "Quality (CRF): 22 - Balanced"
$lblQuality.Location = New-Object System.Drawing.Point(20, 90)
$lblQuality.Size = New-Object System.Drawing.Size(300, 20)
$lblQuality.ForeColor = [System.Drawing.Color]::White
$lblQuality.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
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
    $quality = $trackQuality.Value
    $desc = if ($quality -lt 18) { "Very High" } 
            elseif ($quality -lt 23) { "High" } 
            elseif ($quality -lt 28) { "Balanced" } 
            else { "Low" }
    $lblQuality.Text = "Quality (CRF): $quality - $desc"
    $script:videoQuality = $quality
})
$tabVideo.Controls.Add($trackQuality)

# Framerate
$lblFramerate = New-Object System.Windows.Forms.Label
$lblFramerate.Text = "Framerate (FPS):"
$lblFramerate.Location = New-Object System.Drawing.Point(20, 170)
$lblFramerate.Size = New-Object System.Drawing.Size(150, 20)
$lblFramerate.ForeColor = [System.Drawing.Color]::White
$lblFramerate.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$tabVideo.Controls.Add($lblFramerate)

$comboFramerate = New-Object System.Windows.Forms.ComboBox
$comboFramerate.Location = New-Object System.Drawing.Point(20, 195)
$comboFramerate.Size = New-Object System.Drawing.Size(200, 25)
$comboFramerate.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboFramerate.Items.AddRange(@("Same as source", "23.976", "24", "25", "29.97", "30", "50", "59.94", "60"))
$comboFramerate.SelectedIndex = 0
$comboFramerate.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboFramerate.ForeColor = [System.Drawing.Color]::White
$tabVideo.Controls.Add($comboFramerate)

# Resolution
$lblResolution = New-Object System.Windows.Forms.Label
$lblResolution.Text = "Resolution:"
$lblResolution.Location = New-Object System.Drawing.Point(20, 240)
$lblResolution.Size = New-Object System.Drawing.Size(150, 20)
$lblResolution.ForeColor = [System.Drawing.Color]::White
$lblResolution.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$tabVideo.Controls.Add($lblResolution)

$comboResolution = New-Object System.Windows.Forms.ComboBox
$comboResolution.Location = New-Object System.Drawing.Point(20, 265)
$comboResolution.Size = New-Object System.Drawing.Size(200, 25)
$comboResolution.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboResolution.Items.AddRange(@("Same as source", "3840x2160 (4K)", "1920x1080 (1080p)", "1280x720 (720p)", "854x480 (480p)"))
$comboResolution.SelectedIndex = 0
$comboResolution.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboResolution.ForeColor = [System.Drawing.Color]::White
$tabVideo.Controls.Add($comboResolution)

# ============================================
# TAB 3: AUDIO
# ============================================
$tabAudio = New-Object System.Windows.Forms.TabPage
$tabAudio.Text = "Audio"
$tabAudio.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$tabControl.Controls.Add($tabAudio)

# Audio Codec
$lblAudioCodec = New-Object System.Windows.Forms.Label
$lblAudioCodec.Text = "Audio Codec:"
$lblAudioCodec.Location = New-Object System.Drawing.Point(20, 20)
$lblAudioCodec.Size = New-Object System.Drawing.Size(150, 20)
$lblAudioCodec.ForeColor = [System.Drawing.Color]::White
$lblAudioCodec.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$tabAudio.Controls.Add($lblAudioCodec)

$comboAudioCodec = New-Object System.Windows.Forms.ComboBox
$comboAudioCodec.Location = New-Object System.Drawing.Point(20, 45)
$comboAudioCodec.Size = New-Object System.Drawing.Size(300, 25)
$comboAudioCodec.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboAudioCodec.Items.AddRange(@("AAC", "MP3", "Opus", "Vorbis", "AC3", "FLAC", "Copy (No Re-encode)"))
$comboAudioCodec.SelectedIndex = 0
$comboAudioCodec.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboAudioCodec.ForeColor = [System.Drawing.Color]::White
$tabAudio.Controls.Add($comboAudioCodec)

# Bitrate
$lblBitrate = New-Object System.Windows.Forms.Label
$lblBitrate.Text = "Bitrate (kbps):"
$lblBitrate.Location = New-Object System.Drawing.Point(20, 90)
$lblBitrate.Size = New-Object System.Drawing.Size(150, 20)
$lblBitrate.ForeColor = [System.Drawing.Color]::White
$lblBitrate.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$tabAudio.Controls.Add($lblBitrate)

$comboBitrate = New-Object System.Windows.Forms.ComboBox
$comboBitrate.Location = New-Object System.Drawing.Point(20, 115)
$comboBitrate.Size = New-Object System.Drawing.Size(200, 25)
$comboBitrate.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboBitrate.Items.AddRange(@("64", "96", "128", "160", "192", "256", "320"))
$comboBitrate.SelectedIndex = 3
$comboBitrate.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboBitrate.ForeColor = [System.Drawing.Color]::White
$tabAudio.Controls.Add($comboBitrate)

# Sample Rate
$lblSampleRate = New-Object System.Windows.Forms.Label
$lblSampleRate.Text = "Sample Rate (Hz):"
$lblSampleRate.Location = New-Object System.Drawing.Point(20, 160)
$lblSampleRate.Size = New-Object System.Drawing.Size(150, 20)
$lblSampleRate.ForeColor = [System.Drawing.Color]::White
$lblSampleRate.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$tabAudio.Controls.Add($lblSampleRate)

$comboSampleRate = New-Object System.Windows.Forms.ComboBox
$comboSampleRate.Location = New-Object System.Drawing.Point(20, 185)
$comboSampleRate.Size = New-Object System.Drawing.Size(200, 25)
$comboSampleRate.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboSampleRate.Items.AddRange(@("Same as source", "48000", "44100", "32000", "22050"))
$comboSampleRate.SelectedIndex = 0
$comboSampleRate.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboSampleRate.ForeColor = [System.Drawing.Color]::White
$tabAudio.Controls.Add($comboSampleRate)

# ============================================
# TAB 4: SUBTITLES
# ============================================
$tabSubtitles = New-Object System.Windows.Forms.TabPage
$tabSubtitles.Text = "Subtitles"
$tabSubtitles.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$tabControl.Controls.Add($tabSubtitles)

$lblSubtitles = New-Object System.Windows.Forms.Label
$lblSubtitles.Text = "Add External Subtitles:"
$lblSubtitles.Location = New-Object System.Drawing.Point(20, 20)
$lblSubtitles.Size = New-Object System.Drawing.Size(200, 20)
$lblSubtitles.ForeColor = [System.Drawing.Color]::White
$lblSubtitles.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$tabSubtitles.Controls.Add($lblSubtitles)

$btnBrowseSubtitle = New-Object System.Windows.Forms.Button
$btnBrowseSubtitle.Text = "Browse for SRT/ASS file..."
$btnBrowseSubtitle.Location = New-Object System.Drawing.Point(20, 50)
$btnBrowseSubtitle.Size = New-Object System.Drawing.Size(250, 30)
$btnBrowseSubtitle.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnBrowseSubtitle.ForeColor = [System.Drawing.Color]::White
$btnBrowseSubtitle.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnBrowseSubtitle.Add_Click({
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "Subtitle Files|*.srt;*.ass;*.ssa;*.vtt|All Files|*.*"
    if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:subtitleFile = $openDialog.FileName
        $txtSubtitleFile.Text = $script:subtitleFile
    }
})
$tabSubtitles.Controls.Add($btnBrowseSubtitle)

$txtSubtitleFile = New-Object System.Windows.Forms.TextBox
$txtSubtitleFile.Location = New-Object System.Drawing.Point(20, 90)
$txtSubtitleFile.Size = New-Object System.Drawing.Size(600, 23)
$txtSubtitleFile.ReadOnly = $true
$txtSubtitleFile.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtSubtitleFile.ForeColor = [System.Drawing.Color]::LightGray
$tabSubtitles.Controls.Add($txtSubtitleFile)

# Subtitle Settings
$lblSubtitleFont = New-Object System.Windows.Forms.Label
$lblSubtitleFont.Text = "Font Size:"
$lblSubtitleFont.Location = New-Object System.Drawing.Point(20, 130)
$lblSubtitleFont.Size = New-Object System.Drawing.Size(100, 20)
$lblSubtitleFont.ForeColor = [System.Drawing.Color]::White
$tabSubtitles.Controls.Add($lblSubtitleFont)

$numSubtitleFont = New-Object System.Windows.Forms.NumericUpDown
$numSubtitleFont.Location = New-Object System.Drawing.Point(130, 128)
$numSubtitleFont.Size = New-Object System.Drawing.Size(80, 23)
$numSubtitleFont.Minimum = 12
$numSubtitleFont.Maximum = 72
$numSubtitleFont.Value = 24
$numSubtitleFont.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$numSubtitleFont.ForeColor = [System.Drawing.Color]::White
$tabSubtitles.Controls.Add($numSubtitleFont)

# ============================================
# TAB 5: FILTERS (WATERMARK)
# ============================================
$tabFilters = New-Object System.Windows.Forms.TabPage
$tabFilters.Text = "Filters"
$tabFilters.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$tabControl.Controls.Add($tabFilters)

# Watermark Enable
$chkWatermark = New-Object System.Windows.Forms.CheckBox
$chkWatermark.Text = "Enable Watermark"
$chkWatermark.Location = New-Object System.Drawing.Point(20, 20)
$chkWatermark.Size = New-Object System.Drawing.Size(200, 25)
$chkWatermark.ForeColor = [System.Drawing.Color]::White
$chkWatermark.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$chkWatermark.Add_CheckedChanged({
    $script:watermarkEnabled = $chkWatermark.Checked
    $panelWatermark.Enabled = $chkWatermark.Checked
})
$tabFilters.Controls.Add($chkWatermark)

# Watermark Panel
$panelWatermark = New-Object System.Windows.Forms.Panel
$panelWatermark.Location = New-Object System.Drawing.Point(20, 55)
$panelWatermark.Size = New-Object System.Drawing.Size(700, 420)
$panelWatermark.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$panelWatermark.Enabled = $false
$tabFilters.Controls.Add($panelWatermark)

# Watermark Type
$lblWatermarkType = New-Object System.Windows.Forms.Label
$lblWatermarkType.Text = "Type:"
$lblWatermarkType.Location = New-Object System.Drawing.Point(10, 15)
$lblWatermarkType.Size = New-Object System.Drawing.Size(100, 20)
$lblWatermarkType.ForeColor = [System.Drawing.Color]::White
$lblWatermarkType.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$panelWatermark.Controls.Add($lblWatermarkType)

$radioImage = New-Object System.Windows.Forms.RadioButton
$radioImage.Text = "Image"
$radioImage.Location = New-Object System.Drawing.Point(120, 13)
$radioImage.Size = New-Object System.Drawing.Size(80, 25)
$radioImage.ForeColor = [System.Drawing.Color]::White
$radioImage.Checked = $true
$radioImage.Add_CheckedChanged({
    $panelImageWatermark.Visible = $radioImage.Checked
    $panelTextWatermark.Visible = !$radioImage.Checked
})
$panelWatermark.Controls.Add($radioImage)

$radioText = New-Object System.Windows.Forms.RadioButton
$radioText.Text = "Text"
$radioText.Location = New-Object System.Drawing.Point(210, 13)
$radioText.Size = New-Object System.Drawing.Size(80, 25)
$radioText.ForeColor = [System.Drawing.Color]::White
$panelWatermark.Controls.Add($radioText)

# Image Watermark Panel
$panelImageWatermark = New-Object System.Windows.Forms.Panel
$panelImageWatermark.Location = New-Object System.Drawing.Point(10, 50)
$panelImageWatermark.Size = New-Object System.Drawing.Size(680, 120)
$panelImageWatermark.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$panelWatermark.Controls.Add($panelImageWatermark)

$lblImageFile = New-Object System.Windows.Forms.Label
$lblImageFile.Text = "Image File:"
$lblImageFile.Location = New-Object System.Drawing.Point(10, 15)
$lblImageFile.Size = New-Object System.Drawing.Size(100, 20)
$lblImageFile.ForeColor = [System.Drawing.Color]::White
$panelImageWatermark.Controls.Add($lblImageFile)

$btnBrowseImage = New-Object System.Windows.Forms.Button
$btnBrowseImage.Text = "Browse..."
$btnBrowseImage.Location = New-Object System.Drawing.Point(10, 40)
$btnBrowseImage.Size = New-Object System.Drawing.Size(100, 25)
$btnBrowseImage.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnBrowseImage.ForeColor = [System.Drawing.Color]::White
$btnBrowseImage.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnBrowseImage.Add_Click({
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "Image Files|*.png;*.jpg;*.jpeg;*.gif;*.bmp|All Files|*.*"
    if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:watermarkImage = $openDialog.FileName
        $txtImageFile.Text = $script:watermarkImage
    }
})
$panelImageWatermark.Controls.Add($btnBrowseImage)

$txtImageFile = New-Object System.Windows.Forms.TextBox
$txtImageFile.Location = New-Object System.Drawing.Point(120, 40)
$txtImageFile.Size = New-Object System.Drawing.Size(540, 23)
$txtImageFile.ReadOnly = $true
$txtImageFile.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtImageFile.ForeColor = [System.Drawing.Color]::LightGray
$panelImageWatermark.Controls.Add($txtImageFile)

# Text Watermark Panel
$panelTextWatermark = New-Object System.Windows.Forms.Panel
$panelTextWatermark.Location = New-Object System.Drawing.Point(10, 50)
$panelTextWatermark.Size = New-Object System.Drawing.Size(680, 120)
$panelTextWatermark.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$panelTextWatermark.Visible = $false
$panelWatermark.Controls.Add($panelTextWatermark)

$lblWatermarkText = New-Object System.Windows.Forms.Label
$lblWatermarkText.Text = "Text:"
$lblWatermarkText.Location = New-Object System.Drawing.Point(10, 15)
$lblWatermarkText.Size = New-Object System.Drawing.Size(100, 20)
$lblWatermarkText.ForeColor = [System.Drawing.Color]::White
$panelTextWatermark.Controls.Add($lblWatermarkText)

$txtWatermarkText = New-Object System.Windows.Forms.TextBox
$txtWatermarkText.Location = New-Object System.Drawing.Point(10, 40)
$txtWatermarkText.Size = New-Object System.Drawing.Size(500, 23)
$txtWatermarkText.Text = "Copyright © 2025"
$txtWatermarkText.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$txtWatermarkText.ForeColor = [System.Drawing.Color]::White
$txtWatermarkText.Add_TextChanged({
    $script:watermarkText = $txtWatermarkText.Text
})
$panelTextWatermark.Controls.Add($txtWatermarkText)

$lblTextFont = New-Object System.Windows.Forms.Label
$lblTextFont.Text = "Font Size:"
$lblTextFont.Location = New-Object System.Drawing.Point(10, 75)
$lblTextFont.Size = New-Object System.Drawing.Size(100, 20)
$lblTextFont.ForeColor = [System.Drawing.Color]::White
$panelTextWatermark.Controls.Add($lblTextFont)

$numTextFont = New-Object System.Windows.Forms.NumericUpDown
$numTextFont.Location = New-Object System.Drawing.Point(120, 73)
$numTextFont.Size = New-Object System.Drawing.Size(80, 23)
$numTextFont.Minimum = 12
$numTextFont.Maximum = 144
$numTextFont.Value = 32
$numTextFont.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$numTextFont.ForeColor = [System.Drawing.Color]::White
$panelTextWatermark.Controls.Add($numTextFont)

# Position Controls
$lblPosition = New-Object System.Windows.Forms.Label
$lblPosition.Text = "Position:"
$lblPosition.Location = New-Object System.Drawing.Point(10, 185)
$lblPosition.Size = New-Object System.Drawing.Size(100, 20)
$lblPosition.ForeColor = [System.Drawing.Color]::White
$lblPosition.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$panelWatermark.Controls.Add($lblPosition)

$comboPosition = New-Object System.Windows.Forms.ComboBox
$comboPosition.Location = New-Object System.Drawing.Point(10, 210)
$comboPosition.Size = New-Object System.Drawing.Size(200, 25)
$comboPosition.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboPosition.Items.AddRange(@("Top Left", "Top Center", "Top Right", "Center Left", "Center", "Center Right", "Bottom Left", "Bottom Center", "Bottom Right", "Custom"))
$comboPosition.SelectedIndex = 0
$comboPosition.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$comboPosition.ForeColor = [System.Drawing.Color]::White
$comboPosition.Add_SelectedIndexChanged({
    $panelCustomPosition.Enabled = ($comboPosition.SelectedIndex -eq 9)
})
$panelWatermark.Controls.Add($comboPosition)

# Custom Position
$panelCustomPosition = New-Object System.Windows.Forms.Panel
$panelCustomPosition.Location = New-Object System.Drawing.Point(10, 245)
$panelCustomPosition.Size = New-Object System.Drawing.Size(400, 60)
$panelCustomPosition.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$panelCustomPosition.Enabled = $false
$panelWatermark.Controls.Add($panelCustomPosition)

$lblX = New-Object System.Windows.Forms.Label
$lblX.Text = "X:"
$lblX.Location = New-Object System.Drawing.Point(10, 15)
$lblX.Size = New-Object System.Drawing.Size(30, 20)
$lblX.ForeColor = [System.Drawing.Color]::White
$panelCustomPosition.Controls.Add($lblX)

$numX = New-Object System.Windows.Forms.NumericUpDown
$numX.Location = New-Object System.Drawing.Point(45, 13)
$numX.Size = New-Object System.Drawing.Size(100, 23)
$numX.Minimum = 0
$numX.Maximum = 9999
$numX.Value = 10
$numX.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$numX.ForeColor = [System.Drawing.Color]::White
$numX.Add_ValueChanged({ $script:watermarkX = $numX.Value })
$panelCustomPosition.Controls.Add($numX)

$lblY = New-Object System.Windows.Forms.Label
$lblY.Text = "Y:"
$lblY.Location = New-Object System.Drawing.Point(160, 15)
$lblY.Size = New-Object System.Drawing.Size(30, 20)
$lblY.ForeColor = [System.Drawing.Color]::White
$panelCustomPosition.Controls.Add($lblY)

$numY = New-Object System.Windows.Forms.NumericUpDown
$numY.Location = New-Object System.Drawing.Point(195, 13)
$numY.Size = New-Object System.Drawing.Size(100, 23)
$numY.Minimum = 0
$numY.Maximum = 9999
$numY.Value = 10
$numY.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$numY.ForeColor = [System.Drawing.Color]::White
$numY.Add_ValueChanged({ $script:watermarkY = $numY.Value })
$panelCustomPosition.Controls.Add($numY)

# Opacity
$lblOpacity = New-Object System.Windows.Forms.Label
$lblOpacity.Text = "Opacity: 100%"
$lblOpacity.Location = New-Object System.Drawing.Point(10, 320)
$lblOpacity.Size = New-Object System.Drawing.Size(200, 20)
$lblOpacity.ForeColor = [System.Drawing.Color]::White
$lblOpacity.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$panelWatermark.Controls.Add($lblOpacity)

$trackOpacity = New-Object System.Windows.Forms.TrackBar
$trackOpacity.Location = New-Object System.Drawing.Point(10, 345)
$trackOpacity.Size = New-Object System.Drawing.Size(400, 45)
$trackOpacity.Minimum = 0
$trackOpacity.Maximum = 100
$trackOpacity.Value = 100
$trackOpacity.TickFrequency = 10
$trackOpacity.BackColor = [System.Drawing.Color]::FromArgb(37, 37, 38)
$trackOpacity.Add_ValueChanged({
    $lblOpacity.Text = "Opacity: $($trackOpacity.Value)%"
    $script:watermarkOpacity = $trackOpacity.Value
})
$panelWatermark.Controls.Add($trackOpacity)

# ============================================
# RIGHT PANEL - PREVIEW
# ============================================
$panelPreview = New-Object System.Windows.Forms.Panel
$panelPreview.Dock = [System.Windows.Forms.DockStyle]::Fill
$panelPreview.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$splitContainer.Panel2.Controls.Add($panelPreview)

$lblPreviewTitle = New-Object System.Windows.Forms.Label
$lblPreviewTitle.Text = "Preview"
$lblPreviewTitle.Location = New-Object System.Drawing.Point(10, 10)
$lblPreviewTitle.Size = New-Object System.Drawing.Size(380, 25)
$lblPreviewTitle.ForeColor = [System.Drawing.Color]::White
$lblPreviewTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblPreviewTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$panelPreview.Controls.Add($lblPreviewTitle)

$lblPreview = New-Object System.Windows.Forms.Label
$lblPreview.Text = "No source file selected.`n`nClick 'Open Source' to begin."
$lblPreview.Location = New-Object System.Drawing.Point(10, 50)
$lblPreview.Size = New-Object System.Drawing.Size(380, 450)
$lblPreview.ForeColor = [System.Drawing.Color]::LightGray
$lblPreview.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblPreview.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
$panelPreview.Controls.Add($lblPreview)

# ============================================
# BOTTOM PANEL - ACTION BUTTONS
# ============================================
$panelBottom = New-Object System.Windows.Forms.Panel
$panelBottom.Location = New-Object System.Drawing.Point(10, 695)
$panelBottom.Size = New-Object System.Drawing.Size(1160, 50)
$panelBottom.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$form.Controls.Add($panelBottom)

# Start Encode Button
$btnEncode = New-Object System.Windows.Forms.Button
$btnEncode.Text = "START ENCODE"
$btnEncode.Location = New-Object System.Drawing.Point(950, 10)
$btnEncode.Size = New-Object System.Drawing.Size(200, 35)
$btnEncode.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
$btnEncode.ForeColor = [System.Drawing.Color]::White
$btnEncode.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnEncode.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnEncode.Add_Click({
    if ([string]::IsNullOrEmpty($script:sourceFile)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a source file first!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    if ([string]::IsNullOrEmpty($script:destinationFile)) {
        [System.Windows.Forms.MessageBox]::Show("Please specify destination file!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    # Build FFmpeg command
    $ffmpegCmd = Build-FFmpegCommand
    
    # Show command
    $result = [System.Windows.Forms.MessageBox]::Show("FFmpeg Command:`n`n$ffmpegCmd`n`nCopy to clipboard?", "Command Generated", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Information)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        [System.Windows.Forms.Clipboard]::SetText($ffmpegCmd)
        [System.Windows.Forms.MessageBox]::Show("Command copied to clipboard!`n`nYou can now paste and run it in a terminal with FFmpeg installed.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})
$panelBottom.Controls.Add($btnEncode)

# Copy Command Button
$btnCopyCmd = New-Object System.Windows.Forms.Button
$btnCopyCmd.Text = "Copy Command"
$btnCopyCmd.Location = New-Object System.Drawing.Point(800, 10)
$btnCopyCmd.Size = New-Object System.Drawing.Size(140, 35)
$btnCopyCmd.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnCopyCmd.ForeColor = [System.Drawing.Color]::White
$btnCopyCmd.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$btnCopyCmd.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCopyCmd.Add_Click({
    if ([string]::IsNullOrEmpty($script:sourceFile)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a source file first!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    $ffmpegCmd = Build-FFmpegCommand
    [System.Windows.Forms.Clipboard]::SetText($ffmpegCmd)
    [System.Windows.Forms.MessageBox]::Show("FFmpeg command copied to clipboard!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$panelBottom.Controls.Add($btnCopyCmd)

# ============================================
# FFMPEG COMMAND BUILDER FUNCTION
# ============================================
function Build-FFmpegCommand {
    $cmd = "ffmpeg -i `"$($script:sourceFile)`""
    
    # Video codec
    $videoCodecMap = @{
        "H.264 (x264)" = "libx264"
        "H.265 (x265)" = "libx265"
        "VP9" = "libvpx-vp9"
        "AV1" = "libaom-av1"
        "MPEG-4" = "mpeg4"
        "MPEG-2" = "mpeg2video"
    }
    $cmd += " -c:v $($videoCodecMap[$comboVideoCodec.SelectedItem.ToString()])"
    $cmd += " -crf $($trackQuality.Value)"
    
    # Resolution
    if ($comboResolution.SelectedIndex -gt 0) {
        $resMap = @{
            "3840x2160 (4K)" = "3840:2160"
            "1920x1080 (1080p)" = "1920:1080"
            "1280x720 (720p)" = "1280:720"
            "854x480 (480p)" = "854:480"
        }
        $res = $resMap[$comboResolution.SelectedItem.ToString()]
        if ($res) {
            $cmd += " -vf scale=$res"
        }
    }
    
    # Framerate
    if ($comboFramerate.SelectedIndex -gt 0) {
        $cmd += " -r $($comboFramerate.SelectedItem)"
    }
    
    # Audio codec
    $audioCodecMap = @{
        "AAC" = "aac"
        "MP3" = "libmp3lame"
        "Opus" = "libopus"
        "Vorbis" = "libvorbis"
        "AC3" = "ac3"
        "FLAC" = "flac"
        "Copy (No Re-encode)" = "copy"
    }
    $selectedAudioCodec = $comboAudioCodec.SelectedItem.ToString()
    $cmd += " -c:a $($audioCodecMap[$selectedAudioCodec])"
    
    if ($selectedAudioCodec -ne "Copy (No Re-encode)") {
        $cmd += " -b:a $($comboBitrate.SelectedItem)k"
    }
    
    # Sample rate
    if ($comboSampleRate.SelectedIndex -gt 0) {
        $cmd += " -ar $($comboSampleRate.SelectedItem)"
    }
    
    # Subtitles
    if (![string]::IsNullOrEmpty($script:subtitleFile)) {
        $cmd += " -vf subtitles=`"$($script:subtitleFile)`":force_style='FontSize=$($numSubtitleFont.Value)'"
    }
    
    # Watermark
    if ($script:watermarkEnabled) {
        if ($radioImage.Checked -and ![string]::IsNullOrEmpty($script:watermarkImage)) {
            $opacity = $script:watermarkOpacity / 100.0
            
            $posMap = @{
                0 = "10:10"                    # Top Left
                1 = "(main_w-overlay_w)/2:10"  # Top Center
                2 = "main_w-overlay_w-10:10"   # Top Right
                3 = "10:(main_h-overlay_h)/2"  # Center Left
                4 = "(main_w-overlay_w)/2:(main_h-overlay_h)/2"  # Center
                5 = "main_w-overlay_w-10:(main_h-overlay_h)/2"   # Center Right
                6 = "10:main_h-overlay_h-10"   # Bottom Left
                7 = "(main_w-overlay_w)/2:main_h-overlay_h-10"  # Bottom Center
                8 = "main_w-overlay_w-10:main_h-overlay_h-10"   # Bottom Right
                9 = "$($script:watermarkX):$($script:watermarkY)"  # Custom
            }
            
            $pos = $posMap[$comboPosition.SelectedIndex]
            $cmd += " -i `"$($script:watermarkImage)`" -filter_complex `"[1:v]format=rgba,colorchannelmixer=aa=$opacity[logo];[0:v][logo]overlay=$pos`""
        }
        elseif ($radioText.Checked -and ![string]::IsNullOrEmpty($script:watermarkText)) {
            $posMap = @{
                0 = "x=10:y=10"                    # Top Left
                1 = "x=(w-text_w)/2:y=10"          # Top Center
                2 = "x=w-text_w-10:y=10"           # Top Right
                3 = "x=10:y=(h-text_h)/2"          # Center Left
                4 = "x=(w-text_w)/2:y=(h-text_h)/2"  # Center
                5 = "x=w-text_w-10:y=(h-text_h)/2"   # Center Right
                6 = "x=10:y=h-text_h-10"           # Bottom Left
                7 = "x=(w-text_w)/2:y=h-text_h-10"  # Bottom Center
                8 = "x=w-text_w-10:y=h-text_h-10"   # Bottom Right
                9 = "x=$($script:watermarkX):y=$($script:watermarkY)"  # Custom
            }
            
            $pos = $posMap[$comboPosition.SelectedIndex]
            $opacity = $script:watermarkOpacity / 100.0
            $fontSize = $numTextFont.Value
            $text = $script:watermarkText -replace "'", "\\'"
            $cmd += " -vf `"drawtext=text='$text':fontsize=$fontSize`:fontcolor=white@$opacity`:$pos`""
        }
    }
    
    $cmd += " `"$($script:destinationFile)`""
    
    return $cmd
}

# ============================================
# SHOW FORM
# ============================================
[void]$form.ShowDialog()
