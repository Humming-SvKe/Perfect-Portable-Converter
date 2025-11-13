#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Complete.ps1
git commit -m "DEBUG: Add Files with inline ListView add and success message

- Bypassed Add-VideoFile function completely
- Added files DIRECTLY to ListView in button click event
- Added success popup showing how many files were added
- Added detailed error message with stack trace
- This will show exactly what's happening

Test: Click Add Files, select video, should show 'Added X file(s)' message"
git push origin main
echo ""
echo "DOWNLOAD DEBUG VERSION:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
echo ""
echo "After testing, tell me:"
echo "1. Did the file dialog open?"
echo "2. Did you see 'Added X files' message?"
echo "3. Did files appear in list?"
