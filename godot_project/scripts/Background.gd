extends Node2D
class_name Background

# Background properties
var texture: Texture2D
var background_position: Vector2 = Vector2.ZERO

# Node reference
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# Create sprite if it doesn't exist
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)

	# Set sprite position to center background properly
	sprite.position = Vector2.ZERO

func set_texture(texture_path: String):
	# Try to load the texture, create fallback if not found
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path)
	else:
		# Create a simple colored fallback texture at the target game size
		var image = Image.create(920, 950, false, Image.FORMAT_RGB8)
		if texture_path.contains("menu"):
			image.fill(Color(0.2, 0.3, 0.6)) # Blue for menu
		elif texture_path.contains("highscore"):
			image.fill(Color(0.3, 0.2, 0.4)) # Purple for high score
		else:
			image.fill(Color(0.1, 0.1, 0.2)) # Dark blue for game

		texture = ImageTexture.new()
		texture.set_image(image)
		print("Created fallback background for: " + texture_path)

	if sprite and texture:
		sprite.texture = texture
		# Center the sprite
		sprite.centered = true
		# Position sprite at center of viewport
		sprite.position = Vector2(460, 475) # Half of 920x950

		# Scale background to exactly match target game size (920x950)
		var target_size = Vector2(920, 950)
		var texture_size = Vector2(texture.get_width(), texture.get_height())
		if texture_size.x > 0 and texture_size.y > 0:
			var scale_factor = Vector2(
				target_size.x / texture_size.x,
				target_size.y / texture_size.y
			)
			sprite.scale = scale_factor

func draw_background():
	# In Godot, drawing is handled automatically by the sprite
	# This function exists for compatibility with the original API
	if sprite and texture:
		sprite.visible = true
	else:
		if sprite:
			sprite.visible = false

func update_scaling():
	# Call this after window setup to ensure proper scaling
	if sprite and texture:
		var target_size = Vector2(920, 950)
		var texture_size = Vector2(texture.get_width(), texture.get_height())
		if texture_size.x > 0 and texture_size.y > 0:
			var scale_factor = Vector2(
				target_size.x / texture_size.x,
				target_size.y / texture_size.y
			)
			sprite.scale = scale_factor
			sprite.position = Vector2(460, 475) # Center of 920x950
