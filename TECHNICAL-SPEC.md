# Perfect Portable Converter - Technical Specification

## Architecture Overview

Perfect Portable Converter (PPC) is built on PowerShell and FFmpeg, providing a portable video processing solution with both CLI and GUI interfaces.

### Component Structure

```
PPC System
├── Core Module (PPC-Core.ps1)
│   ├── Hardware acceleration detection
│   ├── Video analysis (FFprobe wrapper)
│   ├── MKV track management
│   ├── Watermark processing
│   ├── Subtitle handling
│   └── Video manipulation functions
├── CLI Interface (PPC.ps1)
│   ├── Interactive menu system
│   ├── Batch processing engine
│   └── Core module integration
├── GUI Interface (PPC-GUI.ps1)
│   ├── Windows Forms UI
│   ├── Tabbed interface
│   ├── Event handlers
│   └── Core module integration
├── Configuration (config/defaults.json)
│   ├── Profile definitions
│   ├── Filter presets
│   └── Application settings
└── FFmpeg Binaries (binaries/)
    ├── ffmpeg.exe
    └── ffprobe.exe
```

## Module: PPC-Core.ps1

### Functions

#### Hardware Acceleration

```powershell
function Get-HardwareAcceleration
```
**Purpose**: Detect available hardware acceleration technologies
**Returns**: Hashtable with detected capabilities
- `nvidia` - NVIDIA NVENC support
- `intel` - Intel Quick Sync support
- `amd` - AMD AMF support
- `available` - Array of available technologies

**Implementation**: Parses FFmpeg encoder list for hardware codecs

#### Video Information

```powershell
function Get-VideoInfo([string]$path)
```
**Purpose**: Extract detailed video file information
**Parameters**:
- `$path` - Full path to video file
**Returns**: Hashtable with:
- `format` - Container format
- `duration` - Duration in seconds
- `size` - File size in bytes
- `bitrate` - Overall bitrate
- `video` - Video stream info (codec, dimensions, fps, bitrate)
- `audio` - Array of audio streams
- `subtitles` - Array of subtitle streams

**Implementation**: Uses FFprobe JSON output

#### MKV Track Management

```powershell
function Extract-MKVTracks([string]$input, [string]$outputDir, [string[]]$trackTypes)
```
**Purpose**: Extract individual tracks from MKV container
**Parameters**:
- `$input` - Input MKV file
- `$outputDir` - Output directory
- `$trackTypes` - Array: 'video', 'audio', 'subtitles'
**Returns**: Boolean success status

**Implementation**:
- Gets track info via Get-VideoInfo
- Uses FFmpeg `-map` parameter for selective extraction
- Uses `-c copy` for lossless extraction
- Generates numbered output files with language tags

```powershell
function Merge-MKVTracks([string[]]$inputs, [string]$output)
```
**Purpose**: Merge multiple files into single MKV
**Parameters**:
- `$inputs` - Array of input file paths
- `$output` - Output MKV path
**Returns**: Boolean success status

**Implementation**: Uses FFmpeg with multiple `-i` and `-map` parameters

#### Watermark Processing

```powershell
function Add-ImageWatermark([string]$input, [string]$output, [string]$watermarkPath, 
                           [string]$position, [double]$opacity)
```
**Purpose**: Overlay image watermark on video
**Parameters**:
- `$input` - Input video
- `$output` - Output video
- `$watermarkPath` - Watermark image (PNG/JPG)
- `$position` - Position preset: topleft, topright, bottomleft, bottomright, center
- `$opacity` - 0.0 to 1.0
**Returns**: Boolean success status

**Implementation**:
- Uses FFmpeg `-filter_complex` with `movie` and `overlay` filters
- Position mapping:
  - `topleft`: `10:10`
  - `topright`: `W-w-10:10`
  - `bottomleft`: `10:H-h-10`
  - `bottomright`: `W-w-10:H-h-10`
  - `center`: `(W-w)/2:(H-h)/2`
- Opacity via `colorchannelmixer=aa=$alpha`

```powershell
function Add-TextWatermark([string]$input, [string]$output, [string]$text, 
                          [string]$position, [int]$fontSize, [string]$color, [double]$opacity)
```
**Purpose**: Add text watermark to video
**Parameters**:
- `$input` - Input video
- `$output` - Output video
- `$text` - Text to display
- `$position` - Position preset
- `$fontSize` - Font size in pixels
- `$color` - Color name (white, black, red, etc.)
- `$opacity` - 0.0 to 1.0
**Returns**: Boolean success status

**Implementation**:
- Uses FFmpeg `drawtext` filter
- Escapes special characters (quotes, colons)
- Position expressions using text width (`tw`) and height (`th`)

#### Subtitle Processing

```powershell
function Burn-Subtitle([string]$input, [string]$output, [string]$subtitlePath)
```
**Purpose**: Permanently burn subtitles into video
**Parameters**:
- `$input` - Input video
- `$output` - Output video
- `$subtitlePath` - Subtitle file (SRT/ASS/VTT)
**Returns**: Boolean success status

**Implementation**:
- Uses FFmpeg `subtitles` filter
- Escapes path for filter syntax
- Re-encodes video (cannot use `-c copy`)

```powershell
function Convert-SubtitleFormat([string]$input, [string]$output, [string]$format)
```
**Purpose**: Convert between subtitle formats
**Parameters**:
- `$input` - Input subtitle file
- `$output` - Output subtitle file
- `$format` - Target format (srt/ass/vtt)
**Returns**: Boolean success status

**Implementation**: Direct FFmpeg conversion

#### Video Tools

```powershell
function Trim-Video([string]$input, [string]$output, [double]$startTime, [double]$duration)
```
**Purpose**: Extract portion of video
**Parameters**:
- `$input` - Input video
- `$output` - Output video
- `$startTime` - Start position in seconds
- `$duration` - Duration in seconds (0 = to end)
**Returns**: Boolean success status

**Implementation**:
- Uses `-ss` for start time
- Uses `-t` for duration
- Uses `-c copy` for fast, lossless cutting

```powershell
function Concatenate-Videos([string[]]$inputs, [string]$output)
```
**Purpose**: Join multiple videos
**Parameters**:
- `$inputs` - Array of input videos
- `$output` - Output video
**Returns**: Boolean success status

**Implementation**:
- Creates temporary concat demuxer file
- Format: `file 'path'` per line
- Uses `-f concat -safe 0`
- Requires identical codecs/parameters

```powershell
function Generate-Thumbnail([string]$input, [string]$output, [double]$timeSeconds)
```
**Purpose**: Extract single frame as image
**Parameters**:
- `$input` - Input video
- `$output` - Output JPG
- `$timeSeconds` - Time position
**Returns**: Boolean success status

**Implementation**:
- Uses `-ss` to seek position
- `-vframes 1` for single frame
- `-q:v 2` for high quality

#### Audio Processing

```powershell
function Normalize-Audio([string]$input, [string]$output, [string]$targetLevel)
```
**Purpose**: Normalize audio levels
**Parameters**:
- `$input` - Input video/audio
- `$output` - Output file
- `$targetLevel` - Target loudness
**Returns**: Boolean success status

**Implementation**:
- Uses `loudnorm` filter
- Target: I=-16, TP=-1.5, LRA=11 (EBU R128)

## Configuration Schema

### defaults.json Structure

```json
{
  "default_format": "mp4",
  "hardware_acceleration": {
    "enabled": true,
    "prefer": "auto"
  },
  "profiles": [
    {
      "name": "Profile Name",
      "vcodec": "libx264",
      "preset": "medium",
      "crf": 23,
      "vb": "5M",
      "acodec": "aac",
      "ab": "160k",
      "scale": "1920:-2",
      "format": "mp4",
      "hwaccel": "nvenc",
      "profile": "high",
      "level": "4.1",
      "maxdur": 180,
      "deinterlace": false,
      "denoise": false,
      "effects": []
    }
  ],
  "filters": {
    "deinterlace": "yadif=0:-1:0",
    "denoise": "hqdn3d=4:3:6:4.5",
    "sharpen": "unsharp=5:5:1.0:5:5:0.0"
  }
}
```

### Profile Parameters

| Parameter | Type | Description | Examples |
|-----------|------|-------------|----------|
| `name` | string | Profile display name | "Fast 1080p H264" |
| `vcodec` | string | Video codec | libx264, libx265, h264_nvenc, none |
| `preset` | string | Encoding speed preset | ultrafast, fast, medium, slow, veryslow |
| `crf` | number | Constant Rate Factor (quality) | 18-28 (lower=better) |
| `vb` | string | Video bitrate (for CBR/HW) | "5M", "10M" |
| `acodec` | string | Audio codec | aac, mp3, libopus, flac, none |
| `ab` | string | Audio bitrate | "128k", "192k", "256k" |
| `scale` | string | Resolution scaling | "1920:-2", "1280:-2", "" (original) |
| `format` | string | Output container | mp4, mkv, webm, m4a |
| `hwaccel` | string | Hardware acceleration type | nvenc, qsv, amf |
| `profile` | string | H.264/265 profile | baseline, main, high |
| `level` | string | H.264/265 level | "3.1", "4.0", "4.1" |
| `maxdur` | number | Maximum duration (seconds) | 180, 300 |
| `deinterlace` | boolean | Apply deinterlacing | true, false |
| `denoise` | boolean | Apply noise reduction | true, false |
| `effects` | array | Additional filters | ["hflip", "vflip"] |

## FFmpeg Integration

### Command Construction

#### Basic Conversion
```bash
ffmpeg -y -hide_banner -loglevel warning \
  -i input.mp4 \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 160k \
  output.mp4
```

#### Hardware Acceleration (NVENC)
```bash
ffmpeg -y -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -c:v h264_nvenc -preset fast -b:v 5M \
  -c:a aac -b:a 160k \
  output.mp4
```

#### Scaling with Filter
```bash
ffmpeg -y -i input.mp4 \
  -vf "scale=1920:-2" \
  -c:v libx264 -crf 23 \
  -c:a copy \
  output.mp4
```

#### Complex Filter (Watermark)
```bash
ffmpeg -y -i input.mp4 \
  -filter_complex "[0:v]movie=logo.png,format=rgba,colorchannelmixer=aa=0.7[wm];[0:v][wm]overlay=W-w-10:H-h-10" \
  -c:a copy \
  output.mp4
```

### Error Handling

1. **Exit Code Check**: `$LASTEXITCODE -ne 0`
2. **Output Validation**: File exists and size > 0
3. **Log Parsing**: Check `logs/ffmpeg.log` for errors
4. **Cleanup**: Remove zero-byte outputs on failure

## GUI Architecture (PPC-GUI.ps1)

### Windows Forms Structure

```
Form (900x650)
└── TabControl (Dock=Fill)
    ├── Tab: Batch Convert
    │   ├── ListBox (file list)
    │   ├── Buttons (Add, Remove, Clear)
    │   ├── ComboBox (profile selector)
    │   ├── Button (output folder)
    │   ├── Button (Start)
    │   ├── ProgressBar
    │   └── TextBox (log)
    ├── Tab: MKV Tools
    │   └── GroupBox: Extract Tracks
    │       ├── TextBox + Button (file browser)
    │       ├── CheckBoxes (video/audio/subs)
    │       ├── Button (Extract)
    │       └── Label (status)
    ├── Tab: Watermark
    │   └── GroupBox: Watermark Type
    │       ├── RadioButtons (Image/Text)
    │       ├── File browsers
    │       ├── Text input
    │       ├── ComboBoxes (position, color)
    │       ├── NumericUpDowns (font, opacity)
    │       └── Button (Apply)
    ├── Tab: Subtitles
    │   └── GroupBox: Burn Subtitles
    │       ├── File browsers
    │       ├── Button (Burn)
    │       └── Label (status)
    ├── Tab: Video Tools
    │   ├── GroupBox: Trim/Cut
    │   │   ├── File browser
    │   │   ├── NumericUpDowns (start, duration)
    │   │   └── Button (Trim)
    │   └── GroupBox: Thumbnail
    │       ├── File browser
    │       ├── NumericUpDown (time)
    │       └── Button (Generate)
    └── Tab: Info & Settings
        ├── TextBox (info display)
        └── Button (Refresh)
```

### Event Flow

1. **Form Load (`Add_Shown`)**:
   - Load profiles from config
   - Populate ComboBox
   - Check FFmpeg availability
   - Display warning if needed
   - Update info tab

2. **Batch Convert Flow**:
   - User adds files → Update ListBox
   - User selects profile → Store selection
   - User clicks Start →
     - Disable UI
     - Set cursor to WaitCursor
     - Loop through files
     - Call `Convert-One` for each
     - Update ProgressBar
     - Append to log TextBox
     - Re-enable UI
     - Show summary MessageBox

3. **Feature Tab Flow**:
   - User selects files via Browse buttons
   - User configures options
   - User clicks action button →
     - Validate inputs
     - Show status label
     - Call core module function
     - Display result
     - Update status label

### Threading Considerations

- **STA Required**: WinForms requires Single-Threaded Apartment
- **Blocking Operations**: Long FFmpeg calls block UI
- **Progress Updates**: Use `.Refresh()` to force UI update
- **Cursor Management**: Set to WaitCursor during processing

## CLI Architecture (PPC.ps1)

### Menu System

```
Main Menu
├── [1] Batch Convert Videos
│   ├── Choose Profile
│   ├── Scan input folder
│   ├── Process each file
│   └── Display statistics
├── [2] Video Information
│   ├── List videos
│   ├── Select file
│   └── Display info (via Get-VideoInfo)
├── [3] MKV Manager
│   ├── [1] Extract tracks
│   │   ├── Select file
│   │   ├── Choose track types
│   │   └── Extract (via Extract-MKVTracks)
│   └── [2] Merge tracks
│       └── Merge all files in input (via Merge-MKVTracks)
├── [4] Watermark Tool
│   ├── [1] Image watermark
│   │   ├── Select video
│   │   ├── Select image from overlays
│   │   ├── Configure position/opacity
│   │   └── Apply (via Add-ImageWatermark)
│   └── [2] Text watermark
│       ├── Select video
│       ├── Enter text
│       ├── Configure style
│       └── Apply (via Add-TextWatermark)
├── [5] Subtitle Tool
│   ├── [1] Burn subtitles
│   │   ├── Select video
│   │   ├── Select subtitle
│   │   └── Burn (via Burn-Subtitle)
│   └── [2] Convert format
│       ├── Select subtitle
│       ├── Choose format
│       └── Convert (via Convert-SubtitleFormat)
├── [6] Video Tools
│   ├── [1] Trim/Cut
│   ├── [2] Concatenate
│   └── [3] Generate thumbnail
├── [7] Hardware Acceleration Info
│   └── Display HW status (via Get-HardwareAcceleration)
└── [8] Exit
```

### User Interaction Pattern

1. Display menu with color-coded options
2. Read user choice
3. Validate input
4. Execute corresponding function
5. Display result
6. Return to menu (loop)

### Color Scheme

- **Cyan**: Headers, borders
- **Green**: Success messages, action options
- **White**: Normal text, options
- **Yellow**: Warnings, info messages
- **Red**: Errors, exit option

## Performance Optimization

### Hardware Acceleration

**Speed Improvements**:
- NVENC: 5-10x faster than software
- QSV: 3-5x faster
- AMF: 3-5x faster

**Quality Trade-off**:
- HW encoding: Slightly lower quality
- Recommendation: Use for 4K, long videos, time-critical tasks

### Batch Processing

**Strategy**:
- Sequential processing (one file at a time)
- Prevents resource contention
- Simpler error handling
- Better progress tracking

**Potential Enhancement**:
- Parallel processing with `-MaxThreads` parameter
- Requires careful resource management
- Complex progress tracking

### Memory Management

**Current Approach**:
- Stream-based processing (FFmpeg)
- No in-memory video data
- Temporary files cleaned up

**Disk Space**:
- Ensure 2x input size available
- Clean temp folder regularly

## Security Considerations

### Input Validation

1. **Path Validation**:
   - Use `-LiteralPath` for file operations
   - Avoid path traversal attacks
   - Sanitize user inputs

2. **Command Injection**:
   - Never use user input directly in commands
   - Escape special characters
   - Use parameterized FFmpeg calls

3. **File Type Validation**:
   - Check file extensions
   - Verify file headers (magic bytes)
   - Limit to known video formats

### Privacy

- **No Telemetry**: No data sent to external servers
- **Offline Operation**: All processing local
- **No Account**: No user tracking

## Error Handling

### Error Levels

1. **WARN**: Non-critical, operation continues
   - Example: Config load failed, using defaults
   
2. **ERROR**: Critical, operation fails
   - Example: FFmpeg not found
   
3. **FAIL**: Single file failed in batch
   - Example: Corrupt input file

### Logging

**Log Files**:
- `logs/ppc.log` - Application log
- `logs/ppc-gui.log` - GUI-specific log
- `logs/ffmpeg.log` - FFmpeg output

**Log Format**:
```
YYYY-MM-DD HH:MM:SS | Message
```

**Log Rotation**:
- Append mode (no automatic rotation)
- Manual cleanup recommended
- REPORT.bat includes log tails

## Testing Strategy

### Unit Testing

**Core Module Functions**:
- Test each function with valid inputs
- Test error conditions
- Verify output files

**Example Test Cases**:
```powershell
# Test hardware detection
$hw = Get-HardwareAcceleration
Assert ($hw -ne $null)

# Test video info
$info = Get-VideoInfo -path "test.mp4"
Assert ($info.video.codec -eq "h264")

# Test watermark
$result = Add-ImageWatermark -input "in.mp4" -output "out.mp4" -watermarkPath "logo.png" -position "bottomright" -opacity 0.7
Assert ($result -eq $true)
Assert (Test-Path "out.mp4")
```

### Integration Testing

**Batch Conversion**:
1. Place test videos in input/
2. Run batch conversion
3. Verify all outputs created
4. Check quality/size

**GUI Testing**:
1. Test each tab functionality
2. Verify error messages
3. Check progress updates
4. Test cancel operations

### Performance Testing

**Benchmarks**:
- Measure conversion time for standard video
- Compare HW vs SW encoding
- Test with various file sizes
- Monitor resource usage

## Deployment

### Release Package Structure

```
PPC-Release.zip
├── PPC.ps1
├── PPC-GUI.ps1
├── PPC-Core.ps1
├── START.bat
├── REPORT.bat
├── README.md
├── USER-GUIDE.md
├── LICENSE
├── config/
│   └── defaults.json
├── binaries/
│   └── .gitkeep (ffmpeg auto-downloaded)
├── input/
│   └── .gitkeep
├── output/
│   └── .gitkeep
├── subtitles/
│   └── .gitkeep
├── overlays/
│   └── .gitkeep
└── thumbnails/
    └── .gitkeep
```

### Version Control

**Release Checklist**:
1. Update version in scripts
2. Test all features
3. Run REPORT.bat
4. Update CHANGELOG.md
5. Create release tag
6. Build ZIP package
7. Update GitHub release

## Future Enhancements

### Planned Features

1. **Database Integration**:
   - SQLite for job history
   - Statistics tracking
   - Preset management

2. **Advanced Video Filters**:
   - Video stabilization
   - Color grading
   - Motion interpolation

3. **Multi-threaded Batch**:
   - Process multiple files simultaneously
   - Configurable thread count

4. **Real-time Preview**:
   - Show video while processing
   - Filter preview before applying

5. **Queue Management**:
   - Pause/resume conversions
   - Job prioritization
   - Scheduled processing

6. **Cloud Integration** (optional):
   - Upload to YouTube/Vimeo
   - Cloud storage backup
   - (User opt-in required)

### API Design

Future module API for extensibility:

```powershell
# Custom filter plugin
function Register-CustomFilter {
  param([string]$Name, [scriptblock]$Implementation)
  $script:CustomFilters[$Name] = $Implementation
}

# Profile plugin
function Register-ProfileProvider {
  param([string]$Source, [scriptblock]$Loader)
  $script:ProfileProviders[$Source] = $Loader
}
```

## Contributing

### Code Style

**PowerShell Guidelines**:
- Use `PascalCase` for functions
- Use `camelCase` for variables
- Use `$script:` for module-level variables
- Use `$global:` only when necessary
- Always use `Set-StrictMode -Version Latest`
- Set `$ErrorActionPreference = 'Stop'` for safety

**Documentation**:
- Document all public functions
- Include parameter descriptions
- Provide usage examples
- Update README/USER-GUIDE

### Pull Request Process

1. Fork repository
2. Create feature branch
3. Make changes with tests
4. Update documentation
5. Submit PR with description
6. Respond to review comments

### Bug Reports

**Required Information**:
1. Steps to reproduce
2. Expected behavior
3. Actual behavior
4. REPORT.bat output
5. Log files
6. OS and hardware info

---

## References

- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Windows Forms API](https://docs.microsoft.com/en-us/dotnet/desktop/winforms/)
- [H.264 Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/H.264)
- [H.265 Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/H.265)

---

**Document Version**: 1.0
**Last Updated**: 2024
**Maintainer**: Perfect Portable Converter Team
