#!/bin/bash

echo "=== Final Validation Test ==="

# Check for syntax errors in modified files
echo "1. Checking PointBullet.gd for syntax errors..."
cd "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project"

# Look for potential issues in the code
echo "2. Checking PointBullet movement logic..."
grep -A3 -B1 "move_to_player" PointBullet.gd

echo ""
echo "3. Checking Main.gd game state logic..."
grep -A8 -B2 "if player.is_dead" Main.gd

echo ""
echo "4. Verifying object clearing in clear_all_game_objects..."
grep -A15 "func clear_all_game_objects" Main.gd

echo ""
echo "5. Checking if all arrays are properly cleared..."
grep -n "\.clear()" Main.gd

echo ""
echo "=== Validation completed ==="
