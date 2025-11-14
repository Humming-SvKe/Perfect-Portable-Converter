#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: Clean Convert tab + visible Add Files button + clear CONVERT message"
git push origin main

echo ""
echo "✅ OPRAVENÉ!"
echo ""
echo "🔧 ZMENY:"
echo "1. Odstránený znak z Convert tabu"
echo "2. Add Files tlačidlo: 140x40 → 120x36 (celé viditeľné)"
echo "3. CONVERT button: jasná správa bez mätúcej info o sťahovaní"
echo ""
echo "⬇️ DOWNLOAD:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
