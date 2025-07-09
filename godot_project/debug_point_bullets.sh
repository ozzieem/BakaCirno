#!/bin/bash

# Simple debug script to check if our main functions exist

echo "=== Point Bullet Debug Check ==="
echo ""

echo "Checking if convert_enemy_bullets_to_points function exists..."
if grep -q "func convert_enemy_bullets_to_points" "Main.gd"; then
    echo "✓ Function exists"
else
    echo "✗ Function missing"
fi

echo ""
echo "Checking if get_bullets functions exist in pattern classes..."
if grep -q "func get_bullets" "CircleShots.gd"; then
    echo "✓ CircleShots get_bullets exists"
else
    echo "✗ CircleShots get_bullets missing"
fi

if grep -q "func get_bullets" "RandomShots.gd"; then
    echo "✓ RandomShots get_bullets exists"
else
    echo "✗ RandomShots get_bullets missing"
fi

echo ""
echo "Checking if PointBullet.tscn exists..."
if [ -f "PointBullet.tscn" ]; then
    echo "✓ PointBullet.tscn exists"
else
    echo "✗ PointBullet.tscn missing - this is the problem!"
    echo "   Need to create PointBullet.tscn scene file"
fi

echo ""
echo "Checking if point bullet texture exists..."
if [ -f "assets/textures/pointBullethalfsize.png" ]; then
    echo "✓ Point bullet texture exists"
else
    echo "✗ Point bullet texture missing - will use fallback"
fi

echo ""
echo "If point bullets still don't work, the issue might be:"
echo "1. PointBullet.tscn scene file doesn't exist"
echo "2. Enemies die before they spawn bullets"
echo "3. Bullet patterns aren't working correctly"
echo "4. Point bullets are spawning but not visible"
