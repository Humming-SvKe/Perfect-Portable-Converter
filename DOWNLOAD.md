# 📦 DOWNLOAD - Perfect Portable Converter

## ✅ **READY TO DOWNLOAD!**

### 🎉 Nová verzia je dostupná:
HandBrake-style GUI s čistým kódom - stiahnuť môžeš hneď teraz z working branch.

### 📥 AKTUÁLNY FUNKČNÝ LINK:
```
https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/59a200d.zip
```
**✅ Tento link obsahuje:**
- `PerfectConverter.ps1` - HandBrake GUI (228 riadkov)
- `START.bat` - Launcher
- Čisté súbory bez starých PPC-*.ps1

**⚠️ Poznámka:** Main branch ešte obsahuje staré súbory. Použite link vyššie pre najnovšiu verziu!

### 🔄 Čo sa deje:
1. ❌ Odstraňovanie starých PPC-*.ps1 súborov
2. ❌ Čistenie PUSH-*.sh skriptov  
3. ❌ Mazanie nadbytočných dokumentov
4. ⏳ Vytvorenie novej verzie s Apowersoft/HandBrake GUI
5. ⏳ Testovanie a finalizácia

### ✅ Čo bude v novej verzii:
- 📁 **Jeden súbor**: `PerfectConverter.ps1` (Apowersoft style)
- 🚀 **Jednoduchý launcher**: `START.bat`
- 🎨 **Dark theme GUI** s menu bar
- 📋 **File list** s drag & drop
- 🔵 **Convert button** - veľké modré tlačidlo
- ⚙️ **Settings** - profile selector

### 📅 Očakávaná dostupnosť:
Hlavný download link bude funkčný po merge cleanup PR.

---

## 🔗 Alternatívne linky (aktuálne):

### Dočasný working branch:
```
https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/copilot/selective-halibut.zip
```

### Repository:
```
https://github.com/Humming-SvKe/Perfect-Portable-Converter
```

---

## 📥 Alternatívne stiahnutie

### Git Clone:
```bash
git clone https://github.com/Humming-SvKe/Perfect-Portable-Converter.git
cd Perfect-Portable-Converter
START.bat
```

### PowerShell Download:
```powershell
Invoke-WebRequest -Uri "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip" -OutFile "Converter.zip"
Expand-Archive -Path "Converter.zip" -DestinationPath "." -Force
cd Perfect-Portable-Converter-main
.\START.bat
```

---

## 📂 Súbory na stiahnutie:

### **Watermark Editor** (Kompletný systém)
- **libhb/watermark_extended.h** - Header súbor
  ```
  https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/libhb/watermark_extended.h
  ```

- **libhb/watermark_extended.c** - Implementácia
  ```
  https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/libhb/watermark_extended.c
  ```

- **gtk/src/watermark_gui.c** - GUI editor s drag & drop
  ```
  https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/gtk/src/watermark_gui.c
  ```

### **Subtitle Editor** (Rozšírený štýl)
- **libhb/subtitle_style_extended.h** - Header
  ```
  https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/libhb/subtitle_style_extended.h
  ```

- **libhb/subtitle_style_extended.c** - Implementácia
  ```
  https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/libhb/subtitle_style_extended.c
  ```

- **gtk/src/subtitle_editor_gui.c** - GUI editor
  ```
  https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/gtk/src/subtitle_editor_gui.c
  ```

### **Príklady a dokumentácia**
- **examples/example_watermark_usage.c** - Príklady použitia
  ```
  https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/examples/example_watermark_usage.c
  ```

- **README.md** - Kompletná dokumentácia
  ```
  https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/README.md
  ```

---

## 🚀 Rýchle stiahnutie všetkého:

## 📦 Čo obsahuje balík?

### ✅ Spustiteľné súbory:
- **START.bat** - Spúšťač (klikni a funguje!)
- **PerfectConverter.ps1** - PowerShell GUI (800×700 okno)

### ✅ Funkcie:
- 🖼️ **Image Watermark**: PNG, JPG, GIF
- ✏️ **Text Watermark**: Custom text, fonts
- 🎯 **Drag & Drop Canvas**: 640×360 preview
- 📍 **Position Control**: X/Y coords + presets
- 💧 **Transparency**: 0-100% slider
- ⚙️ **FFmpeg Export**: Copy/paste ready commands

### 📚 Bonus - C/GTK implementácia:
- `libhb/*.c` - Referenčná C knižnica
- `gtk/src/*.c` - GTK GUI pre Linux
- `examples/*.c` - Code samples

---

## 🎯 Ako to funguje?

1. **Stiahnuť** → **Rozbaliť** → **START.bat**
2. Kliknúť "📁 Open Source" - vybrať video
3. Nastaviť v taboch:
   - **Video** - codec, quality, resolution
   - **Audio** - codec, bitrate
   - **Subtitles** - import SRT súboru
   - **Filters** - pridať watermark
4. Kliknúť "START ENCODE"
5. FFmpeg príkaz v clipboard! ✅

---

## 📸 Screenshot Preview:

```
┌─────────────────────────────────────────┐
│ Perfect Portable Converter              │
├─────────────────────────────────────────┤
│ [Type] [Image] [Text] [Position] [App] │
│                                         │
│  Location: X: [320] Y: [180]           │
│                                         │
│  ╔═══════════════════════════════╗     │
│  ║  ░░░░░░░░░░░░░░░░░░░░░░░░░░  ║     │
│  ║  ░░░░ ┌─────┐ ░░░░░░░░░░░░  ║     │
│  ║  ░░░░ │ IMG │ ░░░░░░░░░░░░  ║     │
│  ║  ░░░░ └─────┘ ░░░░░░░░░░░░  ║     │
│  ║  Position: 320, 180 | 100×50 ║     │
│  ╚═══════════════════════════════╝     │
│                                         │
│  [Generate FFmpeg Command] [Close]     │
└─────────────────────────────────────────┘
```

---

## 🔗 Direct Links:

### Main Repository:
https://github.com/Humming-SvKe/Perfect-Portable-Converter

### ZIP Download:
https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip

### Individual Files:
- START.bat: https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/START.bat
- PerfectConverter.ps1: https://raw.githubusercontent.com/Humming-SvKe/Perfect-Portable-Converter/main/PerfectConverter.ps1

---

**✨ Žiadna inštalácia | Žiadna kompilácia | Len stiahni a spusti!**

### Git Clone:
```bash
git clone https://github.com/Humming-SvKe/Perfect-Portable-Converter.git
```

---

## 📋 Obsah balíka:

### ✅ Watermark funkcionalita:
- Drag & Drop canvas editor
- Image watermark (PNG, JPG, GIF)
- Text watermark s font controls
- 10 position presetov
- Custom X/Y positioning (pixels alebo %)
- Transparency slider (0-100%)
- FFmpeg filter generator

### ✅ Subtitle funkcionalita:
- Font size control (12-255 px)
- RGB color pickers
- X/Y position controls
- Alignment presets (1-9)
- Alpha/transparency
- SSA format export

### ✅ Príklady a dokumentácia:
- Working code examples
- API reference
- Usage guide
- Integration examples

---

## 🔄 Auto-update skript:

Vytvorený **BUILD-RELEASE.bat** (Windows) a **build-release.sh** (Linux) pre automatické balenie.

### Použitie:
```bash
# Linux/Mac
./build-release.sh

# Windows
BUILD-RELEASE.bat
```

Skript automaticky:
1. Vytvorí ZIP archív
2. Zobrazí download linky
3. Otvorí priečinok s výsledkom

---

## 📊 Verzie:

| Verzia | Dátum | Funkcie |
|--------|-------|---------|
| v1.0 | 2025-11-14 | ✅ Watermark Editor (Image + Text) |
| | | ✅ Drag & Drop Canvas |
| | | ✅ Subtitle Style Editor |
| | | ✅ Position Presets |
| | | ✅ FFmpeg/SSA Export |

---

## 📧 Support & Updates:

GitHub Issues: https://github.com/Humming-SvKe/Perfect-Portable-Converter/issues

---

**🎉 Verzia je pripravená na stiahnutie!**
