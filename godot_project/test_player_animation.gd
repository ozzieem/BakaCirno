extends Node

# Test script to verify player animation functionality

func _ready():
	print("=== Player Animation Test ===")

	# Create a player instance to test
	var player = preload("res://Player.tscn").instantiate()
	add_child(player)

	# Wait for player to be ready
	await get_tree().process_frame

	# Test animation frame counts
	print("Testing animation frame counts:")
	print("- Idle animation frames: ", player.get_frame_count_for_texture(player.idle_anim_texture))
	print("- Right animation frames: ", player.get_frame_count_for_texture(player.right_anim_texture))
	print("- Left animation frames: ", player.get_frame_count_for_texture(player.left_anim_texture))
	print("- Explosion animation frames: ", player.get_frame_count_for_texture(player.explosion_anim_texture))

	# Test frame info
	print("\nTesting frame info:")
	var idle_info = player.get_frame_info_for_texture(player.idle_anim_texture)
	print("- Idle frame size: ", idle_info.width, "x", idle_info.height)

	var right_info = player.get_frame_info_for_texture(player.right_anim_texture)
	print("- Right frame size: ", right_info.width, "x", right_info.height)

	var left_info = player.get_frame_info_for_texture(player.left_anim_texture)
	print("- Left frame size: ", left_info.width, "x", left_info.height)

	# Test animation timing
	print("\nTesting animation timing:")
	print("- Animation delay: ", player.animation_delay, " seconds")
	print("- Current frame: ", player.current_frame)

	# Simulate some animation frames
	print("\nSimulating animation frames:")
	for i in range(10):
		player.animate(player.animation_delay + 0.01) # Add small extra time
		print("Frame ", i, " -> Current frame: ", player.current_frame)
		if i == 5:
			print("  (Should have looped back to 0 for idle animation)")
		await get_tree().process_frame

	print("\n=== Animation Test Complete ===")

	# Clean up
	player.queue_free()
