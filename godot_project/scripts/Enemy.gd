extends Area2D
class_name Enemy

# Enemy properties
var enemy_speed: float = 50.0 # 50 pixels/sec
var health: float = 100.0
var is_visible: bool = true

# Movement and targeting
var difference: Vector2
var origin: Vector2

# Shooting properties
var shot_delay: float = 0.0
var max_shot_delay: float = 1.67 # 100 frames at 60fps converted to seconds
var n_circle_spawns: int = 0
var max_circle_spawns: int = 10

# Bullet patterns - using new pattern system
var pattern_manager: PatternManager
var assigned_pattern: String = "" # Pattern assigned to this enemy for its entire lifetime
var assigned_bullet_color: String = "" # Bullet color assigned to this enemy for its entire lifetime
var attack_count: int = 0 # Number of attacks this enemy has performed
var single_pattern_mode: bool = true # If true, enemy uses only one pattern type throughout its lifetime

# Legacy pattern arrays (for backward compatibility)
var random_bullets: Array[RandomShots] = []
var circle_shots: Array[CircleShots] = []

# Difficulty scaling
var speed_increase: float = 0.0
var enemy_deaths: float = 0.0

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var debug_label: Label = $DebugLabel

# Debug and display
var current_pattern_type: String = "None"
var show_debug_info: bool = false

# Sound manager
var sound_manager: Sound

# Random number generator
var rng = RandomNumberGenerator.new()

# Screen bounds
var screen_size: Vector2

func _ready():
	# Initialize random generator
	rng.randomize()

	# Get screen size
	screen_size = get_viewport().get_visible_rect().size

	# Set collision layers and masks
	collision_layer = 8 # Enemy layer
	collision_mask = 1 # Player layer

	# Connect collision signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Initialize shooting properties
	shot_delay = max_shot_delay
	n_circle_spawns = rng.randi_range(2, max_circle_spawns)

	# Initialize pattern manager
	setup_pattern_manager()

	# Assign a bullet color for this enemy's entire lifetime
	assign_bullet_color()

	# Pattern assignment will be done after difficulty is set
	# assign_pattern() will be called from set_difficulty()

	# Initialize debug display
	update_debug_display()

func set_sound_manager(sound_mgr: Sound):
	sound_manager = sound_mgr

	# Also set for pattern manager
	if pattern_manager:
		pattern_manager.set_sound_manager(sound_mgr)

func setup_pattern_manager():
	"""Initialize the pattern manager"""
	pattern_manager = PatternManager.new()
	add_child(pattern_manager)

	pattern_manager.set_enemy_owner(self)
	pattern_manager.set_sound_manager(sound_manager)

	# Configure pattern manager settings
	pattern_manager.auto_spawn_enabled = not single_pattern_mode # Disable auto-spawn for single pattern mode
	pattern_manager.min_pattern_interval = 1.0
	pattern_manager.max_pattern_interval = 3.0

	# Connect pattern manager signals
	pattern_manager.pattern_started.connect(_on_pattern_started)
	pattern_manager.pattern_completed.connect(_on_pattern_completed)

func assign_pattern():
	"""Assign a single pattern to this enemy for its entire lifetime"""
	if assigned_pattern != "":
		return # Already assigned

	# Testing
	# assigned_pattern = "star"
	# return

	# Ensure we have a pattern manager
	if not pattern_manager:
		assigned_pattern = "circle" # Fallback
		return

	# Get all available patterns (excluding random)
	var all_patterns = ["circle", "spiral", "wave", "star", "star_outline", "burst"]
	var available_patterns = []

	for pattern_name in all_patterns:
		if pattern_manager.is_pattern_available(pattern_name):
			available_patterns.append(pattern_name)

	# Select a random pattern from available ones
	if not available_patterns.is_empty():
		assigned_pattern = available_patterns[rng.randi() % available_patterns.size()]
		set_current_pattern_type(assigned_pattern.capitalize())
	else:
		assigned_pattern = "circle" # Fallback to circle if no patterns available

func assign_bullet_color():
	"""Assign a single bullet color to this enemy for its entire lifetime"""
	if assigned_bullet_color != "":
		return # Already assigned

	# Get available bullet colors from pattern parameters
	var pattern_params = PatternParameters.new()
	var bullet_colors = pattern_params.bullet_colors
	var color_keys = bullet_colors.keys()

	if color_keys.size() > 0:
		assigned_bullet_color = color_keys[rng.randi() % color_keys.size()]
	else:
		assigned_bullet_color = "red" # Fallback

func set_texture(texture_path: String):
	# Determine enemy color from texture path
	var color_name = ""
	if "green" in texture_path.to_lower():
		color_name = "green"
	elif "red" in texture_path.to_lower():
		color_name = "red"
	elif "yellow" in texture_path.to_lower():
		color_name = "yellow"
	elif "blue" in texture_path.to_lower():
		color_name = "blue"
	else:
		color_name = "green" # Default fallback

	# Create SpriteFrames resource
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("flap")
	sprite_frames.set_animation_speed("flap", 8.0) # 8 FPS animation
	sprite_frames.set_animation_loop("flap", true)

	# Load the strip texture
	var strip_path = "res://assets/textures/enemies/enemy_" + color_name + "_enemy_flap_strip.png"
	var strip_texture = load(strip_path)

	if strip_texture:
		# Get actual texture dimensions
		var total_width = strip_texture.get_width()
		var total_height = strip_texture.get_height()
		var frame_count = 4

		# Calculate frame dimensions based on actual texture size
		var frame_width = total_width / frame_count
		var frame_height = total_height

		# Create individual frames from the strip
		for i in range(frame_count):
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = strip_texture
			atlas_texture.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("flap", atlas_texture)

		# Assign the SpriteFrames to the AnimatedSprite2D
		if animated_sprite:
			animated_sprite.sprite_frames = sprite_frames
			animated_sprite.animation = "flap"
			animated_sprite.play()

			# Update collision shape based on actual frame size
			if collision_shape and collision_shape.shape is RectangleShape2D:
				var rect_shape = collision_shape.shape as RectangleShape2D
				rect_shape.size = Vector2(frame_width, frame_height)
	else:
		print("ERROR: Failed to load enemy strip texture: ", strip_path)
		# Create fallback texture based on enemy type
		var color = Color.GREEN
		if color_name == "red":
			color = Color.RED
		elif color_name == "yellow":
			color = Color.YELLOW
		elif color_name == "blue":
			color = Color.BLUE

		var image = Image.create(30, 26, false, Image.FORMAT_RGB8)
		image.fill(color)
		var fallback_texture = ImageTexture.new()
		fallback_texture.set_image(image)

		# Create single frame animation as fallback
		sprite_frames.add_frame("flap", fallback_texture)
		if animated_sprite:
			animated_sprite.sprite_frames = sprite_frames
			animated_sprite.animation = "flap"
			animated_sprite.play()

			# Update collision shape for fallback
			if collision_shape and collision_shape.shape is RectangleShape2D:
				var rect_shape = collision_shape.shape as RectangleShape2D
				rect_shape.size = Vector2(30, 26)

func set_difficulty(deaths: float):
	enemy_deaths = deaths

	# Update pattern manager difficulty
	if pattern_manager and pattern_manager.difficulty_scaler:
		pattern_manager.difficulty_scaler.enemy_kills = int(deaths)
		pattern_manager.difficulty_scaler.current_difficulty = 1.0 + deaths * 0.1

		# Force difficulty update in pattern manager
		pattern_manager.current_difficulty = 1.0 + deaths * 0.1

		# Now assign pattern with updated difficulty
		assign_pattern()

func update_movement(delta: float, player: Player):
	if not is_visible:
		return

	follow_player(delta, player)
	update_enemy_position(delta)
	check_collision(player)

	# Update debug display
	update_debug_display()

func follow_player(delta: float, player: Player):
	# Gradually follow player's x position
	difference = player.position - position
	difference = difference.normalized()
	position.x += difference.x * delta * 6.0 # 0.1 * 60 for delta conversion
	position.y += enemy_speed * delta

func update_enemy_position(delta: float):
	# Update origin for bullet spawning
	origin = Vector2(position.x, position.y)

	# Remove enemy if it goes off screen
	if position.y >= screen_size.y:
		is_visible = false

	# Remove enemy if health is depleted
	if health <= 0:
		is_visible = false

func update_shooting(delta: float, player: Player):
	if not is_visible:
		return

	# Don't shoot if enemy is still off-screen (above viewport)
	if position.y < 0:
		return

	# Increase speed based on enemy deaths
	speed_increase += delta * enemy_deaths

	# Update shot delay
	if shot_delay > 0:
		shot_delay -= delta

	# Fire shots when delay reaches zero
	if shot_delay <= 0:
		enemy_shot()
		shot_delay = max_shot_delay

	# Update existing bullets
	update_shots(delta, player)

func enemy_shot():
	"""Fire shots using assigned pattern system"""
	if not pattern_manager or assigned_pattern == "":
		return

	# Increment attack count for spiral expansion
	attack_count += 1

	# Get player position for targeting
	var player_pos = Vector2.ZERO
	if get_parent().has_method("get_player_position"):
		player_pos = get_parent().get_player_position()

	# Use the assigned pattern for this enemy
	var selected_pattern = ""
	if pattern_manager.is_pattern_available(assigned_pattern):
		var params = pattern_manager.get_default_params_for_pattern(assigned_pattern)
		params.apply_difficulty_scaling(1.0 + enemy_deaths * 0.1)

		# For spiral patterns, pass attack count for expansion
		if assigned_pattern == "spiral":
			params.set_custom_param("attack_count", attack_count)
			params.set_custom_param("enemy_position", origin)

		# Handle circle pattern limit
		if assigned_pattern == "circle":
			if n_circle_spawns > 0:
				pattern_manager.spawn_pattern(assigned_pattern, origin, player_pos, params, assigned_bullet_color)
				n_circle_spawns -= 1
				selected_pattern = assigned_pattern.capitalize()
		else:
			# Other patterns don't have limits
			pattern_manager.spawn_pattern(assigned_pattern, origin, player_pos, params, assigned_bullet_color)
			selected_pattern = assigned_pattern.capitalize()

	# Update debug display with current pattern
	if selected_pattern != "":
		set_current_pattern_type(selected_pattern)
	else:
		set_current_pattern_type("None")

func update_shots(delta: float, player: Player):
	# Update circle shots (legacy support)
	for i in range(circle_shots.size() - 1, -1, -1):
		var circle_shot = circle_shots[i]
		if not circle_shot or not circle_shot.is_visible:
			if circle_shot:
				circle_shot.queue_free()
			circle_shots.remove_at(i)
		else:
			circle_shot.update_pattern(delta, player, self)

func check_collision(player: Player):
	# Remove enemy if it goes off screen
	if position.y >= screen_size.y:
		is_visible = false
		return

	# Check collision with player body - use average sprite size for collision area
	var collision_area = Rect2(position - Vector2(15, 13), Vector2(30, 26))
	var player_area = Rect2(player.position, Vector2(64, 128))

	if collision_area.intersects(player_area):
		is_visible = false
		player.take_damage()

func take_damage(damage: int, is_power_shot: bool = false):
	# Debug enemies are invincible
	if has_meta("is_debug_enemy") and get_meta("is_debug_enemy") == true:
		return

	if is_power_shot:
		health -= 30
	else:
		health -= damage

	if health <= 0:
		is_visible = false

func _on_area_entered(area):
	# Handle collision with player bullets
	if area.has_method("get_damage"):
		var damage = area.get_damage()
		var is_power = area.has_method("is_power_shot") and area.is_power_shot()
		take_damage(damage, is_power)
		area.destroy_bullet()

func _on_body_entered(body):
	# Handle collision with player body
	if body.has_method("take_damage"):
		body.take_damage()
		is_visible = false

func _process(delta):
	# Auto-destroy when not visible
	if not is_visible:
		queue_free()

# Pattern Manager Signal Handlers
func _on_pattern_started(pattern: BulletPattern):
	"""Called when a pattern starts"""
	if sound_manager:
		sound_manager.play_enemy_circle_shoot()

func _on_pattern_completed(pattern: BulletPattern):
	"""Called when a pattern completes"""
	pass

# Utility methods for pattern system
func get_player_position() -> Vector2:
	"""Get current player position for targeting"""
	var parent = get_parent()
	if parent and parent.has_method("get_player_position"):
		return parent.get_player_position()
	return Vector2.ZERO

func update_debug_display():
	"""Update debug information display"""
	if debug_label:
		if show_debug_info:
			debug_label.text = "Pattern: " + current_pattern_type
			debug_label.text += "\nHealth: " + str(health)
			debug_label.text += "\nSpeed: " + str(enemy_speed)
			debug_label.text += "\nAttack Count: " + str(attack_count)
			debug_label.visible = true
		else:
			debug_label.visible = false

func set_current_pattern_type(pattern_type: String):
	"""Set the current pattern type for debug display"""
	current_pattern_type = pattern_type
	update_debug_display()

func set_debug_info(show: bool):
	"""Toggle debug information display"""
	show_debug_info = show
	update_debug_display()

func clear_all_bullets():
	"""Clear all bullets using new pattern system - improved version"""
	# First, convert bullets to points if enemy is dying
	if not is_visible:
		convert_bullets_to_points_on_death()

	# Stop auto-spawning immediately
	if pattern_manager:
		pattern_manager.auto_spawn_enabled = false
		# Clear patterns - the conversion method already cleared bullets
		pattern_manager.clear_all_patterns()

	# Also clear legacy patterns for backward compatibility
	for circle_shot in circle_shots:
		if circle_shot and is_instance_valid(circle_shot):
			circle_shot.clear_bullets()
			circle_shot.queue_free()
	circle_shots.clear()

	# Update debug display
	set_current_pattern_type("Cleared")

func convert_bullets_to_points_on_death():
	"""Convert bullets to points when enemy dies - called internally"""
	if pattern_manager:
		# Use the pattern manager's built-in conversion method
		var main_scene = get_parent()
		if main_scene and main_scene.has_method("create_point_bullet_from_bullet"):
			# Create a callback that calls the main scene's method
			var point_creator_callback = Callable(main_scene, "create_point_bullet_from_bullet")
			var total_converted = pattern_manager.convert_all_bullets_to_points(point_creator_callback)

			if total_converted > 0:
				print("Enemy converted ", total_converted, " spiral bullets to point bullets")

func get_enemy_bullet_color() -> String:
	"""Get the bullet color assigned to this enemy"""
	return assigned_bullet_color
