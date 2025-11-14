Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Apowersoft Video Converter Studio"
$form.Size = New-Object System.Drawing.Size(1280, 720)
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)
$form.StartPosition = "CenterScreen"

# Menu Bar
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$menuStrip.ForeColor = [System.Drawing.Color]::White

$convertMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Convert")
$splitMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Split Screen")
$mvMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Make MV")
$downloadMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Download")
$recordMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Record")

$menuStrip.Items.AddRange(@($convertMenu, $splitMenu, $mvMenu, $downloadMenu, $recordMenu))
$form.Controls.Add($menuStrip)

# Toolbar
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.Dock = "Top"
$toolbar.Height = 50
$toolbar.BackColor = [System.Drawing.Color]::FromArgb(58, 63, 69)
$toolbar.Top = 24

$btnAddFiles = New-Object System.Windows.Forms.Button
$btnAddFiles.Text = "+ Add Files"
$btnAddFiles.Location = New-Object System.Drawing.Point(20, 10)
$btnAddFiles.Size = New-Object System.Drawing.Size(100, 30)
$btnAddFiles.BackColor = [System.Drawing.Color]::FromArgb(78, 182, 255)
$btnAddFiles.ForeColor = [System.Drawing.Color]::White
$btnAddFiles.FlatStyle = "Flat"
$btnAddFiles.Add_Click({
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "Video Files|*.mp4;*.mkv;*.avi;*.mov;*.flv;*.wmv|All Files|*.*"
    $openDialog.Multiselect = $true
    if ($openDialog.ShowDialog() -eq "OK") {
        foreach ($file in $openDialog.FileNames) {
            $listView.Items.Add($file)
        }
    }
})

$toolbar.Controls.Add($btnAddFiles)

# ListView for files
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(20, 100)
$listView.Size = New-Object System.Drawing.Size(1240, 400)
$listView.View = "Details"
$listView.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)
$listView.ForeColor = [System.Drawing.Color]::White
$listView.FullRowSelect = $true
$listView.GridLines = $true

$listView.Columns.Add("File Name", 300)
$listView.Columns.Add("Size", 100)
$listView.Columns.Add("Duration", 100)
$listView.Columns.Add("Resolution", 100)
$listView.Columns.Add("Format", 100)
$listView.Columns.Add("Output Format", 150)
$listView.Columns.Add("Status", 150)

$form.Controls.Add($listView)

# Bottom controls
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Dock = "Bottom"
$bottomPanel.Height = 100
$bottomPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 50, 56)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "HandBrake ready - Ready to convert"
$lblStatus.Location = New-Object System.Drawing.Point(20, 10)
$lblStatus.Size = New-Object System.Drawing.Size(300, 20)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
$bottomPanel.Controls.Add($lblStatus)

$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = "CONVERT"
$btnConvert.Location = New-Object System.Drawing.Point(1000, 50)
$btnConvert.Size = New-Object System.Drawing.Size(240, 40)
$btnConvert.BackColor = [System.Drawing.Color]::FromArgb(78, 182, 255)
$btnConvert.ForeColor = [System.Drawing.Color]::White
$btnConvert.FlatStyle = "Flat"
$btnConvert.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$bottomPanel.Controls.Add($btnConvert)

$form.Controls.Add($bottomPanel)

[void]$form.ShowDialog()
