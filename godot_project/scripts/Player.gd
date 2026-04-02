extends CharacterBody2D
class_name Player

# Animation textures
var right_anim_texture: Texture2D
var left_anim_texture: Texture2D
var idle_anim_texture: Texture2D
var explosion_anim_texture: Texture2D
var current_anim_texture: Texture2D

# Bullet textures
var bullet_texture: Texture2D
var power_shot_texture: Texture2D
var current_bullet_texture: Texture2D

# Player properties
var movement_speed: float = 250.0 # pixels per second - base movement speed
var precision_movement_speed: float = 120.0 # pixels per second - precision movement speed
var bullet_speed: int = 240 # pixels per second
var max_bullet_delay: float = 0.3 # seconds between shots (slower auto-fire)
var auto_fire: bool = true # Enable automatic firing

# Player states
var is_colliding: bool = false
var is_dead: bool = false
var power_shot: bool = false
var sound_played: bool = false
var stop_movement: bool = true
var can_shoot: bool = false # New flag to control shooting permission
var is_invincible: bool = false # Debug invincibility mode

# Life-bubble system (now permanent)
var life_bubble_active: bool = true # Always active now
var life_bubble_health: int = 3
var max_life_bubble_health: int = 3
var life_bubble_recovery_time: float = 2.0 # Time before bubble starts recovering
var life_bubble_recovery_timer: float = 0.0
var life_bubble_flash_timer: float = 0.0
var life_bubble_flash_duration: float = 0.1

# Power shot toggle cooldown
var power_shot_toggle_cooldown: float = 0.0
var power_shot_cooldown_time: float = 0.2 # 200ms cooldown to prevent rapid toggling

# Animation properties
var current_frame: int = 0
var animation_elapsed: float = 0.0
var animation_delay: float = 0.2 # Slowed down from 120ms to 200ms for better visibility
var death_animation_delay: float = 0.16 # Slowed down from 40ms to 80ms for death animation
var death_timer: float = 0.0
var death_duration: float = 1.5 # 1500ms converted to seconds

# Bullet management
var bullets: Array[Bullet] = []

# Bullet delay timer
var bullet_delay_timer: float = 0.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var bullet_collision_area: Area2D = $BulletCollisionArea
@onready var point_collision_area: Area2D = $PointCollisionArea

# Life bubble visual nodes
@onready var life_bubble_container: Node2D = $LifeBubbleContainer
@onready var bubble_sprites: Array[Sprite2D] = []

# Visual bubble properties
var bubble_rotation_speed: float = 1.0
var bubble_orbit_radius: float = 45.0
var bubble_scale_animation: float = 0.0
var bubble_pulse_speed: float = 3.0

# Sound manager
var sound_manager: Sound

# Screen bounds
var screen_size: Vector2

func _ready():
	# Add to player group
	add_to_group("player")

	# Get screen size
	screen_size = get_viewport().get_visible_rect().size

	# Set initial position
	position = Vector2(425, 725)

	# Initialize bullet delay timer
	bullet_delay_timer = max_bullet_delay

	# Load assets
	load_player_assets()

	# Setup collision
	setup_collision()

	# Setup life bubble visuals
	setup_life_bubble_visuals()

	# Hide collision shapes (disable debug drawing)
	hide_collision_shapes()

	print("Player initialized at position: ", position)

func set_sound_manager(sound_mgr: Sound):
	sound_manager = sound_mgr

func load_player_assets():
	# Load animation textures with fallbacks
	idle_anim_texture = load_texture_with_fallback("res://assets/textures/player/player_idlecirno.png", Color.CYAN)
	right_anim_texture = load_texture_with_fallback("res://assets/textures/player/player_rightcirno.png", Color.LIGHT_BLUE)
	left_anim_texture = load_texture_with_fallback("res://assets/textures/player/player_leftcirno.png", Color.LIGHT_BLUE)
	explosion_anim_texture = load_texture_with_fallback("res://assets/textures/player/player_blueexplosion.png", Color.RED)

	# Load bullet textures
	bullet_texture = load_texture_with_fallback("res://assets/textures/bullets/bullet_playershot1mini.png", Color.YELLOW)
	power_shot_texture = load_texture_with_fallback("res://assets/textures/bullets/bullet_playershot1.png", Color.ORANGE)

	# Set initial animation
	current_anim_texture = idle_anim_texture
	if sprite and current_anim_texture:
		sprite.texture = current_anim_texture
		sprite.region_enabled = true
		sprite.centered = true

		# Ensure proper transparency handling
		sprite.self_modulate = Color.WHITE # Ensure no color tinting
		sprite.modulate = Color.WHITE # Ensure no transparency override

		# Start with first frame of idle animation
		var frame_info = get_frame_info_for_texture(current_anim_texture)
		sprite.region_rect = Rect2(0, 0, frame_info.width, frame_info.height)

func load_texture_with_fallback(path: String, fallback_color: Color) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded_texture = load(path)
		print("Successfully loaded texture: ", path)
		return loaded_texture
	else:
		# Create a transparent fallback texture with RGBA format
		print("WARNING: Texture not found, creating fallback for: ", path)
		var image = Image.create(68, 128, false, Image.FORMAT_RGBA8)
		# Fill with transparent color (alpha = 0.8 to make fallback visible but not solid)
		var transparent_color = Color(fallback_color.r, fallback_color.g, fallback_color.b, 0.8)
		image.fill(transparent_color)
		var fallback_texture = ImageTexture.new()
		fallback_texture.set_image(image)
		print("Created RGBA fallback texture for: " + path)
		return fallback_texture

func setup_collision():
	# Set collision layers and masks
	collision_layer = 1 # Player layer
	collision_mask = 0 # Player doesn't collide with anything by default

	# Setup bullet collision area
	if bullet_collision_area:
		bullet_collision_area.collision_layer = 1
		bullet_collision_area.collision_mask = 2 # Detect enemy bullets only
		bullet_collision_area.area_entered.connect(_on_bullet_collision)
	else:
		print("WARNING: bullet_collision_area not found!")

	# Setup point collision area
	if point_collision_area:
		point_collision_area.collision_layer = 1
		point_collision_area.collision_mask = 4 + 16 # Detect point bullets and life bubble refills
		point_collision_area.area_entered.connect(_on_point_collision)
	else:
		print("WARNING: point_collision_area not found!")

func setup_life_bubble_visuals():
	"""Setup visual life bubble representations around the player"""
	# Create container if it doesn't exist
	if not life_bubble_container:
		life_bubble_container = Node2D.new()
		life_bubble_container.name = "LifeBubbleContainer"
		add_child(life_bubble_container)

	# Clear existing bubbles
	bubble_sprites.clear()
	for child in life_bubble_container.get_children():
		child.queue_free()

	# Create bubble sprites for each life bubble
	for i in range(max_life_bubble_health):
		var bubble_sprite = Sprite2D.new()

		# Create a circular bubble texture
		var bubble_texture = create_bubble_texture()
		bubble_sprite.texture = bubble_texture

		# Set initial properties
		bubble_sprite.scale = Vector2(0.8, 0.8)
		bubble_sprite.modulate = Color(0.4, 0.8, 1.0, 0.7) # Light blue with transparency

		# Position bubbles in a circle around the player
		var angle = (i * 2 * PI) / max_life_bubble_health
		var offset = Vector2(cos(angle), sin(angle)) * bubble_orbit_radius
		bubble_sprite.position = offset

		life_bubble_container.add_child(bubble_sprite)
		bubble_sprites.append(bubble_sprite)

func create_bubble_texture() -> Texture2D:
	"""Create a bubble texture programmatically"""
	var image = Image.create(24, 24, false, Image.FORMAT_RGBA8)

	# Create a circular bubble with gradient
	for x in range(24):
		for y in range(24):
			var center = Vector2(12, 12)
			var distance = Vector2(x, y).distance_to(center)

			if distance <= 11:
				# Inner bright circle
				if distance <= 8:
					var alpha = 0.6 - (distance / 8.0) * 0.3
					image.set_pixel(x, y, Color(0.7, 0.9, 1.0, alpha))
				# Outer ring
				else:
					var alpha = (11 - distance) / 3.0 * 0.4
					image.set_pixel(x, y, Color(0.5, 0.8, 1.0, alpha))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)

	var texture = ImageTexture.create_from_image(image)
	return texture

func hide_collision_shapes():
	# Disable debug drawing for collision shapes to prevent black boxes
	if collision_shape:
		collision_shape.debug_color = Color.TRANSPARENT

	# Hide collision shapes for bullet collision area
	if bullet_collision_area:
		var bullet_collision_shape = bullet_collision_area.get_node("CollisionShape2D")
		if bullet_collision_shape:
			bullet_collision_shape.debug_color = Color.TRANSPARENT

	# Hide collision shapes for point collision area
	if point_collision_area:
		var point_collision_shape = point_collision_area.get_node("CollisionShape2D")
		if point_collision_shape:
			point_collision_shape.debug_color = Color.TRANSPARENT

func _process(delta):
	if not stop_movement:
		handle_input(delta)

	# Auto-fire bullets continuously - only when allowed to shoot
	if auto_fire and not is_colliding and can_shoot:
		shoot()

	update_bullets(delta)
	boundary_check()

	# Update life-bubble system
	update_life_bubble(delta)

	# Update bubble visuals
	update_bubble_visuals(delta)

	if not is_colliding:
		animate(delta)
	else:
		death_animation(delta)
		death_timer += delta
		if death_timer >= death_duration:
			is_dead = true

	# Update bullet delay timer
	if bullet_delay_timer > 0:
		bullet_delay_timer -= delta

	# Update power shot toggle cooldown
	if power_shot_toggle_cooldown > 0:
		power_shot_toggle_cooldown -= delta

func handle_input(_delta):
	if is_colliding:
		return

	# Check for precision movement mode (holding shift slows down movement)
	var precision_mode = Input.is_action_pressed("precision_move")
	var current_speed = precision_movement_speed if precision_mode else movement_speed

	var input_vector = Vector2.ZERO
	var new_anim_texture = current_anim_texture

	# Movement input - build movement vector for smooth diagonal movement
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		new_anim_texture = right_anim_texture
	elif Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		new_anim_texture = left_anim_texture
	else:
		new_anim_texture = idle_anim_texture

	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1

	# Reset animation frame when switching animations
	if new_anim_texture != current_anim_texture:
		current_frame = 0
		animation_elapsed = 0.0
		current_anim_texture = new_anim_texture

	# Apply movement with proper normalization for diagonal movement
	if input_vector != Vector2.ZERO:
		# Normalize diagonal movement so it's not faster than cardinal movement
		input_vector = input_vector.normalized()
		velocity = input_vector * current_speed
	else:
		velocity = Vector2.ZERO

	# Apply the movement
	move_and_slide()

	# Power shot toggle - Space key toggles between normal and power shots (only during gameplay)
	if Input.is_action_just_pressed("power_shot_toggle") and can_shoot and power_shot_toggle_cooldown <= 0:
		power_shot = not power_shot
		power_shot_toggle_cooldown = power_shot_cooldown_time # Set cooldown
		print("Power shot mode: ", "ON" if power_shot else "OFF")

func shoot():
	# Choose bullet texture based on power shot
	current_bullet_texture = power_shot_texture if power_shot else bullet_texture

	# Decrease bullet delay timer
	if bullet_delay_timer > 0:
		bullet_delay_timer -= get_process_delta_time()

	# Check if we can shoot
	if bullet_delay_timer <= 0:
		# Play shoot sound
		if sound_manager:
			sound_manager.play_player_shoot(power_shot)

		# Create bullet
		var bullet = preload("res://scenes/Bullet.tscn").instantiate()
		get_parent().add_child(bullet)

		# Setup bullet
		var bullet_velocity = Vector2(0, -1) # Shoot upward
		# Spawn bullet at the front/top of the player sprite
		var bullet_spawn_position = position + Vector2(0, -50) # 50 pixels above player center
		bullet.setup_bullet(current_bullet_texture, bullet_spawn_position, bullet_velocity, bullet_speed)
		bullet.set_bullet_type(true) # Mark as player bullet
		bullets.append(bullet)

		# Reset delay timer
		bullet_delay_timer = max_bullet_delay

func update_bullets(delta):
	# Update each bullet (similar to C# version)
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			# Update bullet collision box (similar to C# boundingBox update)
			# This would be handled by the bullet's own collision system in Godot
			# Move bullet upward (bullet.position.Y -= bullet.speed in C#)
			bullet.position.y -= bullet_speed * delta

			# Keep bullets aligned with player X-axis (similar to C# version)
			# Bullets keep in range within player y-axis
			var difference = position - bullet.position
			difference = difference.normalized()
			bullet.position.x += difference.x * delta * 1000.0 # Convert milliseconds factor from C#

	# Remove bullets that are no longer visible (same as C# version)
	for i in range(bullets.size() - 1, -1, -1):
		var bullet = bullets[i]
		if not bullet or not is_instance_valid(bullet) or not bullet.is_visible:
			if bullet and is_instance_valid(bullet):
				bullet.queue_free()
			bullets.remove_at(i)

func animate(delta):
	animation_elapsed += delta

	if animation_elapsed >= animation_delay:
		current_frame += 1
		animation_elapsed = 0.0

		# Get frame count based on current animation
		var frame_count = get_frame_count_for_texture(current_anim_texture)
		if current_frame >= frame_count:
			current_frame = 0

	# Update sprite with current frame
	if sprite and current_anim_texture:
		sprite.texture = current_anim_texture
		sprite.region_enabled = true
		# Update sprite region based on current frame and animation
		var frame_info = get_frame_info_for_texture(current_anim_texture)
		sprite.region_rect = Rect2(frame_info.width * current_frame, 0, frame_info.width, frame_info.height)

func death_animation(delta):
	stop_movement = true

	if not sound_played:
		if sound_manager:
			sound_manager.play_player_death()
		sound_played = true

	# Switch to explosion animation and reset animation if needed
	if current_anim_texture != explosion_anim_texture:
		current_anim_texture = explosion_anim_texture
		current_frame = 0
		animation_elapsed = 0.0

	animation_elapsed += delta
	if animation_elapsed >= death_animation_delay:
		current_frame += 1
		animation_elapsed = 0.0

		# Loop explosion animation
		var frame_count = get_frame_count_for_texture(explosion_anim_texture)
		if current_frame >= frame_count:
			current_frame = 0

	# Update sprite with current frame (same as animate function)
	if sprite and current_anim_texture:
		sprite.texture = current_anim_texture
		sprite.region_enabled = true
		# Update sprite region based on current frame and animation
		var frame_info = get_frame_info_for_texture(current_anim_texture)
		sprite.region_rect = Rect2(frame_info.width * current_frame, 0, frame_info.width, frame_info.height)

func get_frame_count_for_texture(texture: Texture2D) -> int:
	# Frame counts based on the original C# implementation
	var frame_count = 1
	if texture == idle_anim_texture:
		frame_count = 6 # Idle animation has 6 frames
	elif texture == right_anim_texture:
		frame_count = 8 # Right animation has 8 frames
	elif texture == left_anim_texture:
		frame_count = 8 # Left animation has 8 frames
	elif texture == explosion_anim_texture:
		frame_count = 12 # Explosion animation has 12 frames

	return frame_count

func get_frame_info_for_texture(texture: Texture2D) -> Dictionary:
	# Return frame width and height for each animation
	if texture == idle_anim_texture:
		return {"width": 68, "height": 128}
	elif texture == right_anim_texture:
		return {"width": 60, "height": 128}
	elif texture == left_anim_texture:
		return {"width": 71, "height": 128}
	elif texture == explosion_anim_texture:
		return {"width": 91, "height": 128}
	return {"width": 64, "height": 128}

func boundary_check():
	# Keep player within screen bounds
	var sprite_size = Vector2(64, 128) # Approximate player size

	position.x = clamp(position.x, 0, screen_size.x - sprite_size.x)
	position.y = clamp(position.y, 0, screen_size.y - sprite_size.y + 40)

func reset_animation():
	current_anim_texture = idle_anim_texture
	current_frame = 0
	animation_elapsed = 0.0
	death_timer = 0.0
	bullet_delay_timer = max_bullet_delay # Reset bullet delay timer
	can_shoot = false # Reset shooting permission

func set_can_shoot(value: bool):
	can_shoot = value
	if not can_shoot:
		print("Player shooting disabled")
		power_shot = false # Reset power shot when shooting is disabled
	else:
		print("Player shooting enabled")

func clear_bullets():
	# Clear all player bullets (useful for game reset)
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			bullet.queue_free()
	bullets.clear()

func take_damage():
	if is_invincible:
		print("Player is invincible (debug mode) - no damage taken")
		return

	# Check if life bubble is active
	if life_bubble_active and life_bubble_health > 0:
		life_bubble_health -= 1
		life_bubble_recovery_timer = life_bubble_recovery_time
		life_bubble_flash_timer = life_bubble_flash_duration
		print("Life bubble took damage! Health: ", life_bubble_health, "/", max_life_bubble_health)

		# Enhanced visual feedback for bubble damage
		trigger_bubble_damage_effect()

		# Visual feedback - flash the sprite
		if sprite:
			sprite.modulate = Color.RED

		# If bubble is depleted, player takes actual damage
		if life_bubble_health <= 0:
			print("Life bubble depleted! Player taking actual damage!")
			if not is_colliding:
				is_colliding = true
				sound_played = false
				death_timer = 0.0
		return

	# Normal damage when no life bubble
	if not is_colliding:
		print("Player taking damage! Setting is_colliding = true")
		is_colliding = true
		sound_played = false
		death_timer = 0.0

func trigger_bubble_damage_effect():
	"""Trigger visual effect when a bubble is damaged"""
	if not life_bubble_container or bubble_sprites.size() == 0:
		return

	# Find the bubble that was just damaged and create destruction effect
	var damaged_bubble_index = life_bubble_health # The bubble that was just destroyed
	if damaged_bubble_index < bubble_sprites.size():
		var damaged_bubble = bubble_sprites[damaged_bubble_index]
		if damaged_bubble and is_instance_valid(damaged_bubble):
			# Create shatter effect
			create_bubble_shatter_effect(damaged_bubble.global_position)

func create_bubble_shatter_effect(shatter_position: Vector2):
	"""Create a visual shatter effect when a bubble is destroyed"""
	# Create multiple small fragments
	for i in range(6):
		var fragment = Sprite2D.new()
		var fragment_texture = create_fragment_texture()
		fragment.texture = fragment_texture
		fragment.modulate = Color(0.6, 0.9, 1.0, 0.8) # Light blue fragments
		fragment.scale = Vector2(0.3, 0.3)
		get_parent().add_child(fragment)
		fragment.global_position = shatter_position

		# Random direction for fragments
		var angle = (i * PI / 3) + randf() * PI / 6 # Spread fragments around
		var direction = Vector2(cos(angle), sin(angle))
		var target_pos = shatter_position + direction * 20

		var tween = create_tween()
		tween.parallel().tween_property(fragment, "global_position", target_pos, 0.4)
		tween.parallel().tween_property(fragment, "modulate:a", 0.0, 0.4)
		tween.parallel().tween_property(fragment, "rotation", randf() * PI * 2, 0.4)
		tween.tween_callback(fragment.queue_free)

func create_fragment_texture() -> Texture2D:
	"""Create a small fragment texture for bubble destruction"""
	var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)

	# Create an irregular fragment shape
	var pixels = [
		Vector2(2, 1), Vector2(3, 1), Vector2(4, 1),
		Vector2(1, 2), Vector2(2, 2), Vector2(3, 2), Vector2(4, 2),
		Vector2(2, 3), Vector2(3, 3), Vector2(4, 3),
		Vector2(3, 4)
	]

	for pixel in pixels:
		if pixel.x >= 0 and pixel.x < 6 and pixel.y >= 0 and pixel.y < 6:
			image.set_pixel(int(pixel.x), int(pixel.y), Color(1.0, 1.0, 1.0, 0.8))

	var texture = ImageTexture.create_from_image(image)
	return texture

func set_invincible(invincible: bool):
	"""Set player invincibility state for debug mode"""
	is_invincible = invincible

	# Visual indicator for invincibility
	if sprite:
		if invincible:
			sprite.modulate = Color(1.0, 1.0, 1.0, 0.7) # Semi-transparent
			print("Player invincibility enabled - visual indicator active")
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0) # Fully opaque
			print("Player invincibility disabled - visual indicator cleared")

func activate_life_bubble():
	"""Activate the life-bubble system for boss fights"""
	life_bubble_active = true
	life_bubble_health = max_life_bubble_health
	life_bubble_recovery_timer = 0.0
	print("Life bubble activated! Health: ", life_bubble_health, "/", max_life_bubble_health)

func deactivate_life_bubble():
	"""Deactivate the life-bubble system"""
	life_bubble_active = false
	life_bubble_health = 0
	life_bubble_recovery_timer = 0.0
	print("Life bubble deactivated!")

func refill_life_bubble(amount: int = 1):
	"""Refill life bubble by specified amount"""
	if life_bubble_health < max_life_bubble_health:
		life_bubble_health = min(life_bubble_health + amount, max_life_bubble_health)
		print("Life bubble refilled! Health: ", life_bubble_health, "/", max_life_bubble_health)

		# Visual feedback for refill
		trigger_bubble_refill_effect()
		return true
	return false

func restore_life_bubble_full():
	"""Fully restore life bubble to maximum health"""
	if life_bubble_health < max_life_bubble_health:
		life_bubble_health = max_life_bubble_health
		life_bubble_recovery_timer = 0.0
		print("Life bubble fully restored! Health: ", life_bubble_health, "/", max_life_bubble_health)

		# Visual feedback for full restore
		trigger_bubble_refill_effect()
		return true
	return false

func trigger_bubble_refill_effect():
	"""Trigger visual effect when bubbles are refilled"""
	if life_bubble_container:
		# Flash effect for all bubbles
		for i in range(bubble_sprites.size()):
			if i < life_bubble_health:
				var bubble = bubble_sprites[i]
				if bubble and is_instance_valid(bubble):
					# Brief bright flash
					bubble.modulate = Color.WHITE
					var tween = create_tween()
					tween.tween_property(bubble, "modulate", Color(0.4, 0.8, 1.0, 0.8), 0.3)

func update_life_bubble(delta: float):
	"""Update life bubble system"""
	if not life_bubble_active:
		return

	# Handle recovery timer
	if life_bubble_recovery_timer > 0:
		life_bubble_recovery_timer -= delta
		if life_bubble_recovery_timer <= 0 and life_bubble_health < max_life_bubble_health:
			life_bubble_health += 1
			life_bubble_recovery_timer = life_bubble_recovery_time
			print("Life bubble recovered! Health: ", life_bubble_health, "/", max_life_bubble_health)

	# Handle flash effect
	if life_bubble_flash_timer > 0:
		life_bubble_flash_timer -= delta
		if life_bubble_flash_timer <= 0 and sprite:
			sprite.modulate = Color.WHITE # Reset to normal color

	# Visual bubble effect based on health
	if sprite and life_bubble_health > 0:
		var bubble_alpha = 0.3 + (float(life_bubble_health) / float(max_life_bubble_health)) * 0.4
		var bubble_color = Color(0.5, 0.8, 1.0, bubble_alpha) # Light blue tint
		sprite.modulate = sprite.modulate.lerp(bubble_color, 0.1)

func update_bubble_visuals(delta: float):
	"""Update visual bubble effects around the player"""
	if not life_bubble_active or not life_bubble_container:
		return

	# Update animation timers
	bubble_scale_animation += delta * bubble_pulse_speed
	if life_bubble_container:
		life_bubble_container.rotation += delta * bubble_rotation_speed

	# Update each bubble sprite based on current health
	for i in range(bubble_sprites.size()):
		var bubble = bubble_sprites[i]
		if not bubble or not is_instance_valid(bubble):
			continue

		# Show/hide bubbles based on current health
		if i < life_bubble_health:
			bubble.visible = true
			# Healthy bubble - bright and pulsing
			var bubble_scale_factor = 1.0 + sin(bubble_scale_animation + i * 0.5) * 0.1
			bubble.scale = Vector2(0.8, 0.8) * bubble_scale_factor
			bubble.modulate = Color(0.4, 0.8, 1.0, 0.8)
		elif i < max_life_bubble_health:
			bubble.visible = true
			# Damaged/empty bubble - dim and smaller
			bubble.scale = Vector2(0.5, 0.5)
			bubble.modulate = Color(0.2, 0.4, 0.6, 0.3)
		else:
			bubble.visible = false

func _on_bullet_collision(area):
	# Handle collision with enemy bullets only
	# Only process collision if it's an enemy bullet (collision_layer = 2)
	if area and area.collision_layer == 2:
		area.is_visible = false # Destroy the bullet
		take_damage()

func _on_point_collision(area):
	# Handle collision with point bullets (collectibles)
	if area.has_method("collect_point"):
		area.collect_point()
		# Add score through main game manager
		var main = get_parent()
		if main.has_method("add_score"):
			main.add_score(10)

	# Handle collision with life bubble refills
	elif area.has_method("collect_refill"):
		area.collect_refill(self )
