#!/bin/bash
cd /workspaces/Perfect-Portable-Converter
git add -A
git commit -m "FIX: HandBrake download progress using HttpWebRequest with manual chunks

- Replaced WebClient async events with HttpWebRequest synchronous approach
- Manual buffer reading (8192 bytes) with progress calculation
- Live status bar updates: 'Downloading HandBrake: X.X MB / Y.Y MB (Z%)'
- Application.DoEvents() for UI refresh during download
- Fixes DownloadProgressChanged property error"
git push origin main
echo ""
echo "✅ Pushed to GitHub!"
echo "Download: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
