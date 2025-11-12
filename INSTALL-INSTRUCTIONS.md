# 🚀 Inštalačný Návod - Professional Portable Converter Ultimate v2

## ⚠️ DÔLEŽITÉ: Správny spôsob sťahovania

### ❌ CHYBA: Sťahovanie cez "Download ZIP"
Ak sťahuješ z GitHub cez zelené tlačidlo **"Code" → "Download ZIP"**, dostaneš ZIP s vnorenou zložkou:
```
Perfect-Portable-Converter-main.zip
  └── Perfect-Portable-Converter-main/
        └── všetky súbory
```

Po rozbalení máš **duplikované cesty** a **starú verziu**!

---

## ✅ SPRÁVNY POSTUP

### **Metóda 1: Git Clone (Odporúčané)**
```bash
cd C:\vcs
git clone https://github.com/Humming-SvKe/Perfect-Portable-Converter.git
cd Perfect-Portable-Converter
START-ULTIMATE-V2.bat
```

### **Metóda 2: Direct Download ZIP**
1. **Otvor v prehliadači:**
   ```
   https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip
   ```

2. **Stiahni ZIP súbor**

3. **Rozbaľ ZIP** do `C:\vcs\PPC\`

4. **Prejdi do zložky:**
   ```
   C:\vcs\PPC\Perfect-Portable-Converter-main\
   ```

5. **Spusti:**
   ```
   START-ULTIMATE-V2.bat
   ```

---

## 🔧 Ak už máš starú verziu

### **Vyčisti staré súbory:**
```powershell
# Otvor PowerShell v C:\vcs\
cd C:\vcs

# Vymaž staré verzie
Remove-Item -Recurse -Force "Perfect-Portable-Converter-main"

# Stiahni najnovšiu verziu
Invoke-WebRequest -Uri "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip" -OutFile "PPC-latest.zip"

# Rozbaľ
Expand-Archive -Path "PPC-latest.zip" -DestinationPath "." -Force

# Premenuj zložku (voliteľné)
Rename-Item "Perfect-Portable-Converter-main" "PPC"

# Spusti
cd PPC
.\START-ULTIMATE-V2.bat
```

---

## 📋 Overenie správnej verzie

Po spustení by si mal vidieť:

✅ **Okno s titulkom:** `Professional Portable Converter - Ultimate Edition v2`

✅ **Spodný panel výšky 140px** s plne viditeľným tlačidlom `CONVERT`

✅ **Profil dropdown:** zobrazuje "Fast 1080p - H264 (AAC 128k Stereo)"

✅ **Hint text:** "Click '+ Add Files' button or drag & drop video files here to start"

---

## 🛠️ Diagnostika

**Spusti TEST script:**
```powershell
.\TEST-ULTIMATE-V2.ps1
```

**Očakávaný výstup:**
```
[✓] DPI Awareness found
[✓] Hint Label found
[✓] Profile names updated
[✓] Font size 10pt
[✓] Bottom bar height 140
[✓] MinimumSize set

File: 1009 lines, 35KB
Launching GUI...
```

---

## 📞 Podpora

**GitHub Issues:** https://github.com/Humming-SvKe/Perfect-Portable-Converter/issues

**Najnovší Commit:** `2c11e30` (2025-11-12)

**Verzia:** Ultimate Edition v2 - Build 2c11e30
