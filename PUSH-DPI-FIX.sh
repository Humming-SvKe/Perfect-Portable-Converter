#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: DPI scaling and font rendering for crisp text"
git push origin main

echo ""
echo "✅ Pushed DPI fix to GitHub!"
echo ""
echo "Download: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "🔧 FIXED:"
echo "- SetProcessDpiAwareness(2) for per-monitor DPI v2"
echo "- UseCompatibleTextRendering = false for crisp text"
echo "- Font size increased: 9 → 9.75pt (base), 9 → 10pt (tabs/buttons)"
echo "- Window size: 1280x720 → 1400x800 (more space)"
echo "- ListView columns wider for better readability"
echo "- All fonts use GraphicsUnit::Point for proper scaling"
echo ""
echo "Text should now be SHARP and CLEAR! 🎯"
