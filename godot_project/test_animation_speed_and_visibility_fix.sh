#!/bin/bash

# Test script to verify animation speed and player visibility fixes

echo "=== Testing Animation Speed and Player Visibility Fixes ==="

cd "$(dirname "$0")"

echo "Checking animation timing updates in Player.gd:"

# Check regular animation delay
if grep -q "animation_delay: float = 0.2 # Slowed down" Player.gd; then
    echo "✓ Regular animation delay slowed to 0.2 seconds (was 0.12)"
else
    echo "✗ Regular animation delay not updated"
fi

# Check death animation delay
if grep -q "death_animation_delay: float = 0.08 # Slowed down" Player.gd; then
    echo "✓ Death animation delay slowed to 0.08 seconds (was 0.04)"
else
    echo "✗ Death animation delay not updated"
fi

echo ""
echo "Checking player visibility management in Main.gd:"

# Check menu state player visibility
if grep -q "player.visible = true # Show player in menu" Main.gd; then
    echo "✓ Player visible in MENU state"
else
    echo "✗ Player visibility not set for MENU state"
fi

# Check playing state player visibility
if grep -q "player.visible = true # Show player during gameplay" Main.gd; then
    echo "✓ Player visible in PLAYING state"
else
    echo "✗ Player visibility not set for PLAYING state"
fi

# Check game over state player visibility
if grep -q "player.visible = false # Hide player during game over screen" Main.gd; then
    echo "✓ Player hidden in GAME_OVER state"
else
    echo "✗ Player visibility not set for GAME_OVER state"
fi

echo ""
echo "=== Animation and Visibility Fix Test Complete ==="
echo ""
echo "Changes made:"
echo "1. Animation Speed:"
echo "   - Regular animations: 120ms → 200ms (slower, more visible)"
echo "   - Death animation: 40ms → 80ms (slower explosion)"
echo ""
echo "2. Player Visibility:"
echo "   - MENU state: Player visible"
echo "   - PLAYING state: Player visible"
echo "   - GAME_OVER state: Player hidden"
echo ""
echo "To test:"
echo "1. Run the game and observe that animations are slower and easier to see"
echo "2. Play until you die and verify the player disappears on game over screen"
echo "3. Return to menu and verify player is visible again"
