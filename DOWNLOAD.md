# 📥 Download Perfect Portable Converter

## Quick Download

**Download the latest version:**
```
https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip
```

## Installation Steps

1. **Download** the ZIP file from the link above
2. **Extract** the archive to any folder on your computer
3. **Run** `START.bat` to launch the converter

That's it! No installation required.

## 🚀 First Run

On first run, the converter will automatically:
- Download HandBrakeCLI (if not present in `binaries/` folder)
- Download FFmpeg (if not present in `binaries/` folder)
- Create necessary folders (`input/`, `output/`, `logs/`, etc.)

## 📁 Folder Structure

After extraction, you'll have:
```
Perfect-Portable-Converter-main/
├── START.bat                  ← Double-click to launch
├── PerfectConverter.ps1       ← Main converter script
├── README.md                  ← Documentation
├── CHANGELOG.md               ← Version history
├── LICENSE                    ← License information
├── binaries/                  ← HandBrake & FFmpeg (auto-downloaded)
├── config/                    ← Configuration files
├── input/                     ← Place your videos here
├── output/                    ← Converted videos appear here
├── overlays/                  ← Watermark images (optional)
└── subtitles/                 ← Subtitle files (optional)
```

## 🎯 Usage

1. Put your video files in the `input/` folder
2. Run `START.bat`
3. Select a conversion profile
4. Wait for conversion to complete
5. Find converted videos in the `output/` folder

## 💡 Optional Features

### Add Watermark
Place a `watermark.png` file in the `overlays/` folder to add it to all videos.
Or use `videoname.png` to add a watermark to specific videos only.

### Burn-in Subtitles
Place a `videoname.srt` file in the `subtitles/` folder (matching your video filename) to permanently burn subtitles into the video.

## 🔄 Updates

To update to the latest version:
1. Download the latest ZIP from the link above
2. Extract to a new folder
3. Copy your videos from the old `input/` folder to the new one
4. Run `START.bat` in the new folder

## ⚙️ System Requirements

- **OS:** Windows 10/11 (64-bit)
- **PowerShell:** 5.1 or later (included in Windows)
- **RAM:** 4GB minimum
- **Internet:** Required for first-time setup (downloads binaries)
- **Disk Space:** At least 500MB free for binaries and temporary files

## 🐛 Troubleshooting

**Problem:** "PerfectConverter.ps1 not found"
- Solution: Make sure you extracted the entire ZIP file, not just START.bat

**Problem:** Download fails during first run
- Solution: Manually download HandBrakeCLI.exe and ffmpeg.exe and place them in the `binaries/` folder
  - HandBrake: https://handbrake.fr/downloads.php
  - FFmpeg: https://ffmpeg.org/download.html

**Problem:** "Cannot run script, execution policy"
- Solution: The START.bat file already handles this with `-ExecutionPolicy Bypass`

## 📞 Support

- **Issues:** https://github.com/Humming-SvKe/Perfect-Portable-Converter/issues
- **Latest Release:** https://github.com/Humming-SvKe/Perfect-Portable-Converter/releases

## 📜 License

MIT License - Free to use, modify, and distribute.
