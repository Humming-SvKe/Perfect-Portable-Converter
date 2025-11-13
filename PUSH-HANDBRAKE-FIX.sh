#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: Proper DPI handling - AutoScaleMode, clean init, consistent fonts"
git push origin main

echo ""
echo "✅ Fixed rendering!"
echo ""
echo "Download: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "🔧 CHANGES (HandBrake-style):"
echo "- Removed duplicate Add-Type calls"
echo "- SetProcessDpiAwareness(2) - Per-Monitor DPI V2"
echo "- AutoScaleMode = Dpi (automatic scaling)"
echo "- SetCompatibleTextRenderingDefault(false) - GDI+ rendering"
echo "- All fonts: GraphicsUnit::Point for proper DPI scaling"
echo "- Removed UseCompatibleTextRendering properties (not needed)"
echo "- Font size: 9pt base (like HandBrake), 10pt hint, 18pt CONVERT button"
echo ""
echo "Text should now be CRISP on all DPI settings! 🎯"
