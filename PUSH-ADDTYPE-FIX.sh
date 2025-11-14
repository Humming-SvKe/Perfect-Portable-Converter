#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: Removed System.Drawing.Text code - not available in PowerShell"
git push origin main

echo ""
echo "✅ FIXED Add-Type ERROR!"
echo ""
echo "Removed System.Drawing.Text code (not supported in PowerShell)"
echo "GUI will use standard Windows text rendering"
echo ""
echo "⬇️ DOWNLOAD:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "Should launch now! 🚀"
