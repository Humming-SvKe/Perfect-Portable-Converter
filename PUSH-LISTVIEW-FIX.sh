#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add PPC-GUI-Complete.ps1
git commit -m "FIX: Add Files now correctly adds videos to ListView

Fixed:
- Changed Add-VideoFile to use New-Object ListViewItem instead of Items.Add
- This ensures proper column structure (7 columns total)
- Removed annoying 'already added' popup - now silently ignores duplicates
- Better error messages with line breaks

Videos should now appear in list when you select them!"
git push origin main
echo ""
echo "DONE! Download updated version:"
echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
