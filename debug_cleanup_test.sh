#!/bin/bash

echo "=== Debug Print Cleanup Verification ==="

cd "e:/Users/Ozzie/Documents/--DNR--/Github repos/BakaCirno/godot_project"

echo "Remaining print statements in core game files:"
echo ""

echo "Main.gd:"
grep -n "print(" Main.gd | head -10

echo ""
echo "Player.gd:"
grep -n "print(" Player.gd

echo ""
echo "Bullet.gd:"
grep -n "print(" Bullet.gd

echo ""
echo "Enemy.gd:"
grep -n "print(" Enemy.gd

echo ""
echo "PointBullet.gd:"
grep -n "print(" PointBullet.gd

echo ""
echo "=== Summary ==="
echo "Total print statements in core files:"
(grep -c "print(" Main.gd Player.gd Bullet.gd Enemy.gd PointBullet.gd 2>/dev/null | awk -F: '{total += $2} END {print total}') || echo "0"

echo ""
echo "Print cleanup completed!"
