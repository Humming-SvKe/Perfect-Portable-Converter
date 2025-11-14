#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: Sharp text rendering - ClearTypeGridFit + AutoScaleMode Font + DoubleBuffered"
git push origin main

echo ""
echo "✅ Fixed text rendering!"
echo ""
echo "🔧 CHANGES:"
echo "- TextRenderingHint.ClearTypeGridFit for sharp ClearType text"
echo "- AutoScaleMode = Font (Windows standard)"
echo "- DoubleBuffered = true (smooth rendering)"
echo "- Font style explicitly set to Regular"
echo ""
echo "⬇️ DOWNLOAD:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "Text should now be SHARP with ClearType! 🎯"
