# Perfect Portable Converter - Enhanced Edition

**Plne prenosný, offline nástroj na pokročilú konverziu a spracovanie videa**

## 📋 Prehľad

Perfect Portable Converter je komplexné riešenie na konverziu a spracovanie videa s pokročilými funkciami. Aplikácia je plne offline a portable - stačí rozbaliť a spustiť.

### 🎯 Hlavné Funkcie

- ✅ **Batch Konverzia** - Spracovanie viacerých súborov naraz
- ✅ **MKV Manager** - Extrakcia a zlučovanie audio/video/titulkových stôp
- ✅ **Vodoznaky** - Pridanie obrázku alebo textu ako vodoznaku
- ✅ **Titulky** - Vypálenie titulkov do videa, konverzia formátov
- ✅ **Video Nástroje** - Strihanie, spájanie, generovanie náhľadov
- ✅ **Hardvérová Akcelerácia** - Podpora NVIDIA NVENC, Intel Quick Sync, AMD AMF
- ✅ **25 Konverzných Profilov** - Pre rôzne účely a zariadenia (YouTube, Telegram, Instagram, Discord, WhatsApp)
- ✅ **8 Tém (Day/Night + Material)** - Classic, Modern, Professional, Material Dark, Material Blue skins
- ✅ **2-Pass Encoding** - Pre lepšiu kvalitu pri cieľovom bitrate
- ✅ **Pokročilé Filtre** - Brightness, contrast, denoise, sharpen, rotate
- ✅ **Audio Processing** - Volume, speed, normalization, bass/treble
- ✅ **File Size Tools** - Predictor a kalkulátor optimálneho bitrate
- ✅ **Plne Offline** - Žiadne internetové pripojenie nie je potrebné

## 🚀 Rýchly Štart

1. Rozbaľte archív
2. Spustite `START.bat`
3. Vyberte GUI alebo CLI režim
4. Pridajte súbory do `input` priečinku
5. Vyberte profil a spustite konverziu

## 📁 Štruktúra Priečinkov

```
Perfect-Portable-Converter/
├── PPC.ps1              # CLI verzia s pokročilým menu
├── PPC-GUI.ps1          # GUI verzia s tabuľkami
├── PPC-Core.ps1         # Základný modul s funkciami
├── PPC-Themes.ps1       # Theme manager modul
├── START.bat            # Spúšťač aplikácie
├── REPORT.bat           # Diagnostický nástroj
├── binaries/            # FFmpeg nástroje (auto-download)
├── config/
│   ├── defaults.json    # Konfigurácia a profily
│   └── themes.json      # Témy farieb
├── input/               # Vstupné video súbory
├── output/              # Výstupné súbory
├── subtitles/           # SRT, ASS, VTT titulky
├── overlays/            # Obrázky pre vodoznaky
├── thumbnails/          # Generované náhľady
└── logs/                # Logy aplikácie a FFmpeg
```

## 🎬 Funkcie

### 1. Batch Konverzia
- Spracovanie viacerých súborov súčasne
- Výber z 20+ vopred definovaných profilov
- Sledovanie pokroku a štatistiky
- Automatická optimalizácia veľkosti súboru

### 2. MKV Manager
- **Extrakcia stôp**: Získajte audio, video alebo titulky z MKV súborov
- **Zlučovanie**: Spojte viacero súborov do jedného MKV
- Zachovanie pôvodnej kvality (bez prekódovania)

### 3. Vodoznaky
#### Obrázok
- Pridajte PNG/JPG ako vodoznak
- Pozície: roh, stred, vlastná
- Nastaviteľná priehľadnosť

#### Text
- Vlastný text ako vodoznak
- Nastaviteľné písmo, veľkosť, farba
- Flexibilné umiestnenie

### 4. Titulky
- **Vypálenie**: Trvalo vpálte titulky do videa
- **Konverzia**: SRT ↔ ASS ↔ VTT
- Podpora viacerých jazykov

### 5. Video Nástroje
- **Strihanie**: Vystrihnite časť videa (start + trvanie)
- **Spájanie**: Spojte viacero videí do jedného
- **Náhľady**: Generujte JPG náhľady v určitom čase

### 6. Hardvérová Akcelerácia
Automatická detekcia a využitie:
- **NVIDIA NVENC** - H.264/H.265 kódovanie
- **Intel Quick Sync** - Rýchle spracovanie
- **AMD AMF** - AMD grafické karty

## 📊 Konverzné Profily

### Kvalita a Účel
| Profil | Codec | Rozlíšenie | Účel |
|--------|-------|------------|------|
| Fast 1080p H264 | H.264 | 1920x1080 | Rýchla konverzia |
| Small 720p H264 | H.264 | 1280x720 | Malá veľkosť |
| High Quality 1080p H265 | H.265 | 1920x1080 | Vysoká kvalita |
| Ultra 4K H265 | H.265 | 3840x2160 | 4K obsah |
| Archive High Quality | H.265 | Pôvodné | Archivácia |
| Small Size H265 | H.265 | 1280x720 | Minimálna veľkosť |

### Platformy
| Profil | Optimalizované pre |
|--------|-------------------|
| YouTube 1080p/4K | YouTube nahrávanie |
| iPhone/iPad | Apple zariadenia |
| Android Phone | Android telefóny |
| Device WhatsApp H264 | WhatsApp správy (max 3 min) |
| Telegram Free | Telegram (pod 2GB limit) |
| Telegram Premium | Telegram Premium (pod 4GB limit) |
| Instagram Story | Instagram Story (9:16, 15s, 4MB) |
| Instagram Post | Instagram Post (1:1, 60s, 100MB) |
| Instagram Reel | Instagram Reel (9:16, 90s, 100MB) |
| Discord Basic | Discord (8MB limit) |
| Discord Nitro | Discord Nitro (50MB limit) |
| Web VP9 1080p | Webové prehrávanie |

### Hardware Acceleration
| Profil | Technológia | Výkon |
|--------|------------|-------|
| NVIDIA H264/H265 Fast | NVENC | 5-10x rýchlejšie |
| Intel QSV H264/H265 | Quick Sync | 3-5x rýchlejšie |
| AMD AMF H264 | AMF | 3-5x rýchlejšie |

### Špeciálne
- **Audio Only** - Extrakcia len audio do M4A
- **Archive High Quality** - FLAC audio + H.265

## 🖥️ Rozhrania

### GUI (PPC-GUI.ps1)
- **Modernérozhranie s tabuľkami**
- Batch Convert - Hromadná konverzia
- MKV Tools - MKV spracovanie
- Watermark - Vodoznaky
- Subtitles - Titulky
- Video Tools - Nástroje
- Info & Settings - Informácie + výber témy

### CLI (PPC.ps1)
- **Interaktívne menu**
- Všetky funkcie dostupné cez klávesnicu
- Advanced Tools - 2-pass, filtre, audio processing
- Theme Settings - výber a zmena témy
- Ideálne pre pokročilých používateľov
- Podpora dávkových skriptov

## 🎨 Témy (Themes)

**6 farebných schém (3 skins × 2 režimy)**:

### Classic (Blue/Navy)
- **Day Mode** - Svetlé pozadie, modrý akcent
- **Night Mode** - Tmavé pozadie, cyan akcent

### Modern (Green/Teal)
- **Day Mode** - Svetlé pozadie, zelený akcent
- **Night Mode** - Tmavé pozadie, zeleno-cyan akcent

### Professional (Orange/Purple)
- **Day Mode** - Svetlé pozadie, oranžový akcent
- **Night Mode** - Tmavé pozadie, oranžovo-fialový akcent

**Zmena témy**:
- **CLI**: Menu položka [9] Theme Settings
- **GUI**: Info & Settings tab → Theme dropdown → Apply Theme button

## ⚙️ Technické Špecifikácie

### Podporované Formáty

#### Vstup
- Video: MP4, MKV, AVI, MOV, WebM, FLV, WMV
- Audio: MP3, AAC, FLAC, WAV, OGG
- Titulky: SRT, ASS, SSA, VTT

#### Výstup
- Video: MP4, MKV, WebM, M4V
- Audio: AAC, MP3, FLAC, Opus, M4A
- Titulky: SRT, ASS, VTT

### Video Kodeky
- H.264 (AVC) - Univerzálna kompatibilita
- H.265 (HEVC) - Lepšia kompresia
- VP9 - Webový štandard
- H.264_NVENC - NVIDIA hardvér
- H.264_QSV - Intel hardvér
- H.264_AMF - AMD hardvér

### Audio Kodeky
- AAC - Vysoká kvalita, malá veľkosť
- MP3 - Univerzálna podpora
- Opus - Najlepšia webová kvalita
- FLAC - Bezstratové

### Video Filtre
- Škálovanie (resize)
- Deinterlacing - Odstránenie prekladania
- Denoise - Redukcia šumu
- Sharpen - Doostření
- Rotate/Flip - Otáčanie

## 📝 Použitie

### Príklad 1: Základná Konverzia
1. Skopírujte video do `input/`
2. Spustite `START.bat`
3. Vyberte "Batch Convert"
4. Vyberte profil "Fast 1080p H264"
5. Kliknite "Start"

### Príklad 2: Pridanie Vodoznaku
1. Umiestnite video do `input/`
2. Umiestnite logo do `overlays/`
3. Otvorte tabuľku "Watermark"
4. Vyberte video a logo
5. Nastavte pozíciu a priehľadnosť
6. Kliknite "Apply"

### Príklad 3: Extrakcia Audio z MKV
1. Skopírujte MKV do `input/`
2. Otvorte "MKV Tools"
3. Vyberte súbor
4. Zaškrtnite "Extract Audio"
5. Kliknite "Extract Tracks"

### Príklad 4: Vypálenie Titulkov
1. Video do `input/`
2. SRT súbor do `subtitles/`
3. Otvorte "Subtitles"
4. Vyberte video a titulky
5. Kliknite "Burn Subtitles"

## 🔧 Pokročilé Nastavenia

### config/defaults.json
```json
{
  "default_format": "mp4",
  "hardware_acceleration": {
    "enabled": true,
    "prefer": "auto"
  },
  "profiles": [
    {
      "name": "Vlastný Profil",
      "vcodec": "libx264",
      "preset": "medium",
      "crf": 23,
      "acodec": "aac",
      "ab": "192k",
      "scale": "1920:-2",
      "format": "mp4"
    }
  ]
}
```

### Pridanie Vlastného Profilu
1. Otvorte `config/defaults.json`
2. Pridajte nový objekt do `profiles` poľa
3. Nastavte parametre
4. Reštartujte aplikáciu

## 🐛 Riešenie Problémov

### FFmpeg sa nenašiel
- Aplikácia automaticky stiahne FFmpeg pri prvom spustení
- Vyžaduje internetové pripojenie raz
- Alternatívne: Manuálne umiestnite `ffmpeg.exe` do `binaries/`

### Hardvérová akcelerácia nefunguje
- Skontrolujte ovládače grafickej karty
- Spustite "Hardware Acceleration Info" v CLI
- Použite software profily ak HW nie je dostupný

### Video sa nezobrazuje správne
- Skúste iný profil
- Overte vstupný súbor pomocou "Video Information"
- Skontrolujte `logs/ffmpeg.log` pre detaily

### Aplikácia padá
1. Spustite `REPORT.bat`
2. Odošlite `logs/REPORT-*.txt` vývojárom
3. Skontrolujte `logs/ppc.log` pre chybové hlásenia

## 📚 Dokumentácia FFmpeg

Pre pokročilých používateľov:
- [FFmpeg Oficiálna Dokumentácia](https://ffmpeg.org/documentation.html)
- [H.264 Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/H.264)
- [H.265 Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/H.265)

## 🔒 Bezpečnosť a Súkromie

- ✅ Plne offline operácia (po stiahnutí FFmpeg)
- ✅ Žiadne telemetrické dáta
- ✅ Všetky súbory zostávajú lokálne
- ✅ Žiadna registrácia alebo účet

## 📄 Licencia

Tento projekt je open-source. FFmpeg je licencovaný pod GPL/LGPL.

## 🤝 Prispievanie

Príspevky sú vítané! Prosím:
1. Fork repozitára
2. Vytvorte feature branch
3. Commit zmeny
4. Push do branch
5. Otvorte Pull Request

## 📞 Podpora

Pri problémoch:
1. Skontrolujte túto dokumentáciu
2. Spustite `REPORT.bat` pre diagnostiku
3. Otvorte issue na GitHub
4. Priložte log súbory

## 🌟 Vlastnosti

- **Offline First**: Funguje bez internetu
- **Portable**: Žiadna inštalácia potrebná
- **Výkonné**: Hardvérová akcelerácia
- **Flexibilné**: 20+ profilov
- **Jednoduché**: GUI aj CLI rozhranie
- **Profesionálne**: Pokročilé funkcie

---

**Perfect Portable Converter** - Všetko čo potrebujete pre spracovanie videa, v jednom portable balíku! 🎬✨
