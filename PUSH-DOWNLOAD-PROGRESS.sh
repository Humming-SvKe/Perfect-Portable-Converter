#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: HandBrake download progress visible in status bar with live updates"
git push origin main

echo ""
echo "✅ OPRAVENÉ: Priebeh sťahovania HandBrake!"
echo ""
echo "🎯 ČO SA ZOBRAZUJE:"
echo "1. Status bar: 'Downloading HandBrake CLI (15 MB)... Please wait' (oranžová)"
echo "2. Live update: 'Downloading HandBrake: X.X MB / 15.0 MB (Y%)'"
echo "3. Po stiahnutí: 'Extracting HandBrake...' (oranžová)"
echo "4. Hotovo: 'HandBrake ready - Ready to convert' (zelená)"
echo ""
echo "🔄 Update každých 500ms pre plynulý progress"
echo "📊 Zobrazuje: stiahnuté MB / celkom MB (percento)"
echo ""
echo "⬇️ DOWNLOAD:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
