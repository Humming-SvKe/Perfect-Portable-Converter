#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Dark.ps1
git commit -m "FIX: Syntax error - removed extra closing brace"
git push origin main

echo ""
echo "✅ FIXED SYNTAX ERROR!"
echo ""
echo "⬇️ DOWNLOAD:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "GUI should now launch without errors! 🎯"
