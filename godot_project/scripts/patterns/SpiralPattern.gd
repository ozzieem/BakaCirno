extends BulletPattern
class_name SpiralPattern

# Archimedean spiral pattern - creates expanding spirals around enemy
# Uses the mathematical formula: r = a + b*θ
# where r is radius, a is initial radius, b controls expansion rate, θ is angle
# r = a + b*θ where a is initial radius, b controls expansion rate
# Extends BulletPattern to use the new framework

# Spiral-specific properties
var current_rotation: float = 0.0 # Overall rotation of the spiral
var bullets_spawned: int = 0
var last_spawn_time: float = 0.0
var spawn_interval: float = 0.05 # Frequent spawning for smooth spiral
var spiral_arms: int = 1 # Number of spiral arms
var spiral_expansion_factor: float = 8.0 # How much the spiral expands per revolution (b in r = a + b*θ)
var initial_radius: float = 20.0 # Starting radius (a in r = a + b*θ)
var max_spiral_length: float = 200.0 # Maximum spiral length in pixels
var rotation_speed: float = 2.0 # How fast the spiral rotates around enemy
var attack_count: int = 1 # Number of attacks this enemy has performed
var enemy_center: Vector2 # Center position of the enemy

func initialize_pattern():
	"""Initialize the Archimedean spiral pattern"""
	super.initialize_pattern()
	current_rotation = 0.0
	bullets_spawned = 0
	last_spawn_time = 0.0
	spawn_interval = 1.0 / pattern_params.spawn_rate

	# Get custom parameters
	spiral_arms = pattern_params.get_custom_param("spiral_arms", 1)
	spiral_expansion_factor = pattern_params.get_custom_param("spiral_expansion_factor", 8.0)
	initial_radius = pattern_params.get_custom_param("initial_radius", 20.0)
	attack_count = pattern_params.get_custom_param("attack_count", 1)
	enemy_center = pattern_params.get_custom_param("enemy_position", spawn_position)

	# Calculate max spiral length based on attack count
	# Each attack makes the spiral longer, incentivizing quick kills
	max_spiral_length = initial_radius + (attack_count * 80.0) # 80 pixels per attack

	# Rotation speed varies slightly per attack for visual variety
	rotation_speed = 1.5 + (attack_count * 0.3)

func update_pattern(delta: float):
	"""Update the Archimedean spiral pattern"""
	super.update_pattern(delta)

	# Spawn bullets at intervals
	if should_spawn_bullet():
		spawn_spiral_bullets()

	# Update spiral rotation around enemy
	current_rotation += rotation_speed * delta

func should_spawn_bullet() -> bool:
	"""Check if it's time to spawn new bullets"""
	var time_since_last = pattern_timer - last_spawn_time
	return time_since_last >= spawn_interval and bullets_spawned < pattern_params.bullet_density

func spawn_spiral_bullets():
	"""Spawn bullets in an Archimedean spiral pattern around the enemy"""
	var bullet_texture = get_bullet_texture()

	# Spawn bullets for each spiral arm
	for arm in range(spiral_arms):
		# Calculate the spiral angle for this bullet
		# Using more bullets for longer spirals based on attack count
		var spiral_progress = float(bullets_spawned) / float(pattern_params.bullet_density)
		var max_angle = (2.0 * PI) * (2.0 + attack_count * 0.5) # More revolutions per attack
		var spiral_angle = spiral_progress * max_angle

		# Add arm offset for multiple arms
		var arm_offset = arm * (2.0 * PI / spiral_arms)
		spiral_angle += arm_offset

		# Add current rotation to make spiral rotate around enemy
		spiral_angle += current_rotation

		# Calculate radius using Archimedean spiral formula: r = a + b*θ
		var spiral_radius = initial_radius + (spiral_expansion_factor * spiral_angle)

		# Limit radius to max spiral length (grows with attack count)
		spiral_radius = min(spiral_radius, max_spiral_length)

		# Calculate bullet position relative to enemy center
		var spiral_x = cos(spiral_angle) * spiral_radius
		var spiral_y = sin(spiral_angle) * spiral_radius
		var bullet_spawn_pos = enemy_center + Vector2(spiral_x, spiral_y)

		# Calculate bullet direction - tangent to the spiral
		# For Archimedean spiral, the tangent angle is spiral_angle + atan2(spiral_expansion_factor, spiral_radius)
		var tangent_angle = spiral_angle + atan2(spiral_expansion_factor, spiral_radius)
		var bullet_direction = Vector2(cos(tangent_angle), sin(tangent_angle))

		# Calculate bullet velocity
		var bullet_velocity = bullet_direction * pattern_params.bullet_speed

		# Spawn bullet
		var bullet = spawn_bullet(bullet_texture, bullet_spawn_pos, bullet_velocity, pattern_params.bullet_speed)

		if bullet:
			bullets_spawned += 1

	last_spawn_time = pattern_timer

func should_complete_pattern() -> bool:
	"""Archimedean spiral pattern completes when maximum bullets spawned"""
	return bullets_spawned >= pattern_params.bullet_density

func get_pattern_info() -> Dictionary:
	"""Get information about this spiral pattern"""
	return {
		"type": "archimedean_spiral",
		"bullets_spawned": bullets_spawned,
		"current_rotation": current_rotation,
		"spiral_arms": spiral_arms,
		"attack_count": attack_count,
		"max_spiral_length": max_spiral_length,
		"active_bullets": get_active_bullet_count()
	}
