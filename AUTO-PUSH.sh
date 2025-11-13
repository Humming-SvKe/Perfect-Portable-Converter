#!/bin/bash
set -e
cd /workspaces/Perfect-Portable-Converter

# Stage emoji fix
git add PPC-GUI-Complete.ps1

# Commit
git commit -m "FIX: Remove emoji characters causing PowerShell parse errors

- Removed emoji from Watermark, Subtitle, Crop buttons
- Fixes 'Unexpected token' error on Windows PowerShell 5.1"

# Push
git push origin main

echo "DONE! Updated version now on GitHub."
