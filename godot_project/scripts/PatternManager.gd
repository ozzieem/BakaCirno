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
	pattern_registry["random"] = RandomPattern
	pattern_registry["burst"] = BurstPattern

	# Set default weights
	pattern_weights = {
		"circle": 1.0,
		"spiral": 0.8,
		"wave": 0.6,
		"star": 0.4,
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

	if pattern_name == "star" and current_difficulty >= 1.5:
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
			active_patterns.remove_at(i)

func clear_all_patterns():
	"""Clear all active patterns immediately"""
	for pattern in active_patterns:
		if pattern and is_instance_valid(pattern):
			pattern.is_active = false
			pattern.clear_all_bullets() # Clear bullets immediately
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
				if bullet and is_instance_valid(bullet) and bullet.is_visible:
					all_bullets.append(bullet)

	return all_bullets

func convert_all_bullets_to_points(point_creator_callback: Callable):
	"""Convert all active bullets to point bullets using a callback"""
	var total_converted = 0

	for pattern in active_patterns:
		if pattern and is_instance_valid(pattern):
			total_converted += pattern.convert_bullets_to_points(point_creator_callback)

	return total_converted

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
