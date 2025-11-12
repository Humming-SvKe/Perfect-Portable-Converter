# PPC-GUI-Ultimate-v2.ps1 - Changelog

## Ultimate Edition v2 - Modern Dark Mode GUI

### MASSIVE UI IMPROVEMENTS
- ✅ Completely flat modern design inspired by VS Code
- ✅ NO gridlines, NO ugly borders, NO Win95 aesthetics  
- ✅ Custom helper functions: `New-ModernButton`, `New-ModernTextBox`, `New-ModernComboBox`
- ✅ Proper hover effects (`MouseOverBackColor`)
- ✅ Hand cursor on all buttons for better UX

### Clean Color Palette
- **Background:** `#1E1E1E` (dark)
- **Panel:** `#2D2D30` (medium dark)  
- **Panel Light:** `#373739` (lighter panel)
- **Text:** `#F1F1F1` (almost white)
- **Text Dim:** `#AAAAAA` (dimmed text)
- **Accent:** `#007ACC` (VS Code blue)
- **Accent Hover:** `#1C97EA` (lighter blue)
- **Success:** `#49BEAA` (teal)
- **Error:** `#F44747` (red)

### Layout Changes
1. **Toolbar** at top with:
   - `+ Add Files` (primary blue button)
   - `Remove` and `Clear All` (secondary gray buttons)
   - `Merge files` checkbox

2. **ListView** (task list):
   - No borders, no gridlines
   - Fills middle area with `Dock = 'Fill'`
   - Proper dark background

3. **Bottom Bar**:
   - Profile dropdown (500px wide)
   - `Edit Preset...` button
   - Output folder path (400px wide)
   - `...` browse button
   - `Open Folder` button
   - **HUGE CONVERT button** (215px × 90px, top-right corner)

### Features Preserved
- ✅ Drag & Drop file support
- ✅ Context menu (Edit, Remove)
- ✅ Edit Window for Subtitles & Watermark
- ✅ Preset Editor modal
- ✅ Full FFmpeg/HandBrake conversion pipeline
- ✅ Status tracking with color coding:
  - `✓ Success` = green (#49BEAA)
  - `✗ Failed` = red (#F44747)

### Technical Details
- `FlatStyle = 'Flat'` on all buttons
- `FlatAppearance.BorderSize = 0` (no borders!)
- `Cursor = [System.Windows.Forms.Cursors]::Hand` on buttons
- `FormBorderStyle = 'FixedDialog'` on modals (no maximize)
- `ClientSize` instead of `Width/Height` for precise sizing
- Proper `Dock` usage for responsive layout

---

**Result:** This version looks like a REAL modern app, not a 1995 Windows relic!
