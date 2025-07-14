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
var glow_animation: float = 0.0
var glow_speed: float = 4.0
var rotation_speed: float = 2.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var glow_sprite: Sprite2D = $GlowSprite

func _ready():
	# Set up collision layer and mask
	collision_layer = 16 # Life bubble refill layer
	collision_mask = 0 # Don't collide with anything

	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Set initial properties
	lifetime_timer = lifetime

	# Create glow effect sprite
	create_glow_effect()

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
		sprite.modulate = Color(0.4, 1.0, 0.6, 1.0) # Bright green tint for buff effect
		sprite.scale = Vector2(1.2, 1.2) # Slightly larger
	else:
		# Fallback to colored rectangle
		create_fallback_texture(Color(0.4, 1.0, 0.6, 1.0))

func load_full_restore_texture():
	"""Load texture for full restore"""
	if not sprite:
		print("ERROR: Sprite not available for full restore texture loading")
		return

	var texture_path = "res://assets/textures/bullets/bullet_pointBullethalfsize.png"
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.modulate = Color(1.0, 0.8, 0.2, 1.0) # Golden tint for full restore
		sprite.scale = Vector2(1.5, 1.5) # Make it bigger
	else:
		# Fallback to colored rectangle
		create_fallback_texture(Color(1.0, 0.8, 0.2, 1.0))

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
	# Update animation timers
	glow_animation += delta * glow_speed

	# Update glow effect
	if glow_sprite:
		# Pulsing glow effect
		var glow_intensity = 0.4 + sin(glow_animation) * 0.2
		if is_full_restore:
			glow_sprite.modulate = Color(1.0, 0.6, 0.1, glow_intensity) # Golden glow
		else:
			glow_sprite.modulate = Color(0.2, 1.0, 0.4, glow_intensity) # Green glow

		# Rotate the glow for extra effect
		glow_sprite.rotation += delta * rotation_speed

	# Rotating the main sprite for buff effect
	if sprite:
		sprite.rotation += delta * rotation_speed * 0.5

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
			if glow_sprite:
				glow_sprite.visible = sprite.visible

	# Handle flash effect
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0 and sprite:
			if is_full_restore:
				sprite.modulate = Color(1.0, 0.8, 0.2, 1.0)
			else:
				sprite.modulate = Color(0.4, 1.0, 0.6, 1.0)

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
		# Play collection effect with enhanced visuals
		flash_timer = flash_duration

		# Create collection burst effect
		create_collection_effect()

		if sprite:
			sprite.modulate = Color.WHITE
		if glow_sprite:
			glow_sprite.modulate = Color.WHITE

		# Add score
		var main = get_node("/root/Main")
		if main and main.has_method("add_score"):
			var score_value = 100 if is_full_restore else 50
			main.add_score(score_value)

		# Delay removal slightly for effect to show
		var tween = create_tween()
		tween.tween_interval(0.1)
		tween.tween_callback(queue_free)

func create_collection_effect():
	"""Create a burst effect when collected"""
	# Create multiple small particles that spread out
	for i in range(8):
		var particle = Sprite2D.new()
		var particle_texture = create_particle_texture()
		particle.texture = particle_texture

		if is_full_restore:
			particle.modulate = Color(1.0, 0.8, 0.2, 0.8) # Golden particles
		else:
			particle.modulate = Color(0.4, 1.0, 0.6, 0.8) # Green particles

		particle.scale = Vector2(0.5, 0.5)
		get_parent().add_child(particle)
		particle.global_position = global_position

		# Animate particles spreading out
		var angle = (i * 2 * PI) / 8
		var direction = Vector2(cos(angle), sin(angle))
		var target_pos = global_position + direction * 30

		var tween = create_tween()
		tween.parallel().tween_property(particle, "global_position", target_pos, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(particle, "scale", Vector2.ZERO, 0.5)
		tween.tween_callback(particle.queue_free)

func create_particle_texture() -> Texture2D:
	"""Create a small particle texture for the collection effect"""
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)

	# Create a small bright circle
	for x in range(8):
		for y in range(8):
			var center = Vector2(4, 4)
			var distance = Vector2(x, y).distance_to(center)

			if distance <= 3:
				var intensity = 1.0 - (distance / 3.0)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, intensity))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)

	var texture = ImageTexture.create_from_image(image)
	return texture

func load_initial_texture():
	"""Load initial texture based on current setup"""
	if is_full_restore:
		load_full_restore_texture()
	else:
		load_refill_texture()

func create_glow_effect():
	"""Create a glowing background effect"""
	if not glow_sprite:
		glow_sprite = Sprite2D.new()
		glow_sprite.name = "GlowSprite"
		add_child(glow_sprite)
		# Put glow behind the main sprite
		move_child(glow_sprite, 0)

	# Create a glowing circle texture
	var glow_texture = create_glow_texture()
	glow_sprite.texture = glow_texture
	glow_sprite.modulate = Color(0.2, 1.0, 0.4, 0.6) # Green glow
	glow_sprite.scale = Vector2(2.0, 2.0) # Make it bigger than the main sprite

func create_glow_texture() -> Texture2D:
	"""Create a soft glowing circle texture"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)

	# Create a soft gradient circle
	for x in range(32):
		for y in range(32):
			var center = Vector2(16, 16)
			var distance = Vector2(x, y).distance_to(center)

			if distance <= 15:
				# Soft gradient from center to edge
				var intensity = 1.0 - (distance / 15.0)
				intensity = intensity * intensity # Square for softer falloff
				var alpha = intensity * 0.5
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)

	var texture = ImageTexture.create_from_image(image)
	return texture
