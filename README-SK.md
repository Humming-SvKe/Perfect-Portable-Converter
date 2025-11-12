# 🎬 Professional Portable Converter

Kompletný video konvertor s podporou vodoznakov, titulkov a pokročilých funkcií.

---

## 🚀 Prvé spustenie

### Varianta A: Automatická inštalácia
1. Spusti **CLEANUP-OLD-FILES.bat** (iba prvýkrát)
2. Spusti **START.bat**

### Varianta B: Test diagnostika
Ak START.bat nefunguje:
1. Spusti **TEST-GUI.bat**
2. Skontroluj chybové hlášky

---

## 📋 Čo GUI umožňuje?

### ✅ Toolbar funkcie
- **+ Add Files** - Pridaj video súbory (MP4, MKV, AVI, MOV...)
- **Remove** - Vymaž vybrané súbory zo zoznamu
- **Clear All** - Vymaž všetky súbory
- **Watermark** - Pridaj vodoznak (PNG, JPG)
- **Subtitle** - Pridaj titulky (SRT, ASS)
- **Crop** - Orež video

### ✅ Nastavenia konverzie
- **Output Format**: MP4, MKV, AVI, MOV, WMV
- **Quality**: Fast, Balanced, High Quality, Best Quality
- **Resolution**: Source, 1080p, 720p, 480p
- **Output Folder**: Kam sa uložia konvertované súbory

### ✅ Drag & Drop
Jednoducho potiahni video súbory do okna!

---

## 📁 Štruktúra súborov

```
Perfect-Portable-Converter/
├── PPC-GUI-Complete.ps1      ← Hlavný GUI (AKTUÁLNY)
├── START.bat                  ← Spúšťač s auto-cleanup
├── TEST-GUI.bat               ← Diagnostický test
├── CLEANUP-OLD-FILES.bat      ← Vymaž staré verzie
├── FIX-START-BAT.md          ← Návod na riešenie problémov
├── input/                     ← Vstupné video súbory
├── output/                    ← Výstupné konvertované súbory
├── overlays/                  ← Vodoznaky (PNG/JPG)
├── subtitles/                 ← Titulky (SRT/ASS)
└── config/
    └── defaults.json          ← Predvolené nastavenia
```

---

## 🔧 Riešenie problémov

### "START.bat sa otvorí a zavrie"
```
1. Spusti CLEANUP-OLD-FILES.bat
2. Potom spusti START.bat znova
```

### "Add Files nefunguje"
```
1. Spusti TEST-GUI.bat
2. Pošli screenshot s chybou
```

### "PowerShell chyba"
```
START.bat automaticky používa -ExecutionPolicy Bypass
Ak to zlyhá, spusti ako Administrátor
```

### "Vnorené priečinky"
Ak vidíš:
```
C:\vcs\Perfect-Portable-Converter-main\Perfect-Portable-Converter-main\
```
→ Rozbalil si ZIP nesprávne. Stiahni znova a rozbaľ iba raz.

---

## 📞 Potrebuješ pomoc?

1. Spusti **TEST-GUI.bat**
2. Urob screenshot chybovej hlášky
3. Spusti: `dir *.ps1` a pošli výstup
4. Otvor **FIX-START-BAT.md** pre podrobný návod

---

## 🎯 Podporované formáty

### Vstupné
MP4, MKV, AVI, MOV, WMV, FLV, WEBM, M4V

### Výstupné
- **MP4** - H264 (Fast/Balanced/High/Best)
- **MKV** - H265 (High Quality)
- **AVI** - MPEG4 (Compatible)
- **MOV** - QuickTime
- **WMV** - Windows Media

### Vodoznaky
PNG, JPG (s priehľadnosťou)

### Titulky
SRT, ASS, SSA

---

## 📝 Poznámky

- **PPC-GUI-Complete.ps1** je jediná aktuálna verzia
- Staré verzie (Modern, Ultimate, Final) sú zastarané
- START.bat automaticky vymaže staré verzie pri spustení
- GUI má 550+ riadkov kódu s plnou funkčnosťou

---

**Verzia:** Complete (Apowersoft-style)  
**Aktualizované:** Po cleanup starých verzií  
**Status:** ✅ GUI hotové | ⏳ Konverzný engine (v príprave)
