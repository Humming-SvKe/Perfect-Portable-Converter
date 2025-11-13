#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "SIMPLIFY: Remove DPI awareness - use standard Windows rendering"
git push origin main

echo ""
echo "✅ Simplified DPI handling!"
echo ""
echo "Download: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "🔧 CHANGES:"
echo "- Removed SetProcessDPIAware() call"
echo "- Kept EnableVisualStyles() + SetCompatibleTextRenderingDefault(false)"
echo "- Windows will handle DPI automatically with default settings"
echo "- Larger fonts (10pt base) compensate for high DPI"
echo ""
echo "Let Windows handle DPI scaling automatically! 🎯"
