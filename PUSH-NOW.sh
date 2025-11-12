#!/bin/bash
# PUSH-NOW.sh - Immediate push to GitHub

set -e

cd /workspaces/Perfect-Portable-Converter

echo "========================================="
echo "  PUSHING CLEANUP TO GITHUB"
echo "========================================="
echo ""

# Stage all changes
echo "[1/4] Staging all changes..."
git add -A

# Show what will be committed
echo ""
echo "[2/4] Changes to be committed:"
git status --short

# Commit
echo ""
echo "[3/4] Creating commit..."
git commit -m "CLEANUP: Remove 12 old GUI versions, add diagnostic tools

REMOVED (12 old files):
- PPC-GUI.ps1
- PPC-GUI-Modern.ps1 + backup + v2 + v3
- PPC-GUI-Ultimate.ps1 + v2 + v3
- PPC-GUI-Final.ps1
- PPC-GUI-Modern-Clean.ps1
- TEST-ULTIMATE-V2.ps1
- VERIFY-VERSION.ps1

ADDED (8 new files):
- CLEANUP-OLD-FILES.bat - Auto-cleanup script
- TEST-GUI.bat - Diagnostic tool
- VERSION-CHECK.bat - Version checker
- ZACNI-TU.md - Slovak quick start
- FIX-START-BAT.md - Troubleshooting guide
- README-SK.md - Full Slovak docs
- CHANGELOG-CLEANUP.md - Change log
- START.bat (improved) - Better error handling
- .gitignore (updated) - Ignore old versions

CURRENT VERSION:
- PPC-GUI-Complete.ps1 - ONLY maintained GUI (550+ lines, Apowersoft-style)

Fixes: 'START.bat iba otvoril a zavrel... vela PS1 suborov'
User can now download clean version with auto-cleanup tools."

# Push
echo ""
echo "[4/4] Pushing to GitHub..."
git push origin main

echo ""
echo "========================================="
echo "  ✓ SUCCESS! Changes pushed to GitHub"
echo "========================================="
echo ""
echo "Download clean version from:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "Or browse repository:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter"
echo ""
