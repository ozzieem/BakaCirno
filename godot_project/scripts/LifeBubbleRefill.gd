extends Area2D
class_name LifeBubbleRefill

# Movement properties
var movement_speed: float = 100.0
var lifetime: float = 15.0 # Despawn after 15 seconds
var lifetime_timer: float = 0.0

# Refill properties
var refill_amount: int = 1
var is_full_restore: bool = false

# Visual properties
var flash_timer: float = 0.0
var flash_duration: float = 0.1
var blink_timer: float = 0.0
var blink_duration: float = 0.5

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Set up collision layer and mask
	collision_layer = 16 # Life bubble refill layer
	collision_mask = 0 # Don't collide with anything

	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Set initial properties
	lifetime_timer = lifetime

	# Load appropriate texture based on refill type
	# Use call_deferred to ensure setup_refill has been called first
	call_deferred("load_initial_texture")

func load_refill_texture():
	"""Load texture for regular refill"""
	if not sprite:
		print("ERROR: Sprite not available for refill texture loading")
		return

	var texture_path = "res://assets/textures/bullets/bullet_pointBullethalfsize.png"
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.modulate = Color.CYAN # Blue tint for refill
	else:
		# Fallback to colored rectangle
		create_fallback_texture(Color.CYAN)

func load_full_restore_texture():
	"""Load texture for full restore"""
	if not sprite:
		print("ERROR: Sprite not available for full restore texture loading")
		return

	var texture_path = "res://assets/textures/bullets/bullet_pointBullethalfsize.png"
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.modulate = Color.GOLD # Gold tint for full restore
		sprite.scale = Vector2(1.5, 1.5) # Make it bigger
	else:
		# Fallback to colored rectangle
		create_fallback_texture(Color.GOLD)

func create_fallback_texture(color: Color):
	"""Create a fallback colored rectangle texture"""
	if not sprite:
		print("ERROR: Sprite not available for fallback texture creation")
		return

	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

func setup_refill(amount: int, full_restore: bool = false):
	"""Setup the refill properties"""
	refill_amount = amount
	is_full_restore = full_restore

	# If sprite is not ready yet, defer the texture loading
	if not sprite:
		call_deferred("load_textures_deferred")
	else:
		if is_full_restore:
			load_full_restore_texture()
		else:
			load_refill_texture()

func load_textures_deferred():
	"""Load textures after the node is ready"""
	if is_full_restore:
		load_full_restore_texture()
	else:
		load_refill_texture()

func _process(delta):
	# Update lifetime
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		queue_free()
		return

	# Handle blinking when approaching expiry
	if lifetime_timer < 3.0 and sprite:
		blink_timer += delta
		if blink_timer >= blink_duration:
			blink_timer = 0.0
			sprite.visible = !sprite.visible

	# Handle flash effect
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0 and sprite:
			if is_full_restore:
				sprite.modulate = Color.GOLD
			else:
				sprite.modulate = Color.CYAN

	# Move downward
	position.y += movement_speed * delta

	# Remove if off screen
	if position.y > get_viewport().get_visible_rect().size.y + 50:
		queue_free()

func _on_body_entered(body):
	"""Handle collision with player"""
	if body.is_in_group("player") or body.has_method("refill_life_bubble"):
		collect_refill(body)

func _on_area_entered(area):
	"""Handle collision with player area"""
	var parent = area.get_parent()
	if parent and (parent.is_in_group("player") or parent.has_method("refill_life_bubble")):
		collect_refill(parent)

func collect_refill(player):
	"""Collect the refill and apply to player"""
	if not player.has_method("refill_life_bubble"):
		return

	var success = false
	if is_full_restore:
		success = player.restore_life_bubble_full()
	else:
		success = player.refill_life_bubble(refill_amount)

	if success:
		# Play collection effect
		flash_timer = flash_duration
		if sprite:
			sprite.modulate = Color.WHITE

		# Add score
		var main = get_node("/root/Main")
		if main and main.has_method("add_score"):
			var score_value = 100 if is_full_restore else 50
			main.add_score(score_value)

		# Remove the refill
		queue_free()
