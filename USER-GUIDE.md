# Perfect Portable Converter - Užívateľská Príručka

## Obsah
1. [Úvod](#úvod)
2. [Inštalácia a Nastavenie](#inštalácia-a-nastavenie)
3. [Základné Použitie](#základné-použitie)
4. [Pokročilé Funkcie](#pokročilé-funkcie)
5. [Profily a Nastavenia](#profily-a-nastavenia)
6. [Riešenie Problémov](#riešenie-problémov)
7. [FAQ](#faq)

## Úvod

Perfect Portable Converter (PPC) je profesionálny nástroj na spracovanie videa, ktorý nevyžaduje inštaláciu a môže pracovať kompletne offline. Aplikácia poskytuje dva režimy práce:

- **GUI** (Grafické rozhranie) - Intuitívne tabuľkové rozhranie
- **CLI** (Príkazový riadok) - Pokročilé interaktívne menu

## Inštalácia a Nastavenie

### Prvé Spustenie

1. **Rozbaľte archív** na ľubovoľné miesto (napr. `C:\PPC`)
2. **Spustite START.bat**
   - Automaticky otvorí GUI verziu
   - Pre CLI použite: `START.bat /CLI`
3. **Prvé spustenie** automaticky stiahne FFmpeg (vyžaduje internet)
4. **Po stiahnutí** aplikácia funguje úplne offline

### Overenie Inštalácie

1. Skontrolujte priečinok `binaries/`
2. Mali by sa tam nachádzať:
   - `ffmpeg.exe`
   - `ffprobe.exe`
3. V GUI prejdite na tabuľku "Info & Settings"
4. Skontrolujte status FFmpeg

## Základné Použitie

### Batch Konverzia (Najčastejšie použitie)

#### GUI Verzia

1. **Otvorte GUI** (START.bat)
2. **Prejdite na tabuľku "Batch Convert"**
3. **Pridajte súbory**:
   - Kliknite "Add Files"
   - Vyberte jedno alebo viacero videí
   - Súbory sa zobrazia v zozname
4. **Vyberte profil**:
   - V rozbaľovacom menu "Profile" vyberte vhodný profil
   - Napríklad: "Fast 1080p H264" pre rýchlu konverziu
5. **Nastavte výstupný priečinok** (voliteľné):
   - Kliknite "Change Output..."
   - Vyberte priečinok (predvolený je `output/`)
6. **Spustite konverziu**:
   - Kliknite "Start Conversion"
   - Sledujte pokrok v progress bare
   - Logy sa zobrazujú v dolnom poli

#### CLI Verzia

1. **Spustite CLI** (`START.bat /CLI`)
2. **Umiestnite súbory** do priečinka `input/`
3. **V menu vyberte [1] Batch Convert Videos**
4. **Vyberte profil** zadaním čísla (napr. `0` pre prvý profil)
5. **Počkajte** na dokončenie spracovania
6. **Výstup** nájdete v priečinku `output/`

### Rýchle Príklady

#### Príklad 1: Zmenšiť Video pre WhatsApp
```
1. Pridať video do GUI
2. Vybrať profil "Device WhatsApp H264"
3. Spustiť konverziu
→ Video bude škálované na 720p, max 3 minúty
```

#### Príklad 2: Konvertovať pre YouTube
```
1. Pridať video
2. Vybrať "YouTube 1080p" alebo "YouTube 4K"
3. Spustiť
→ Optimálne nastavenia pre YouTube
```

#### Príklad 3: Minimálna Veľkosť Súboru
```
1. Pridať video
2. Vybrať "Small Size H265"
3. Spustiť
→ Najmenšia veľkosť s prijateľnou kvalitou
```

## Pokročilé Funkcie

### 1. MKV Manager

MKV súbory často obsahujú viacero audio stôp, titulkov a video stôp. PPC umožňuje ich jednoduché spracovanie.

#### Extrakcia Stôp

**GUI:**
1. Tabuľka "MKV Tools"
2. Browse → Vyberte MKV súbor
3. Zaškrtnite čo extrahovať:
   - ☐ Extract Video
   - ☑ Extract Audio
   - ☑ Extract Subtitles
4. Kliknite "Extract Tracks"
5. Výstup: `output/extracted/`

**CLI:**
1. Menu [3] MKV Manager
2. [1] Extract tracks from MKV
3. Vyberte súbor z `input/`
4. Vyberte typ: A(udio), V(ideo), S(ubtitles), All

**Výsledok:**
```
output/extracted/
├── myfilm.audio0.eng.aac
├── myfilm.audio1.cze.aac
├── myfilm.sub0.eng.srt
├── myfilm.sub1.cze.srt
└── myfilm.video.h264.mkv
```

#### Zlučovanie Stôp

**Postup:**
1. Umiestnite súbory do `input/`
   - video.mkv
   - audio_cze.aac
   - subtitles.srt
2. CLI: Menu [3] → [2] Merge tracks
3. Alebo použite príkaz FFmpeg

### 2. Vodoznaky

#### Obrázok ako Vodoznak

**Príprava:**
1. Pripravte PNG alebo JPG obrázok
2. Odporúčaná veľkosť: max 200x200 px
3. Umiestnite do `overlays/`

**GUI Postup:**
1. Tabuľka "Watermark"
2. Vyberte "Image Watermark"
3. Input Video: Vyberte video súbor
4. Watermark Image: Vyberte logo z `overlays/`
5. Position: topleft, topright, bottomleft, bottomright, center
6. Opacity: 0-100 (70 je vhodné)
7. Kliknite "Apply Watermark"

**CLI Postup:**
1. Menu [4] Watermark Tool
2. [1] Add image watermark
3. Vyberte video
4. Vyberte obrázok z `overlays/`
5. Zadajte pozíciu a opacity

**Pozície:**
- `topleft` - Ľavý horný roh
- `topright` - Pravý horný roh
- `bottomleft` - Ľavý dolný roh
- `bottomright` - Pravý dolný roh (najčastejšie)
- `center` - Stred

#### Text ako Vodoznak

**GUI Postup:**
1. Tabuľka "Watermark"
2. Vyberte "Text Watermark"
3. Input Video: Vyberte video
4. Watermark Text: Zadajte text (napr. "© 2024 Moje Meno")
5. Font Size: 24-48 (podľa videa)
6. Color: white, black, red, atď.
7. Position: Vyberte umiestnenie
8. Opacity: 0-100
9. Kliknite "Apply Watermark"

**Tipy:**
- Pre tmavé video: biely text
- Pre svetlé video: čierny text
- Opacity 70-80% pre jemný efekt
- Väčšie písmo pre 4K video

### 3. Titulky

#### Vypálenie Titulkov do Videa

Vypálené titulky sú trvalo súčasťou videa (nie je možné ich vypnúť).

**GUI Postup:**
1. Tabuľka "Subtitles"
2. Input Video: Vyberte video
3. Subtitle File: Vyberte SRT/ASS/VTT z `subtitles/`
4. Kliknite "Burn Subtitles"

**CLI Postup:**
1. Menu [5] Subtitle Tool
2. [1] Burn subtitles into video
3. Vyberte video a titulky
4. Počkajte na spracovanie

**Podporované Formáty:**
- SRT (SubRip) - Najčastejší
- ASS/SSA (Advanced SubStation) - Pokročilé
- VTT (WebVTT) - Webový

#### Konverzia Formátov Titulkov

**Použitie:**
1. CLI: Menu [5] → [2] Convert subtitle format
2. Vyberte titulky z `subtitles/`
3. Zadajte formát: srt, ass, vtt
4. Výstup: `output/`

**Prečo konvertovať:**
- SRT: Univerzálna podpora
- ASS: Pokročilé formátovanie, farby
- VTT: Pre webové prehrávače

### 4. Video Nástroje

#### Strihanie (Trim/Cut)

**Použitie - GUI:**
1. Tabuľka "Video Tools"
2. Sekcia "Trim/Cut Video"
3. Input Video: Vyberte video
4. Start (sec): Začiatočná pozícia (napr. 30 = začať od 30. sekundy)
5. Duration (0=all): Trvanie (0 = do konca, alebo napr. 60 = 60 sekúnd)
6. Kliknite "Trim Video"

**Použitie - CLI:**
1. Menu [6] Video Tools
2. [1] Trim/Cut video
3. Vyberte video
4. Zadajte start a duration

**Príklady:**
- Vystrihnutie úvodu: Start=10, Duration=0 (odstráni prvých 10s)
- Vystrihnutie časti: Start=30, Duration=60 (30s až 90s)
- Vystrihnutie konca: Start=0, Duration=300 (prvých 5 minút)

#### Spájanie Videí (Concatenate)

**Postup:**
1. Umiestnite všetky videá do `input/`
2. Premenujte na číselné poradie:
   - `01_intro.mp4`
   - `02_main.mp4`
   - `03_outro.mp4`
3. CLI: Menu [6] → [2] Concatenate videos
4. Výstup: `output/concatenated.mp4`

**Poznámka:**
- Videá musia mať rovnaký kodek a rozlíšenie
- Ak nie, najprv ich prekonvertujte na rovnaký profil

#### Generovanie Náhľadov (Thumbnail)

**GUI Postup:**
1. Tabuľka "Video Tools"
2. Sekcia "Generate Thumbnail"
3. Input Video: Vyberte video
4. Time (sec): Pozícia v sekundách (napr. 5 = 5. sekunda)
5. Kliknite "Generate"
6. Výstup: `thumbnails/`

**CLI Postup:**
1. Menu [6] → [3] Generate thumbnail
2. Vyberte video
3. Zadajte čas v sekundách
4. Náhľad sa uloží do `thumbnails/`

**Tipy:**
- Pre akčný film: 10-20% dĺžky
- Pre dokumenty: 5-10 sekúnd
- Skúste viacero pozícií pre najlepší výsledok

### 5. Hardvérová Akcelerácia

Hardvérová akcelerácia výrazne zrýchľuje konverziu (5-10x).

#### Overenie Podpory

**GUI:**
1. Tabuľka "Info & Settings"
2. Kliknite "Refresh Hardware Info"
3. Skontrolujte dostupnosť:
   - NVIDIA NVENC
   - Intel Quick Sync
   - AMD AMF

**CLI:**
1. Menu [7] Hardware Acceleration Info
2. Zobrazí sa status každej technológie

#### Použitie HW Profilov

**NVIDIA Grafické Karty:**
- "NVIDIA H264 Fast"
- "NVIDIA H265 Fast"
- Vyžaduje: GeForce GTX 600+ alebo novšie

**Intel Procesory:**
- "Intel QSV H264"
- "Intel QSV H265"
- Vyžaduje: Intel HD Graphics, 4. gen+

**AMD Grafické Karty:**
- "AMD AMF H264"
- Vyžaduje: Radeon HD 7000+

**Výhody:**
- 5-10x rýchlejšie
- Nižšia záťaž CPU
- Vhodné pre 4K video

**Nevýhody:**
- Mierne nižšia kvalita ako software
- Menej nastavení
- Závisí od HW

### 6. Informácie o Videu

**Zobrazenie Info:**
1. CLI: Menu [2] Video Information
2. Vyberte video z `input/`
3. Zobrazí sa:
   - Formát a kontajner
   - Trvanie a veľkosť
   - Video kodek, rozlíšenie, FPS
   - Audio stopy (kodek, kanály, jazyk)
   - Titulkové stopy (kodek, jazyk)

**Využitie:**
- Overenie pred konverziou
- Zistenie audio/titulkových stôp
- Kontrola parametrov

## Profily a Nastavenia

### Vysvetlenie Profilov

#### Univerzálne

**Fast 1080p H264**
- Kodek: H.264
- Rozlíšenie: 1920x1080
- Rýchlosť: Veľmi rýchla
- Kvalita: Dobrá
- Použitie: Všeobecná konverzia

**Small 720p H264**
- Kodek: H.264
- Rozlíšenie: 1280x720
- Rýchlosť: Veľmi rýchla
- Kvalita: Dobrá
- Použitie: Menšie súbory, mobily

**High Quality 1080p H265**
- Kodek: H.265 (HEVC)
- Rozlíšenie: 1920x1080
- Rýchlosť: Stredná
- Kvalita: Vysoká
- Použitie: Kvalitné video, menší súbor

**Ultra 4K H265**
- Kodek: H.265
- Rozlíšenie: 3840x2160
- Rýchlosť: Pomalá
- Kvalita: Ultra vysoká
- Použitie: 4K televízory

#### Platformy a Zariadenia

**YouTube 1080p / 4K**
- Optimalizované pre YouTube upload
- Vysoká kvalita, dobré bitrate
- H.264 pre kompatibilitu

**iPhone/iPad**
- Profil: High, Level 4.1
- AAC audio
- Plná kompatibilita s iOS

**Android Phone**
- 720p pre úsporu priestoru
- Široká kompatibilita

**Device WhatsApp H264**
- Max 720p
- Max 180 sekúnd (3 min)
- Optimalizované pre WhatsApp

**Web VP9 1080p**
- VP9 kodek
- Opus audio
- Ideálne pre webové prehrávače

#### Špeciálne Účely

**Archive High Quality**
- H.265 + FLAC audio
- Bezstratové audio
- Najvyššia kvalita
- MKV kontajner
- Použitie: Archivácia originálov

**Small Size H265**
- Maximálna kompresia
- H.265, CRF 28
- 720p
- Použitie: Úspora miesta

**Audio Only**
- Len audio, bez videa
- AAC 192 kbps
- M4A formát
- Použitie: Extrakcia hudby/podcatstov

### Parametre Profilov

#### CRF (Constant Rate Factor)
- **18-20**: Veľmi vysoká kvalita, veľké súbory
- **21-23**: Vysoká kvalita (odporúčané)
- **24-26**: Dobrá kvalita, menšie súbory
- **27-30**: Nižšia kvalita, malé súbory

#### Preset (Rýchlosť vs Kvalita)
- **veryslow**: Najlepšia kvalita, veľmi pomalé
- **slow**: Vysoká kvalita, pomalé
- **medium**: Vyvážené
- **fast**: Rýchle, dobrá kvalita
- **veryfast**: Veľmi rýchle, primeraná kvalita
- **ultrafast**: Najrýchlejšie, nižšia kvalita

#### Audio Bitrate
- **96k**: Reč, podcasty
- **128k**: Dostatočné pre väčšinu
- **160k-192k**: Vysoká kvalita
- **256k+**: Premium kvalita

### Vytvorenie Vlastného Profilu

1. **Otvorte** `config/defaults.json` v textovom editore
2. **Pridajte** nový profil do `profiles` poľa:

```json
{
  "name": "Môj Vlastný Profil",
  "vcodec": "libx264",
  "preset": "medium",
  "crf": 23,
  "acodec": "aac",
  "ab": "160k",
  "scale": "1920:-2",
  "format": "mp4",
  "deinterlace": false,
  "denoise": false
}
```

3. **Uložte** súbor
4. **Reštartujte** PPC
5. **Nový profil** sa zobrazí v zozname

#### Parametre Profilu

| Parameter | Popis | Príklady |
|-----------|-------|----------|
| `name` | Názov profilu | "Môj Profil" |
| `vcodec` | Video kodek | libx264, libx265, libvpx-vp9 |
| `preset` | Rýchlosť kódovania | ultrafast, fast, medium, slow |
| `crf` | Kvalita (nižšie=lepšie) | 18-28 |
| `acodec` | Audio kodek | aac, mp3, libopus |
| `ab` | Audio bitrate | "128k", "192k" |
| `scale` | Rozlíšenie | "1920:-2", "1280:-2" |
| `format` | Výstupný formát | mp4, mkv, webm |
| `vb` | Video bitrate (pre HW) | "5M", "10M" |
| `maxdur` | Max trvanie (sek) | 180 |
| `deinterlace` | Deinterlacing | true/false |
| `denoise` | Redukcia šumu | true/false |

## Riešenie Problémov

### FFmpeg sa Nenašiel

**Symptóm:** Chyba pri spustení - "FFmpeg missing"

**Riešenie:**
1. Pripojte sa na internet
2. Reštartujte aplikáciu
3. FFmpeg sa automaticky stiahne
4. Alebo manuálne:
   - Stiahnite FFmpeg z https://ffmpeg.org/download.html
   - Rozbaľte `ffmpeg.exe` a `ffprobe.exe`
   - Umiestnite do priečinka `binaries/`

### Hardvérová Akcelerácia Nefunguje

**Symptóm:** HW profily nefungujú alebo sú pomalé

**Riešenie:**
1. **Aktualizujte ovládače** grafickej karty
2. **Overte podporu**:
   - CLI: Menu [7] Hardware Info
   - GUI: Info & Settings → Refresh
3. **Skúste software profily** ak HW nie je dostupný

**NVIDIA:**
- Vyžaduje GeForce GTX 600+ (Kepler) alebo novší
- Aktualizujte na najnovšie ovládače
- Niektoré notebooky majú vypnuté NVENC

**Intel:**
- Vyžaduje Intel HD Graphics (4. generácia+)
- Zapnite iGPU v BIOS
- Nainštalujte Intel Graphics ovládače

**AMD:**
- Vyžaduje Radeon HD 7000+ (GCN)
- Nainštalujte najnovšie AMD ovládače

### Video sa Nekonvertuje

**Symptóm:** Konverzia zlyhá, chybové hlásenie

**Riešenie:**
1. **Skontrolujte logy**:
   - `logs/ffmpeg.log` - Detailné FFmpeg výstupy
   - `logs/ppc.log` - Aplikačné logy
2. **Overte vstupný súbor**:
   - CLI: Menu [2] Video Information
   - Skontrolujte, či sa súbor dá prehrať
3. **Skúste iný profil**:
   - Začnite s "Fast 1080p H264"
4. **Spustite REPORT.bat**:
   - Vygeneruje diagnostický report
   - Nájdete v `logs/REPORT-*.txt`

### Nízka Kvalita Výstupu

**Symptóm:** Video je rozmazané, bloky, artefakty

**Riešenie:**
1. **Použite kvalitnejší profil**:
   - "High Quality 1080p H265"
   - "Archive High Quality"
2. **Znížte CRF** (v custom profile):
   - CRF 18-21 = vysoká kvalita
3. **Zmeňte preset** na slow/slower:
   - Lepšia kvalita, pomalšie
4. **Nekonvertujte viacnásobne**:
   - Každá konverzia znižuje kvalitu
   - Pracujte vždy s originálom

### Veľké Výstupné Súbory

**Symptóm:** Výstup je väčší ako vstup

**Riešenie:**
1. **Použite H.265 profil**:
   - "High Quality 1080p H265"
   - "Small Size H265"
2. **Zvýšte CRF** (custom profile):
   - CRF 24-26 = menšie súbory
3. **Znížte rozlíšenie**:
   - 720p namiesto 1080p
4. **Optimalizujte audio**:
   - AAC 128k namiesto 192k

### Pomalá Konverzia

**Symptóm:** Konverzia trvá veľmi dlho

**Riešenie:**
1. **Použite HW akceleráciu**:
   - Profily s NVENC/QSV/AMF
2. **Rýchlejší preset**:
   - "veryfast" namiesto "medium"
3. **Znížte rozlíšenie**:
   - 720p je rýchlejšie ako 1080p
4. **H.264 namiesto H.265**:
   - H.265 je pomalší
5. **Zatvorte iné aplikácie**:
   - Uvoľnite CPU a RAM

### Titulky sa Nezobrazujú

**Symptóm:** Vypálené titulky nie sú viditeľné

**Riešenie:**
1. **Overte cestu k titulkom**:
   - Nesmú obsahovať špeciálne znaky
   - Použite anglické názvy
2. **Skontrolujte formát**:
   - SRT je najkompatibilnejší
3. **Skúste iný profil**:
   - Software profily (nie HW)
4. **Overte kódovanie titulkov**:
   - UTF-8 je optimálne

### Aplikácia Padá/Zamrzne

**Symptóm:** PPC sa neočakávane zavrie

**Riešenie:**
1. **Spustite ako admin** (pravý klik → Spustiť ako správca)
2. **Skontrolujte miesto na disku**:
   - Video spracovanie vyžaduje voľné miesto
3. **Zavrite iné aplikácie**:
   - Najmä iné video editory
4. **Vytvorte diagnostický report**:
   ```
   REPORT.bat
   ```
5. **Skontrolujte logy**:
   - `logs/ppc.log`
   - Hľadajte ERROR a FAIL správy

## FAQ

### Všeobecné

**Q: Je PPC zadarmo?**
A: Áno, je open-source a zadarmo.

**Q: Potrebujem internet?**
A: Len raz pri prvom spustení na stiahnutie FFmpeg. Potom funguje offline.

**Q: Koľko miesta potrebujem?**
A: ~200 MB pre aplikáciu + miesto na video súbory.

**Q: Podporuje PPC všetky formáty?**
A: Podporuje najčastejšie: MP4, MKV, AVI, MOV, WebM, FLV, WMV.

**Q: Môžem použiť na Mac/Linux?**
A: PPC je primárne pre Windows. Na Mac/Linux použite FFmpeg priamo.

### Konverzia

**Q: Ktorý profil je najlepší?**
A: Závisí od účelu:
- Všeobecne: "Fast 1080p H264"
- Kvalita: "High Quality 1080p H265"
- Veľkosť: "Small Size H265"
- YouTube: "YouTube 1080p"

**Q: Stratím kvalitu pri konverzii?**
A: Áno, mierne. Použite CRF 18-23 pre minimálnu stratu.

**Q: Môžem konvertovať 4K video?**
A: Áno, použite profil "Ultra 4K H265" alebo vlastný.

**Q: Aký je rozdiel medzi H.264 a H.265?**
A:
- H.264: Širšia kompatibilita, rýchlejšie
- H.265: Lepšia kompresia, menšie súbory, pomalšie

**Q: Prečo trvá konverzia tak dlho?**
A: Závisí od:
- Dĺžky videa
- Rozlíšenia (4K vs 720p)
- Profilu (preset slow vs veryfast)
- Hardware (CPU, GPU)
Použite HW akceleráciu pre zrýchlenie.

### Hardvér

**Q: Ako zistím, či mám NVIDIA NVENC?**
A: CLI Menu [7] alebo GPU-Z aplikácia. GeForce GTX 600+ má NVENC.

**Q: Je HW akcelerácia lepšia?**
A: Výhody: 5-10x rýchlejšie
Nevýhody: Mierne nižšia kvalita
Použite: Pre 4K, dlhé videá, časová tieseň

**Q: Môžem použiť GPU a CPU súčasne?**
A: FFmpeg typicky používa jedno alebo druhé. HW profily = GPU, ostatné = CPU.

### Pokročilé

**Q: Ako pridať vlastný profil?**
A: Upravte `config/defaults.json` - viď sekciu "Vytvorenie Vlastného Profilu".

**Q: Môžem dávkovo spracovať stovky videí?**
A: Áno, pridajte všetky do Batch Convert. PPC ich spracuje sekvenčne.

**Q: Podporuje PPC 2-pass encoding?**
A: Nie priamo v GUI/CLI. Môžete použiť FFmpeg priamo s custom skriptami.

**Q: Ako zmeniť výstupný priečinok?**
A: GUI: Kliknite "Change Output..."
CLI: Upravte `$Out` premennú v `PPC.ps1`

**Q: Môžem použiť PPC v batch skriptoch?**
A: Áno, PPC.ps1 je PowerShell skript. Môžete ho volať automatizovane.

### Problémy

**Q: Prečo sa HW profily nezobrazujú?**
A: Zobrazujú sa vždy, ale nefungujú ak nemáte kompatibilný HW.

**Q: Video má čierne okraje**
A: Vstup má iný aspect ratio. Použite `scale` parameter s crop filtrami.

**Q: Audio je nesynchronizované**
A: Skúste `-async 1` flag alebo rekonvertujte audio samostatne.

**Q: Výstup nemá audio**
A: Overte, že profil má nastavený `acodec`. Skontrolujte vstupný súbor.

**Q: Nemôžem prehrať výstupné video**
A: Použite profil s lepšou kompatibilitou (Fast 1080p H264).
Aktualizujte prehrávač (VLC, MPV).

---

## Kontakt a Podpora

- **GitHub**: [Issues](https://github.com/Humming-SvKe/Perfect-Portable-Converter/issues)
- **Dokumentácia**: README.md
- **Diagnostika**: Spustite `REPORT.bat`

**Pri hlásení problémov:**
1. Spustite `REPORT.bat`
2. Priložte `logs/REPORT-*.txt`
3. Opíšte kroky na reprodukciu
4. Uvedte verziu OS a HW

---

**Užite si Perfect Portable Converter!** 🎬✨
