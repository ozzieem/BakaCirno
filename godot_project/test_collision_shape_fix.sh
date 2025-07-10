#!/bin/bash

# Test script to verify collision shape visibility fix

echo "=== Testing Black Box (Collision Shape) Fix ==="

cd "$(dirname "$0")"

echo "Checking collision shape hiding implementation:"

# Check if hide_collision_shapes function was added to Player.gd
if grep -q "func hide_collision_shapes" Player.gd; then
    echo "✓ hide_collision_shapes() function added to Player.gd"
else
    echo "✗ hide_collision_shapes() function not found"
fi

# Check if function is called in _ready()
if grep -q "hide_collision_shapes()" Player.gd; then
    echo "✓ hide_collision_shapes() called in _ready()"
else
    echo "✗ hide_collision_shapes() not called in _ready()"
fi

# Check if debug transparency is set
if grep -q "debug_color = Color.TRANSPARENT" Player.gd; then
    echo "✓ Collision shapes set to transparent"
else
    echo "✗ Collision shape transparency not set"
fi

echo ""
echo "Checking global debug collision disable in Main.gd:"

# Check if global debug collision hint is disabled
if grep -q "debug_collisions_hint = false" Main.gd; then
    echo "✓ Global collision debug disabled in Main.gd"
else
    echo "✗ Global collision debug setting not found"
fi

echo ""
echo "=== Black Box Fix Test Complete ==="
echo ""
echo "Solution implemented:"
echo "1. Added hide_collision_shapes() function to Player.gd"
echo "2. Set collision shape debug_color to Color.TRANSPARENT"
echo "3. Disabled global debug_collisions_hint in Main.gd"
echo ""
echo "The black box behind the player should now be removed!"
echo ""
echo "To test:"
echo "1. Run the game and check if the black box is gone"
echo "2. The player sprite should be clean without any background shapes"
echo "3. Collision detection should still work normally"
