#!/bin/bash

# Test Script for BakaCirno Godot Migration
# This script helps verify that sprite animation and background placement are working correctly

echo "=== BakaCirno Godot Test Guide ==="
echo ""

echo "1. SPRITE ANIMATION TESTING:"
echo "   - Open the Godot project"
echo "   - Run the Main scene (F6)"
echo "   - Check that the player sprite:"
echo "     • Shows the idle animation when not moving"
echo "     • Shows the right animation when moving right"
echo "     • Shows the left animation when moving left"
echo "     • Shows the explosion animation when hit"
echo ""

echo "2. BACKGROUND TESTING:"
echo "   - The backgrounds should be properly scaled and positioned"
echo "   - Menu background should show behind the menu text"
echo "   - Game background should show during gameplay"
echo "   - High score background should show in high score state"
echo ""

echo "3. MANUAL TESTING STEPS:"
echo "   a. Start the game and verify menu background is visible"
echo "   b. Press Enter to start - game background should appear"
echo "   c. Use arrow keys to move the player and watch sprite changes"
echo "   d. Let an enemy hit you to see death animation"
echo "   e. Check that backgrounds stay behind other game objects"
echo ""

echo "4. DEBUGGING TIPS:"
echo "   - Check the Remote Inspector in Godot to see node hierarchy"
echo "   - Verify z_index values: backgrounds should be -100"
echo "   - Check that sprite.region_enabled is true for player"
echo "   - Verify texture paths are correct in assets folder"
echo ""

echo "5. SPRITE IMPORT SETTINGS:"
echo "   - Ensure sprites are imported as '2D Pixel' not '2D'"
echo "   - Disable 'Mipmaps' for pixel-perfect sprites"
echo "   - Set 'Filter' to OFF for crisp pixel art"
echo ""

echo "6. FALLBACK BEHAVIOR:"
echo "   - If textures are missing, colored rectangles should appear"
echo "   - Player: cyan=idle, light blue=movement, red=explosion"
echo "   - Backgrounds: blue=menu, purple=highscore, dark blue=game"
echo ""

echo "Run this test after making any changes to verify functionality."
echo "=== End Test Guide ==="
