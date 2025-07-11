extends BulletPattern
class_name RandomPattern

# Random bullet pattern - shoots bullets towards player with variation
# Extends BulletPattern to use the new framework

# Random-specific properties
var bullets_spawned: int = 0
var last_spawn_time: float = 0.0
var spawn_interval: float = 0.5 # Time between bullet spawns

func initialize_pattern():
	"""Initialize the random pattern"""
	super.initialize_pattern()
	bullets_spawned = 0
	last_spawn_time = 0.0
	spawn_interval = 1.0 / pattern_params.spawn_rate

func update_pattern(delta: float):
	"""Update the random pattern"""
	super.update_pattern(delta)

	# Spawn bullets at intervals
	if should_spawn_bullet():
		spawn_random_bullet()

func get_bullet_texture(color_name: String = "") -> Texture2D:
	"""Get random shot texture - uses dedicated sprites for random pattern"""
	var random_textures = [
		"res://assets/textures/bullets/bullet_randomShot.png",
		"res://assets/textures/bullets/bullet_randomShot2.png",
		"res://assets/textures/bullets/bullet_randomShot3.png",
		"res://assets/textures/bullets/bullet_randomShot4.png"
	]

	# For random pattern, use consistent texture per pattern instance
	if not pattern_texture:
		var selected_texture = random_textures[rng.randi() % random_textures.size()]
		if ResourceLoader.exists(selected_texture):
			pattern_texture = load(selected_texture)
		else:
			# Fallback to first texture
			pattern_texture = load(random_textures[0])

	return pattern_texture

func should_spawn_bullet() -> bool:
	"""Check if it's time to spawn a new bullet"""
	var time_since_last = pattern_timer - last_spawn_time
	return time_since_last >= spawn_interval and bullets_spawned < pattern_params.bullet_density

func spawn_random_bullet():
	"""Spawn a single random bullet"""
	# Get bullet texture
	var bullet_texture = get_bullet_texture()

	# Calculate base direction to target
	var base_direction = get_direction_to_target()

	# Add random variation
	var random_angle = rng.randf_range(-PI / 6, PI / 6) # ±30 degrees
	var bullet_direction = base_direction.rotated(random_angle)

	# Add random speed variation
	var speed_variation = rng.randf_range(0.8, 1.2)
	var bullet_speed = pattern_params.bullet_speed * speed_variation

	# Calculate bullet velocity
	var bullet_velocity = bullet_direction * bullet_speed

	# Add slight downward bias
	bullet_velocity.y += 30.0

	# Spawn bullet
	var bullet = spawn_bullet(bullet_texture, spawn_position, bullet_velocity, bullet_speed)

	if bullet:
		bullets_spawned += 1
		last_spawn_time = pattern_timer

		# Apply homing if specified
		if pattern_params.homing_strength > 0.0:
			bullet.set_custom_behavior("homing", pattern_params.homing_strength)

func update_bullet_behavior(bullet: Bullet, delta: float):
	"""Update individual bullet behavior"""
	super.update_bullet_behavior(bullet, delta)

	# Apply homing behavior if enabled
	if pattern_params.homing_strength > 0.0:
		apply_homing_behavior(bullet, delta)

func apply_homing_behavior(bullet: Bullet, delta: float):
	"""Apply homing behavior to bullet"""
	if not bullet or not is_instance_valid(bullet):
		return

	# Get current direction to target
	var current_target_direction = (target_position - bullet.position).normalized()

	# Blend current velocity with target direction
	var homing_strength = pattern_params.homing_strength
	var current_direction = bullet.velocity.normalized()
	var new_direction = current_direction.lerp(current_target_direction, homing_strength * delta)

	# Apply new velocity
	bullet.velocity = new_direction * bullet.velocity.length()

func should_complete_pattern() -> bool:
	"""Random pattern completes when all bullets spawned and time elapsed"""
	return bullets_spawned >= pattern_params.bullet_density and pattern_timer >= pattern_params.pattern_duration

func get_pattern_info() -> Dictionary:
	"""Get information about this pattern"""
	return {
		"type": "random",
		"bullets_spawned": bullets_spawned,
		"spawn_interval": spawn_interval,
		"last_spawn_time": last_spawn_time,
		"active_bullets": get_active_bullet_count()
	}
