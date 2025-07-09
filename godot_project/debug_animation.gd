# Debug Animation System for Player
# Add this code to Player.gd to debug animation issues

# Add this function to help debug sprite region calculations
func debug_animation_info():
	if sprite and current_anim_texture:
		var frame_info = get_frame_info_for_texture(current_anim_texture)
		print("Current Animation Debug:")
		print("  Texture: ", current_anim_texture.resource_path if current_anim_texture else "None")
		print("  Current Frame: ", current_frame)
		print("  Frame Info: ", frame_info)
		print("  Region Rect: ", sprite.region_rect)
		print("  Region Enabled: ", sprite.region_enabled)
		print("  Sprite Position: ", sprite.position)
		print("  Player Position: ", position)

# Add this to _ready() function for initial debug
# debug_animation_info()

# Add this to animate() function to debug frame changes
# if current_frame == 0:  # Only print on frame 0 to avoid spam
#     debug_animation_info()

# Common Animation Issues and Solutions:
# 1. Sprite not changing: Check that region_enabled is true
# 2. Wrong frame size: Verify frame_info width/height values
# 3. Animation too fast/slow: Adjust animation_delay value
# 4. Texture not loading: Check texture paths and fallback creation
# 5. Sprite positioning: Ensure sprite.centered is set appropriately
