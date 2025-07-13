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

	# Spawn star bullets immediately
	spawn_star_bullets()

func spawn_star_bullets():
	var bullet_texture = get_bullet_texture()
	if not bullet_texture:
		push_error("StarPattern: Could not load bullet texture")
		return

	var points = pattern_params.get_custom_param("star_points", 5)
	var outer_radius = pattern_params.get_custom_param("outer_radius", 200.0)
	var inner_radius = outer_radius * pattern_params.get_custom_param("inner_radius_factor", 0.5)
	var outline_thickness = pattern_params.get_custom_param("outline_thickness", 2)

	var angle_step = PI / points # Half-step for alternating outer/inner
	var shape_points = []

	# Generate alternating outer/inner points
	for i in range(points * 2):
		var angle = current_rotation + i * angle_step
		var radius = outer_radius if i % 2 == 0 else inner_radius
		var point = spawn_position + Vector2(cos(angle), sin(angle)) * radius
		shape_points.append(point)

	# Draw lines between points to form outline
	for i in range(shape_points.size()):
		var a = shape_points[i]
		var b = shape_points[(i + 1) % shape_points.size()]

		for j in range(outline_thickness):
			var t = float(j) / outline_thickness
			var interp = a.lerp(b, t)
			var direction = (interp - spawn_position).normalized()
			var velocity = direction * pattern_params.bullet_speed
			var bullet = spawn_bullet(bullet_texture, interp, velocity, pattern_params.bullet_speed)
			if bullet:
				bullets_spawned += 1

	spawn_completed = true


func spawn_star_ray(bullet_texture: Texture2D, angle: float, bullet_count: int, ray_length: float):
	"""Spawn bullets along a star ray"""
	var direction = Vector2(cos(angle), sin(angle))

	# Create bullets along the ray
	for i in range(bullet_count):
		# Calculate position along ray (evenly spaced)
		var distance = (i + 1) * (ray_length / bullet_count)
		var bullet_pos = spawn_position + direction * distance

		# Calculate velocity - bullets move outward from spawn position
		var bullet_velocity = direction * pattern_params.bullet_speed

		# Add slight spread if enabled
		if pattern_params.get_custom_param("ray_spread", false):
			var spread_angle = rng.randf_range(-0.1, 0.1)
			bullet_velocity = bullet_velocity.rotated(spread_angle)

		# Spawn bullet at calculated position with outward velocity
		var bullet = spawn_bullet(bullet_texture, bullet_pos, bullet_velocity, pattern_params.bullet_speed)

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
