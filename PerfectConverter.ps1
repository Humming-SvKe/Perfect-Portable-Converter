<#
  PerfectConverter.ps1
  HandBrake-inspired dark theme video converter interface
  Complete PowerShell GUI with 5 tabs: Summary, Video, Audio, Subtitles, Filters
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ensure STA mode for Windows Forms
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$PSCommandPath`"" -WindowStyle Normal
    return
}

# Paths
$Root = Split-Path -Parent $PSCommandPath
$Bin = Join-Path $Root 'binaries'
$Out = Join-Path $Root 'output'
$Subs = Join-Path $Root 'subtitles'
$Ovls = Join-Path $Root 'overlays'
@($Bin, $Out, $Subs, $Ovls) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }

# Global state
$script:sourceFile = $null
$script:outputFile = $null
$script:currentTab = 'Summary'
$script:ffmpegCommand = ""

# WinForms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable Visual Styles
[Windows.Forms.Application]::EnableVisualStyles()
[Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# HandBrake Dark Theme Colors
$colors = @{
    Background = [Drawing.Color]::FromArgb(35, 35, 38)      # #232326
    Panel = [Drawing.Color]::FromArgb(45, 45, 48)           # #2D2D30
    TabPanel = [Drawing.Color]::FromArgb(37, 37, 38)        # #252526
    Control = [Drawing.Color]::FromArgb(30, 30, 30)         # #1E1E1E
    Text = [Drawing.Color]::White
    TextMuted = [Drawing.Color]::FromArgb(170, 170, 170)
    Border = [Drawing.Color]::FromArgb(63, 63, 70)
    Accent = [Drawing.Color]::FromArgb(0, 122, 204)
    AccentHover = [Drawing.Color]::FromArgb(28, 151, 234)
}

# ===================================
# MAIN FORM
# ===================================
$form = New-Object Windows.Forms.Form
$form.Text = 'PerfectConverter - HandBrake Style'
$form.ClientSize = New-Object Drawing.Size(1200, 800)
$form.MinimumSize = New-Object Drawing.Size(1200, 800)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $colors.Background
$form.ForeColor = $colors.Text
$form.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Regular)

# ===================================
# TOP TOOLBAR
# ===================================
$toolbar = New-Object Windows.Forms.Panel
$toolbar.Height = 50
$toolbar.Dock = 'Top'
$toolbar.BackColor = $colors.Panel
$form.Controls.Add($toolbar)

function New-ToolbarButton($text, $x) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object Drawing.Point($x, 10)
    $btn.Size = New-Object Drawing.Size(100, 30)
    $btn.FlatStyle = 'Flat'
    $btn.BackColor = $colors.Control
    $btn.ForeColor = $colors.Text
    $btn.FlatAppearance.BorderColor = $colors.Border
    $btn.FlatAppearance.MouseOverBackColor = $colors.AccentHover
    return $btn
}

$btnOpenSource = New-ToolbarButton 'Open Source' 10
$btnOpenSource.Add_Click({
    $dialog = New-Object Windows.Forms.OpenFileDialog
    $dialog.Filter = 'Video Files|*.mp4;*.mkv;*.avi;*.mov;*.wmv;*.flv;*.webm;*.m4v|All Files|*.*'
    $dialog.Title = 'Select Source Video'
    if ($dialog.ShowDialog() -eq 'OK') {
        $script:sourceFile = $dialog.FileName
        $lblSource.Text = "Source: $($script:sourceFile)"
        Update-Summary
    }
})
$toolbar.Controls.Add($btnOpenSource)

$btnSaveAs = New-ToolbarButton 'Save As' 120
$btnSaveAs.Add_Click({
    $dialog = New-Object Windows.Forms.SaveFileDialog
    $dialog.Filter = 'MP4 Video|*.mp4|MKV Video|*.mkv|AVI Video|*.avi|All Files|*.*'
    $dialog.Title = 'Select Output File'
    if ($dialog.ShowDialog() -eq 'OK') {
        $script:outputFile = $dialog.FileName
        $lblOutput.Text = "Output: $($script:outputFile)"
        Update-Summary
    }
})
$toolbar.Controls.Add($btnSaveAs)

$btnPresets = New-ToolbarButton 'Presets' 230
$btnPresets.Add_Click({
    [Windows.Forms.MessageBox]::Show('Preset management coming soon!', 'Presets', 'OK', 'Information')
})
$toolbar.Controls.Add($btnPresets)

$btnQueue = New-ToolbarButton 'Queue' 340
$btnQueue.Add_Click({
    [Windows.Forms.MessageBox]::Show('Queue management coming soon!', 'Queue', 'OK', 'Information')
})
$toolbar.Controls.Add($btnQueue)

# Source/Output labels
$lblSource = New-Object Windows.Forms.Label
$lblSource.Text = 'Source: No file selected'
$lblSource.Location = New-Object Drawing.Point(460, 10)
$lblSource.Size = New-Object Drawing.Size(720, 15)
$lblSource.ForeColor = $colors.TextMuted
$lblSource.Font = New-Object Drawing.Font('Segoe UI', 8)
$toolbar.Controls.Add($lblSource)

$lblOutput = New-Object Windows.Forms.Label
$lblOutput.Text = 'Output: Not set'
$lblOutput.Location = New-Object Drawing.Point(460, 28)
$lblOutput.Size = New-Object Drawing.Size(720, 15)
$lblOutput.ForeColor = $colors.TextMuted
$lblOutput.Font = New-Object Drawing.Font('Segoe UI', 8)
$toolbar.Controls.Add($lblOutput)

# ===================================
# MAIN CONTAINER - Split View
# ===================================
$mainContainer = New-Object Windows.Forms.Panel
$mainContainer.Dock = 'Fill'
$mainContainer.BackColor = $colors.Background
$form.Controls.Add($mainContainer)

# ===================================
# LEFT PANEL - TABS
# ===================================
$leftPanel = New-Object Windows.Forms.Panel
$leftPanel.Width = 700
$leftPanel.Dock = 'Left'
$leftPanel.BackColor = $colors.Panel
$mainContainer.Controls.Add($leftPanel)

# Tab buttons panel
$tabButtonsPanel = New-Object Windows.Forms.Panel
$tabButtonsPanel.Height = 40
$tabButtonsPanel.Dock = 'Top'
$tabButtonsPanel.BackColor = $colors.TabPanel
$leftPanel.Controls.Add($tabButtonsPanel)

$tabNames = @('Summary', 'Video', 'Audio', 'Subtitles', 'Filters')
$tabButtons = @{}

function New-TabButton($text, $index) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object Drawing.Point(($index * 120 + 10), 5)
    $btn.Size = New-Object Drawing.Size(110, 30)
    $btn.FlatStyle = 'Flat'
    $btn.ForeColor = $colors.TextMuted
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = [Drawing.Color]::Transparent
    $btn.Tag = $text
    
    $btn.Add_Click({
        $script:currentTab = $this.Tag
        Switch-Tab $this.Tag
    })
    
    return $btn
}

for ($i = 0; $i -lt $tabNames.Count; $i++) {
    $btn = New-TabButton $tabNames[$i] $i
    $tabButtons[$tabNames[$i]] = $btn
    $tabButtonsPanel.Controls.Add($btn)
}

# Tab content panel
$tabContentPanel = New-Object Windows.Forms.Panel
$tabContentPanel.Dock = 'Fill'
$tabContentPanel.BackColor = $colors.Panel
$tabContentPanel.AutoScroll = $true
$leftPanel.Controls.Add($tabContentPanel)

# ===================================
# TAB PANELS
# ===================================
$tabPanels = @{}

# Summary Tab
$summaryPanel = New-Object Windows.Forms.Panel
$summaryPanel.Dock = 'Fill'
$summaryPanel.BackColor = $colors.Panel
$summaryPanel.Visible = $true
$tabPanels['Summary'] = $summaryPanel

$summaryTitle = New-Object Windows.Forms.Label
$summaryTitle.Text = 'Summary'
$summaryTitle.Location = New-Object Drawing.Point(20, 20)
$summaryTitle.Size = New-Object Drawing.Size(300, 30)
$summaryTitle.Font = New-Object Drawing.Font('Segoe UI', 14, [Drawing.FontStyle]::Bold)
$summaryTitle.ForeColor = $colors.Text
$summaryPanel.Controls.Add($summaryTitle)

$summaryInfo = New-Object Windows.Forms.TextBox
$summaryInfo.Location = New-Object Drawing.Point(20, 60)
$summaryInfo.Size = New-Object Drawing.Size(650, 600)
$summaryInfo.Multiline = $true
$summaryInfo.ScrollBars = 'Vertical'
$summaryInfo.BackColor = $colors.Control
$summaryInfo.ForeColor = $colors.Text
$summaryInfo.BorderStyle = 'FixedSingle'
$summaryInfo.ReadOnly = $true
$summaryInfo.Font = New-Object Drawing.Font('Consolas', 9)
$summaryInfo.Text = "No source file selected.`n`nUse 'Open Source' button to select a video file."
$summaryPanel.Controls.Add($summaryInfo)

# Video Tab
$videoPanel = New-Object Windows.Forms.Panel
$videoPanel.Dock = 'Fill'
$videoPanel.BackColor = $colors.Panel
$videoPanel.Visible = $false
$videoPanel.AutoScroll = $true
$tabPanels['Video'] = $videoPanel

$videoTitle = New-Object Windows.Forms.Label
$videoTitle.Text = 'Video Settings'
$videoTitle.Location = New-Object Drawing.Point(20, 20)
$videoTitle.Size = New-Object Drawing.Size(300, 30)
$videoTitle.Font = New-Object Drawing.Font('Segoe UI', 14, [Drawing.FontStyle]::Bold)
$videoTitle.ForeColor = $colors.Text
$videoPanel.Controls.Add($videoTitle)

# Codec selection
$lblCodec = New-Object Windows.Forms.Label
$lblCodec.Text = 'Video Codec:'
$lblCodec.Location = New-Object Drawing.Point(20, 70)
$lblCodec.Size = New-Object Drawing.Size(100, 20)
$lblCodec.ForeColor = $colors.Text
$videoPanel.Controls.Add($lblCodec)

$cmbCodec = New-Object Windows.Forms.ComboBox
$cmbCodec.Location = New-Object Drawing.Point(130, 68)
$cmbCodec.Size = New-Object Drawing.Size(200, 25)
$cmbCodec.DropDownStyle = 'DropDownList'
$cmbCodec.BackColor = $colors.Control
$cmbCodec.ForeColor = $colors.Text
$cmbCodec.FlatStyle = 'Flat'
@('H.264 (x264)', 'H.265 (x265)', 'VP9', 'AV1', 'MPEG-4', 'MPEG-2') | ForEach-Object { [void]$cmbCodec.Items.Add($_) }
$cmbCodec.SelectedIndex = 0
$videoPanel.Controls.Add($cmbCodec)

# Quality slider
$lblQuality = New-Object Windows.Forms.Label
$lblQuality.Text = 'Quality (CRF):'
$lblQuality.Location = New-Object Drawing.Point(20, 110)
$lblQuality.Size = New-Object Drawing.Size(100, 20)
$lblQuality.ForeColor = $colors.Text
$videoPanel.Controls.Add($lblQuality)

$trackQuality = New-Object Windows.Forms.TrackBar
$trackQuality.Location = New-Object Drawing.Point(130, 105)
$trackQuality.Size = New-Object Drawing.Size(400, 45)
$trackQuality.Minimum = 0
$trackQuality.Maximum = 51
$trackQuality.Value = 23
$trackQuality.TickFrequency = 5
$trackQuality.BackColor = $colors.Panel
$videoPanel.Controls.Add($trackQuality)

$lblQualityValue = New-Object Windows.Forms.Label
$lblQualityValue.Text = '23 (Balanced)'
$lblQualityValue.Location = New-Object Drawing.Point(540, 110)
$lblQualityValue.Size = New-Object Drawing.Size(120, 20)
$lblQualityValue.ForeColor = $colors.Accent
$videoPanel.Controls.Add($lblQualityValue)

$trackQuality.Add_ValueChanged({
    $val = $trackQuality.Value
    $quality = if ($val -le 18) { 'Very High' } elseif ($val -le 28) { 'Balanced' } else { 'Low' }
    $lblQualityValue.Text = "$val ($quality)"
})

# Framerate
$lblFramerate = New-Object Windows.Forms.Label
$lblFramerate.Text = 'Framerate:'
$lblFramerate.Location = New-Object Drawing.Point(20, 160)
$lblFramerate.Size = New-Object Drawing.Size(100, 20)
$lblFramerate.ForeColor = $colors.Text
$videoPanel.Controls.Add($lblFramerate)

$cmbFramerate = New-Object Windows.Forms.ComboBox
$cmbFramerate.Location = New-Object Drawing.Point(130, 158)
$cmbFramerate.Size = New-Object Drawing.Size(200, 25)
$cmbFramerate.DropDownStyle = 'DropDownList'
$cmbFramerate.BackColor = $colors.Control
$cmbFramerate.ForeColor = $colors.Text
$cmbFramerate.FlatStyle = 'Flat'
@('Same as source', '23.976', '24', '25', '29.97', '30', '50', '59.94', '60') | ForEach-Object { [void]$cmbFramerate.Items.Add($_) }
$cmbFramerate.SelectedIndex = 0
$videoPanel.Controls.Add($cmbFramerate)

# Resolution
$lblResolution = New-Object Windows.Forms.Label
$lblResolution.Text = 'Resolution:'
$lblResolution.Location = New-Object Drawing.Point(20, 200)
$lblResolution.Size = New-Object Drawing.Size(100, 20)
$lblResolution.ForeColor = $colors.Text
$videoPanel.Controls.Add($lblResolution)

$cmbResolution = New-Object Windows.Forms.ComboBox
$cmbResolution.Location = New-Object Drawing.Point(130, 198)
$cmbResolution.Size = New-Object Drawing.Size(200, 25)
$cmbResolution.DropDownStyle = 'DropDownList'
$cmbResolution.BackColor = $colors.Control
$cmbResolution.ForeColor = $colors.Text
$cmbResolution.FlatStyle = 'Flat'
@('Same as source', '4K (3840x2160)', '1080p (1920x1080)', '720p (1280x720)', '480p (854x480)') | ForEach-Object { [void]$cmbResolution.Items.Add($_) }
$cmbResolution.SelectedIndex = 0
$videoPanel.Controls.Add($cmbResolution)

# Audio Tab
$audioPanel = New-Object Windows.Forms.Panel
$audioPanel.Dock = 'Fill'
$audioPanel.BackColor = $colors.Panel
$audioPanel.Visible = $false
$audioPanel.AutoScroll = $true
$tabPanels['Audio'] = $audioPanel

$audioTitle = New-Object Windows.Forms.Label
$audioTitle.Text = 'Audio Settings'
$audioTitle.Location = New-Object Drawing.Point(20, 20)
$audioTitle.Size = New-Object Drawing.Size(300, 30)
$audioTitle.Font = New-Object Drawing.Font('Segoe UI', 14, [Drawing.FontStyle]::Bold)
$audioTitle.ForeColor = $colors.Text
$audioPanel.Controls.Add($audioTitle)

# Audio codec
$lblAudioCodec = New-Object Windows.Forms.Label
$lblAudioCodec.Text = 'Audio Codec:'
$lblAudioCodec.Location = New-Object Drawing.Point(20, 70)
$lblAudioCodec.Size = New-Object Drawing.Size(100, 20)
$lblAudioCodec.ForeColor = $colors.Text
$audioPanel.Controls.Add($lblAudioCodec)

$cmbAudioCodec = New-Object Windows.Forms.ComboBox
$cmbAudioCodec.Location = New-Object Drawing.Point(130, 68)
$cmbAudioCodec.Size = New-Object Drawing.Size(200, 25)
$cmbAudioCodec.DropDownStyle = 'DropDownList'
$cmbAudioCodec.BackColor = $colors.Control
$cmbAudioCodec.ForeColor = $colors.Text
$cmbAudioCodec.FlatStyle = 'Flat'
@('AAC', 'MP3', 'Opus', 'Vorbis', 'AC3', 'FLAC', 'Copy') | ForEach-Object { [void]$cmbAudioCodec.Items.Add($_) }
$cmbAudioCodec.SelectedIndex = 0
$audioPanel.Controls.Add($cmbAudioCodec)

# Bitrate
$lblBitrate = New-Object Windows.Forms.Label
$lblBitrate.Text = 'Bitrate:'
$lblBitrate.Location = New-Object Drawing.Point(20, 110)
$lblBitrate.Size = New-Object Drawing.Size(100, 20)
$lblBitrate.ForeColor = $colors.Text
$audioPanel.Controls.Add($lblBitrate)

$cmbBitrate = New-Object Windows.Forms.ComboBox
$cmbBitrate.Location = New-Object Drawing.Point(130, 108)
$cmbBitrate.Size = New-Object Drawing.Size(200, 25)
$cmbBitrate.DropDownStyle = 'DropDownList'
$cmbBitrate.BackColor = $colors.Control
$cmbBitrate.ForeColor = $colors.Text
$cmbBitrate.FlatStyle = 'Flat'
@('64 kbps', '96 kbps', '128 kbps', '160 kbps', '192 kbps', '256 kbps', '320 kbps') | ForEach-Object { [void]$cmbBitrate.Items.Add($_) }
$cmbBitrate.SelectedIndex = 2
$audioPanel.Controls.Add($cmbBitrate)

# Sample rate
$lblSampleRate = New-Object Windows.Forms.Label
$lblSampleRate.Text = 'Sample Rate:'
$lblSampleRate.Location = New-Object Drawing.Point(20, 150)
$lblSampleRate.Size = New-Object Drawing.Size(100, 20)
$lblSampleRate.ForeColor = $colors.Text
$audioPanel.Controls.Add($lblSampleRate)

$cmbSampleRate = New-Object Windows.Forms.ComboBox
$cmbSampleRate.Location = New-Object Drawing.Point(130, 148)
$cmbSampleRate.Size = New-Object Drawing.Size(200, 25)
$cmbSampleRate.DropDownStyle = 'DropDownList'
$cmbSampleRate.BackColor = $colors.Control
$cmbSampleRate.ForeColor = $colors.Text
$cmbSampleRate.FlatStyle = 'Flat'
@('Same as source', '48000 Hz', '44100 Hz', '32000 Hz', '22050 Hz') | ForEach-Object { [void]$cmbSampleRate.Items.Add($_) }
$cmbSampleRate.SelectedIndex = 0
$audioPanel.Controls.Add($cmbSampleRate)

# Subtitles Tab
$subtitlesPanel = New-Object Windows.Forms.Panel
$subtitlesPanel.Dock = 'Fill'
$subtitlesPanel.BackColor = $colors.Panel
$subtitlesPanel.Visible = $false
$subtitlesPanel.AutoScroll = $true
$tabPanels['Subtitles'] = $subtitlesPanel

$subtitlesTitle = New-Object Windows.Forms.Label
$subtitlesTitle.Text = 'Subtitle Settings'
$subtitlesTitle.Location = New-Object Drawing.Point(20, 20)
$subtitlesTitle.Size = New-Object Drawing.Size(300, 30)
$subtitlesTitle.Font = New-Object Drawing.Font('Segoe UI', 14, [Drawing.FontStyle]::Bold)
$subtitlesTitle.ForeColor = $colors.Text
$subtitlesPanel.Controls.Add($subtitlesTitle)

# Import subtitle
$lblSubtitle = New-Object Windows.Forms.Label
$lblSubtitle.Text = 'Subtitle File:'
$lblSubtitle.Location = New-Object Drawing.Point(20, 70)
$lblSubtitle.Size = New-Object Drawing.Size(100, 20)
$lblSubtitle.ForeColor = $colors.Text
$subtitlesPanel.Controls.Add($lblSubtitle)

$txtSubtitle = New-Object Windows.Forms.TextBox
$txtSubtitle.Location = New-Object Drawing.Point(130, 68)
$txtSubtitle.Size = New-Object Drawing.Size(400, 25)
$txtSubtitle.BackColor = $colors.Control
$txtSubtitle.ForeColor = $colors.Text
$txtSubtitle.BorderStyle = 'FixedSingle'
$txtSubtitle.ReadOnly = $true
$subtitlesPanel.Controls.Add($txtSubtitle)

$btnBrowseSubtitle = New-Object Windows.Forms.Button
$btnBrowseSubtitle.Text = '...'
$btnBrowseSubtitle.Location = New-Object Drawing.Point(540, 66)
$btnBrowseSubtitle.Size = New-Object Drawing.Size(40, 25)
$btnBrowseSubtitle.FlatStyle = 'Flat'
$btnBrowseSubtitle.BackColor = $colors.Control
$btnBrowseSubtitle.ForeColor = $colors.Text
$btnBrowseSubtitle.FlatAppearance.BorderColor = $colors.Border
$btnBrowseSubtitle.Add_Click({
    $dialog = New-Object Windows.Forms.OpenFileDialog
    $dialog.Filter = 'Subtitle Files|*.srt;*.ass;*.ssa;*.vtt|All Files|*.*'
    $dialog.Title = 'Select Subtitle File'
    if ($dialog.ShowDialog() -eq 'OK') {
        $txtSubtitle.Text = $dialog.FileName
    }
})
$subtitlesPanel.Controls.Add($btnBrowseSubtitle)

# Font size
$lblSubFontSize = New-Object Windows.Forms.Label
$lblSubFontSize.Text = 'Font Size:'
$lblSubFontSize.Location = New-Object Drawing.Point(20, 110)
$lblSubFontSize.Size = New-Object Drawing.Size(100, 20)
$lblSubFontSize.ForeColor = $colors.Text
$subtitlesPanel.Controls.Add($lblSubFontSize)

$numSubFontSize = New-Object Windows.Forms.NumericUpDown
$numSubFontSize.Location = New-Object Drawing.Point(130, 108)
$numSubFontSize.Size = New-Object Drawing.Size(80, 25)
$numSubFontSize.Minimum = 12
$numSubFontSize.Maximum = 72
$numSubFontSize.Value = 24
$numSubFontSize.BackColor = $colors.Control
$numSubFontSize.ForeColor = $colors.Text
$numSubFontSize.BorderStyle = 'FixedSingle'
$subtitlesPanel.Controls.Add($numSubFontSize)

# Burn-in checkbox
$chkBurnIn = New-Object Windows.Forms.CheckBox
$chkBurnIn.Text = 'Burn-in subtitles (permanently embed)'
$chkBurnIn.Location = New-Object Drawing.Point(20, 150)
$chkBurnIn.Size = New-Object Drawing.Size(300, 25)
$chkBurnIn.ForeColor = $colors.Text
$chkBurnIn.Checked = $true
$subtitlesPanel.Controls.Add($chkBurnIn)

# Filters Tab (Watermark)
$filtersPanel = New-Object Windows.Forms.Panel
$filtersPanel.Dock = 'Fill'
$filtersPanel.BackColor = $colors.Panel
$filtersPanel.Visible = $false
$filtersPanel.AutoScroll = $true
$tabPanels['Filters'] = $filtersPanel

$filtersTitle = New-Object Windows.Forms.Label
$filtersTitle.Text = 'Filters - Watermark'
$filtersTitle.Location = New-Object Drawing.Point(20, 20)
$filtersTitle.Size = New-Object Drawing.Size(300, 30)
$filtersTitle.Font = New-Object Drawing.Font('Segoe UI', 14, [Drawing.FontStyle]::Bold)
$filtersTitle.ForeColor = $colors.Text
$filtersPanel.Controls.Add($filtersTitle)

# Watermark type
$lblWatermarkType = New-Object Windows.Forms.Label
$lblWatermarkType.Text = 'Type:'
$lblWatermarkType.Location = New-Object Drawing.Point(20, 70)
$lblWatermarkType.Size = New-Object Drawing.Size(100, 20)
$lblWatermarkType.ForeColor = $colors.Text
$filtersPanel.Controls.Add($lblWatermarkType)

$cmbWatermarkType = New-Object Windows.Forms.ComboBox
$cmbWatermarkType.Location = New-Object Drawing.Point(130, 68)
$cmbWatermarkType.Size = New-Object Drawing.Size(200, 25)
$cmbWatermarkType.DropDownStyle = 'DropDownList'
$cmbWatermarkType.BackColor = $colors.Control
$cmbWatermarkType.ForeColor = $colors.Text
$cmbWatermarkType.FlatStyle = 'Flat'
@('None', 'Image (PNG/JPG)', 'Text') | ForEach-Object { [void]$cmbWatermarkType.Items.Add($_) }
$cmbWatermarkType.SelectedIndex = 0
$filtersPanel.Controls.Add($cmbWatermarkType)

# Watermark file/text
$lblWatermarkContent = New-Object Windows.Forms.Label
$lblWatermarkContent.Text = 'Image/Text:'
$lblWatermarkContent.Location = New-Object Drawing.Point(20, 110)
$lblWatermarkContent.Size = New-Object Drawing.Size(100, 20)
$lblWatermarkContent.ForeColor = $colors.Text
$filtersPanel.Controls.Add($lblWatermarkContent)

$txtWatermarkContent = New-Object Windows.Forms.TextBox
$txtWatermarkContent.Location = New-Object Drawing.Point(130, 108)
$txtWatermarkContent.Size = New-Object Drawing.Size(400, 25)
$txtWatermarkContent.BackColor = $colors.Control
$txtWatermarkContent.ForeColor = $colors.Text
$txtWatermarkContent.BorderStyle = 'FixedSingle'
$filtersPanel.Controls.Add($txtWatermarkContent)

$btnBrowseWatermark = New-Object Windows.Forms.Button
$btnBrowseWatermark.Text = '...'
$btnBrowseWatermark.Location = New-Object Drawing.Point(540, 106)
$btnBrowseWatermark.Size = New-Object Drawing.Size(40, 25)
$btnBrowseWatermark.FlatStyle = 'Flat'
$btnBrowseWatermark.BackColor = $colors.Control
$btnBrowseWatermark.ForeColor = $colors.Text
$btnBrowseWatermark.FlatAppearance.BorderColor = $colors.Border
$btnBrowseWatermark.Add_Click({
    $dialog = New-Object Windows.Forms.OpenFileDialog
    $dialog.Filter = 'Image Files|*.png;*.jpg;*.jpeg|All Files|*.*'
    $dialog.Title = 'Select Watermark Image'
    if ($dialog.ShowDialog() -eq 'OK') {
        $txtWatermarkContent.Text = $dialog.FileName
    }
})
$filtersPanel.Controls.Add($btnBrowseWatermark)

# Position presets
$lblPosition = New-Object Windows.Forms.Label
$lblPosition.Text = 'Position:'
$lblPosition.Location = New-Object Drawing.Point(20, 150)
$lblPosition.Size = New-Object Drawing.Size(100, 20)
$lblPosition.ForeColor = $colors.Text
$filtersPanel.Controls.Add($lblPosition)

$cmbPosition = New-Object Windows.Forms.ComboBox
$cmbPosition.Location = New-Object Drawing.Point(130, 148)
$cmbPosition.Size = New-Object Drawing.Size(200, 25)
$cmbPosition.DropDownStyle = 'DropDownList'
$cmbPosition.BackColor = $colors.Control
$cmbPosition.ForeColor = $colors.Text
$cmbPosition.FlatStyle = 'Flat'
@('Top Left', 'Top Center', 'Top Right', 'Center Left', 'Center', 'Center Right', 'Bottom Left', 'Bottom Center', 'Bottom Right', 'Custom X/Y') | ForEach-Object { [void]$cmbPosition.Items.Add($_) }
$cmbPosition.SelectedIndex = 0
$filtersPanel.Controls.Add($cmbPosition)

# Custom X/Y
$lblCustomX = New-Object Windows.Forms.Label
$lblCustomX.Text = 'Custom X:'
$lblCustomX.Location = New-Object Drawing.Point(20, 190)
$lblCustomX.Size = New-Object Drawing.Size(100, 20)
$lblCustomX.ForeColor = $colors.Text
$filtersPanel.Controls.Add($lblCustomX)

$numCustomX = New-Object Windows.Forms.NumericUpDown
$numCustomX.Location = New-Object Drawing.Point(130, 188)
$numCustomX.Size = New-Object Drawing.Size(80, 25)
$numCustomX.Minimum = 0
$numCustomX.Maximum = 9999
$numCustomX.Value = 10
$numCustomX.BackColor = $colors.Control
$numCustomX.ForeColor = $colors.Text
$numCustomX.BorderStyle = 'FixedSingle'
$filtersPanel.Controls.Add($numCustomX)

$lblCustomY = New-Object Windows.Forms.Label
$lblCustomY.Text = 'Custom Y:'
$lblCustomY.Location = New-Object Drawing.Point(250, 190)
$lblCustomY.Size = New-Object Drawing.Size(80, 20)
$lblCustomY.ForeColor = $colors.Text
$filtersPanel.Controls.Add($lblCustomY)

$numCustomY = New-Object Windows.Forms.NumericUpDown
$numCustomY.Location = New-Object Drawing.Point(340, 188)
$numCustomY.Size = New-Object Drawing.Size(80, 25)
$numCustomY.Minimum = 0
$numCustomY.Maximum = 9999
$numCustomY.Value = 10
$numCustomY.BackColor = $colors.Control
$numCustomY.ForeColor = $colors.Text
$numCustomY.BorderStyle = 'FixedSingle'
$filtersPanel.Controls.Add($numCustomY)

# Opacity slider
$lblOpacity = New-Object Windows.Forms.Label
$lblOpacity.Text = 'Opacity:'
$lblOpacity.Location = New-Object Drawing.Point(20, 230)
$lblOpacity.Size = New-Object Drawing.Size(100, 20)
$lblOpacity.ForeColor = $colors.Text
$filtersPanel.Controls.Add($lblOpacity)

$trackOpacity = New-Object Windows.Forms.TrackBar
$trackOpacity.Location = New-Object Drawing.Point(130, 225)
$trackOpacity.Size = New-Object Drawing.Size(300, 45)
$trackOpacity.Minimum = 0
$trackOpacity.Maximum = 100
$trackOpacity.Value = 100
$trackOpacity.TickFrequency = 10
$trackOpacity.BackColor = $colors.Panel
$filtersPanel.Controls.Add($trackOpacity)

$lblOpacityValue = New-Object Windows.Forms.Label
$lblOpacityValue.Text = '100%'
$lblOpacityValue.Location = New-Object Drawing.Point(440, 230)
$lblOpacityValue.Size = New-Object Drawing.Size(50, 20)
$lblOpacityValue.ForeColor = $colors.Accent
$filtersPanel.Controls.Add($lblOpacityValue)

$trackOpacity.Add_ValueChanged({
    $lblOpacityValue.Text = "$($trackOpacity.Value)%"
})

# Font size for text watermark
$lblWatermarkFontSize = New-Object Windows.Forms.Label
$lblWatermarkFontSize.Text = 'Text Font Size:'
$lblWatermarkFontSize.Location = New-Object Drawing.Point(20, 280)
$lblWatermarkFontSize.Size = New-Object Drawing.Size(100, 20)
$lblWatermarkFontSize.ForeColor = $colors.Text
$filtersPanel.Controls.Add($lblWatermarkFontSize)

$numWatermarkFontSize = New-Object Windows.Forms.NumericUpDown
$numWatermarkFontSize.Location = New-Object Drawing.Point(130, 278)
$numWatermarkFontSize.Size = New-Object Drawing.Size(80, 25)
$numWatermarkFontSize.Minimum = 12
$numWatermarkFontSize.Maximum = 144
$numWatermarkFontSize.Value = 48
$numWatermarkFontSize.BackColor = $colors.Control
$numWatermarkFontSize.ForeColor = $colors.Text
$numWatermarkFontSize.BorderStyle = 'FixedSingle'
$filtersPanel.Controls.Add($numWatermarkFontSize)

# Add all tab panels to tab content panel
foreach ($panel in $tabPanels.Values) {
    $tabContentPanel.Controls.Add($panel)
}

# ===================================
# RIGHT PANEL - PREVIEW
# ===================================
$rightPanel = New-Object Windows.Forms.Panel
$rightPanel.Dock = 'Fill'
$rightPanel.BackColor = $colors.Control
$mainContainer.Controls.Add($rightPanel)

$previewTitle = New-Object Windows.Forms.Label
$previewTitle.Text = 'Preview / Command'
$previewTitle.Location = New-Object Drawing.Point(20, 20)
$previewTitle.Size = New-Object Drawing.Size(450, 30)
$previewTitle.Font = New-Object Drawing.Font('Segoe UI', 12, [Drawing.FontStyle]::Bold)
$previewTitle.ForeColor = $colors.Text
$rightPanel.Controls.Add($previewTitle)

$txtCommand = New-Object Windows.Forms.TextBox
$txtCommand.Location = New-Object Drawing.Point(20, 60)
$txtCommand.Size = New-Object Drawing.Size(450, 580)
$txtCommand.Multiline = $true
$txtCommand.ScrollBars = 'Both'
$txtCommand.BackColor = $colors.Panel
$txtCommand.ForeColor = $colors.Text
$txtCommand.BorderStyle = 'FixedSingle'
$txtCommand.ReadOnly = $true
$txtCommand.Font = New-Object Drawing.Font('Consolas', 8)
$txtCommand.WordWrap = $false
$rightPanel.Controls.Add($txtCommand)

# Start Encode button
$btnStartEncode = New-Object Windows.Forms.Button
$btnStartEncode.Text = 'START ENCODE'
$btnStartEncode.Location = New-Object Drawing.Point(20, 660)
$btnStartEncode.Size = New-Object Drawing.Size(200, 40)
$btnStartEncode.FlatStyle = 'Flat'
$btnStartEncode.BackColor = $colors.Accent
$btnStartEncode.ForeColor = $colors.Text
$btnStartEncode.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
$btnStartEncode.FlatAppearance.BorderColor = $colors.Accent
$btnStartEncode.Add_Click({
    if ($script:ffmpegCommand) {
        try {
            [Windows.Forms.Clipboard]::SetText($script:ffmpegCommand)
            [Windows.Forms.MessageBox]::Show("FFmpeg command copied to clipboard!`n`nYou can now paste and execute it in a command prompt.`n`nNote: Actual encoding functionality will be implemented in a future update.", 'Command Copied', 'OK', 'Information')
        } catch {
            [Windows.Forms.MessageBox]::Show("Command generated but clipboard copy failed.`n`nCommand is displayed in the preview panel.", 'Info', 'OK', 'Information')
        }
    } else {
        [Windows.Forms.MessageBox]::Show('Please select source and output files first.', 'Missing Files', 'OK', 'Warning')
    }
})
$rightPanel.Controls.Add($btnStartEncode)

# Copy to Clipboard button
$btnCopyClipboard = New-Object Windows.Forms.Button
$btnCopyClipboard.Text = 'Copy to Clipboard'
$btnCopyClipboard.Location = New-Object Drawing.Point(230, 660)
$btnCopyClipboard.Size = New-Object Drawing.Size(150, 40)
$btnCopyClipboard.FlatStyle = 'Flat'
$btnCopyClipboard.BackColor = $colors.Control
$btnCopyClipboard.ForeColor = $colors.Text
$btnCopyClipboard.FlatAppearance.BorderColor = $colors.Border
$btnCopyClipboard.Add_Click({
    if ($script:ffmpegCommand) {
        try {
            [Windows.Forms.Clipboard]::SetText($script:ffmpegCommand)
            [Windows.Forms.MessageBox]::Show('FFmpeg command copied to clipboard!', 'Success', 'OK', 'Information')
        } catch {
            [Windows.Forms.MessageBox]::Show('Failed to copy to clipboard.', 'Error', 'OK', 'Error')
        }
    } else {
        [Windows.Forms.MessageBox]::Show('No command to copy. Please configure settings first.', 'Info', 'OK', 'Information')
    }
})
$rightPanel.Controls.Add($btnCopyClipboard)

# ===================================
# FUNCTIONS
# ===================================

function Switch-Tab($tabName) {
    # Update button styles
    foreach ($btn in $tabButtons.Values) {
        $btn.BackColor = [Drawing.Color]::Transparent
        $btn.ForeColor = $colors.TextMuted
    }
    
    $tabButtons[$tabName].BackColor = $colors.Panel
    $tabButtons[$tabName].ForeColor = $colors.Text
    
    # Show/hide panels
    foreach ($panel in $tabPanels.Values) {
        $panel.Visible = $false
    }
    $tabPanels[$tabName].Visible = $true
    
    # Update command preview
    Update-Command
}

function Update-Summary() {
    if ($script:sourceFile) {
        $info = "Source File: $($script:sourceFile)`n"
        
        if (Test-Path $script:sourceFile) {
            $fileInfo = Get-Item $script:sourceFile
            $info += "Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB`n"
            $info += "Modified: $($fileInfo.LastWriteTime)`n"
        }
        
        $info += "`n"
    } else {
        $info = "No source file selected.`n`n"
    }
    
    if ($script:outputFile) {
        $info += "Output File: $($script:outputFile)`n`n"
    } else {
        $info += "Output File: Not set`n`n"
    }
    
    $info += "=== Current Settings ===`n"
    $info += "Video Codec: $($cmbCodec.SelectedItem)`n"
    $info += "Quality (CRF): $($trackQuality.Value)`n"
    $info += "Framerate: $($cmbFramerate.SelectedItem)`n"
    $info += "Resolution: $($cmbResolution.SelectedItem)`n"
    $info += "`n"
    $info += "Audio Codec: $($cmbAudioCodec.SelectedItem)`n"
    $info += "Bitrate: $($cmbBitrate.SelectedItem)`n"
    $info += "Sample Rate: $($cmbSampleRate.SelectedItem)`n"
    $info += "`n"
    
    if ($txtSubtitle.Text) {
        $info += "Subtitle: $($txtSubtitle.Text)`n"
        $info += "Burn-in: $($chkBurnIn.Checked)`n"
        $info += "`n"
    }
    
    if ($cmbWatermarkType.SelectedItem -ne 'None') {
        $info += "Watermark Type: $($cmbWatermarkType.SelectedItem)`n"
        $info += "Watermark Content: $($txtWatermarkContent.Text)`n"
        $info += "Position: $($cmbPosition.SelectedItem)`n"
        $info += "Opacity: $($trackOpacity.Value)%`n"
    }
    
    $summaryInfo.Text = $info
    Update-Command
}

function Update-Command() {
    if (-not $script:sourceFile -or -not $script:outputFile) {
        $txtCommand.Text = "# No source or output file selected`n# Use 'Open Source' and 'Save As' buttons to configure"
        $script:ffmpegCommand = ""
        return
    }
    
    # Build FFmpeg command
    $cmd = "ffmpeg -i `"$($script:sourceFile)`""
    
    # Video codec mapping
    $videoCodecMap = @{
        'H.264 (x264)' = 'libx264'
        'H.265 (x265)' = 'libx265'
        'VP9' = 'libvpx-vp9'
        'AV1' = 'libaom-av1'
        'MPEG-4' = 'mpeg4'
        'MPEG-2' = 'mpeg2video'
    }
    
    $videoCodec = $videoCodecMap[$cmbCodec.SelectedItem]
    $cmd += " -c:v $videoCodec"
    
    # CRF quality
    $cmd += " -crf $($trackQuality.Value)"
    
    # Framerate
    if ($cmbFramerate.SelectedItem -ne 'Same as source') {
        $cmd += " -r $($cmbFramerate.SelectedItem)"
    }
    
    # Resolution
    $resolutionMap = @{
        '4K (3840x2160)' = '3840:2160'
        '1080p (1920x1080)' = '1920:1080'
        '720p (1280x720)' = '1280:720'
        '480p (854x480)' = '854:480'
    }
    
    if ($resolutionMap.ContainsKey($cmbResolution.SelectedItem)) {
        $cmd += " -vf scale=$($resolutionMap[$cmbResolution.SelectedItem])"
    }
    
    # Audio codec mapping
    $audioCodecMap = @{
        'AAC' = 'aac'
        'MP3' = 'libmp3lame'
        'Opus' = 'libopus'
        'Vorbis' = 'libvorbis'
        'AC3' = 'ac3'
        'FLAC' = 'flac'
        'Copy' = 'copy'
    }
    
    $audioCodec = $audioCodecMap[$cmbAudioCodec.SelectedItem]
    $cmd += " -c:a $audioCodec"
    
    # Audio bitrate
    if ($cmbAudioCodec.SelectedItem -ne 'Copy' -and $cmbAudioCodec.SelectedItem -ne 'FLAC') {
        $bitrate = $cmbBitrate.SelectedItem -replace ' kbps', 'k'
        $cmd += " -b:a $bitrate"
    }
    
    # Sample rate
    if ($cmbSampleRate.SelectedItem -ne 'Same as source') {
        $sampleRate = $cmbSampleRate.SelectedItem -replace ' Hz', ''
        $cmd += " -ar $sampleRate"
    }
    
    # Subtitles (burn-in)
    if ($txtSubtitle.Text -and $chkBurnIn.Checked) {
        $subPath = $txtSubtitle.Text -replace '\\', '/'
        $subPath = $subPath -replace ':', '\\:'
        $cmd += " -vf `"subtitles='$subPath'`""
    }
    
    # Watermark
    if ($cmbWatermarkType.SelectedItem -eq 'Image (PNG/JPG)' -and $txtWatermarkContent.Text) {
        $wmPath = $txtWatermarkContent.Text -replace '\\', '/'
        $wmPath = $wmPath -replace ':', '\\:'
        
        # Position calculation
        $pos = switch ($cmbPosition.SelectedItem) {
            'Top Left' { '10:10' }
            'Top Center' { '(main_w-overlay_w)/2:10' }
            'Top Right' { 'main_w-overlay_w-10:10' }
            'Center Left' { '10:(main_h-overlay_h)/2' }
            'Center' { '(main_w-overlay_w)/2:(main_h-overlay_h)/2' }
            'Center Right' { 'main_w-overlay_w-10:(main_h-overlay_h)/2' }
            'Bottom Left' { '10:main_h-overlay_h-10' }
            'Bottom Center' { '(main_w-overlay_w)/2:main_h-overlay_h-10' }
            'Bottom Right' { 'main_w-overlay_w-10:main_h-overlay_h-10' }
            'Custom X/Y' { "$($numCustomX.Value):$($numCustomY.Value)" }
        }
        
        $opacity = $trackOpacity.Value / 100.0
        $cmd += " -vf `"movie='$wmPath',format=rgba,colorchannelmixer=aa=$opacity[wm];[in][wm]overlay=$pos[out]`""
    }
    elseif ($cmbWatermarkType.SelectedItem -eq 'Text' -and $txtWatermarkContent.Text) {
        $text = $txtWatermarkContent.Text -replace "'", "\\'"
        $fontSize = $numWatermarkFontSize.Value
        
        # Position calculation for text
        $pos = switch ($cmbPosition.SelectedItem) {
            'Top Left' { 'x=10:y=10' }
            'Top Center' { 'x=(w-text_w)/2:y=10' }
            'Top Right' { 'x=w-text_w-10:y=10' }
            'Center Left' { 'x=10:y=(h-text_h)/2' }
            'Center' { 'x=(w-text_w)/2:y=(h-text_h)/2' }
            'Center Right' { 'x=w-text_w-10:y=(h-text_h)/2' }
            'Bottom Left' { 'x=10:y=h-text_h-10' }
            'Bottom Center' { 'x=(w-text_w)/2:y=h-text_h-10' }
            'Bottom Right' { 'x=w-text_w-10:y=h-text_h-10' }
            'Custom X/Y' { "x=$($numCustomX.Value):y=$($numCustomY.Value)" }
        }
        
        $opacity = $trackOpacity.Value / 100.0
        $cmd += " -vf `"drawtext=text='$text':fontsize=$fontSize`:fontcolor=white@$opacity`:$pos`""
    }
    
    $cmd += " `"$($script:outputFile)`""
    
    $txtCommand.Text = $cmd
    $script:ffmpegCommand = $cmd
}

# Initial tab switch
Switch-Tab 'Summary'

# Show form
[void]$form.ShowDialog()
