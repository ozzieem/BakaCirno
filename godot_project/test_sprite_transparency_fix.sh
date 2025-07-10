#!/bin/bash

# Test script to diagnose sprite transparency issues

echo "=== Sprite Transparency Diagnostic Test ==="

cd "$(dirname "$0")"

echo "Checking texture loading improvements:"

# Check if RGBA format is being used in fallback
if grep -q "Image.FORMAT_RGBA8" Player.gd; then
    echo "✓ Fallback textures now use RGBA format (supports transparency)"
else
    echo "✗ Fallback textures still using RGB format"
fi

# Check if transparency settings are added
if grep -q "sprite.self_modulate = Color.WHITE" Player.gd; then
    echo "✓ Player sprite transparency settings added"
else
    echo "✗ Player sprite transparency settings missing"
fi

# Check if explosion transparency is fixed
if grep -q "sprite.self_modulate = Color.WHITE" Explosion.gd; then
    echo "✓ Explosion sprite transparency settings added"
else
    echo "✗ Explosion sprite transparency settings missing"
fi

echo ""
echo "Checking if texture files exist:"
echo "Player textures:"
for texture in idlecirno.png rightcirno.png leftcirno.png blueexplosion.png; do
    if [ -f "assets/textures/$texture" ]; then
        echo "  ✓ Found: $texture"
    else
        echo "  ✗ Missing: $texture"
    fi
done

echo ""
echo "Enemy explosion texture:"
if [ -f "assets/textures/EnemyExplosion.png" ]; then
    echo "  ✓ Found: EnemyExplosion.png"
else
    echo "  ✗ Missing: EnemyExplosion.png"
fi

echo ""
echo "=== Diagnosis Complete ==="
echo ""
echo "If black boxes persist, the issue is likely:"
echo "1. PNG files have black backgrounds instead of transparency"
echo "2. PNG import settings in Godot need adjustment"
echo "3. Sprite sheet layout issues"
echo ""
echo "To test:"
echo "1. Run the game and check if debug messages show texture loading"
echo "2. If you see 'Successfully loaded texture:' messages, the PNGs are loading"
echo "3. If black boxes persist, the PNG files themselves may have black backgrounds"
echo ""
echo "Solution if PNGs have black backgrounds:"
echo "- Edit the PNG files in an image editor (GIMP, Photoshop, etc.)"
echo "- Make the black areas transparent"
echo "- Save with alpha channel support"
