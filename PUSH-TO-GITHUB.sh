#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add -A
git commit -m "CLEANUP: Remove 12 old GUI versions, add diagnostic tools

Removed:
- PPC-GUI.ps1, PPC-GUI-Modern*.ps1, PPC-GUI-Ultimate*.ps1
- PPC-GUI-Final.ps1, PPC-GUI-Modern-Clean.ps1
- TEST-ULTIMATE-V2.ps1, VERIFY-VERSION.ps1

Added:
- CLEANUP-OLD-FILES.bat, TEST-GUI.bat, VERSION-CHECK.bat
- ZACNI-TU.md, FIX-START-BAT.md, README-SK.md, CHANGELOG-CLEANUP.md
- START.bat (improved), .gitignore (updated)

Only PPC-GUI-Complete.ps1 is maintained going forward."

git push origin main
echo "Done! Check: https://github.com/Humming-SvKe/Perfect-Portable-Converter"
