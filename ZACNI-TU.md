# ⚡ URGENTNÉ - Ako vyriešiť START.bat problém

## 🔴 Tvoj problém
> "staart.bat iba otvoril a zavrel cierne okno. vidim tu vela PS1 suborov... odstran ich a daj tam novu verziu"

---

## ✅ RIEŠENIE v 4 krokoch

### Krok 1: Stiahni NOVÚ verziu
Prejdi na: https://github.com/Humming-SvKe/Perfect-Portable-Converter

1. Klikni zelené **Code** tlačidlo
2. Klikni **Download ZIP**
3. Ulož do nového priečinka (napr. `C:\PPC`)

### Krok 2: Vymaž STARÝ priečinok
Vymaž celý tvoj starý priečinok:
```
C:\vcs\Perfect-Portable-Converter-main\   ← VYMAŽ TOTO
```

### Krok 3: Rozbaľ NOVÚ verziu
Rozbaľ stiahnutý ZIP do:
```
C:\PPC\
```

**POZOR:** Rozbaľ iba RAZ! Nesmieš mať vnorené priečinky!

### Krok 4: Spusti cleanup a GUI

**A) Najprv cleanup (iba raz):**
```
CLEANUP-OLD-FILES.bat
```

**B) Potom overovacie skripty:**
```
VERSION-CHECK.bat  ← Skontroluje či máš správne súbory
TEST-GUI.bat       ← Otestuje či GUI funguje
```

**C) Ak všetko OK, spusti normálne:**
```
START.bat
```

---

## 🎯 Čo sa stane po cleanup?

### Pred cleanup (14 súborov - CHAOS):
```
PPC-GUI.ps1
PPC-GUI-Modern.ps1
PPC-GUI-Modern-v2.ps1
PPC-GUI-Modern-v3.ps1
PPC-GUI-Ultimate.ps1
PPC-GUI-Ultimate-v2.ps1
PPC-GUI-Ultimate-v3.ps1
PPC-GUI-Final.ps1
PPC-GUI-Modern-Clean.ps1
PPC-GUI-Complete.ps1    ← len tento je správny!
TEST-ULTIMATE-V2.ps1
VERIFY-VERSION.ps1
PPC-HandBrake.ps1
PPC.ps1
```

### Po cleanup (2 súbory - ČISTO):
```
PPC-GUI-Complete.ps1    ← HLAVNÝ GUI
PPC.ps1                 ← CLI verzia
```

---

## 📋 Nové pomocné skripty

### 1. **CLEANUP-OLD-FILES.bat**
- Vymaže všetkých 12 starých verzií
- Spusti raz po stiahnutí novej verzie

### 2. **VERSION-CHECK.bat**
- Ukáže ktoré GUI súbory máš
- Povie či sú [CURRENT] alebo [OLD]

### 3. **TEST-GUI.bat**
- Otestuje či GUI dokáže načítať
- Zobrazí detailné chyby ak zlyhá

### 4. **START.bat** (vylepšený)
- Automaticky vymaže staré verzie
- Zobrazí chyby ak GUI zlyhá
- Lepšia diagnostika

---

## 🔍 Ako poznám že funguje?

### ✅ Správne fungovanie:
1. Dvojklik na `START.bat`
2. Zobrazí sa okno "Professional Portable Converter"
3. Vidíš Menu bar (File, Tools, Help)
4. Vidíš Toolbar s modrým tlačidlom **+ Add Files**
5. Vidíš ListView (prázdny zoznam súborov)
6. Dole vidíš oranžové tlačidlo **START CONVERSION**

### ❌ Ak stále nefunguje:
1. Spusti `TEST-GUI.bat`
2. Urob screenshot CELÉHO čierneho okna
3. Pošli mi screenshot
4. Napíš mi aké chyby vidíš

---

## 💡 Prečo to nefungovalo predtým?

1. **Malo si 14 starých PS1 súborov**
   - Z každého pokusu o GUI ostal jeden súbor
   - Windows nevedel ktorý spustiť
   - START.bat hľadal zlý súbor

2. **Vnorené priečinky**
   - Možno si rozbalil ZIP viackrát
   - Vznikla štruktúra: `PPC-main\PPC-main\PPC-main\`
   - Skripty nenašli súbory

3. **Žiadna diagnostika**
   - START.bat neukázal chyby
   - PowerShell okno sa zavrel okamžite
   - Nevidel si čo zlyhalo

---

## 📚 Dokumentácia (nové súbory)

### **FIX-START-BAT.md**
- Kompletný návod na riešenie problémov
- Všetky diagnostické príkazy
- FAQ pre najbežnejšie chyby

### **README-SK.md**
- Prehľad všetkých funkcií
- Podporované formáty
- Quick start guide
- Štruktúra súborov

### **CHANGELOG-CLEANUP.md**
- Čo bolo urobené
- Zoznam zastaraných súborov
- Ďalšie kroky

---

## 🎬 Čo GUI dokáže?

### Menu Bar
- **File**: Add Files, Add Folder, Exit
- **Tools**: Merge, Split, Crop, Rotate
- **Help**: About

### Toolbar
- `+ Add Files` - Pridaj video (modrý button)
- `Remove` - Vymaž vybraný
- `Clear All` - Vymaž všetko
- `Watermark` - Pridaj vodoznak (PNG/JPG)
- `Subtitle` - Pridaj titulky (SRT/ASS)
- `Crop` - Orež video

### Nastavenia
- **Format**: MP4, MKV, AVI, MOV, WMV
- **Quality**: Fast, Balanced, High, Best
- **Resolution**: Source, 1080p, 720p, 480p
- **Output Folder**: Kam uložiť výsledok

### Extra funkcie
- Drag & Drop súborov
- Multi-select (vyber viacero naraz)
- Progress bar pri konverzii
- Professional Apowersoft-style dizajn

---

## 🚨 AK PROBLÉM PRETRVÁVA

### Diagnostika v 3 krokoch:

**1. Overovacie skripty**
```
VERSION-CHECK.bat  ← Ktoré súbory máš?
TEST-GUI.bat       ← Načíta sa GUI?
```

**2. Screenshot chýb**
- Spusti TEST-GUI.bat
- Urob screenshot CELÉHO okna
- Pošli mi to

**3. Zoznam súborov**
Otvor CMD v priečinku PPC a spusti:
```
dir *.ps1
```
Pošli mi výstup.

---

## 📞 Potrebuješ pomoc?

**Pošli mi:**
1. Screenshot z `TEST-GUI.bat`
2. Výstup z `dir *.ps1`
3. Screenshot z `VERSION-CHECK.bat`

**Napíš mi:**
- Aké chyby vidíš?
- Spustil si `CLEANUP-OLD-FILES.bat`?
- Stiahol si novú verziu z GitHubu?

---

## ✅ Checklist pred spustením

- [ ] Stiahol som NOVÚ verziu z GitHubu
- [ ] Vymazal som STARÝ priečinok
- [ ] Rozbalil som ZIP do C:\PPC\ (nie vnorene!)
- [ ] Spustil som CLEANUP-OLD-FILES.bat
- [ ] Spustil som VERSION-CHECK.bat (vidím [CURRENT])
- [ ] Spustil som TEST-GUI.bat (žiadne chyby)
- [ ] Spustil som START.bat (GUI sa zobrazilo!)

---

**DÔLEŽITÉ:**  
Po vyčistení bude v priečinku iba **PPC-GUI-Complete.ps1** ako hlavný súbor.  
Všetky ostatné PS1 súbory sú ZASTARANÉ a budú vymazané.

---

**Posledná aktualizácia:** Po vytvorení cleanup skriptov  
**Hlavný súbor:** PPC-GUI-Complete.ps1 (550+ riadkov)  
**Status:** ✅ GUI hotové | ⏳ Čaká na user testing po cleanup
