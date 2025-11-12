# Perfect Portable Converter

Plne prenosný nástroj na konverziu videa pomocou FFmpeg a HandBrake. Offline ZIP obsahuje všetko – stačí rozbaliť a spustiť `START.bat`.

## 🎨 Modern GUI Edition (NEW!)

**Aero-style Windows XP/Vista dizajn s gradientmi, tieňmi a modernými funkciami!**

### ✨ Features
- 🎨 **Aero theme** - modré gradienty, tieň efekty, zaoblené rohy
- 📁 **Drag & drop support** - pridávaj súbory jednoducho
- 🖼️ **Watermark overlay** - pridaj logo/watermark na videá
- 💬 **Subtitle burn-in** - natrvalo vpáľ titulky (SRT/ASS)
- ⚡ **Dual-engine** - FFmpeg + HandBrake profily v jednom GUI
- 📊 **Real-time progress** - vidíš [X/Y] súborov a percentá
- 🎯 **5 optimalizovaných profilov** - rýchly 1080p, malý 720p, x265...

### 🚀 Quick Start
```bat
START.bat
```
→ Automaticky načíta moderné GUI s Aero témou

### 📸 Vizuálny dizajn
```
┌─────────────────────────────────────────┐
│  Perfect Portable Converter      [_][□][X]│
│  Modern Edition                         │
├─────────────────────────────────────────┤
│ [📁 Add] [🖼️ Watermark] [💬 Subtitle]   │
│ [▶ Start Conversion]                    │
│                                         │
│ Profile: HandBrake - Fast 1080p ▼      │
│                                         │
│ Files to Convert:                       │
│ ┌─────────────────────────────────┐    │
│ │ video1.mp4                      │    │
│ │ video2.mkv                      │    │
│ └─────────────────────────────────┘    │
│                                         │
│ Activity Log:                           │
│ ┌─────────────────────────────────┐    │
│ │ [1/2] (50%) Processing...       │    │
│ │ ✓ Conversion complete           │    │
│ └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

---

## HandBrake mode ⚡
This repository now includes a **modern HandBrake-based converter** `PPC-HandBrake.ps1` that can be launched via `START.bat /HB` or by running the script directly.

### ✨ Features
- **Automatic downloads** - HandBrakeCLI and FFmpeg auto-download on first run
- **Real-time progress** - See FPS, ETA, and percentage during encoding
- **Color-coded output** - Green (success), Red (error), Yellow (warning), Cyan (info)
- **Batch processing** - Shows current file X/Y and overall progress %
- **Watermark overlay** - Place `watermark.png` in `overlays/` (or per-file `filename.png`)
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
