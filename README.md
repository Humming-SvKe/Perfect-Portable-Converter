# Professional Portable Converter - Ultimate Edition v2

Modern Dark Mode video converter with FFmpeg and HandBrake support. Zero installation - just download, extract, and run `START.bat`.

## 🚀 Quick Start

**Download latest version:**
```
https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip
```

**Extract and run:**
```bat
START.bat
```

That's it! The modern dark UI will launch automatically.

## ✨ Features

- 🎨 **Modern Dark Mode** - Professional flat UI inspired by VS Code
- 📁 **Drag & Drop** - Add video files easily
- 🖼️ **Watermark Support** - Add logos to your videos
- 💬 **Subtitle Burn-in** - Permanently embed SRT/ASS subtitles
- ⚡ **Dual Engine** - FFmpeg + HandBrake profiles
- 📊 **Real-time Progress** - Live conversion status
- 🎯 **4 Optimized Presets** - Fast 1080p, High Quality, Small Size, HEVC/H265
- � **DPI Aware** - Crystal clear on high-DPI monitors
- 🌐 **No Installation** - Portable, runs from any folder

## �️ System Requirements

- Windows 10/11 (64-bit)
- PowerShell 5.1+ (included in Windows)
- 4GB RAM minimum
- Internet connection (first run only - downloads FFmpeg/HandBrake)

## 📋 Usage

1. **Run START.bat**
2. **Click "+ Add Files"** or drag & drop videos
3. **Select conversion profile** from dropdown
4. **Choose output folder** (optional)
5. **Click CONVERT**

## �️ Troubleshooting

**Problem: GUI looks wrong or features missing**
```powershell
# Run version checker
.\VERIFY-VERSION.ps1
```

If it shows errors, re-download from GitHub link above.

**Problem: "Display is still wrong"**

Make sure you don't have nested folders:
- ✓ Correct: `C:\vcs\Perfect-Portable-Converter-main\START.bat`
- ✗ Wrong: `C:\vcs\...\...\...\START.bat`

See `INSTALL-INSTRUCTIONS.md` for detailed fix.

## 📁 Project Structure

```
Perfect-Portable-Converter/
├── START.bat                  ← Main launcher
├── PPC-GUI-Ultimate-v2.ps1    ← Modern Dark Mode GUI
├── VERIFY-VERSION.ps1         ← Version checker
├── INSTALL-INSTRUCTIONS.md    ← Setup guide
├── config/
│   └── defaults.json          ← Conversion profiles
├── binaries/                  ← FFmpeg/HandBrake (auto-downloaded)
├── input/                     ← Source videos
├── output/                    ← Converted videos
├── overlays/                  ← Watermark images
└── subtitles/                 ← SRT/ASS files
```

## 🔄 Conversion Profiles

**Fast 1080p - H264 (AAC 128k Stereo)**
- Preset: veryfast, CRF 23
- Best for: Quick conversions, streaming

**High Quality - 1080p H264 (AAC 160k Stereo)**
- Preset: medium, CRF 20
- Best for: Archival, high-quality output

**Small Size - 720p H264 (AAC 128k Stereo)**
- Scaled to 1280x720, CRF 25
- Best for: Mobile devices, web upload

**HEVC/H265 - MKV (AAC 160k Stereo)**
- Uses HandBrake engine
- Best for: Space-efficient archival (50% smaller than H264)

## 💡 Tips

- **Watermarks**: Place `watermark.png` in `overlays/` folder
- **Subtitles**: Place `video_name.srt` in `subtitles/` folder (must match video filename)
- **Custom profiles**: Edit `config/defaults.json` to add your own presets
- **Batch conversion**: Add multiple files before clicking CONVERT

## 🐛 Known Issues

None currently! All major bugs fixed as of commit `2c11e30`.

## 📝 Changelog

**v2.0.0 (2025-11-12) - Ultimate Edition**
- ✨ Complete UI rewrite with modern Dark Mode
- 🔧 Fixed critical PropertyNotFoundException error
- 📐 Improved layout with better control positioning
- 🎨 DPI awareness for high-resolution displays
- 📋 Hint label for empty file list
- 🔒 Minimum window size constraint

See `CHANGELOG-v2.md` for full history.

## 📜 License

MIT License - See `LICENSE` file

## 🤝 Contributing

Contributions welcome! Please open an issue or pull request on GitHub.

## 🔗 Links

- **GitHub**: https://github.com/Humming-SvKe/Perfect-Portable-Converter
- **Issues**: https://github.com/Humming-SvKe/Perfect-Portable-Converter/issues
- **Latest Release**: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip
- **Subtitle burn-in** - Place `filename.srt` in `subtitles/` for automatic burn-in
- **Visual indicators** - Modern progress display with clear step-by-step feedback

### 🚀 Quick Start
```bat
START.bat /HB
```

### 📁 Workflow
1. Put source files into `input/`
2. (Optional) Put overlays into `overlays/` 
   - Global: `watermark.png` 
   - Per-file: `myvideo.png`
3. (Optional) Put subtitles into `subtitles/`
   - Per-file: `myvideo.srt`
4. Run `START.bat /HB` and pick a profile
5. Watch the **real-time progress** with FPS and ETA
6. Get converted files from `output/`

### 🎨 Visual Example
```
[1/3] (33.3%) Processing: myvideo.mp4
============================================================
  [STEP 1/2] Preprocessing (watermark=True, subtitle=True)
  Preprocessing complete!
  
  [STEP 2/2] Encoding with HandBrake...
  
Encoding: task 1 of 1, 45.67 % (123 fps, ETA 00h02m15s)

  SUCCESS: myvideo.mp4 -> myvideo.mp4 (45.67 MB)
```

### ⚙️ Profiles
- **Fast 1080p (x264)** - Quality 22, AAC 160k
- **Small 720p (x264)** - Quality 24, AAC 128k  
- **x265 Medium** - Quality 26, AAC 160k

### 📦 Requirements
- Windows PC
- Internet connection (one-time, for auto-download of binaries)
- Or manually place `HandBrakeCLI.exe` and `ffmpeg.exe` into `binaries/`
