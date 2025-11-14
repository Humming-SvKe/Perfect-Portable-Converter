#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: Clean tab labels + HandBrake install info + removed Actions column"
git push origin main

echo ""
echo "✅ OPRAVENÉ!"
echo ""
echo "🔧 ZMENY:"
echo "1. Odstránené špeciálne znaky z tabov (Split Screen, Make MV, Download, Record)"
echo "2. CONVERT button ukazuje info o inštalácii HandBrake (~15 MB, 2-3 min)"
echo "3. Odstránený stĺpec Actions ([Edit] [Size]) - tlačidlá ešte nefungujú"
echo ""
echo "⬇️ DOWNLOAD:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
