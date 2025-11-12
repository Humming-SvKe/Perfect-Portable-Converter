# VERIFY-VERSION.ps1 - Check if you have the latest version
$ErrorActionPreference = 'Continue'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Version Verification Tool" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$scriptPath = Join-Path (Split-Path -Parent $PSCommandPath) "PPC-GUI-Ultimate-v2.ps1"
$expectedCommit = "2c11e30"
$expectedLines = 1009
$expectedSizeKB = 35

Write-Host "Checking installation..." -ForegroundColor Yellow

# Check 1: File exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "`n[X] CRITICAL: PPC-GUI-Ultimate-v2.ps1 NOT FOUND!" -ForegroundColor Red
    Write-Host "`nExpected location: $scriptPath" -ForegroundColor Yellow
    Write-Host "`nCurrent directory: $PSScriptRoot" -ForegroundColor Yellow
    
    if ($PSScriptRoot -match "Perfect-Portable-Converter-main.*Perfect-Portable-Converter-main") {
        Write-Host "`n[!] PROBLEM DETECTED: Nested folder structure!" -ForegroundColor Red
        Write-Host "    Your path contains multiple 'Perfect-Portable-Converter-main' folders." -ForegroundColor Yellow
        Write-Host "    This means you extracted a ZIP inside a ZIP." -ForegroundColor Yellow
        Write-Host "`n    SOLUTION:" -ForegroundColor Green
        Write-Host "    1. Delete the entire folder: C:\vcs\Perfect-Portable-Converter-main" -ForegroundColor White
        Write-Host "    2. Download fresh copy from:" -ForegroundColor White
        Write-Host "       https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip" -ForegroundColor Cyan
        Write-Host "    3. Extract ONCE to C:\vcs\" -ForegroundColor White
        Write-Host "    4. Run START-ULTIMATE-V2.bat from the extracted folder" -ForegroundColor White
    } else {
        Write-Host "`n    Please download from:" -ForegroundColor Yellow
        Write-Host "    https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip" -ForegroundColor Cyan
    }
    
    pause
    exit 1
}

Write-Host "[✓] File found" -ForegroundColor Green

# Check 2: File size
$fileInfo = Get-Item $scriptPath
$actualLines = (Get-Content $scriptPath).Count
$actualSizeKB = [math]::Round($fileInfo.Length / 1KB, 1)

Write-Host "`nFile Statistics:" -ForegroundColor Yellow
Write-Host "  Lines:    $actualLines (expected: $expectedLines)" -ForegroundColor $(if ($actualLines -ge $expectedLines) {"Green"} else {"Red"})
Write-Host "  Size:     ${actualSizeKB}KB (expected: ~${expectedSizeKB}KB)" -ForegroundColor $(if ($actualSizeKB -ge $expectedSizeKB) {"Green"} else {"Red"})
Write-Host "  Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray

# Check 3: Latest features
$content = Get-Content $scriptPath -Raw

Write-Host "`nFeature Verification:" -ForegroundColor Yellow

$features = @(
    @{Name="DPI Awareness"; Pattern="SetProcessDPIAware"; Critical=$true},
    @{Name="Bottom bar 140px height"; Pattern="\`$bottomBar\.Height = 140"; Critical=$true},
    @{Name="MinimumSize constraint"; Pattern="MinimumSize"; Critical=$true},
    @{Name="CONVERT button anchor"; Pattern="\`$btnConvert\.Anchor = 'Top,Right'"; Critical=$true},
    @{Name="Engine property safety"; Pattern="Add-Member.*engine"; Critical=$true},
    @{Name="Updated profile names"; Pattern="Fast 1080p - H264"; Critical=$false},
    @{Name="Hint label positioning"; Pattern="lblHint"; Critical=$false}
)

$criticalMissing = 0
$allPassed = $true

foreach ($feature in $features) {
    $passed = $content -match $feature.Pattern
    
    Write-Host "  [" -NoNewline
    if ($passed) {
        Write-Host "✓" -ForegroundColor Green -NoNewline
    } else {
        Write-Host "✗" -ForegroundColor Red -NoNewline
        $allPassed = $false
        if ($feature.Critical) { $criticalMissing++ }
    }
    Write-Host "] $($feature.Name)" -ForegroundColor $(if ($passed) {"White"} else {"Red"})
}

# Final verdict
Write-Host "`n========================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "[SUCCESS] You have the LATEST version!" -ForegroundColor Green
    Write-Host "`nCommit: $expectedCommit (2025-11-12)" -ForegroundColor Cyan
    Write-Host "Version: Ultimate Edition v2" -ForegroundColor Cyan
    Write-Host "`nYou can safely run START-ULTIMATE-V2.bat" -ForegroundColor Green
} elseif ($criticalMissing -gt 0) {
    Write-Host "[ERROR] You have an OUTDATED version!" -ForegroundColor Red
    Write-Host "`nMissing $criticalMissing critical feature(s)." -ForegroundColor Yellow
    Write-Host "`nACTION REQUIRED:" -ForegroundColor Yellow
    Write-Host "  1. Close any running PPC windows" -ForegroundColor White
    Write-Host "  2. Delete this folder completely" -ForegroundColor White
    Write-Host "  3. Download latest version:" -ForegroundColor White
    Write-Host "     https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip" -ForegroundColor Cyan
    Write-Host "  4. Extract to C:\vcs\ (NOT inside another folder)" -ForegroundColor White
    Write-Host "  5. Run VERIFY-VERSION.ps1 again" -ForegroundColor White
} else {
    Write-Host "[WARNING] Some optional features missing" -ForegroundColor Yellow
    Write-Host "`nYour version should work, but may not have all improvements." -ForegroundColor Gray
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
pause
