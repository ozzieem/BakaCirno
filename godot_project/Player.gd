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
var movement_speed: float = 360.0 # pixels per second
var bullet_speed: int = 240 # pixels per second
var max_bullet_delay: float = 0.25 # seconds between shots

# Player states
var is_colliding: bool = false
var is_dead: bool = false
var power_shot: bool = false
var sound_played: bool = false
var stop_movement: bool = true

# Animation properties
var current_frame: int = 0
var animation_elapsed: float = 0.0
var animation_delay: float = 0.12 # 120ms converted to seconds
var death_animation_delay: float = 0.04 # 40ms converted to seconds
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

# Sound manager
var sound_manager: Sound

# Screen bounds
var screen_size: Vector2

func _ready():
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

	# Create sound manager
	sound_manager = Sound.new()
	add_child(sound_manager)

	print("Player initialized at position: ", position)

func load_player_assets():
	# Load animation textures with fallbacks
	idle_anim_texture = load_texture_with_fallback("res://assets/textures/idlecirno.png", Color.CYAN)
	right_anim_texture = load_texture_with_fallback("res://assets/textures/rightcirno.png", Color.LIGHT_BLUE)
	left_anim_texture = load_texture_with_fallback("res://assets/textures/leftcirno.png", Color.LIGHT_BLUE)
	explosion_anim_texture = load_texture_with_fallback("res://assets/textures/blueexplosion.png", Color.RED)

	# Load bullet textures
	bullet_texture = load_texture_with_fallback("res://assets/textures/playershot1mini.png", Color.YELLOW)
	power_shot_texture = load_texture_with_fallback("res://assets/textures/playershot1.png", Color.ORANGE)

	# Set initial animation
	current_anim_texture = idle_anim_texture
	if sprite and current_anim_texture:
		sprite.texture = current_anim_texture
		sprite.region_enabled = true
		sprite.centered = true
		# Start with first frame of idle animation
		var frame_info = get_frame_info_for_texture(current_anim_texture)
		sprite.region_rect = Rect2(0, 0, frame_info.width, frame_info.height)

func load_texture_with_fallback(path: String, fallback_color: Color) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	else:
		# Create a simple colored fallback texture
		var image = Image.create(68, 128, false, Image.FORMAT_RGB8)
		image.fill(fallback_color)
		var fallback_texture = ImageTexture.new()
		fallback_texture.set_image(image)
		print("Created fallback texture for: " + path)
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
		point_collision_area.collision_mask = 4 # Detect point bullets
		point_collision_area.area_entered.connect(_on_point_collision)
	else:
		print("WARNING: point_collision_area not found!")

func _process(delta):
	if not stop_movement:
		handle_input()

	update_bullets(delta)
	boundary_check()

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

func handle_input():
	if is_colliding:
		return

	var input_vector = Vector2.ZERO

	# Movement input
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		current_anim_texture = right_anim_texture
	elif Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		current_anim_texture = left_anim_texture
	else:
		current_anim_texture = idle_anim_texture

	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1

	# Apply movement
	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * movement_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Shooting input
	if Input.is_action_pressed("shoot"):
		shoot()

	# Power shot
	power_shot = Input.is_action_pressed("power_shot")

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
			sound_manager.play_player_shoot()

		# Create bullet
		var bullet = preload("res://Bullet.tscn").instantiate()
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

	# Switch to explosion animation
	current_anim_texture = explosion_anim_texture

	animation_elapsed += delta
	if animation_elapsed >= death_animation_delay:
		current_frame += 1
		animation_elapsed = 0.0

		# Loop explosion animation
		var frame_count = get_frame_count_for_texture(explosion_anim_texture)
		if current_frame >= frame_count:
			current_frame = 0

func get_frame_count_for_texture(texture: Texture2D) -> int:
	# This would need to be adjusted based on your sprite sheet layout
	var frame_count = 1
	if texture == idle_anim_texture:
		frame_count = 1 # Temporarily set to 1 to test single frame
	elif texture == right_anim_texture:
		frame_count = 1 # Temporarily set to 1
	elif texture == left_anim_texture:
		frame_count = 1 # Temporarily set to 1
	elif texture == explosion_anim_texture:
		frame_count = 1 # Temporarily set to 1

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

func clear_bullets():
	# Clear all player bullets (useful for game reset)
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			bullet.queue_free()
	bullets.clear()

func take_damage():
	if not is_colliding:
		print("Player taking damage! Setting is_colliding = true")
		is_colliding = true
		sound_played = false
		death_timer = 0.0

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
