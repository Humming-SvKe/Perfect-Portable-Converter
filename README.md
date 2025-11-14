# Perfect Portable Converter
## HandBrake Style GUI - Profesionálny Video Converter! 🎬

**Complete video converter s HandBrake interface - bez kompilácie!**

---

## 📥 **DOWNLOAD ZIP:**
### **https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip**

---

## 🚀 Rýchly štart:

1. **Stiahni ZIP** z GitHubu
2. **Rozbaľ** kamkoľvek na disk
3. **Spusti START.bat**
4. **HandBrake-style GUI** sa otvorí automaticky! ✅

### 💡 Interface:
- **Top Toolbar** - Open Source, Save As, Presets, Queue
- **Source/Destination** - Video vstup a výstup
- **Tabs** - Summary, Video, Audio, Subtitles, Filters (Watermark)
- **Preview Panel** - Info o súbore
- **START ENCODE** - Generate FFmpeg command

---

## 🎯 Funkcie - HandBrake Style Interface

### 🎬 **SUMMARY Tab**
- Prehľad všetkých nastavení
- Info o source/destination súboroch
- Format a codec summary

### 📹 **VIDEO Tab**
- **Codec**: H.264 (x264), H.265 (x265), VP9, AV1, MPEG-4, MPEG-2
- **Quality (CRF)**: Slider 0-51 (Very High → Balanced → Low)
- **Framerate**: Same as source, 23.976, 24, 25, 29.97, 30, 50, 59.94, 60 FPS
- **Resolution**: Same as source, 4K, 1080p, 720p, 480p

### 🔊 **AUDIO Tab**
- **Codec**: AAC, MP3, Opus, Vorbis, AC3, FLAC, Copy (no re-encode)
- **Bitrate**: 64-320 kbps
- **Sample Rate**: Same as source, 48000, 44100, 32000, 22050 Hz

### 📝 **SUBTITLES Tab**
- **Import**: SRT, ASS, SSA, VTT files
- **Font Size**: 12-72 px
- **Burn-in**: Vloženie titulkov do videa

### 🎨 **FILTERS Tab (Watermark)**

#### 🖼️ Image Watermark:
- **Browse**: Výber PNG, JPG, GIF
- **Position**: 9 presets + Custom X/Y
- **Opacity**: 0-100% slider

#### ✏️ Text Watermark:
- **Text Entry**: Custom text (napr. "Copyright © 2025")
- **Font Size**: 12-144 px
- **Position**: 9 presets + Custom X/Y
- **Opacity**: 0-100% slider
  - Middle Left, Middle Center, Middle Right
  - Bottom Left, Bottom Center, Bottom Right (default)
- **Custom X/Y**: Presné súradnice (Location: 320, 180)
- **Use Percentage**: Percentuálne hodnoty (0-100%)
- **Drag & Drop Canvas**: Interaktívny náhľad 640×360
  -視覚化 watermark pozície
  - Drag & drop na presné umiestnenie
  - Live preview s grid overlay
  - Zobrazenie aktuálnych súradníc
  - Červené handle body pre presné ovládanie

**5. Appearance Tab** - Vzhľad
- **Transparency**: Priehľadnosť 0-100% (slider)
- **Rotation**: Otáčanie -180° až +180°
- **Size**: Veľkosť watermarku (640 × 359)

#### Drag & Drop Features:
- **Visual Canvas**: 640×360 preview area s tmavým pozadím
- **Grid Overlay**: 40px mriežka pre presné zarovnanie
- **Watermark Indicator**: 
  - Modrý obdĺžnik pre obrázok s bielym rámikom
  - Žltý outline pre text
  - Červené handle body v rohoch
- **Real-time Positioning**: 
  - Klikni a ťahaj watermark
  - Live update súradníc
  - Clamp to bounds (nemôže vyjsť mimo canvas)
- **Coordinate Display**: "Position: X, Y | Size: W × H" v ľavom dolnom rohu

### Subtitle Style Editor
Nové rozhranie pre editovanie štýlu titulkov s nasledujúcimi možnosťami:

#### 1. **Font Tab** - Nastavenia písma
- **Font Family**: Výber typu písma (Arial, Times New Roman, atď.)
- **Font Size**: Veľkosť písma 12-255 pixelov (posuvník)
- **Bold**: Tučné písmo (checkbox)
- **Italic**: Kurzíva (checkbox)
- **Underline**: Podčiarknuté (checkbox)

#### 2. **Colors Tab** - Farby a priehľadnosť
- **Text Color**: Farba textu (RGB color picker)
- **Text Transparency**: Priehľadnosť textu 0-100% (slider)
- **Outline Color**: Farba obrysu (RGB color picker)
- **Outline Transparency**: Priehľadnosť obrysu (slider)
- **Shadow Color**: Farba tieňa (RGB color picker)
- **Shadow Transparency**: Priehľadnosť tieňa (slider)

#### 3. **Position Tab** - Presné umiestnenie
- **X Position**: Horizontálna pozícia 0-100% šírky obrazovky
- **Y Position**: Vertikálna pozícia 0-100% výšky obrazovky
- **Alignment**: 9 možností zarovnania (numpad layout):
  - 1 = Vľavo dole
  - 2 = V strede dole (default)
  - 3 = Vpravo dole
  - 4 = Vľavo v strede
  - 5 = Presne v strede
  - 6 = Vpravo v strede
  - 7 = Vľavo hore
  - 8 = V strede hore
  - 9 = Vpravo hore
- **Margins**: Okraje (Left, Right, Vertical) 0-100 pixelov

#### 4. **Preview** - Živý náhľad
- Okamžité zobrazenie zmien štýlu
- Real-time preview titulku s aktuálnymi nastaveniami

---

## 📦 Obsah balíka

### 🚀 Spustiteľné súbory:
- **START.bat** - Hlavný spúšťač (Windows)
- **PerfectConverter.ps1** - PowerShell GUI aplikácia

### 📚 Referenčné implementácie (C/GTK):
```
libhb/
  watermark_extended.h         - Header watermark API
  watermark_extended.c         - C implementácia
  subtitle_style_extended.h    - Header subtitle API
  subtitle_style_extended.c    - C implementácia
gtk/src/
  watermark_gui.c              - GTK GUI (Linux)
  subtitle_editor_gui.c        - GTK GUI (Linux)
examples/
  example_watermark_usage.c    - Príklady použitia C API
```

### 📖 Dokumentácia:
- **README.md** - Tento súbor
- **DOWNLOAD.md** - Download linky

---

## 💻 Systémové požiadavky

### Windows:
- Windows 7 / 8 / 10 / 11
- PowerShell 3.0+ (predinštalované)
- .NET Framework 4.0+ (predinštalované)

### Linux (GTK verzia):
- GTK+ 3.0
- GCC kompilátor
- Make

---

## 🎮 Použitie

### Windows - Jednoduchý spôsob:
```batch
1. Stiahnuť ZIP
2. Rozbaliť
3. Spustiť START.bat
4. Vybrať watermark/subtitle nastavenia
5. Kliknúť "Generate FFmpeg Command"
6. Skopírovať príkaz (automaticky v clipboard)
```

### Generovaný FFmpeg príkaz:
```bash
# Image watermark:
ffmpeg -i input.mp4 -i logo.png -filter_complex "[1:v]scale=100:50,format=rgba,colorchannelmixer=aa=0.7[wm];[0:v][wm]overlay=320:180" output.mp4

# Text watermark:
ffmpeg -i input.mp4 -vf "drawtext=text='K.jpg':fontsize=24:fontcolor=white@0.7:x=320:y=180:borderw=2:bordercolor=black" output.mp4
```

---

## 🔧 Technické detaily

### PowerShell GUI Features:
- Windows Forms (.NET)
- Real-time canvas preview
- Drag & drop positioning
- Grid overlay (40px)
- Visual handles
- Live coordinate display

### C/GTK Implementation:
- GTK+ 3.0 widgets
- Cairo graphics for canvas
- FFmpeg filter generation

### Watermark API

```c
// Vytvorenie nového watermarku
watermark_extended_t* watermark_create();

// Nastavenie obrázka
void watermark_set_image(watermark_extended_t *wm, const char *path);

// Nastavenie textu
void watermark_set_text(watermark_extended_t *wm, const char *text);

// Nastavenie pozície pomocou X/Y súradníc
void watermark_set_position_xy(watermark_extended_t *wm, int x, int y, int use_percentage);

// Nastavenie pozície pomocou presetu
void watermark_set_position_preset(watermark_extended_t *wm, watermark_position_preset_t preset);

// Konverzia do FFmpeg filter
char* watermark_to_ffmpeg_filter(watermark_extended_t *wm, int video_width, int video_height);

// Uvoľnenie pamäte
void watermark_free(watermark_extended_t *wm);
```

### Watermark Types

```c
typedef enum {
    WATERMARK_TYPE_NONE = 0,
    WATERMARK_TYPE_IMAGE,
    WATERMARK_TYPE_TEXT
} watermark_type_t;
```

### Position Presets

```c
typedef enum {
    WATERMARK_POSITION_CUSTOM = 0,
    WATERMARK_POSITION_TOP_LEFT,
    WATERMARK_POSITION_TOP_CENTER,
    WATERMARK_POSITION_TOP_RIGHT,
    WATERMARK_POSITION_MIDDLE_LEFT,
    WATERMARK_POSITION_MIDDLE_CENTER,
    WATERMARK_POSITION_MIDDLE_RIGHT,
    WATERMARK_POSITION_BOTTOM_LEFT,
    WATERMARK_POSITION_BOTTOM_CENTER,
    WATERMARK_POSITION_BOTTOM_RIGHT
} watermark_position_preset_t;
```

### FFmpeg Integration

Watermark editor generuje správne FFmpeg filtre:

**Image Watermark:**
```bash
movie=logo.png,scale=100:100,format=rgba,colorchannelmixer=aa=0.70[wm];[in][wm]overlay=320:180[out]
```

**Text Watermark:**
```bash
drawtext=text='K.jpg':fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:fontsize=24:fontcolor=0xFFFFFF@0.70:x=320:y=180:borderw=2:bordercolor=0x000000
```

### Integrácia s HandBrake

Rozšírený editor je plne kompatibilný s existujúcim HandBrake SSA/ASS subtitle systémom:

- **SSA Format**: Generuje správny SSA štýl string
- **Color Format**: Konverzia RGB ↔ BGR (SSA používa BGR)
- **Alpha Values**: Inverzia alpha (SSA: 0=opaque, 255=transparent)
- **Position**: Percentuálne hodnoty X/Y
- **Margins**: Podpora pixel-based margins

### API funkcie

```c
// Vytvorenie nového štýlu s default hodnotami
subtitle_style_extended_t* subtitle_style_create_default();

// Konverzia štýlu do SSA formátu
char* subtitle_style_to_ssa(subtitle_style_extended_t *style);

// Aplikovanie štýlu na existujúci SSA header
void subtitle_style_apply(subtitle_style_extended_t *style, const char *ssa_header);

// Uvoľnenie pamäte
void subtitle_style_free(subtitle_style_extended_t *style);
```

### GUI API

```c
// Vytvorenie editora
SubtitleEditorGUI* subtitle_editor_create();

// Zobrazenie okna
void subtitle_editor_show(SubtitleEditorGUI *editor);

// Zatvorenie a cleanup
void subtitle_editor_destroy(SubtitleEditorGUI *editor);
```

## Použitie

### V kóde
```c
#include "subtitle_style_extended.h"

// Vytvorenie nového štýlu
subtitle_style_extended_t *style = subtitle_style_create_default();

// Nastavenie vlastných hodnôt
style->font_size = 36;
style->primary_color = 0xFFFF00;  // Žltá
style->position_x = 50;            // Horizontálne v strede
style->position_y = 10;            // 10% od vrchu

// Konverzia do SSA
char *ssa_string = subtitle_style_to_ssa(style);
printf("%s\n", ssa_string);

// Cleanup
free(ssa_string);
subtitle_style_free(style);
```

### Príklad vygenerovaného SSA štýlu
```
Style: Extended,Arial,36,&H00FFFF00,&H0000FF00,&HFF000000,&H80000000,0,0,0,0,100,100,0,0.00,1,2,2,8,10,10,10,1
```

## Kompilácia

```bash
# Build libhb s rozšíreniami
cd libhb
gcc -c subtitle_style_extended.c -o subtitle_style_extended.o

# Build GTK GUI
cd ../gtk/src
gcc -c subtitle_editor_gui.c $(pkg-config --cflags gtk+-3.0) -o subtitle_editor_gui.o

# Link
gcc subtitle_style_extended.o subtitle_editor_gui.o $(pkg-config --libs gtk+-3.0) -o subtitle_editor
```

---

## 🎯 Príklady

### PowerShell GUI - Workflow:
1. Spusti `START.bat`
2. Vyber záložku **"Watermark Type"** → Image/Text
3. Nastav parametre (file/text, veľkosť, farbu)
4. Choď na **"Position"** → Drag watermark na canvas
5. Nastav **"Appearance"** → Transparency slider
6. Klikni **"Generate FFmpeg Command"**
7. Príkaz sa skopíruje do clipboard

### C API - Image Watermark:
```c
#include "watermark_extended.h"

watermark_extended_t *wm = watermark_create();

// Nastavenie obrázka
watermark_set_image(wm, "/path/to/logo.png");
wm->image_width = 100;
wm->image_height = 100;

// Pozícia: Bottom Right s 10px marginom
watermark_set_position_preset(wm, WATERMARK_POSITION_BOTTOM_RIGHT);
wm->margin_x = 10;
wm->margin_y = 10;

// Priehľadnosť 70%
wm->opacity = 70;

// Generovanie FFmpeg filtra
char *filter = watermark_to_ffmpeg_filter(wm, 1920, 1080);
printf("Filter: %s\n", filter);

// Cleanup
free(filter);
watermark_free(wm);
```

### Text Watermark
```c
watermark_extended_t *wm = watermark_create();

// Nastavenie textu
watermark_set_text(wm, "© 2025 Company");
wm->font_size = 24;
wm->text_color = 0xFFFFFF;  // White
wm->text_bold = 1;

// Custom pozícia (percentá)
watermark_set_position_xy(wm, 50, 90, 1);  // 50% right, 90% down

// Outline
wm->outline_width = 2;
wm->outline_color = 0x000000;  // Black

char *filter = watermark_to_ffmpeg_filter(wm, 1920, 1080);
// Use filter with FFmpeg/HandBrake
```

---

## 🆘 Troubleshooting

### PowerShell script sa nespustí:
```powershell
# Povoliť PowerShell skripty (spusti ako Admin):
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### FFmpeg nie je nainštalovaný:
```bash
# Windows (Chocolatey):
choco install ffmpeg

# Linux:
sudo apt install ffmpeg

# Mac:
brew install ffmpeg
```

---

## 📝 Licencia

GPL v2 - Based on HandBrake project  
Extended GUI by Perfect Portable Converter

---

## 🔗 Links

- **Repository**: https://github.com/Humming-SvKe/Perfect-Portable-Converter
- **Download**: https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip
- **Issues**: https://github.com/Humming-SvKe/Perfect-Portable-Converter/issues

---

**✨ Version: 1.0 | Ready to Use | No Compilation Required!**
