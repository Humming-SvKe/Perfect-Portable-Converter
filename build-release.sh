#!/bin/bash
# ============================================
# Perfect Portable Converter - Build & Release
# Vytvorí ZIP archív a zobrazí download link
# ============================================

echo ""
echo "========================================"
echo " Perfect Portable Converter - BUILD"
echo "========================================"
echo ""

# Get version from date
VERSION=$(date +%Y%m%d-%H%M%S)
echo "Building version: $VERSION"
echo ""

# Create release directory
mkdir -p releases

# Define output filename
OUTPUT="releases/HandBrake-Extended-v${VERSION}.zip"

echo "Packaging files..."
echo ""

# Create ZIP archive
zip -r "$OUTPUT" \
    libhb/*.h \
    libhb/*.c \
    gtk/src/*.c \
    examples/*.c \
    README.md \
    -x "*.git*" \
    2>/dev/null

if [ -f "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    
    echo ""
    echo "========================================"
    echo " BUILD SUCCESSFUL!"
    echo "========================================"
    echo ""
    echo "File: $OUTPUT"
    echo "Size: $SIZE"
    echo ""
    echo "========================================"
    echo " DOWNLOAD LINKS:"
    echo "========================================"
    echo ""
    echo "GitHub Direct Download:"
    echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/archive/refs/heads/main.zip"
    echo ""
    echo "GitHub Repository:"
    echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter"
    echo ""
    echo "Raw Files:"
    echo "https://github.com/Humming-SvKe/Perfect-Portable-Converter/tree/main"
    echo ""
    echo "========================================"
    echo ""
    
    # List included files
    echo "Included files:"
    unzip -l "$OUTPUT" | tail -n +4 | head -n -2
    echo ""
else
    echo ""
    echo "ERROR: Build failed!"
    echo ""
fi
