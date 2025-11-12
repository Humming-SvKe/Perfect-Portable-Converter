# 🔧 START.bat sa nezapína - Riešenie

## Problém
START.bat otvára a zatvára čierne okno bez zobrazenia GUI.

## Príčina
Máš v priečinku **14 starých verzií PS1 súborov** z predošlého vývoja. Tieto súbory spôsobujú chaos a START.bat nemôže správne načítať GUI.

---

## ✅ RIEŠENIE - Čistá inštalácia

### Krok 1: Vymaž celý priečinok
```
C:\vcs\Perfect-Portable-Converter-main
```
(alebo akýkoľvek priečinok kde máš momentálne rozbalený projekt)

### Krok 2: Stiahni NOVÚ verziu z GitHubu
https://github.com/Humming-SvKe/Perfect-Portable-Converter

1. Klikni na zelené tlačidlo **Code**
2. Vyber **Download ZIP**
3. Rozbaľ do nového priečinka (napr. `C:\PPC-Clean`)

### Krok 3: Spusti cleanup (iba raz)
1. Otvor priečinok kde si rozbalil ZIP
2. Spusti súbor: **CLEANUP-OLD-FILES.bat**
3. Počkaj kým sa vymažú staré verzie

### Krok 4: Spusti GUI
1. Dvojklik na **START.bat**
2. Malo by sa otvoriť okno Professional Portable Converter

---

## 📋 Zoznam súborov na vymazanie

Ak nechceš stiahnuť novú verziu, môžeš manuálne vymazať:

- ❌ `PPC-GUI.ps1`
- ❌ `PPC-GUI-Modern.ps1` (a všetky `.backup`)
- ❌ `PPC-GUI-Modern-v2.ps1`
- ❌ `PPC-GUI-Modern-v3.ps1`
- ❌ `PPC-GUI-Ultimate.ps1`
- ❌ `PPC-GUI-Ultimate-v2.ps1`
- ❌ `PPC-GUI-Ultimate-v3.ps1`
- ❌ `PPC-GUI-Final.ps1`
- ❌ `PPC-GUI-Modern-Clean.ps1`
- ❌ `TEST-ULTIMATE-V2.ps1`
- ❌ `VERIFY-VERSION.ps1`

**Ponechaj IBA:**
- ✅ `PPC-GUI-Complete.ps1` ← TOTO je aktuálna verzia!
- ✅ `START.bat`

---

## 🔍 Diagnostika chýb

Ak START.bat stále nefunguje po vyčistení:

### Test 1: Spusti GUI priamo
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "PPC-GUI-Complete.ps1"
```

### Test 2: Skontroluj chybovú hlášku
Nová verzia START.bat zobrazí chybu ak GUI zlyhá. Skopíruj mi celú chybovú hlášku.

### Test 3: Overovacie skripty
Spusti:
```
START.bat
```
A pošli mi screenshot celého čierneho okna (vrátane chybových hlášok).

---

## 📦 Čo obsahuje aktuálna verzia?

**PPC-GUI-Complete.ps1** (550+ riadkov)
- ✅ Menu bar (File, Tools, Help)
- ✅ Toolbar s 6 tlačidlami
- ✅ **+ Add Files** (modré tlačidlo) - pridaj video súbory
- ✅ **Watermark** - pridaj vodoznak (PNG/JPG)
- ✅ **Subtitle** - pridaj titulky (SRT/ASS)
- ✅ **Crop** - orezanie videa
- ✅ Drag & Drop podpora
- ✅ Výber formátu (MP4, MKV, AVI, MOV, WMV)
- ✅ Výber kvality (Fast, Balanced, High, Best)
- ✅ Výber rozlíšenia (Source, 1080p, 720p, 480p)
- ✅ **START CONVERSION** (veľké oranžové tlačidlo)

---

## 🚀 Najbežnejšie problémy

### "Okno sa otvorí a zavrie"
→ Spusti **CLEANUP-OLD-FILES.bat** najprv

### "PowerShell nedokáže spustiť skript"
→ START.bat používa `-ExecutionPolicy Bypass`, malo by fungovať

### "File not found: PPC-GUI-Complete.ps1"
→ Rozbalil si ZIP správne? Skontroluj či súbor existuje

### "GUI sa zobrazí ale Add Files nefunguje"
→ Toto je nový problém - pošli mi screenshot a chybovú hlášku

---

## 📞 Ďalšia pomoc

Ak problém pretrváva:
1. Spusti START.bat
2. Urob screenshot celého okna (vrátane chýb)
3. Pošli mi zoznam súborov v priečinku (dir *.ps1)

---

**Aktualizované:** Po vyčistení starých verzií  
**Hlavný súbor:** PPC-GUI-Complete.ps1  
**Launcher:** START.bat (s auto-cleanup)
