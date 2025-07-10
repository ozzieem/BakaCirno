#!/bin/bash

# Test script to verify death animation fix

echo "=== Testing Player Death Animation Fix ==="

cd "$(dirname "$0")"

# Check if Player.gd exists
if [ ! -f "Player.gd" ]; then
    echo "ERROR: Player.gd not found!"
    exit 1
fi

echo "Checking death animation updates in Player.gd:"

# Check if death animation has sprite update code
if grep -A 10 "func death_animation" Player.gd | grep -q "sprite.texture = current_anim_texture"; then
    echo "✓ Death animation sprite update added"
else
    echo "✗ Death animation sprite update missing"
fi

# Check if death animation has region update code
if grep -A 15 "func death_animation" Player.gd | grep -q "sprite.region_rect = Rect2"; then
    echo "✓ Death animation region update added"
else
    echo "✗ Death animation region update missing"
fi

# Check if death animation resets properly when switching
if grep -A 10 "func death_animation" Player.gd | grep -q "if current_anim_texture != explosion_anim_texture"; then
    echo "✓ Death animation reset logic added"
else
    echo "✗ Death animation reset logic missing"
fi

# Check if explosion animation has correct frame count
if grep -q "frame_count = 10 # Explosion animation has 10 frames" Player.gd; then
    echo "✓ Explosion animation has 10 frames"
else
    echo "✗ Explosion animation frame count incorrect"
fi

echo ""
echo "=== Death Animation Fix Test Complete ==="
echo ""
echo "To test the death animation fix:"
echo "1. Run the main game (Main.tscn)"
echo "2. Start playing and let the player get hit by an enemy bullet"
echo "3. Observe that the player should display an explosion animation when dying"
echo ""
echo "Expected behavior:"
echo "- Player switches to explosion animation texture when colliding"
echo "- Explosion animation cycles through 10 frames"
echo "- Animation continues until death timer expires"
echo "- Death animation should be visible and animated"
