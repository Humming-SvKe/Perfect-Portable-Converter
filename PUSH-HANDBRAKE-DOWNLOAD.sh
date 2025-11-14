#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FEATURE: Auto-download HandBrake with progress bar on startup"
git push origin main

echo ""
echo "✅ PRIDANÉ: Automatické sťahovanie HandBrake!"
echo ""
echo "🎯 NOVÉ FUNKCIE:"
echo "1. Pri spustení GUI sa automaticky skontroluje HandBrake"
echo "2. Ak chýba, zobrazí sa progress bar so sťahovaním (15 MB)"
echo "3. Progress ukazuje: 'X MB / 15 MB (Y%)'"
echo "4. Po stiahnutí sa automaticky extrahuje do binaries/"
echo "5. Status label ukáže 'HandBrake ready - Ready to convert'"
echo ""
echo "📦 HandBrake CLI 1.8.2 sa stiahne z oficiálneho GitHub release"
echo ""
echo "⬇️ DOWNLOAD:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
