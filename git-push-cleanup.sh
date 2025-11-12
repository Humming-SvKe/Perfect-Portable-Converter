#!/bin/bash

cd /workspaces/Perfect-Portable-Converter

echo "Adding all new files and changes..."
git add -A

echo "Committing cleanup changes..."
git commit -m "CLEANUP: Remove 12 obsolete GUI versions and add diagnostic tools

Removed old files:
- PPC-GUI.ps1 (original version)
- PPC-GUI-Modern.ps1 + backup + v2 + v3
- PPC-GUI-Ultimate.ps1 + v2 + v3  
- PPC-GUI-Final.ps1
- PPC-GUI-Modern-Clean.ps1
- TEST-ULTIMATE-V2.ps1
- VERIFY-VERSION.ps1

Added new files:
- CLEANUP-OLD-FILES.bat - Auto-removes old versions
- TEST-GUI.bat - Diagnostic test tool
- VERSION-CHECK.bat - Shows which files are current
- START.bat (improved) - Better error handling
- ZACNI-TU.md - Slovak quick start guide
- FIX-START-BAT.md - Troubleshooting guide
- README-SK.md - Full Slovak documentation
- CHANGELOG-CLEANUP.md - What was changed and why
- .gitignore (updated) - Ignores old versions

Current version:
- PPC-GUI-Complete.ps1 - ONLY maintained version (Apowersoft-style)

Fixes issue: 'START.bat iba otvoril a zavrel cierne okno... vela PS1 suborov'
User can now download clean version from GitHub."

echo "Pushing to GitHub..."
git push origin main

echo ""
echo "========================================="
echo " DONE! Changes pushed to GitHub"
echo "========================================="
echo ""
echo "You can now download fresh version from:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter"
