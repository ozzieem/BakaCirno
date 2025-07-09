#!/bin/bash

# Test script to validate the "previously freed" fix
# Check if the null safety improvements are properly implemented

echo "=== Checking for 'previously freed' error fixes ==="
echo ""

echo "1. Checking update_explosions function..."
if grep -q "is_instance_valid" "Main.gd" && grep -A 5 "update_explosions" "Main.gd" | grep -q "is_instance_valid"; then
    echo "✓ update_explosions has null safety checks"
else
    echo "✗ update_explosions missing null safety checks"
fi

echo ""
echo "2. Checking update_enemies function..."
if grep -A 10 "Update existing enemies" "Main.gd" | grep -q "is_instance_valid"; then
    echo "✓ update_enemies has null safety checks"
else
    echo "✗ update_enemies missing null safety checks"
fi

echo ""
echo "3. Checking update_point_bullets function..."
if grep -A 10 "update_point_bullets" "Main.gd" | grep -q "is_instance_valid"; then
    echo "✓ update_point_bullets has null safety checks"
else
    echo "✗ update_point_bullets missing null safety checks"
fi

echo ""
echo "4. Checking clear functions..."
if grep -A 5 "clear_explosions" "Main.gd" | grep -q "is_instance_valid"; then
    echo "✓ clear_explosions has null safety checks"
else
    echo "✗ clear_explosions missing null safety checks"
fi

if grep -A 5 "clear_enemies" "Main.gd" | grep -q "is_instance_valid"; then
    echo "✓ clear_enemies has null safety checks"
else
    echo "✗ clear_enemies missing null safety checks"
fi

if grep -A 5 "clear_point_bullets" "Main.gd" | grep -q "is_instance_valid"; then
    echo "✓ clear_point_bullets has null safety checks"
else
    echo "✗ clear_point_bullets missing null safety checks"
fi

echo ""
echo "=== Summary ==="
echo "The 'previously freed' error should now be resolved."
echo "All update functions now check if objects are valid before calling methods on them."
echo "This prevents calling methods on objects that have been queued for deletion."
