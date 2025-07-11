extends BulletPattern
class_name CirclePattern

# Circle bullet pattern - shoots bullets in a complete circle
# Extends BulletPattern to use the new framework

# Circle-specific properties
var current_angle: float = 0.0
var bullets_spawned: int = 0
var spawn_completed: bool = false

func initialize_pattern():
	"""Initialize the circle pattern"""
	super.initialize_pattern()
	current_angle = 0.0
	bullets_spawned = 0
	spawn_completed = false

	# Spawn all bullets at once for circle pattern
	spawn_circle_bullets()

func spawn_circle_bullets():
	"""Spawn bullets in a circle formation"""
	var bullet_count = pattern_params.bullet_density
	var angle_step = deg_to_rad(pattern_params.spread_angle / bullet_count)

	# Get bullet texture
	var bullet_texture = get_bullet_texture()

	# Create bullets in circle
	for i in range(bullet_count):
		var angle = i * angle_step + deg_to_rad(current_angle)

		# Calculate velocity direction
		var velocity_direction = Vector2(cos(angle), sin(angle))

		# Apply rotation if specified
		if pattern_params.rotation_speed != 0.0:
			var rotation_angle = pattern_timer * pattern_params.rotation_speed
			velocity_direction = velocity_direction.rotated(rotation_angle)

		# Calculate bullet velocity
		var bullet_velocity = velocity_direction * pattern_params.bullet_speed

		# Spawn bullet
		var bullet = spawn_bullet(bullet_texture, spawn_position, bullet_velocity, pattern_params.bullet_speed)

		# Apply pattern-specific properties
		if bullet:
			bullets_spawned += 1

	spawn_completed = true

func update_pattern(delta: float):
	"""Update the circle pattern"""
	super.update_pattern(delta)

	# Update rotation if specified
	if pattern_params.rotation_speed != 0.0:
		current_angle += rad_to_deg(pattern_params.rotation_speed * delta)

		# Update bullet velocities for rotation
		update_bullet_rotations(delta)

func update_bullet_rotations(delta: float):
	"""Update bullet velocities for rotation effect"""
	var rotation_delta = pattern_params.rotation_speed * delta

	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			# Rotate the bullet's velocity
			bullet.velocity = bullet.velocity.rotated(rotation_delta)

func should_complete_pattern() -> bool:
	"""Circle pattern completes when all bullets are spawned and time elapsed"""
	return spawn_completed and (pattern_timer >= pattern_params.pattern_duration or bullets.is_empty())

func get_pattern_info() -> Dictionary:
	"""Get information about this pattern"""
	return {
		"type": "circle",
		"bullets_spawned": bullets_spawned,
		"current_angle": current_angle,
		"spawn_completed": spawn_completed,
		"active_bullets": get_active_bullet_count()
	}
