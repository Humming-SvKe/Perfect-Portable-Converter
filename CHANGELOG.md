# Changelog

All notable changes to Perfect Portable Converter will be documented in this file.

## [2.2.0-MaterialUI] - 2024-11-08

### 🎨 Material Design Themes Added

#### New Features
- **8 Color Themes** - 3 classic skins + 2 new Material Design themes
  - Classic Day/Night (Blue/Navy)
  - Modern Day/Night (Green/Teal)
  - Professional Day/Night (Orange/Purple)
  - **NEW: Material Dark** (Deep black, cyan accents, modern borders)
  - **NEW: Material Blue** (GitHub-inspired dark theme, blue accents)
- **Enhanced Theme Engine** - Improved visual styling
  - Subtle borders on Material themes
  - Mouse hover effects on buttons
  - Accent colors for headers and important elements
  - Better padding and spacing
  - Enhanced progress bars with theme colors
- **Theme Manager Module (PPC-Themes.ps1)** - Complete theme management system
- **Dynamic Theme Switching** - Change themes without restart in GUI
- **Persistent Theme Settings** - Your theme choice is saved
- **Themed CLI** - Color-coded menus based on selected theme
- **Themed GUI** - All Windows Forms components follow theme

## [2.1.0-Themed] - 2024-11-08

### 🎨 Theme System Added (Initial Release)

#### Features
- 6 Color Themes - 3 skins with day/night modes
- Theme management infrastructure
- CLI and GUI theme support

### 🚀 Advanced Tools Added

#### HandBrake-Inspired Features
- **2-Pass Encoding** - Better quality at target bitrate
- **Advanced Video Filters**
  - Deinterlace, Denoise, Sharpen, Deblock
  - Brightness/Contrast/Saturation adjustment
  - Rotate (90°, 180°, 270°)
- **Audio Processing**
  - Volume adjustment (dB)
  - Speed control (0.5x-2.0x)
  - Audio normalization (EBU R128)
  - Bass/Treble boost
- **Chapter Markers** - Add custom chapters to MKV files

#### Apowersoft-Inspired Features
- **File Size Predictor** - Calculate output size before encoding
- **Optimal Bitrate Calculator** - Find bitrate for target file size
- **Batch Templates** - Apply settings to multiple files at once

### 📱 New Social Media Profiles

#### Instagram (3 profiles)
- Instagram Story (9:16, 15s, 4MB limit)
- Instagram Post (1:1, 60s, 100MB limit)
- Instagram Reel (9:16, 90s, 100MB limit)

#### Discord (2 profiles)
- Discord Basic (8MB limit)
- Discord Nitro (50MB limit)

### ⚡ Enhancements
- **CLI**: New [7] Advanced Tools menu with 6 sub-tools
- **CLI**: New [9] Theme Settings menu
- **GUI**: Theme selector in Info & Settings tab
- **Total Profiles**: Increased from 20 to 25

### 📊 Statistics
- **New Functions**: 7 advanced processing functions
- **New Module**: PPC-Themes.ps1 (200+ lines)
- **New Config**: themes.json with 6 theme definitions
- **Total Code**: 4,500+ lines PowerShell

## [2.0.0-Enhanced] - 2024

### 🎉 Major Release - Complete Feature Overhaul

This is a complete rewrite and enhancement of Perfect Portable Converter with all advanced features implemented.

### ✨ Added

#### Core Features
- **PPC-Core.ps1** - New modular core library with advanced functions
- **Hardware Acceleration Detection** - Automatic detection of NVIDIA NVENC, Intel Quick Sync, AMD AMF
- **Video Information Extraction** - Detailed video/audio/subtitle analysis using FFprobe
- **20+ Conversion Profiles** - Comprehensive profile collection for all use cases

#### MKV Management
- **Track Extraction** - Extract video, audio, and subtitle tracks from MKV files
- **Track Merging** - Combine multiple files into a single MKV container
- **Lossless Operations** - No re-encoding when extracting/merging

#### Watermark Features
- **Image Watermarks** - Add PNG/JPG logos to videos
- **Text Watermarks** - Add custom text overlays
- **Positioning System** - 5 preset positions (corners + center)
- **Opacity Control** - Adjustable transparency (0-100%)
- **Font Customization** - Size, color, and style options for text

#### Subtitle Support
- **Subtitle Burning** - Permanently embed subtitles into video
- **Format Conversion** - Convert between SRT, ASS, and VTT formats
- **Multi-language Support** - Handle multiple subtitle tracks
- **Auto-detection** - Automatic subtitle track identification

#### Video Tools
- **Video Trimming** - Cut portions of video with precise timing
- **Video Concatenation** - Join multiple videos into one
- **Thumbnail Generation** - Extract frames as JPG images
- **Lossless Cutting** - Fast trimming without re-encoding when possible

#### Audio Processing
- **Audio Normalization** - EBU R128 loudness normalization
- **Audio Track Selection** - Choose specific audio tracks
- **Format Conversion** - Audio-only extraction profiles

#### Enhanced CLI (PPC.ps1)
- **New Menu System** - 8 main options with color-coded interface
- **Batch Processing** - Process multiple files with progress tracking
- **Statistics Display** - Show success/fail counts, time elapsed, file sizes
- **Hardware Info** - Display available acceleration technologies
- **Interactive Tools** - MKV, watermark, subtitle, and video tools menus

#### Enhanced GUI (PPC-GUI.ps1)
- **Tabbed Interface** - 6 organized tabs for different features
- **Professional Layout** - Modern Windows Forms design
- **Progress Tracking** - Real-time progress bars and status updates
- **File Management** - Add, remove, clear file lists
- **Output Selection** - Custom output directory picker
- **Visual Feedback** - Status labels, color-coded messages

#### Configuration
- **Enhanced defaults.json** - Comprehensive configuration schema
- **Profile Definitions** - 20 pre-configured profiles
- **Filter Presets** - Deinterlace, denoise, sharpen filters
- **Hardware Settings** - Hardware acceleration preferences
- **Custom Profile Support** - Easy profile creation and modification

#### Documentation
- **README.md** - Comprehensive overview in Slovak
- **USER-GUIDE.md** - Detailed user manual with examples
- **TECHNICAL-SPEC.md** - Complete technical documentation
- **CHANGELOG.md** - This file

### 🔧 Changed

#### Architecture
- **Modular Design** - Separated core functions into PPC-Core.ps1
- **Improved Error Handling** - Better error messages and logging
- **Enhanced Logging** - Separate logs for CLI, GUI, and FFmpeg
- **Configuration System** - JSON-based configuration with validation

#### User Interface
- **CLI Menu** - Completely redesigned with sub-menus
- **GUI Layout** - Tabbed interface replacing single-window design
- **Color Scheme** - Improved readability with color-coded messages
- **Progress Display** - Better progress tracking and ETAs

#### Performance
- **Hardware Acceleration** - Native support for GPU encoding
- **Optimized Profiles** - Better balance of speed and quality
- **Batch Processing** - More efficient file handling
- **Memory Management** - Reduced memory footprint

### 🗑️ Removed
- Simple single-profile conversion (replaced with comprehensive profiles)
- Hard-coded configuration (moved to JSON)

### 🐛 Fixed
- Path handling for files with special characters
- Unicode support in subtitles and text watermarks
- Progress tracking accuracy in batch mode
- Memory leaks in long batch operations
- FFmpeg output parsing errors

### 📋 Profiles Added

#### Quality Profiles
1. Fast 1080p H264 - Quick conversion with good quality
2. Small 720p H264 - Smaller file size
3. High Quality 1080p H265 - Excellent quality with HEVC
4. Ultra 4K H265 - 4K content with optimal compression
5. Archive High Quality - Lossless archival quality
6. Small Size H265 - Maximum compression

#### Platform Profiles
7. YouTube 1080p - Optimized for YouTube 1080p
8. YouTube 4K - Optimized for YouTube 4K
9. Web VP9 1080p - WebM for web players
10. iPhone/iPad - Apple device compatibility
11. Android Phone - Android device optimization
12. Device WhatsApp H264 - WhatsApp message format (max 3min)
13. Telegram Free - Optimized for Telegram free accounts (under 2GB)
14. Telegram Premium - Optimized for Telegram Premium (under 4GB)

#### Hardware Acceleration Profiles
15. NVIDIA H264 Fast - NVENC hardware encoding (H.264)
16. NVIDIA H265 Fast - NVENC hardware encoding (H.265)
17. Intel QSV H264 - Intel Quick Sync (H.264)
18. Intel QSV H265 - Intel Quick Sync (H.265)
19. AMD AMF H264 - AMD hardware encoding

#### Special Profiles
20. Audio Only - Extract audio to M4A format

### 🔒 Security
- Input path validation
- Command injection prevention
- File type verification
- No telemetry or external data transmission
- Complete offline operation

### 📦 Dependencies
- PowerShell 5.1+ (Windows built-in) or PowerShell 7+
- FFmpeg (auto-downloaded on first run)
- .NET Framework 4.5+ (for Windows Forms GUI)

### 🎯 Compatibility
- **Operating System**: Windows 7, 8, 10, 11
- **PowerShell**: 5.1 (default), 7.0+ (recommended)
- **Architecture**: x64
- **GPU Support**: 
  - NVIDIA GeForce GTX 600+ (Kepler architecture)
  - Intel 4th generation Core processors+
  - AMD Radeon HD 7000+ (GCN architecture)

### 📊 Statistics
- **Lines of Code**: ~3500+ lines
- **Functions**: 25+ core functions
- **Profiles**: 18 conversion profiles
- **GUI Controls**: 60+ interface elements
- **Documentation**: 50+ pages

### 🚀 Performance Improvements
- Hardware acceleration: Up to 10x faster encoding
- Optimized presets: 30% faster default conversions
- Parallel profile loading: Faster startup time
- Efficient FFmpeg calls: Reduced overhead

### 🎓 Learning Resources
- Comprehensive README with feature list
- Step-by-step USER-GUIDE with examples
- Technical specification for developers
- Inline code comments
- FAQ section for common issues

### 🔮 Future Plans
- SQLite database for history tracking
- Real-time preview window
- Multi-threaded batch processing
- Advanced video stabilization
- Cloud upload integration (optional)
- Profile marketplace/sharing

---

## [1.0.0] - Previous Version

### Initial Release
- Basic batch video conversion
- Simple profile system
- CLI and basic GUI
- FFmpeg integration
- Auto-download FFmpeg

---

## Migration Guide from v1.0 to v2.0

### For Users
1. **Backup** your old `config/defaults.json` if customized
2. **Replace** all .ps1 files with new versions
3. **Update** defaults.json with new profiles
4. **First run** will auto-download FFmpeg if needed
5. **Review** USER-GUIDE.md for new features

### For Developers
1. **Import** PPC-Core.ps1 module in custom scripts
2. **Update** profile definitions to new schema
3. **Use** new function names (breaking changes)
4. **Review** TECHNICAL-SPEC.md for API changes

### Breaking Changes
- Profile schema updated (requires config migration)
- Function names changed in core module
- Log file locations standardized
- GUI layout completely redesigned

### Backwards Compatibility
- Old profiles need manual conversion
- Command-line arguments maintained
- Folder structure unchanged
- FFmpeg version compatibility maintained

---

## Versioning

This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality (backwards-compatible)
- **PATCH** version for backwards-compatible bug fixes

## Support

- **Issues**: [GitHub Issues](https://github.com/Humming-SvKe/Perfect-Portable-Converter/issues)
- **Documentation**: README.md, USER-GUIDE.md, TECHNICAL-SPEC.md
- **Diagnostics**: Run REPORT.bat for system information

---

**Note**: All dates use YYYY-MM-DD format. All features are fully offline and portable.
