extends Node2D
class_name BulletPattern

# Base class for all bullet patterns
# Provides common functionality and structure for bullet patterns

# Pattern state
var is_active: bool = false
var is_complete: bool = false
var pattern_timer: float = 0.0
var spawn_position: Vector2
var target_position: Vector2

# Pattern configuration
var pattern_params: PatternParameters
var bullets: Array[Bullet] = []

# Pattern lifecycle
var spawn_delay: float = 0.0
var pattern_duration: float = 5.0
var cleanup_delay: float = 2.0

# Sound and visual effects
var sound_manager: Sound
var rng: RandomNumberGenerator

# Consistent color per pattern instance
var pattern_color: String = ""
var pattern_texture: Texture2D = null

# Signals for pattern events
signal pattern_started
signal pattern_completed
signal bullet_spawned(bullet: Bullet)
signal bullet_destroyed(bullet: Bullet)

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()

	# Initialize default parameters if not set
	if not pattern_params:
		pattern_params = PatternParameters.new()

func _process(delta):
	if is_active and not is_complete:
		update_pattern(delta)
		cleanup_destroyed_bullets()

		# Check if pattern should complete
		if should_complete_pattern():
			complete_pattern()

# Virtual methods to be overridden by specific patterns
func setup_pattern(pos: Vector2, target: Vector2 = Vector2.ZERO, params: PatternParameters = null):
	"""Initialize the pattern with position and parameters"""
	spawn_position = pos
	target_position = target

	if params:
		pattern_params = params

	reset_pattern()

func start_pattern():
	"""Start the pattern execution"""
	if spawn_delay > 0:
		await get_tree().create_timer(spawn_delay).timeout

	is_active = true
	is_complete = false
	pattern_timer = 0.0

	emit_signal("pattern_started")
	initialize_pattern()

func stop_pattern():
	"""Stop the pattern and clean up"""
	is_active = false
	complete_pattern()

func reset_pattern():
	"""Reset pattern to initial state"""
	is_active = false
	is_complete = false
	pattern_timer = 0.0
	clear_all_bullets()

# Virtual methods for specific pattern implementation
func initialize_pattern():
	"""Override this to set up pattern-specific initialization"""
	# Select a consistent color for this pattern instance
	if pattern_color == "":
		select_pattern_color()

func select_pattern_color():
	"""Select a consistent color for this pattern instance"""
	var bullet_colors = pattern_params.bullet_colors
	var color_keys = bullet_colors.keys()

	if color_keys.size() > 0:
		pattern_color = color_keys[rng.randi() % color_keys.size()]
		pattern_texture = load(bullet_colors[pattern_color])
	else:
		# Fallback to default
		pattern_color = "red"
		pattern_texture = load("res://assets/textures/bullets/bullet_redshot1.png")

func update_pattern(delta: float):
	"""Override this to implement pattern-specific update logic"""
	pattern_timer += delta

	# Update all bullets
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			update_bullet_behavior(bullet, delta)

func update_bullet_behavior(bullet: Bullet, delta: float):
	"""Override this to implement custom bullet behavior"""
	pass

func should_complete_pattern() -> bool:
	"""Override this to define when pattern should complete"""
	return pattern_timer >= pattern_duration

func complete_pattern():
	"""Complete the pattern and start cleanup"""
	if is_complete:
		return

	is_complete = true
	is_active = false
	emit_signal("pattern_completed")

	# Start cleanup timer
	if cleanup_delay > 0:
		await get_tree().create_timer(cleanup_delay).timeout

	queue_free()

# Common bullet management
func spawn_bullet(texture: Texture2D, pos: Vector2, velocity: Vector2, speed: float = 200.0) -> Bullet:
	"""Spawn a new bullet with given parameters"""
	var bullet = preload("res://scenes/Bullet.tscn").instantiate()
	get_parent().add_child(bullet)

	bullet.setup_bullet(texture, pos, velocity, speed)
	bullet.set_bullet_type(false) # Mark as enemy bullet

	bullets.append(bullet)
	emit_signal("bullet_spawned", bullet)

	return bullet

func get_bullet_texture(color_name: String = "") -> Texture2D:
	"""Get a bullet texture based on color name or use pattern's consistent color"""
	var bullet_colors = pattern_params.bullet_colors

	# If a specific color is requested and exists, use it
	if color_name != "" and color_name in bullet_colors:
		return load(bullet_colors[color_name])

	# Use the pattern's consistent color
	if pattern_texture:
		return pattern_texture

	# Fallback: select and store pattern color
	if pattern_color == "":
		select_pattern_color()

	return pattern_texture

func cleanup_destroyed_bullets():
	"""Remove bullets that are no longer visible"""
	for i in range(bullets.size() - 1, -1, -1):
		var bullet = bullets[i]
		if not bullet or not is_instance_valid(bullet) or not bullet.is_visible:
			if bullet and is_instance_valid(bullet):
				emit_signal("bullet_destroyed", bullet)
				bullet.queue_free()
			bullets.remove_at(i)

func clear_all_bullets():
	"""Clear all bullets immediately"""
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			emit_signal("bullet_destroyed", bullet)
			bullet.is_visible = false # Hide immediately
			bullet.queue_free()
	bullets.clear()

func convert_bullets_to_points(point_creator_callback: Callable) -> int:
	"""Convert all bullets to point bullets using callback"""
	var converted_count = 0

	for bullet in bullets:
		if bullet and is_instance_valid(bullet) and bullet.is_visible:
			# Call the callback to create point bullet
			point_creator_callback.call(bullet)
			bullet.is_visible = false # Hide original bullet
			converted_count += 1

	# Clear the bullets array after conversion
	bullets.clear()

	return converted_count

# Utility functions
func get_direction_to_target() -> Vector2:
	"""Get normalized direction from spawn position to target"""
	if target_position == Vector2.ZERO:
		return Vector2.DOWN
	return (target_position - spawn_position).normalized()

func get_angle_to_target() -> float:
	"""Get angle in radians from spawn position to target"""
	return get_direction_to_target().angle()

func apply_difficulty_scaling():
	"""Apply difficulty scaling to pattern parameters"""
	var scale_factor = pattern_params.difficulty_scale

	pattern_params.bullet_speed *= scale_factor
	pattern_params.bullet_density = int(pattern_params.bullet_density * scale_factor)
	pattern_params.spawn_rate *= scale_factor

# Pattern state queries
func is_pattern_active() -> bool:
	return is_active

func is_pattern_complete() -> bool:
	return is_complete

func get_bullet_count() -> int:
	return bullets.size()

func get_active_bullet_count() -> int:
	var count = 0
	for bullet in bullets:
		if bullet and is_instance_valid(bullet) and bullet.is_visible:
			count += 1
	return count

func set_sound_manager(sound_mgr: Sound):
	sound_manager = sound_mgr

func get_pattern_progress() -> float:
	"""Get pattern completion progress (0.0 to 1.0)"""
	if pattern_duration <= 0:
		return 1.0
	return min(pattern_timer / pattern_duration, 1.0)

# Debug and visualization
func debug_draw():
	"""Override this to draw debug information"""
	pass

func set_pattern_color(color_name: String):
	"""Set a specific color for this pattern (overrides random selection)"""
	if color_name != "" and color_name in pattern_params.bullet_colors:
		pattern_color = color_name
		pattern_texture = load(pattern_params.bullet_colors[color_name])
	else:
		# Fallback to red if color not found
		pattern_color = "red"
		pattern_texture = load("res://assets/textures/bullets/bullet_redshot1.png")
