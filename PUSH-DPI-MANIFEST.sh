#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1 app.manifest
git commit -m "FIX: DPI rendering - manifest + SetProcessDPIAware + simplified fonts"
git push origin main

echo ""
echo "✅ Fixed DPI rendering!"
echo ""
echo "Download: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "🔧 CRITICAL FIXES:"
echo "- Added app.manifest with PerMonitorV2 DPI awareness"
echo "- Changed to SetProcessDPIAware() (more stable for WinForms)"
echo "- Removed AutoScaleMode (causes blur on WinForms)"
echo "- Removed GraphicsUnit::Point (not needed)"
echo "- ClientSize instead of Size (proper client area)"
echo "- Simple font declarations without GraphicsUnit"
echo ""
echo "This should fix blurry text on all DPI settings! 🎯"
