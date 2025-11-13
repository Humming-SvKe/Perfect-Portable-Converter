#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Complete.ps1
git commit -m "FIX: Add Files button - better error handling and dialog

- Added try-catch error handling in Add Files button
- Added InitialDirectory to open My Videos folder by default
- Better error messages if file not found or already added
- Fixed ShowDialog to pass parent form for proper modal behavior

Now shows error messages if something goes wrong instead of silently failing."
git push origin main
echo "Done! https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
