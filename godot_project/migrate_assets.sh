#!/bin/bash

# Asset Migration Script for BakaCirno
# This script helps copy assets from the MonoGame project to the Godot project

echo "BakaCirno Asset Migration Script"
echo "================================"

# Source and destination paths
SOURCE_DIR="../BakaCirno/assets"
DEST_DIR="assets"

# Create destination directories if they don't exist
mkdir -p "$DEST_DIR/textures"
mkdir -p "$DEST_DIR/sounds"
mkdir -p "$DEST_DIR/fonts"

echo "Copying texture assets..."
# Copy texture files
cp "$SOURCE_DIR/textures/"*.png "$DEST_DIR/textures/" 2>/dev/null || echo "No PNG files found in textures"

echo "Copying sound assets..."
# Copy sound files (note: WAV files work in Godot, but you may want to convert to OGG for web)
cp "$SOURCE_DIR/sound/"*.wav "$DEST_DIR/sounds/" 2>/dev/null || echo "No WAV files found in sounds"

echo "Copying font assets..."
# Copy font files (XNB files will need to be replaced with TTF/OTF files)
echo "Note: XNB font files need to be replaced with TTF/OTF files for Godot"

echo ""
echo "Asset migration helper completed!"
echo ""
echo "IMPORTANT NOTES:"
echo "1. XNB font files (.xnb) need to be replaced with TTF or OTF files"
echo "2. For web export, consider converting WAV files to OGG format"
echo "3. WMA files should be converted to OGG for web compatibility"
echo "4. All texture files should be verified for correct import settings in Godot"
echo ""
echo "Next steps:"
echo "1. Run this script from the godot_project directory"
echo "2. Open Godot and verify asset imports"
echo "3. Replace font files with TTF/OTF equivalents"
echo "4. Convert audio files for web compatibility if needed"
