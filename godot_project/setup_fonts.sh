#!/bin/bash

# Font Setup Helper Script for BakaCirno
# This script helps download and set up fonts for the game

echo "BakaCirno Font Setup Helper"
echo "=========================="

FONTS_DIR="assets/fonts"

# Create fonts directory if it doesn't exist
mkdir -p "$FONTS_DIR"

echo ""
echo "Font setup options:"
echo "1. Download Press Start 2P (recommended pixel font)"
echo "2. Use system fonts"
echo "3. Manual font installation guide"
echo ""

read -p "Choose an option (1-3): " choice

case $choice in
    1)
        echo "To download Press Start 2P font:"
        echo "1. Go to: https://fonts.google.com/specimen/Press+Start+2P"
        echo "2. Click 'Download family'"
        echo "3. Extract the zip file"
        echo "4. Copy 'PressStart2P-Regular.ttf' to $FONTS_DIR/"
        echo "5. Rename it to 'PressStart2P.ttf'"
        echo ""
        echo "The game will automatically detect and use this font!"
        ;;
    2)
        echo "Using system fonts (no download needed):"
        echo "The game will use the default system font."
        echo "This works but may not match the original game's pixel aesthetic."
        ;;
    3)
        echo "Manual font installation guide:"
        echo ""
        echo "1. Find a TTF or OTF font file you want to use"
        echo "2. Copy it to the $FONTS_DIR/ directory"
        echo "3. Rename it to one of these names for auto-detection:"
        echo "   - Font.ttf (matches original)"
        echo "   - PressStart2P.ttf (pixel font)"
        echo "   - game_font.ttf (generic)"
        echo "   - pixel_font.ttf (another pixel option)"
        echo ""
        echo "Good font sources:"
        echo "- Google Fonts (fonts.google.com)"
        echo "- DaFont (dafont.com) - especially bitmap/pixel fonts"
        echo "- Font Squirrel (fontsquirrel.com)"
        ;;
    *)
        echo "Invalid option. Please run the script again."
        ;;
esac

echo ""
echo "Current fonts directory contents:"
ls -la "$FONTS_DIR" 2>/dev/null || echo "No fonts directory found"

echo ""
echo "Note: After adding fonts, restart Godot to ensure proper loading."
