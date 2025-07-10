#!/bin/bash

# Test script to verify player animation fix

echo "=== Testing Player Animation Fix ==="
echo "Testing frame counts for different animation types:"

cd "$(dirname "$0")"

# Check if Player.gd exists
if [ ! -f "Player.gd" ]; then
    echo "ERROR: Player.gd not found!"
    exit 1
fi

# Check if the frame counts were properly updated
echo "Checking frame count updates in Player.gd:"

# Check for idle animation frames
if grep -q "frame_count = 5 # Idle animation has 5 frames" Player.gd; then
    echo "✓ Idle animation: 5 frames (FIXED)"
else
    echo "✗ Idle animation: frame count not updated"
fi

# Check for right animation frames
if grep -q "frame_count = 5 # Right animation has 5 frames" Player.gd; then
    echo "✓ Right animation: 5 frames (FIXED)"
else
    echo "✗ Right animation: frame count not updated"
fi

# Check for left animation frames
if grep -q "frame_count = 7 # Left animation has 7 frames" Player.gd; then
    echo "✓ Left animation: 7 frames (FIXED)"
else
    echo "✗ Left animation: frame count not updated"
fi

# Check for explosion animation frames
if grep -q "frame_count = 10 # Explosion animation has 10 frames" Player.gd; then
    echo "✓ Explosion animation: 10 frames (FIXED)"
else
    echo "✗ Explosion animation: frame count not updated"
fi

echo ""
echo "Checking animation frame reset logic:"
if grep -q "if new_anim_texture != current_anim_texture:" Player.gd; then
    echo "✓ Animation frame reset logic added"
else
    echo "✗ Animation frame reset logic missing"
fi

echo ""
echo "=== Animation Fix Test Complete ==="
echo ""
echo "To test the fix:"
echo "1. Run the main game (Main.tscn)"
echo "2. Use arrow keys or WASD to move the player"
echo "3. Observe that the player sprite now animates properly"
echo ""
echo "Expected behavior:"
echo "- Idle: Player cycles through 5 animation frames"
echo "- Moving left: Player cycles through 7 animation frames"
echo "- Moving right: Player cycles through 5 animation frames"
echo "- Smooth transitions between animation states"
