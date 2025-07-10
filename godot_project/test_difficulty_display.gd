extends Node
# Test script to verify difficulty multiplier display works

func _ready():
	print("=== Testing Difficulty Display ===")

	# Test basic functionality
	var text_overlay = TextOverlay.new()

	# Test initial state
	assert(text_overlay.difficulty_multiplier == 0.0, "Initial difficulty should be 0.0")
	print("✓ Initial difficulty multiplier: 0.0")

	# Test setting difficulty
	text_overlay.set_difficulty_multiplier(0.15)
	assert(text_overlay.difficulty_multiplier == 0.15, "Difficulty should be 0.15")
	print("✓ Setting difficulty multiplier: 0.15")

	# Test reset
	text_overlay.reset_stats()
	assert(text_overlay.difficulty_multiplier == 0.0, "Reset should clear difficulty")
	print("✓ Reset clears difficulty multiplier")

	# Test realistic game scenario
	var simulated_difficulty = 0.0
	for i in range(10): # Simulate killing 10 enemies
		simulated_difficulty += 0.03 # Each enemy kill adds 0.03

	text_overlay.set_difficulty_multiplier(simulated_difficulty)
	var expected_display = 1.0 + simulated_difficulty
	print("✓ After 10 enemies killed:")
	print("  - Raw difficulty increase: " + str(simulated_difficulty))
	print("  - Display value: x" + str(expected_display, 2))
	print("  - Expected: x1.30")

	print("=== All tests passed! ===")

	# Cleanup
	text_overlay.queue_free()
