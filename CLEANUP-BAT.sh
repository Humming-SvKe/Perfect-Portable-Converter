#!/bin/bash
cd /workspaces/Perfect-Portable-Converter

# Remove extra BAT files (keep only START.bat)
git rm CLEANUP-OLD-FILES.bat
git rm TEST-GUI.bat
git rm VERSION-CHECK.bat
git rm REPORT.bat

# Update .gitignore to ignore BAT files except START.bat
echo "" >> .gitignore
echo "# Only START.bat is needed" >> .gitignore
echo "*.bat" >> .gitignore
echo "!START.bat" >> .gitignore

git add .gitignore
git commit -m "CLEANUP: Remove extra BAT files - only START.bat needed"
git push origin main

echo ""
echo "✅ Removed extra BAT files!"
echo ""
echo "Deleted:"
echo "- CLEANUP-OLD-FILES.bat"
echo "- TEST-GUI.bat"
echo "- VERSION-CHECK.bat"
echo "- REPORT.bat"
echo ""
echo "Kept: START.bat (main launcher)"
echo ""
echo "Download: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
