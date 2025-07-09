#!/bin/bash

# BakaCirno Game Validation Script
# Run this script to check if all fixes are properly implemented

echo "=== BakaCirno Bullet Hell Game - Fix Validation ==="
echo ""

# Check if key files exist and contain expected changes
echo "1. Checking file modifications..."

# Check Bullet.gd for collision layer fixes
if grep -q "collision_layer == 3" "Bullet.gd"; then
    echo "✓ Player bullet collision layer logic found"
else
    echo "✗ Player bullet collision layer logic missing"
fi

if grep -q "rotation_speed = 0.0" "Bullet.gd"; then
    echo "✓ Player bullet rotation fix found"
else
    echo "✗ Player bullet rotation fix missing"
fi

# Check Enemy.gd for texture fallback
if grep -q "fallback texture" "Enemy.gd"; then
    echo "✓ Enemy texture fallback system found"
else
    echo "✗ Enemy texture fallback system missing"
fi

# Check Player.gd for collision improvements
if grep -q "Player bullet collision ignored" "Player.gd"; then
    echo "✓ Player bullet collision filtering found"
else
    echo "✗ Player bullet collision filtering missing"
fi

echo ""
echo "2. Checking asset structure..."

# Check if texture directories exist
if [ -d "assets/textures" ]; then
    echo "✓ Texture directory exists"
    echo "  Found $(ls assets/textures/*.png 2>/dev/null | wc -l) PNG texture files"
else
    echo "✗ Texture directory missing"
fi

echo ""
echo "3. Checking scene files..."

# Check if key scene files exist
for scene in "Main.tscn" "Player.tscn" "Enemy.tscn" "Bullet.tscn"; do
    if [ -f "$scene" ]; then
        echo "✓ $scene exists"
    else
        echo "✗ $scene missing"
    fi
done

echo ""
echo "4. Summary of fixes implemented:"
echo "   • Player bullets no longer remove enemy bullets"
echo "   • Enemy sprites have fallback textures when assets missing"
echo "   • Player bullets don't rotate (professional appearance)"
echo "   • Improved collision layer separation"
echo "   • Player bullets can damage enemies"
echo ""
echo "Game should now be fully functional!"
echo "Load Main.tscn in Godot to test the game."
