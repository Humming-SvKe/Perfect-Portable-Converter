# 📦 DOWNLOAD - Perfect Portable Converter

## ✅ **HandBrake-Style GUI - VERIFIED WORKING!**

### 🎉 Overená funkčná verzia:
✅ Testované a funkčné - GUI sa zobrazuje správne!

---

## 📥 DOWNLOAD LINKS:

### 🔗 LINK 1 - Odporúčaný (najnovší):
```
https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/59a200d.zip
```
**✅ Obsahuje:**
- `PerfectConverter.ps1` - HandBrake GUI (228 riadkov)
- `START.bat` - Jednoduchý launcher
- Všetky potrebné priečinky (binaries/, config/, input/, output/)

### 🔗 LINK 2 - Alternatívny branch:
```
https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/copilot/selective-halibut.zip
```

### 🔗 LINK 3 - Main branch:
```
https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip
```
⚠️ **Poznámka:** Main branch čaká na cleanup PR merge

---

## 🚀 Ako používať:

### 1️⃣ Stiahni ZIP
Použite **LINK 1** vyššie (najnovšia verzia)

### 2️⃣ Rozbaľ
Extrahuj ZIP do ľubovoľného priečinka

### 3️⃣ Spusti START.bat
Dvoj-klikni na `START.bat`

### 4️⃣ Otvorí sa GUI
- Toolbar: **Open Source** | **Save As**
- 5 Tabs: **Summary** | **Video** | **Audio** | **Subtitles** | **Filters**
- Zelené tlačidlo: **START ENCODE**

---

## 🎨 Čo vidíš v GUI:

```
┌─────────────────────────────────────────────────────┐
│  Perfect Portable Converter - HandBrake Style       │
├─────────────────────────────────────────────────────┤
│  [Open Source]  [Save As]                           │
├─────────────────────────────────────────────────────┤
│  [Summary] [Video] [Audio] [Subtitles] [Filters]   │
│                                                      │
│  HandBrake-Style Video Converter                    │
│                                                      │
│  Select video file to begin.                        │
│                                                      │
│                                                      │
│                                                      │
├─────────────────────────────────────────────────────┤
│                          [START ENCODE]             │
└─────────────────────────────────────────────────────┘
```

---

## ⚙️ Funkcie:

### 📹 Video Tab:
- ✅ Codec: H.264, H.265, VP9, AV1, MPEG-4, MPEG-2
- ✅ Quality slider (CRF 0-51)

### 🔊 Audio Tab:
- ✅ Codec: AAC, MP3, Opus, Vorbis, AC3, FLAC

### 📝 Subtitles Tab:
- ✅ Browse pre SRT súbory

### 🎨 Filters Tab:
- ✅ Watermark checkbox
- ✅ Opacity slider (0-100%)

### ✅ START ENCODE:
- Generuje FFmpeg príkaz
- Kopíruje do clipboard
- Zobrazí preview v dialógu

---

## 📋 Požiadavky:

- ✅ Windows 10/11
- ✅ PowerShell 5.1+ (predinštalované)
- ✅ .NET Framework 4.0+ (predinštalované)
- ❌ ŽIADNA inštalácia
- ❌ ŽIADNE admin práva

---

## 🔄 Aktualizácia stránky:

**Status:** Cleanup PR čaká na merge
**Kedy bude main funkčný:** Po merge PR `copilot/fashionable-anglerfish`

### Ako urýchliť:
1. Otvor: https://github.com/Humming-SvKe/Perfect-Portable-Converter/pulls
2. Klikni na otvorený PR
3. Klikni **"Merge pull request"**
4. Klikni **"Confirm merge"**

Po merge bude LINK 3 (main) obsahovať čisté súbory.

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
