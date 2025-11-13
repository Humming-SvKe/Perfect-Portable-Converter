#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "IMPROVE: Larger window (1600x900) and bigger fonts (10-22pt) for better readability"
git push origin main

echo ""
echo "✅ Increased sizes for better readability!"
echo ""
echo "Download: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "📐 SIZE IMPROVEMENTS:"
echo "- Window: 1400x800 → 1600x900 (bigger display area)"
echo "- Base font: 9pt → 10pt (all controls)"
echo "- Tab buttons: 150x34 → 160x36 (10pt font)"
echo "- Add Files: 130x38 → 140x40 (10pt bold)"
echo "- ListView: 1340x460 → 1540x520 (10pt font)"
echo "- CONVERT button: 380x120 → 420x130 (18pt → 22pt bold)"
echo "- Hint text: 10pt → 11pt italic"
echo "- All text inputs: 10pt"
echo ""
echo "Larger fonts = better readability on high DPI! 📖"
