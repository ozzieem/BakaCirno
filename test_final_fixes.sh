#!/bin/bash

echo "=== Testing Point Bullet Speed and Game Over Clearing ==="

# Check point bullet speed changes
echo "1. Checking Point Bullet speed improvements..."
grep -n "x_move_speed.*=" "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project/PointBullet.gd"
grep -n "y_move_speed.*=" "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project/PointBullet.gd"

echo ""
echo "2. Checking for clear_all_game_objects function..."
grep -n "clear_all_game_objects" "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project/Main.gd"

echo ""
echo "3. Checking GAME_OVER state transition with clearing..."
grep -A5 -B2 "current_state = GameState.GAME_OVER" "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project/Main.gd"

echo ""
echo "4. Verifying all clear functions are defined..."
echo "clear_enemies:"
grep -n "func clear_enemies" "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project/Main.gd"
echo "clear_point_bullets:"
grep -n "func clear_point_bullets" "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project/Main.gd"
echo "clear_explosions:"
grep -n "func clear_explosions" "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project/Main.gd"
echo "clear_all_game_objects:"
grep -n "func clear_all_game_objects" "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project/Main.gd"

echo ""
echo "=== Test completed ==="
