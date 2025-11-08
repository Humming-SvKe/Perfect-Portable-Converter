<# Perfect Portable Converter (PPC) - GUI (WinForms, PS5.1 safe, verified output) #>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Relaunch in STA if needed (required by WinForms)
try {
  if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile','-ExecutionPolicy','Bypass','-STA','-File', $PSCommandPath) -WindowStyle Normal
    return
  }
} catch {}

# Paths
$Root  = Split-Path -Parent $PSCommandPath
$Bins  = Join-Path $Root 'binaries'
$Logs  = Join-Path $Root 'logs'
$Temp  = Join-Path $Root 'temp'
$Out   = Join-Path $Root 'output'
$Cfg   = Join-Path $Root 'config\defaults.json'

$null = New-Item -ItemType Directory -Force -Path $Bins,$Logs,$Temp,$Out | Out-Null
$LogFile = Join-Path $Logs 'ppc.log'
$FFLog  = Join-Path $Logs 'ffmpeg.log'

function Write-Log([string]$m){
  $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); "$ts | $m" | Out-File -Append -Encoding UTF8 $LogFile
}

# TLS + download helpers
function Ensure-Tls12 { try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {} }
function Download-File([string]$Url,[string]$Dst){ Ensure-Tls12; Write-Log ("Downloading: " + $Url); Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Dst }
function Expand-Zip([string]$Zip,[string]$Dest){
  try { Expand-Archive -Path $Zip -DestinationPath $Dest -Force }
  catch { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory($Zip,$Dest) }
}

# Config (fallback defaults)
$Config = @{
  default_format = 'mp4';
  profiles = @(
    @{ name='Fast 1080p H264';  vcodec='libx264'; preset='veryfast'; crf=23; acodec='aac'; ab='160k'; scale='' },
    @{ name='Small 720p H264'; vcodec='libx264'; preset='veryfast'; crf=25; acodec='aac'; ab='128k'; scale='1280:-2' },
    @{ name='Device WhatsApp H264'; vcodec='libx264'; preset='medium'; crf=24; acodec='aac'; ab='128k'; scale='1280:-2' }
  )
}
if (Test-Path $Cfg) { try { $Config = Get-Content $Cfg -Raw | ConvertFrom-Json } catch { Write-Log 'WARN: Config load failed, using defaults.' } }

$global:FFMPEG=''; $global:FFPROBE=''
function Install-FFTools {
  try {
    $zip = Join-Path $Temp 'ffmpeg.zip'; $dst = Join-Path $Temp 'ffmpeg'
    if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    $url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
    Download-File -Url $url -Dst $zip
    Expand-Zip -Zip $zip -Dest $dst
    $ff = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    $fp = Get-ChildItem -LiteralPath $dst -Recurse -Filter ffprobe.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ff) { Copy-Item -LiteralPath $ff.FullName -Destination (Join-Path $Bins 'ffmpeg.exe') -Force }
    if ($fp) { Copy-Item -LiteralPath $fp.FullName -Destination (Join-Path $Bins 'ffprobe.exe') -Force }
    Remove-Item $zip -Force -ErrorAction SilentlyContinue; Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
    return $true
  } catch { Write-Log ('ERROR: FFmpeg install failed: ' + $_.Exception.Message); return $false }
}
function Resolve-FFTools {
  $ff = Join-Path $Bins 'ffmpeg.exe'; $fp = Join-Path $Bins 'ffprobe.exe'
  if (Test-Path $ff) { $global:FFMPEG = $ff }
  if (Test-Path $fp) { $global:FFPROBE = $fp }
  if (-not (Test-Path $ff)) {
    Write-Log 'WARN: ffmpeg.exe not found, trying auto-download...'
    if (Install-FFTools) { if (Test-Path $ff) { $global:FFMPEG=$ff }; if (Test-Path $fp) { $global:FFPROBE=$fp } }
  }
  if (-not (Test-Path $ff)) { Write-Log "ERROR: FFmpeg missing. Place ffmpeg.exe into 'binaries' or allow internet."; return $false }
  return $true
}

function Build-Args($p, [string]$src, [string]$dst){
  $v=@(); if($p.vcodec){$v+='-c:v';$v+=$p.vcodec}; if($p.preset){$v+='-preset';$v+=$p.preset}; if($null -ne $p.crf){$v+='-crf';$v+=[string]$p.crf}
  $a=@(); if($p.acodec){$a+='-c:a';$a+=$p.acodec}; if($p.ab){$a+='-b:a';$a+=$p.ab}
  $filters=@(); if($p.scale){$filters+=('scale=' + $p.scale)}
  $vf=@(); if($filters.Count -gt 0){ $vf = @('-vf', ([string]::Join(',', $filters))) }
  return @('-y','-hide_banner','-loglevel','warning','-i', $src) + $vf + $v + $a + @($dst)
}

function Convert-One([string]$src,[string]$dst,$p){
  if (-not (Resolve-FFTools)) { return $false }
  # Ensure output directory exists (user may have changed it)
  $outDir = Split-Path -Parent $dst; if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

  $args = Build-Args -p $p -src $src -dst $dst
  Write-Log ('ffmpeg ' + ($args -join ' '))
  & $global:FFMPEG @args 2>&1 | Tee-Object -FilePath $FFLog -Append | Out-Null

  if ($LASTEXITCODE -ne 0) { Write-Log ('FFmpeg failed with code ' + $LASTEXITCODE); return $false }
  if (-not (Test-Path -LiteralPath $dst)) { Write-Log ('FAIL: Output file not created: ' + $dst); return $false }
  $fi = Get-Item -LiteralPath $dst -ErrorAction SilentlyContinue
  if ($null -eq $fi -or [int64]$fi.Length -le 0) { Write-Log ('FAIL: Output appears empty: ' + $dst); return $false }
  return $true
}

# GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Perfect Portable Converter (GUI)'
$form.Width = 820; $form.Height = 560
$form.StartPosition = 'CenterScreen'

$btnAdd = New-Object System.Windows.Forms.Button; $btnAdd.Text='Add files'; $btnAdd.Left=10; $btnAdd.Top=10; $btnAdd.Width=100
$btnOut = New-Object System.Windows.Forms.Button; $btnOut.Text='Output...'; $btnOut.Left=120; $btnOut.Top=10; $btnOut.Width=100
$cmbProf = New-Object System.Windows.Forms.ComboBox; $cmbProf.Left=230; $cmbProf.Top=12; $cmbProf.Width=260; $cmbProf.DropDownStyle='DropDownList'
$btnStart = New-Object System.Windows.Forms.Button; $btnStart.Text='Start'; $btnStart.Left=500; $btnStart.Top=10; $btnStart.Width=100
$lblOut = New-Object System.Windows.Forms.Label; $lblOut.Left=10; $lblOut.Top=45; $lblOut.Width=780; $lblOut.Text = ('Output: ' + $Out)
$lst = New-Object System.Windows.Forms.ListBox; $lst.Left=10; $lst.Top=70; $lst.Width=780; $lst.Height=350
$log = New-Object System.Windows.Forms.TextBox; $log.Left=10; $log.Top=430; $log.Width=780; $log.Height=80; $log.Multiline=$true; $log.ScrollBars='Vertical'; $log.ReadOnly=$true

$form.Controls.AddRange(@($btnAdd,$btnOut,$cmbProf,$btnStart,$lblOut,$lst,$log))

# Load profiles
$cmbProf.Items.Clear(); foreach($p in $Config.profiles){ [void]$cmbProf.Items.Add($p.name) }; if($cmbProf.Items.Count -gt 0){ $cmbProf.SelectedIndex = 0 }
$script:Out = $Out

# Handlers
$btnAdd.Add_Click({ $ofd = New-Object System.Windows.Forms.OpenFileDialog; $ofd.Multiselect = $true; $ofd.Filter = 'Videos|*.mp4;*.mkv;*.avi;*.mov;*.webm|All|*.*'; if($ofd.ShowDialog() -eq 'OK'){ $ofd.FileNames | ForEach-Object { [void]$lst.Items.Add($_) } } })
$btnOut.Add_Click({ $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; $fbd.SelectedPath = $script:Out; if($fbd.ShowDialog() -eq 'OK'){ $script:Out = $fbd.SelectedPath; $lblOut.Text = ('Output: ' + $script:Out) } })
$btnStart.Add_Click({
  if ($lst.Items.Count -eq 0){ [System.Windows.Forms.MessageBox]::Show('Add at least one file.'); return }
  if ($cmbProf.SelectedIndex -lt 0){ [System.Windows.Forms.MessageBox]::Show('Select a profile.'); return }
  $p = $Config.profiles[$cmbProf.SelectedIndex]

  # Disable UI during processing
  $btnAdd.Enabled=$false; $btnOut.Enabled=$false; $btnStart.Enabled=$false; $cmbProf.Enabled=$false
  $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
  $okCount=0; $failCount=0
  try {
    foreach($it in $lst.Items){
      try{
        $src = [string]$it
        $ext = if ($p.PSObject.Properties.Name -contains 'format' -and $p.format) { $p.format } else { $Config.default_format }
        $dst = Join-Path $script:Out ('{0}.{1}' -f [IO.Path]::GetFileNameWithoutExtension($src), $ext)
        $ok = Convert-One -src $src -dst $dst -p $p
        if ($ok) { $okCount++; $msg = ('OK: {0} -> {1}' -f [IO.Path]::GetFileName($src), $dst) }
        else { $failCount++; $msg = ('FAIL: {0} -> see logs/ffmpeg.log' -f [IO.Path]::GetFileName($src)) }
        $log.AppendText($msg + [Environment]::NewLine); Write-Log $msg
      } catch { $failCount++; $em = 'FAIL: ' + $_.Exception.Message; $log.AppendText($em + [Environment]::NewLine); Write-Log $em }
    }
  }
  finally {
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
    $btnAdd.Enabled=$true; $btnOut.Enabled=$true; $btnStart.Enabled=$true; $cmbProf.Enabled=$true
  }
  [System.Windows.Forms.MessageBox]::Show(('Completed. OK: {0}, FAIL: {1}' -f $okCount, $failCount))
})

# Ensure tools are present on form load
$form.Add_Shown({ if(-not (Resolve-FFTools)){ [System.Windows.Forms.MessageBox]::Show("FFmpeg missing. Place ffmpeg.exe into 'binaries' or allow internet for one-time download.") } })

[void]$form.ShowDialog()