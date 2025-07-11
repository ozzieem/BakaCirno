extends BulletPattern
class_name WavePattern

# Wave bullet pattern - creates sine wave formations
# Extends BulletPattern to use the new framework

# Wave-specific properties
var bullets_spawned: int = 0
var last_spawn_time: float = 0.0
var spawn_interval: float = 0.1
var wave_offset: float = 0.0

func initialize_pattern():
	"""Initialize the wave pattern"""
	super.initialize_pattern()
	bullets_spawned = 0
	last_spawn_time = 0.0
	spawn_interval = 1.0 / pattern_params.spawn_rate
	wave_offset = 0.0

func update_pattern(delta: float):
	"""Update the wave pattern"""
	super.update_pattern(delta)

	# Spawn bullets at intervals
	if should_spawn_bullet():
		spawn_wave_bullet()

	# Update wave offset for animation
	wave_offset += pattern_params.frequency * delta

func should_spawn_bullet() -> bool:
	"""Check if it's time to spawn a new bullet"""
	var time_since_last = pattern_timer - last_spawn_time
	return time_since_last >= spawn_interval and bullets_spawned < pattern_params.bullet_density

func spawn_wave_bullet():
	"""Spawn a bullet following wave pattern"""
	var bullet_texture = get_bullet_texture()

	# Calculate wave parameters
	var wave_progress = (bullets_spawned / float(pattern_params.bullet_density)) * 2.0 * PI
	var wave_angle = wave_progress + wave_offset

	# Calculate base direction (towards target or downward)
	var base_direction = get_direction_to_target()

	# Calculate wave offset perpendicular to base direction
	var perpendicular = Vector2(-base_direction.y, base_direction.x)
	var wave_displacement = sin(wave_angle * pattern_params.frequency) * pattern_params.amplitude

	# Calculate bullet direction
	var bullet_direction = base_direction + (perpendicular * wave_displacement / 100.0)
	bullet_direction = bullet_direction.normalized()

	# Calculate bullet velocity
	var bullet_velocity = bullet_direction * pattern_params.bullet_speed

	# Spawn bullet
	var bullet = spawn_bullet(bullet_texture, spawn_position, bullet_velocity, pattern_params.bullet_speed)

	if bullet:
		bullets_spawned += 1
		last_spawn_time = pattern_timer

func update_bullet_behavior(bullet: Bullet, delta: float):
	"""Update individual bullet behavior"""
	super.update_bullet_behavior(bullet, delta)

	# Apply wave motion if enabled
	if pattern_params.get_custom_param("continuous_wave", false):
		apply_wave_motion(bullet, delta)

func apply_wave_motion(bullet: Bullet, delta: float):
	"""Apply continuous wave motion to bullet"""
	if not bullet or not is_instance_valid(bullet):
		return

	# Calculate wave motion perpendicular to velocity
	var velocity_direction = bullet.velocity.normalized()
	var perpendicular = Vector2(-velocity_direction.y, velocity_direction.x)

	# Apply wave motion
	var wave_time = pattern_timer + bullet.position.length() * 0.01
	var wave_force = sin(wave_time * pattern_params.frequency) * pattern_params.amplitude * 0.5

	bullet.velocity += perpendicular * wave_force * delta

func should_complete_pattern() -> bool:
	"""Wave pattern completes when all bullets spawned"""
	return bullets_spawned >= pattern_params.bullet_density

func get_pattern_info() -> Dictionary:
	"""Get information about this pattern"""
	return {
		"type": "wave",
		"bullets_spawned": bullets_spawned,
		"wave_offset": wave_offset,
		"frequency": pattern_params.frequency,
		"amplitude": pattern_params.amplitude,
		"active_bullets": get_active_bullet_count()
	}
