#!/bin/bash
# Removes old GUI versions from git and filesystem

echo "Removing old GUI versions from git..."

git rm -f PPC-GUI.ps1 \
         PPC-GUI-Modern.ps1 \
         PPC-GUI-Modern.ps1.backup \
         PPC-GUI-Modern-v2.ps1 \
         PPC-GUI-Modern-v3.ps1 \
         PPC-GUI-Ultimate.ps1 \
         PPC-GUI-Ultimate-v2.ps1 \
         PPC-GUI-Ultimate-v3.ps1 \
         PPC-GUI-Final.ps1 \
         PPC-GUI-Modern-Clean.ps1 \
         TEST-ULTIMATE-V2.ps1 \
         VERIFY-VERSION.ps1 2>/dev/null

echo "Done! Old versions removed from git."
echo "Now commit and push these changes."
