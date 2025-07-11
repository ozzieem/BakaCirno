extends BulletPattern
class_name BurstPattern

# Burst bullet pattern - creates rapid bursts of bullets
# Extends BulletPattern to use the new framework

# Burst-specific properties
var bullets_spawned: int = 0
var current_burst: int = 0
var burst_bullets_spawned: int = 0
var last_spawn_time: float = 0.0
var last_burst_time: float = 0.0
var burst_spawn_interval: float = 0.05 # Fast spawning within burst
var burst_interval: float = 1.0 # Time between bursts

func initialize_pattern():
	"""Initialize the burst pattern"""
	super.initialize_pattern()
	bullets_spawned = 0
	current_burst = 0
	burst_bullets_spawned = 0
	last_spawn_time = 0.0
	last_burst_time = 0.0

	# Calculate intervals
	burst_spawn_interval = 0.05 # Fast spawning
	burst_interval = pattern_params.burst_delay

	# Adjust bullet density per burst
	if pattern_params.burst_count > 0:
		pattern_params.bullet_density = max(1, pattern_params.bullet_density / pattern_params.burst_count)

func update_pattern(delta: float):
	"""Update the burst pattern"""
	super.update_pattern(delta)

	# Check if we should start a new burst
	if should_start_burst():
		start_new_burst()

	# Spawn bullets within current burst
	if is_in_burst() and should_spawn_bullet():
		spawn_burst_bullet()

func should_start_burst() -> bool:
	"""Check if it's time to start a new burst"""
	if current_burst >= pattern_params.burst_count:
		return false

	var time_since_last_burst = pattern_timer - last_burst_time
	return time_since_last_burst >= burst_interval

func start_new_burst():
	"""Start a new burst"""
	current_burst += 1
	burst_bullets_spawned = 0
	last_burst_time = pattern_timer
	last_spawn_time = pattern_timer

func is_in_burst() -> bool:
	"""Check if we're currently in a burst"""
	return current_burst > 0 and burst_bullets_spawned < pattern_params.bullet_density

func should_spawn_bullet() -> bool:
	"""Check if it's time to spawn a bullet in current burst"""
	var time_since_last = pattern_timer - last_spawn_time
	return time_since_last >= burst_spawn_interval

func spawn_burst_bullet():
	"""Spawn a bullet in the current burst"""
	var bullet_texture = get_bullet_texture()

	# Calculate direction based on burst type
	var bullet_direction = calculate_burst_direction()

	# Add random spread if enabled
	if pattern_params.get_custom_param("burst_spread", true):
		var spread_angle = rng.randf_range(-PI / 8, PI / 8) # ±22.5 degrees
		bullet_direction = bullet_direction.rotated(spread_angle)

	# Calculate bullet velocity
	var bullet_velocity = bullet_direction * pattern_params.bullet_speed

	# Spawn bullet
	var bullet = spawn_bullet(bullet_texture, spawn_position, bullet_velocity, pattern_params.bullet_speed)

	if bullet:
		bullets_spawned += 1
		burst_bullets_spawned += 1
		last_spawn_time = pattern_timer

func calculate_burst_direction() -> Vector2:
	"""Calculate direction for burst bullets"""
	var burst_type = pattern_params.get_custom_param("burst_type", "targeted")

	match burst_type:
		"targeted":
			# Aim towards target
			return get_direction_to_target()
		"spread":
			# Spread bullets in arc
			var spread_angle = deg_to_rad(pattern_params.spread_angle)
			var bullet_angle = - spread_angle / 2 + (burst_bullets_spawned / float(pattern_params.bullet_density)) * spread_angle
			return Vector2(cos(bullet_angle), sin(bullet_angle))
		"random":
			# Random direction
			var random_angle = rng.randf() * 2.0 * PI
			return Vector2(cos(random_angle), sin(random_angle))
		_:
			return get_direction_to_target()

func should_complete_pattern() -> bool:
	"""Burst pattern completes when all bursts are finished"""
	return current_burst >= pattern_params.burst_count and not is_in_burst()

func get_pattern_info() -> Dictionary:
	"""Get information about this pattern"""
	return {
		"type": "burst",
		"bullets_spawned": bullets_spawned,
		"current_burst": current_burst,
		"burst_bullets_spawned": burst_bullets_spawned,
		"total_bursts": pattern_params.burst_count,
		"is_in_burst": is_in_burst(),
		"active_bullets": get_active_bullet_count()
	}
