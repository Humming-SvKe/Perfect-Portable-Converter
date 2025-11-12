# Test script to verify PPC-GUI-Ultimate-v2.ps1 is loading correctly
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "PPC-GUI-Ultimate-v2 Version Check" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Join-Path $PSScriptRoot "PPC-GUI-Ultimate-v2.ps1"

if (Test-Path $scriptPath) {
    Write-Host "Script found: " -NoNewline -ForegroundColor Green
    Write-Host $scriptPath
    
    $content = Get-Content $scriptPath -Raw
    
    # Check for key features
    Write-Host ""
    Write-Host "Feature Check:" -ForegroundColor Yellow
    Write-Host "  [" -NoNewline
    if ($content -match "SetProcessDPIAware") { 
        Write-Host "✓" -NoNewline -ForegroundColor Green 
    } else { 
        Write-Host "✗" -NoNewline -ForegroundColor Red 
    }
    Write-Host "] DPI Awareness"
    
    Write-Host "  [" -NoNewline
    if ($content -match "lblHint") { 
        Write-Host "✓" -NoNewline -ForegroundColor Green 
    } else { 
        Write-Host "✗" -NoNewline -ForegroundColor Red 
    }
    Write-Host "] Hint Label"
    
    Write-Host "  [" -NoNewline
    if ($content -match "Fast 1080p - H264") { 
        Write-Host "✓" -NoNewline -ForegroundColor Green 
    } else { 
        Write-Host "✗" -NoNewline -ForegroundColor Red 
    }
    Write-Host "] Updated Profile Names"
    
    Write-Host "  [" -NoNewline
    if ($content -match "Segoe UI', 10") { 
        Write-Host "✓" -NoNewline -ForegroundColor Green 
    } else { 
        Write-Host "✗" -NoNewline -ForegroundColor Red 
    }
    Write-Host "] Font Size 10pt"
    
    $lines = (Get-Content $scriptPath).Count
    Write-Host ""
    Write-Host "Total lines: " -NoNewline
    Write-Host $lines -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "File size: " -NoNewline
    $size = [math]::Round((Get-Item $scriptPath).Length / 1KB, 2)
    Write-Host "$size KB" -ForegroundColor Cyan
    
} else {
    Write-Host "ERROR: Script not found!" -ForegroundColor Red
    Write-Host $scriptPath
}

Write-Host ""
Write-Host "Press any key to launch GUI..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Launch the GUI
& $scriptPath
