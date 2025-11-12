# 🎨 Modern GUI Features - Perfect Portable Converter

## ✨ Nový Aero-Style Windows XP/Vista dizajn!

### 🖼️ Vizuálne vylepšenia

```
┌─────────────────────────────────────────────────────────────┐
│  Perfect Portable Converter                          [_][□][X]│
│  Modern Edition - FFmpeg & HandBrake Support                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  [📁 Add Files] [🖼️ Watermark] [💬 Subtitles] [📂 Output]    │
│  [▶ Start Conversion]                                        │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Conversion Profile: ▼                               │    │
│  │ ┌─────────────────────────────────────────────┐     │    │
│  │ │ HandBrake - Fast 1080p x264              ▼ │     │    │
│  │ └─────────────────────────────────────────────┘     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Files to Convert                                    │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ C:\Videos\vacation.mp4                             │    │
│  │ C:\Videos\birthday.mov                             │    │
│  │ C:\Videos\tutorial.mkv                             │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  Output: C:\Users\You\Videos\output                          │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Activity Log                                        │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │ [1/3] (33.3%) Processing: vacation.mp4             │    │
│  │   ✓ Conversion complete                            │    │
│  │ [2/3] (66.7%) Processing: birthday.mov             │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 🆕 Nové funkcie

### 1. **Aero-Style tlačidlá**
   - Gradientový modrý dizajn (ako Windows XP/Vista)
   - Hover efekt (svetlejší pri prechode myšou)
   - Pressed efekt (tmavší pri kliknutí)
   - Tieň (DropShadow) pre 3D efekt
   - Zaoblené rohy (CornerRadius)

### 2. **Watermark podpora** 🖼️
   - Klikni "Watermark" button
   - Vyber PNG/JPG obrázok
   - Aplikuje sa na všetky videá (overlay v dolnom pravom rohu)

### 3. **Subtitle burn-in podpora** 💬
   - Klikni "Subtitles" button
   - Vyber SRT/ASS súbor
   - Titulky sa natrvalo vpália do videa

### 4. **Dual-engine support**
   - **FFmpeg profily** - klasická konverzia
   - **HandBrake profily** - moderná konverzia s lepšou kompresiou
   - Automatický výber enginu podľa profilu

### 5. **Real-time activity log**
   - Farebný log s progress indikátormi
   - Vidíš aktuálny súbor [X/Y]
   - Vidíš percentá (33.3%, 66.7%, ...)
   - ✓ checkmark pri úspešnej konverzii

### 6. **Moderné farby a gradienty**
   ```
   Header: #4A90E2 (modrá s gradientom)
   Buttons: #E8F4FF → #B3D9FF (svetlá modrá)
   Start button: #B8E6B8 → #77DD77 (zelená)
   Borders: #CCCCCC (jemná sivá)
   Background: #F0F0F0 (svetlá sivá)
   Shadows: DropShadow s opacity 0.3-0.4
   ```

## 🚀 Spustenie

### Automaticky (dvojklik):
```bat
START.bat
```
→ Automaticky načíta `PPC-GUI-Modern.ps1` ak existuje

### Manuálne:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -STA -File PPC-GUI-Modern.ps1
```

## 📋 Profily

### FFmpeg profily:
- ✅ FFmpeg - Fast 1080p H264
- ✅ FFmpeg - Small 720p H264

### HandBrake profily:
- ✅ HandBrake - Fast 1080p x264
- ✅ HandBrake - Small 720p x264
- ✅ HandBrake - x265 Medium

## 🎨 Dizajn prvky

### Tlačidlá s Aero efektom:
```xml
<Style x:Key="AeroButton">
  - LinearGradientBrush (modrá)
  - DropShadowEffect (tieň)
  - CornerRadius="3" (zaoblené rohy)
  - Hover: svetlejší gradient
  - Pressed: tmavší gradient
</Style>
```

### Header s tieňom:
```xml
<Border Background="#4A90E2" CornerRadius="5">
  - DropShadowEffect depth 3, blur 6
  - Biele písmo (White)
  - 22pt Bold nadpis
</Border>
```

### File list box:
```xml
<Border Background="White" CornerRadius="3">
  - DropShadowEffect (jemný tieň)
  - Sivý border (#CCCCCC)
  - Header s pozadím #F5F5F5
</Border>
```

## 🔧 Technické detaily

**Framework:** WPF (Windows Presentation Foundation)
**Theme:** Aero-inspired (Windows XP/Vista štýl)
**Jazyk:** PowerShell + XAML
**Minimum:** Windows PowerShell 5.1, .NET Framework 4.5+

**Farby:**
- Primary: `#4A90E2` (modrá)
- Success: `#77DD77` (zelená)
- Border: `#CCCCCC` (sivá)
- Background: `#F0F0F0` (svetlá)
- Text: `#333333` (tmavá)

**Efekty:**
- Tieň na tlačidlách
- Tieň na paneloch
- Gradienty na tlačidlách
- Hover/Pressed animácie

---

## 📦 Súbory

- `PPC-GUI-Modern.ps1` - nové moderné WPF GUI
- `PPC-GUI.ps1` - pôvodné WinForms GUI (fallback)
- `START.bat` - automaticky načíta Modern GUI ak existuje

## 🎯 Porovnanie

| Feature | Staré GUI | Nové GUI |
|---------|-----------|----------|
| Theme | WinForms (sivé) | WPF Aero (modré gradienty) |
| Watermark | ❌ | ✅ |
| Subtitles | ❌ | ✅ |
| HandBrake | ❌ | ✅ |
| Progress | Text | Real-time s % |
| Tlačidlá | Ploché | 3D s tieňom |
| Farby | Sivá | Modré gradienty |
| Ikony | ❌ | ✅ (emoji) |
| Layout | Jednoduchý | Moderný s kartami |

**Nový dizajn vyzerá ako Windows XP/Vista Aero Glass theme! 🎨✨**
