extends Node2D
class_name Explosion

# Animation properties
var current_frame: int = 1
var animation_elapsed: float = 0.0
var animation_delay: float = 0.1 # 100ms converted to seconds
var frame_width: int = 134
var max_frames: int = 10
var is_visible: bool = true

# Texture and sprite
var texture: Texture2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# Load explosion texture
	texture = load("res://assets/textures/effects/fx_EnemyExplosion.png")
	if sprite and texture:
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(frame_width * current_frame, 0, frame_width, texture.get_height())

		# Ensure proper transparency handling
		sprite.self_modulate = Color.WHITE # Ensure no color tinting
		sprite.modulate = Color.WHITE # Ensure no transparency override

		print("Explosion texture loaded: ", texture.get_size())

	# Adjust position to align with enemy position
	position = Vector2(position.x, position.y)

func update_animation(delta: float):
	if not is_visible:
		return

	animation_elapsed += delta

	if animation_elapsed >= animation_delay:
		current_frame += 1
		animation_elapsed = 0.0

		if current_frame >= max_frames:
			is_visible = false
			current_frame = 0
			return

		# Update sprite region to show current frame
		if sprite and texture:
			sprite.region_rect = Rect2(frame_width * current_frame, 0, frame_width, texture.get_height())

func _process(delta):
	update_animation(delta)

	# Auto-destroy when animation finishes
	if not is_visible:
		queue_free()
