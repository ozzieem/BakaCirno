extends Area2D
class_name Bullet

# Bullet properties
var velocity: Vector2 = Vector2.ZERO
var speed: float = 10.0
var rotation_speed: float = 5.0
var is_visible: bool = true

# Sprite and collision
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Screen bounds
var screen_size: Vector2

# Custom behavior system
var custom_behaviors: Dictionary = {}

func _ready():
	# Connect collision signal
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Get screen size
	screen_size = get_viewport().get_visible_rect().size

	# Set default collision layers and masks (will be overridden by set_bullet_type)
	collision_layer = 2 # Default enemy bullet layer
	collision_mask = 1 # Default player layer

func setup_bullet(texture: Texture2D, start_position: Vector2, bullet_velocity: Vector2, bullet_speed: float = 10.0):
	position = start_position
	velocity = bullet_velocity.normalized() * bullet_speed
	speed = bullet_speed

	if sprite and texture:
		sprite.texture = texture

	# Setup collision shape based on texture size
	if collision_shape and collision_shape.shape is RectangleShape2D and texture:
		var rect_shape = collision_shape.shape as RectangleShape2D
		rect_shape.size = Vector2(texture.get_width(), texture.get_height())

func _process(delta):
	if not is_visible:
		queue_free()
		return

	update_movement(delta)
	update_rotation(delta)
	check_screen_bounds()

func update_movement(delta):
	position += velocity * delta

func update_rotation(delta):
	# Only rotate enemy bullets (layer 2), not player bullets (layer 3)
	if collision_layer == 2:
		rotation += rotation_speed * delta

func check_screen_bounds():
	# Remove bullet if it goes off screen
	if position.x < -20 or position.x > screen_size.x + 20 or \
	   position.y < -20 or position.y > screen_size.y + 20:
		is_visible = false

func _on_area_entered(area):
	# Handle collision with other areas
	# Player bullets (layer 3) hitting enemies (layer 8)
	if collision_layer == 3 and area.collision_layer == 8:
		if area.has_method("take_damage"):
			area.take_damage(10, false) # Basic damage for player bullets
		is_visible = false
	# Enemy bullets (layer 2) hitting player collision areas (layer 1)
	elif collision_layer == 2 and area.collision_layer == 1:
		is_visible = false

func _on_body_entered(body):
	# Handle collision with player body - only for enemy bullets
	# Only enemy bullets (layer 2) can damage the player
	if body.has_method("take_damage") and collision_layer == 2:
		body.take_damage()
		is_visible = false
	else:
		is_visible = false # Still destroy the bullet, but don't damage player

func set_bullet_type(is_player_bullet: bool):
	# Set collision layer based on bullet type
	if is_player_bullet:
		collision_layer = 3 # Player bullet layer
		collision_mask = 8 # Can hit enemies only (layer 8)
		rotation_speed = 0.0 # Player bullets don't rotate
	else:
		collision_layer = 2 # Enemy bullet layer
		collision_mask = 1 # Can hit player only (layer 1)

# Custom behavior system
func set_custom_behavior(behavior_name: String, value):
	"""Set a custom behavior parameter"""
	custom_behaviors[behavior_name] = value

func get_custom_behavior(behavior_name: String, default_value = null):
	"""Get a custom behavior parameter"""
	return custom_behaviors.get(behavior_name, default_value)

func has_custom_behavior(behavior_name: String) -> bool:
	"""Check if bullet has a custom behavior"""
	return behavior_name in custom_behaviors
