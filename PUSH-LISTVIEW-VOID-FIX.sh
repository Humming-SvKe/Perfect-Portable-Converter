#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Complete.ps1
git commit -m "FIX: ListView add with [void] and status label instead of popup"
git push origin main

echo ""
echo "✅ Pushed to GitHub!"
echo ""
echo "Download: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "Changes:"
echo "- Removed annoying popup message"
echo "- Used [void] instead of | Out-Null for faster ListView refresh"
echo "- Status label shows 'Added X file(s) - Ready to convert' in green"
echo "- Duplicate files skipped silently"
