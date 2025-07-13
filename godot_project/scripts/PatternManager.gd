extends Node
class_name PatternManager

# Manages bullet patterns for enemies
# Handles pattern selection, sequencing, difficulty scaling, and coordination

# Pattern registry
var pattern_registry: Dictionary = {}
var pattern_presets: Dictionary = {}

# Active patterns
var active_patterns: Array[BulletPattern] = []
var pattern_queue: Array[Dictionary] = []

# Global bullet tracking - tracks ALL bullets from ALL patterns (active and completed)
var all_bullets: Array[Bullet] = []

# Pattern selection
var current_difficulty: float = 1.0
var pattern_weights: Dictionary = {}
var forced_next_pattern: String = ""

# Timing and sequencing
var pattern_cooldown: float = 0.0
var min_pattern_interval: float = 1.0
var max_pattern_interval: float = 3.0
var auto_spawn_enabled: bool = true

# Difficulty scaling
var difficulty_scaler: DifficultyScaler
var base_difficulty: float = 1.0
var time_based_scaling: bool = true
var kill_based_scaling: bool = true

# References
var enemy_owner: Enemy
var sound_manager: Sound
var rng: RandomNumberGenerator

# Signals
signal pattern_started(pattern: BulletPattern)
signal pattern_completed(pattern: BulletPattern)
signal all_patterns_completed()
signal difficulty_changed(new_difficulty: float)

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()

	# Initialize difficulty scaler
	difficulty_scaler = DifficultyScaler.new()
	difficulty_scaler.difficulty_changed.connect(_on_difficulty_changed)

	# Register default patterns
	register_default_patterns()
	setup_default_presets()

func _process(delta):
	# Update pattern cooldown
	if pattern_cooldown > 0:
		pattern_cooldown -= delta

	# Update difficulty
	if difficulty_scaler:
		difficulty_scaler.update_difficulty(delta)

	# Auto-spawn patterns if enabled
	if auto_spawn_enabled and pattern_cooldown <= 0 and active_patterns.size() < get_max_concurrent_patterns():
		spawn_next_pattern()

	# Update active patterns
	update_active_patterns(delta)

	# Process pattern queue
	process_pattern_queue()

func register_default_patterns():
	"""Register all available pattern types"""
	# Note: Using direct class references since the patterns are loaded via class_name
	pattern_registry["circle"] = CirclePattern
	pattern_registry["spiral"] = SpiralPattern
	pattern_registry["wave"] = WavePattern
	pattern_registry["star"] = StarPattern
	pattern_registry["star_outline"] = StarPattern
	pattern_registry["random"] = RandomPattern
	pattern_registry["burst"] = BurstPattern

	# Set default weights
	pattern_weights = {
		"circle": 1.0,
		"spiral": 0.8,
		"wave": 0.6,
		"star": 0.4,
		"star_outline": 0.3,
		"random": 1.2,
		"burst": 0.5
	}

func setup_default_presets():
	"""Set up default pattern presets"""
	pattern_presets["easy_circle"] = PatternParameters.create_circle_preset()
	pattern_presets["easy_circle"].difficulty_scale = 0.8

	pattern_presets["normal_circle"] = PatternParameters.create_circle_preset()

	pattern_presets["hard_circle"] = PatternParameters.create_circle_preset()
	pattern_presets["hard_circle"].difficulty_scale = 1.5

	pattern_presets["easy_spiral"] = PatternParameters.create_spiral_preset()
	pattern_presets["easy_spiral"].difficulty_scale = 0.7

	pattern_presets["normal_spiral"] = PatternParameters.create_spiral_preset()

	pattern_presets["easy_star"] = PatternParameters.create_star_preset()
	pattern_presets["easy_star"].difficulty_scale = 0.8
	pattern_presets["easy_star"].bullet_speed = 70.0 # Slower for easier dodging
	pattern_presets["easy_star"].set_custom_param("star_points", 5) # Classic 5-pointed star
	pattern_presets["easy_star"].set_custom_param("bullets_per_ray", 2) # Fewer bullets per ray
	pattern_presets["easy_star"].set_custom_param("outer_radius", 70.0) # Smaller initial radius
	pattern_presets["easy_star"].set_custom_param("bullet_spacing", 25.0) # More spacing between bullets
	pattern_presets["easy_star"].set_custom_param("ray_spread_factor", 1.2) # Less spread

	pattern_presets["normal_star"] = PatternParameters.create_star_preset()
	pattern_presets["normal_star"].set_custom_param("star_points", 6) # 6-pointed star
	pattern_presets["normal_star"].set_custom_param("bullets_per_ray", 3) # Standard bullets per ray
	pattern_presets["normal_star"].set_custom_param("outer_radius", 85.0) # Standard radius

	pattern_presets["hard_star"] = PatternParameters.create_star_preset()
	pattern_presets["hard_star"].difficulty_scale = 1.3
	pattern_presets["hard_star"].bullet_speed = 100.0 # Faster bullets
	pattern_presets["hard_star"].set_custom_param("star_points", 8) # 8-pointed star
	pattern_presets["hard_star"].set_custom_param("bullets_per_ray", 4) # More bullets per ray
	pattern_presets["hard_star"].set_custom_param("outer_radius", 100.0) # Larger initial radius
	pattern_presets["hard_star"].set_custom_param("bullet_spacing", 15.0) # Tighter spacing
	pattern_presets["hard_star"].set_custom_param("ray_spread_factor", 2.0) # More spread
	pattern_presets["hard_star"].set_custom_param("inner_radius_factor", 0.2) # Deeper valleys

	# Star outline presets
	pattern_presets["easy_star_outline"] = PatternParameters.create_star_outline_preset()
	pattern_presets["easy_star_outline"].difficulty_scale = 0.8
	pattern_presets["easy_star_outline"].bullet_speed = 70.0 # Slower for easier dodging
	pattern_presets["easy_star_outline"].set_custom_param("star_points", 5) # Classic 5-pointed star
	pattern_presets["easy_star_outline"].set_custom_param("outer_radius", 70.0) # Smaller radius
	pattern_presets["easy_star_outline"].set_custom_param("inner_radius_factor", 0.3) # Shallower valleys
	pattern_presets["easy_star_outline"].set_custom_param("outline_thickness", 2) # Thinner outline

	pattern_presets["normal_star_outline"] = PatternParameters.create_star_outline_preset()
	pattern_presets["normal_star_outline"].set_custom_param("star_points", 6) # 6-pointed star
	pattern_presets["normal_star_outline"].set_custom_param("outer_radius", 85.0) # Standard radius
	pattern_presets["normal_star_outline"].set_custom_param("inner_radius_factor", 0.25) # Standard valleys
	pattern_presets["normal_star_outline"].set_custom_param("outline_thickness", 3) # Standard thickness

	pattern_presets["hard_star_outline"] = PatternParameters.create_star_outline_preset()
	pattern_presets["hard_star_outline"].difficulty_scale = 1.3
	pattern_presets["hard_star_outline"].bullet_speed = 100.0 # Faster bullets
	pattern_presets["hard_star_outline"].set_custom_param("star_points", 8) # 8-pointed star
	pattern_presets["hard_star_outline"].set_custom_param("outer_radius", 100.0) # Larger radius
	pattern_presets["hard_star_outline"].set_custom_param("inner_radius_factor", 0.2) # Deeper valleys
	pattern_presets["hard_star_outline"].set_custom_param("outline_thickness", 4) # Thicker outline

	pattern_presets["easy_random"] = PatternParameters.create_random_preset()
	pattern_presets["easy_random"].difficulty_scale = 0.9

func register_pattern(pattern_name: String, pattern_class: GDScript, weight: float = 1.0):
	"""Register a new pattern type"""
	pattern_registry[pattern_name] = pattern_class
	pattern_weights[pattern_name] = weight

func create_pattern_preset(name: String, params: PatternParameters):
	"""Create a new pattern preset"""
	pattern_presets[name] = params.clone()

func spawn_pattern(pattern_name: String, spawn_pos: Vector2, target_pos: Vector2 = Vector2.ZERO, params: PatternParameters = null, force_color: String = "") -> BulletPattern:
	"""Spawn a specific pattern"""
	if not pattern_name in pattern_registry:
		push_error("Pattern not found: " + pattern_name)
		return null

	var pattern_class = pattern_registry[pattern_name]
	var pattern = pattern_class.new()

	# Set up the pattern
	if not params:
		params = get_default_params_for_pattern(pattern_name)

	# Apply difficulty scaling
	params.apply_difficulty_scaling(current_difficulty)

	# Add to scene
	if enemy_owner:
		enemy_owner.get_parent().add_child(pattern)
	else:
		get_parent().add_child(pattern)

	# Configure pattern
	pattern.setup_pattern(spawn_pos, target_pos, params)
	pattern.set_sound_manager(sound_manager)
	pattern.pattern_manager = self # Set reference to this PatternManager

	# Force specific color if provided
	if force_color != "":
		pattern.set_pattern_color(force_color)

	# Connect signals
	pattern.pattern_started.connect(_on_pattern_started)
	pattern.pattern_completed.connect(_on_pattern_completed)

	# Start pattern
	pattern.start_pattern()

	# Track active pattern
	active_patterns.append(pattern)

	return pattern

func spawn_next_pattern():
	"""Spawn the next pattern based on current settings"""
	var pattern_name = ""

	# Check for forced pattern
	if forced_next_pattern != "":
		pattern_name = forced_next_pattern
		forced_next_pattern = ""
	else:
		# Select pattern based on weights and difficulty
		pattern_name = select_weighted_pattern()

	if pattern_name == "":
		return

	# Get spawn position
	var spawn_pos = Vector2.ZERO
	if enemy_owner:
		spawn_pos = enemy_owner.global_position

	# Get target position (usually player)
	var target_pos = Vector2.ZERO
	if enemy_owner and enemy_owner.get_parent().has_method("get_player_position"):
		target_pos = enemy_owner.get_parent().get_player_position()

	# Spawn the pattern
	spawn_pattern(pattern_name, spawn_pos, target_pos)

	# Set cooldown
	pattern_cooldown = rng.randf_range(min_pattern_interval, max_pattern_interval)

func select_weighted_pattern() -> String:
	"""Select a pattern based on weights and difficulty"""
	var available_patterns = get_available_patterns()
	if available_patterns.is_empty():
		return ""

	# Calculate total weight
	var total_weight = 0.0
	for pattern_name in available_patterns:
		total_weight += pattern_weights.get(pattern_name, 1.0)

	# Select random pattern based on weight
	var random_value = rng.randf() * total_weight
	var current_weight = 0.0

	for pattern_name in available_patterns:
		current_weight += pattern_weights.get(pattern_name, 1.0)
		if random_value <= current_weight:
			return pattern_name

	# Fallback to first available
	return available_patterns[0]

func get_available_patterns() -> Array[String]:
	"""Get patterns available at current difficulty"""
	var available: Array[String] = []

	for pattern_name in pattern_registry.keys():
		if is_pattern_available(pattern_name):
			available.append(pattern_name)

	return available

func is_pattern_available(pattern_name: String) -> bool:
	"""Check if pattern is available at current difficulty"""
	# Basic patterns always available
	if pattern_name == "circle":
		return true

	# Make other patterns more accessible with lower difficulty requirements
	if pattern_name == "spiral" and current_difficulty >= 1.0:
		return true

	if pattern_name == "wave" and current_difficulty >= 1.2:
		return true

	if pattern_name == "star" and current_difficulty >= 1.1:
		return true

	if pattern_name == "star_outline" and current_difficulty >= 1.4:
		return true

	if pattern_name == "burst" and current_difficulty >= 1.3:
		return true

	# Random pattern removed from rotation
	if pattern_name == "random":
		return false

	return false

func get_default_params_for_pattern(pattern_name: String) -> PatternParameters:
	"""Get default parameters for a pattern type"""
	var difficulty_tier = get_difficulty_tier()
	var preset_name = difficulty_tier + "_" + pattern_name

	if preset_name in pattern_presets:
		return pattern_presets[preset_name].clone()

	# Fallback to pattern type defaults
	match pattern_name:
		"circle":
			return PatternParameters.create_circle_preset()
		"spiral":
			return PatternParameters.create_spiral_preset()
		"wave":
			return PatternParameters.create_wave_preset()
		"star":
			return PatternParameters.create_star_preset()
		"star_outline":
			return PatternParameters.create_star_outline_preset()
		"random":
			return PatternParameters.create_random_preset()
		_:
			return PatternParameters.new()

func get_difficulty_tier() -> String:
	"""Get difficulty tier name"""
	if current_difficulty < 1.2:
		return "easy"
	elif current_difficulty < 1.8:
		return "normal"
	else:
		return "hard"

func queue_pattern(pattern_name: String, delay: float = 0.0, spawn_pos: Vector2 = Vector2.ZERO, target_pos: Vector2 = Vector2.ZERO, params: PatternParameters = null):
	"""Queue a pattern to be spawned later"""
	pattern_queue.append({
		"pattern_name": pattern_name,
		"delay": delay,
		"spawn_pos": spawn_pos,
		"target_pos": target_pos,
		"params": params,
		"timer": 0.0
	})
	print("Queued pattern: ", pattern_name, " with delay: ", delay, " seconds",
		" at position: ", spawn_pos, " targeting: ", target_pos, ", with params: ", params)

func process_pattern_queue():
	"""Process queued patterns"""
	for i in range(pattern_queue.size() - 1, -1, -1):
		var queued_pattern = pattern_queue[i]
		queued_pattern.timer += get_process_delta_time()

		if queued_pattern.timer >= queued_pattern.delay:
			spawn_pattern(
				queued_pattern.pattern_name,
				queued_pattern.spawn_pos,
				queued_pattern.target_pos,
				queued_pattern.params
			)
			pattern_queue.remove_at(i)

func update_active_patterns(delta: float):
	"""Update all active patterns"""
	for i in range(active_patterns.size() - 1, -1, -1):
		var pattern = active_patterns[i]
		if not pattern or not is_instance_valid(pattern) or pattern.is_pattern_complete():
			# Pattern is complete, remove from active patterns
			# NOTE: Bullets from this pattern are still tracked in all_bullets array
			active_patterns.remove_at(i)
			# Don't queue_free the pattern immediately - let it clean up naturally
			# The bullets will still be tracked in all_bullets for conversion

func clear_all_patterns():
	"""Clear all active patterns immediately"""
	# First clean up all tracked bullets
	for bullet in all_bullets:
		if bullet and is_instance_valid(bullet):
			bullet.force_cleanup()
	all_bullets.clear()

	# Clear patterns
	for pattern in active_patterns:
		if pattern and is_instance_valid(pattern):
			pattern.is_active = false
			pattern.clear_all_bullets() # Clear bullets immediately
			pattern.queue_free()
	active_patterns.clear()
	pattern_queue.clear()

	# Stop auto-spawning
	auto_spawn_enabled = false

func clear_patterns_without_bullets():
	"""Clear all active patterns but preserve bullets (used when bullets are converted to points)"""
	for pattern in active_patterns:
		if pattern and is_instance_valid(pattern):
			pattern.is_active = false
			# Don't clear bullets - they've already been converted to points
			pattern.bullets.clear() # Clear the reference array but bullets remain in scene
			pattern.queue_free()
	active_patterns.clear()
	pattern_queue.clear()

	# Stop auto-spawning
	auto_spawn_enabled = false

func get_max_concurrent_patterns() -> int:
	"""Get maximum number of concurrent patterns based on difficulty"""
	if current_difficulty < 1.5:
		return 1
	elif current_difficulty < 2.5:
		return 2
	else:
		return 3

func set_enemy_owner(enemy: Enemy):
	"""Set the enemy that owns this pattern manager"""
	enemy_owner = enemy

func set_sound_manager(sound_mgr: Sound):
	"""Set the sound manager"""
	sound_manager = sound_mgr

func force_next_pattern(pattern_name: String):
	"""Force the next pattern to be a specific type"""
	forced_next_pattern = pattern_name

func set_pattern_weight(pattern_name: String, weight: float):
	"""Set the weight for pattern selection"""
	pattern_weights[pattern_name] = weight

func get_pattern_stats() -> Dictionary:
	"""Get statistics about pattern usage"""
	return {
		"active_patterns": active_patterns.size(),
		"queued_patterns": pattern_queue.size(),
		"current_difficulty": current_difficulty,
		"available_patterns": get_available_patterns(),
		"max_concurrent": get_max_concurrent_patterns()
	}

func get_all_active_bullets() -> Array[Bullet]:
	"""Get all bullets from all active patterns"""
	var all_bullets: Array[Bullet] = []

	for pattern in active_patterns:
		if pattern and is_instance_valid(pattern):
			for bullet in pattern.bullets:
				# Include all valid bullets, even if off-screen (is_visible = false)
				if bullet and is_instance_valid(bullet):
					all_bullets.append(bullet)

	return all_bullets

func convert_all_bullets_to_points(point_creator_callback: Callable):
	"""Convert all bullets to point bullets using a callback - uses global bullet tracking"""
	var total_converted = 0

	# First clean up invalid bullets
	cleanup_invalid_bullets()

	# Convert all tracked bullets (from active AND completed patterns, including off-screen ones)
	for i in range(all_bullets.size() - 1, -1, -1):
		var bullet = all_bullets[i]
		if bullet and is_instance_valid(bullet):
			# Convert ALL bullets, even if they're off-screen (is_visible = false)
			# This ensures off-screen bullets are also converted to point bullets
			point_creator_callback.call(bullet)
			bullet.is_visible = false # Ensure bullet is hidden after conversion
			# Force cleanup now that bullet has been converted
			bullet.force_cleanup()
			total_converted += 1

		# Remove bullet from tracking (converted or invalid)
		all_bullets.remove_at(i)

	return total_converted

# Global bullet tracking methods
func register_bullet(bullet: Bullet):
	"""Register a bullet in the global tracking system"""
	if bullet and is_instance_valid(bullet) and bullet not in all_bullets:
		all_bullets.append(bullet)
		# Enable conversion tracking to prevent automatic cleanup
		bullet.set_prevent_auto_cleanup(true)

func unregister_bullet(bullet: Bullet):
	"""Unregister a bullet from the global tracking system"""
	if bullet in all_bullets:
		all_bullets.erase(bullet)
		# Re-enable automatic cleanup
		if bullet and is_instance_valid(bullet):
			bullet.set_prevent_auto_cleanup(false)

func cleanup_invalid_bullets():
	"""Remove invalid bullets from the global tracking system"""
	for i in range(all_bullets.size() - 1, -1, -1):
		var bullet = all_bullets[i]
		# Only remove bullets that are truly invalid (null or freed)
		# Keep bullets that are just invisible (off-screen) so they can be converted to points
		if not bullet or not is_instance_valid(bullet):
			all_bullets.remove_at(i)

func get_all_tracked_bullets() -> Array[Bullet]:
	"""Get all bullets from the global tracking system (active and completed patterns)"""
	cleanup_invalid_bullets()
	return all_bullets.duplicate()

# Signal handlers
func _on_pattern_started(pattern: BulletPattern):
	emit_signal("pattern_started", pattern)

func _on_pattern_completed(pattern: BulletPattern):
	emit_signal("pattern_completed", pattern)

	# Check if all patterns are complete
	if active_patterns.is_empty() and pattern_queue.is_empty():
		emit_signal("all_patterns_completed")

func _on_difficulty_changed(new_difficulty: float):
	current_difficulty = new_difficulty
	emit_signal("difficulty_changed", new_difficulty)
