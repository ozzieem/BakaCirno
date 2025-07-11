extends BulletPattern
class_name StarPattern

# Star bullet pattern - creates star formations with variable points
# Extends BulletPattern to use the new framework

# Star-specific properties
var star_points: int = 5
var bullets_spawned: int = 0
var current_rotation: float = 0.0
var spawn_completed: bool = false

func initialize_pattern():
	"""Initialize the star pattern"""
	super.initialize_pattern()
	star_points = pattern_params.get_custom_param("star_points", 5)
	bullets_spawned = 0
	current_rotation = 0.0
	spawn_completed = false

	# Spawn star bullets
	spawn_star_bullets()

func spawn_star_bullets():
	"""Spawn bullets in star formation"""
	var bullet_texture = get_bullet_texture()

	# Calculate angle between star points
	var angle_between_points = (2.0 * PI) / star_points

	# Create bullets for each star point
	for point in range(star_points):
		var point_angle = point * angle_between_points + current_rotation

		# Create main ray
		spawn_star_ray(bullet_texture, point_angle, pattern_params.bullet_density)

		# Create secondary rays for more complex star (if enabled)
		if pattern_params.get_custom_param("complex_star", false):
			var secondary_angle = point_angle + (angle_between_points * 0.5)
			spawn_star_ray(bullet_texture, secondary_angle, pattern_params.bullet_density / 2)

	spawn_completed = true

func spawn_star_ray(bullet_texture: Texture2D, angle: float, bullet_count: int):
	"""Spawn bullets along a star ray"""
	var direction = Vector2(cos(angle), sin(angle))

	# Create bullets along the ray
	for i in range(bullet_count):
		# Calculate position along ray
		var distance_factor = (i + 1) / float(bullet_count)
		var bullet_velocity = direction * pattern_params.bullet_speed * distance_factor

		# Add slight spread if enabled
		if pattern_params.get_custom_param("ray_spread", false):
			var spread_angle = rng.randf_range(-0.1, 0.1)
			bullet_velocity = bullet_velocity.rotated(spread_angle)

		# Spawn bullet
		var bullet = spawn_bullet(bullet_texture, spawn_position, bullet_velocity, pattern_params.bullet_speed)

		if bullet:
			bullets_spawned += 1

func update_pattern(delta: float):
	"""Update the star pattern"""
	super.update_pattern(delta)

	# Update rotation if specified
	if pattern_params.rotation_speed != 0.0:
		current_rotation += pattern_params.rotation_speed * delta

		# Update bullet velocities for rotation (if enabled)
		if pattern_params.get_custom_param("rotating_bullets", false):
			update_bullet_rotations(delta)

func update_bullet_rotations(delta: float):
	"""Update bullet velocities for rotation effect"""
	var rotation_delta = pattern_params.rotation_speed * delta

	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			# Rotate the bullet's velocity
			bullet.velocity = bullet.velocity.rotated(rotation_delta)

func should_complete_pattern() -> bool:
	"""Star pattern completes when all bullets are spawned and time elapsed"""
	return spawn_completed and (pattern_timer >= pattern_params.pattern_duration or bullets.is_empty())

func get_pattern_info() -> Dictionary:
	"""Get information about this pattern"""
	return {
		"type": "star",
		"star_points": star_points,
		"bullets_spawned": bullets_spawned,
		"current_rotation": current_rotation,
		"spawn_completed": spawn_completed,
		"active_bullets": get_active_bullet_count()
	}
