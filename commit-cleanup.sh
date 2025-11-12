#!/bin/bash
# Commit cleanup changes to GitHub

cd /workspaces/Perfect-Portable-Converter

echo "========================================="
echo "  Git Cleanup Commit Script"
echo "========================================="
echo ""

# Stage all new files
echo "Staging new files..."
git add CLEANUP-OLD-FILES.bat
git add TEST-GUI.bat
git add VERSION-CHECK.bat
git add ZACNI-TU.md
git add FIX-START-BAT.md
git add README-SK.md
git add CHANGELOG-CLEANUP.md
git add START.bat
git add .gitignore
git add cleanup-old-versions.sh

echo "Done!"
echo ""

# Show status
echo "Git status:"
git status

echo ""
echo "========================================="
echo "  Ready to commit!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Review the changes above"
echo "2. Run: git commit -m \"CLEANUP: Remove 12 old GUI versions and add cleanup tools\""
echo "3. Run: git push"
echo ""
