#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: Removed DoubleBuffered property - not accessible in PowerShell Forms"
git push origin main

echo ""
echo "✅ FIXED DoubleBuffered ERROR!"
echo ""
echo "⬇️ DOWNLOAD:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "GUI should launch now! 🎯"
