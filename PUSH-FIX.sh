#!/bin/bash
cd /workspaces/Perfect-Portable-Converter

echo "Fixing emoji characters in PPC-GUI-Complete.ps1..."
git add PPC-GUI-Complete.ps1

git commit -m "FIX: Remove emoji characters causing PowerShell parse errors

Changed:
- Watermark button: '🖼 Watermark' -> 'Watermark'
- Subtitle button: '💬 Subtitle' -> 'Subtitle'  
- Crop button: '✂ Crop' -> 'Crop'

Fixes: 'Unexpected token in expression or statement'
PowerShell 5.1 on Windows has issues with Unicode emoji."

git push origin main

echo ""
echo "✓ Fixed! Download updated version:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
