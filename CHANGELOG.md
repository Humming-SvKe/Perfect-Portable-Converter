# Changelog - Perfect Portable Converter

## [HandBrake Update] - 2025-11-12

### ✨ Nové funkcie
- **HandBrake režim** (`START.bat /HB`) s plnou podporou pre HandBrakeCLI
- **Automatické sťahovanie** HandBrakeCLI a FFmpeg pri prvom spustení
- **Farebný výstup** s vizuálnymi indikátormi (zelená=úspech, červená=chyba, žltá=varovanie)
- **Real-time progress** zobrazenie z HandBrakeCLI (FPS, ETA, percentá)
- **Batch progress tracker** - vidíš aktuálny súbor X/Y a celkový progress %
- **Watermark overlay** podpora (PNG obrázky v `overlays/`)
- **Subtitle burn-in** podpora (SRT titulky v `subtitles/`)

### 🎨 Vizuálne vylepšenia
```
============================================================
  PERFECT PORTABLE CONVERTER - HANDBRAKE MODE
============================================================

  [1] Batch Convert Videos
  [2] Exit

============================================================

[1/3] (33.3%) Processing: moje_video.mp4
============================================================

  [STEP 1/2] Preprocessing (watermark=True, subtitle=True)
  Running: ffmpeg ...
  Preprocessing complete!

  [STEP 2/2] Encoding with HandBrake...

========================================
  ENCODING IN PROGRESS
========================================
HandBrakeCLI is processing your video...
You should see progress below (FPS, ETA, %):

Encoding: task 1 of 1, 45.67 % (123.45 fps, avg 120.12 fps, ETA 00h02m15s)

  SUCCESS: moje_video.mp4 -> moje_video.mp4 (45.67 MB)

============================================================
  BATCH CONVERSION COMPLETE!
  Processed: 3/3 files
  Output folder: C:\...\output
============================================================
```

### 🔧 Technické zmeny
- Farebný výstup s `Write-Success`, `Write-Error`, `Write-Warning`, `Write-Info`
- HandBrakeCLI spúšťaný s live console output (vidíš progress v reálnom čase)
- FFmpeg preprocessing s vizuálnym indikátorom krokov
- Lepšie error handling s čitateľnými chybovými hláškami
- Progress tracker pre batch konverziu (X/Y súborov, % hotové)
- Veľkosť výstupného súboru v MB zobrazená po konverzii

### 📦 Auto-download URL
- **HandBrakeCLI 1.10.2**: `https://github.com/HandBrake/HandBrake/releases/download/1.10.2/HandBrakeCLI-1.10.2-win-x86_64.zip`
- **FFmpeg**: `https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip`

### 📝 Súbory zmenené
- `PPC-HandBrake.ps1` - nový HandBrake konvertor (356 riadkov)
- `START.bat` - pridaný `/HB` parameter
- `README.md` - dokumentácia HandBrake režimu

---

## Použitie

```bat
REM Spustenie HandBrake režimu
START.bat /HB

REM Klasický FFmpeg režim (GUI)
START.bat

REM Klasický FFmpeg režim (CLI)
START.bat /CLI
```

### Priečinková štruktúra
```
input/           ← Vlož sem zdrojové videá
overlays/        ← Vlož sem watermark.png (alebo nazov_videa.png)
subtitles/       ← Vlož sem nazov_videa.srt
output/          ← Tu nájdeš skonvertované videá
binaries/        ← Auto-stiahne HandBrakeCLI.exe a ffmpeg.exe
logs/            ← Logy zo všetkých operácií
temp/            ← Dočasné súbory (automaticky čistené)
```
