#!/bin/bash

# BakaCirno Godot Project Verification Script
# This script checks if all required files are present

echo "BakaCirno Godot 4 Migration - Project Verification"
echo "=================================================="

# Function to check if file exists
check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
    else
        echo "❌ $1 (MISSING)"
    fi
}

# Function to check if directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo "✅ $1/"
    else
        echo "❌ $1/ (MISSING)"
    fi
}

echo ""
echo "Checking core project files..."
check_file "project.godot"
check_file "Main.gd"
check_file "Main.tscn"

echo ""
echo "Checking gameplay scripts..."
check_file "Player.gd"
check_file "Player.tscn"
check_file "Enemy.gd"
check_file "Enemy.tscn"
check_file "Bullet.gd"
check_file "Bullet.tscn"
check_file "Explosion.gd"
check_file "Explosion.tscn"
check_file "PointBullet.gd"
check_file "PointBullet.tscn"

echo ""
echo "Checking bullet patterns..."
check_file "CircleShots.gd"
check_file "RandomShots.gd"

echo ""
echo "Checking UI and systems..."
check_file "TextOverlay.gd"
check_file "TextOverlay.tscn"
check_file "HighScoreText.gd"
check_file "HighScoreText.tscn"
check_file "Background.gd"
check_file "Background.tscn"
check_file "Sound.gd"

echo ""
echo "Checking asset directories..."
check_dir "assets"
check_dir "assets/textures"
check_dir "assets/sounds"
check_dir "assets/fonts"

echo ""
echo "Checking helper files..."
check_file "README.md"
check_file "migrate_assets.sh"

echo ""
echo "Verification complete!"
echo ""

# Count files
total_files=$(find . -name "*.gd" -o -name "*.tscn" | wc -l)
echo "Total GDScript and scene files: $total_files"

# Check for common issues
echo ""
echo "Quick issue check..."

if [ ! -d "assets/textures" ]; then
    echo "⚠️  Assets directory structure needs to be created"
fi

if [ ! -f "assets/textures/idlecirno.png" ]; then
    echo "⚠️  Game assets need to be copied from original project"
fi

echo ""
echo "Next steps:"
echo "1. Run ./migrate_assets.sh to copy assets from MonoGame project"
echo "2. Replace XNB fonts with TTF/OTF files"
echo "3. Convert WMA audio to OGG for web compatibility"
echo "4. Open project in Godot 4.4+ and test"
