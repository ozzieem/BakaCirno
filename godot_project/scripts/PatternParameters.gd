extends Resource
class_name PatternParameters

# Configuration class for bullet patterns
# Handles all parameters that can be adjusted for different patterns

# Basic pattern properties
@export var bullet_speed: float = 200.0
@export var bullet_density: int = 18 # Number of bullets in pattern
@export var spawn_rate: float = 1.0 # Spawns per second
@export var pattern_duration: float = 5.0 # How long pattern lasts
@export var spawn_delay: float = 0.0 # Delay before pattern starts

# Movement and rotation
@export var rotation_speed: float = 0.0 # Radians per second
@export var movement_speed: float = 0.0 # Pattern movement speed
@export var scale_factor: float = 1.0 # Pattern scale multiplier
@export var acceleration: float = 0.0 # Speed increase over time

# Geometric properties
@export var spread_angle: float = 360.0 # Angle coverage in degrees
@export var radius: float = 0.0 # Pattern radius
@export var frequency: float = 1.0 # For wave patterns
@export var amplitude: float = 50.0 # For wave patterns

# Targeting and behavior
@export var target_player: bool = true # Whether to target player
@export var track_player: bool = false # Whether to continuously track player
@export var lead_target: bool = false # Whether to lead target's movement
@export var homing_strength: float = 0.0 # How much bullets home in (0.0 to 1.0)

# Visual and audio
@export var bullet_colors: Dictionary = {
	"blue": "res://assets/textures/bullets/bullet_Blueshot1.png",
	"red": "res://assets/textures/bullets/bullet_Redshot1.png",
	"yellow": "res://assets/textures/bullets/bullet_Yellowshot1.png",
	"green": "res://assets/textures/bullets/bullet_Greenshot1.png",
	"purple": "res://assets/textures/bullets/bullet_Purpleshot.png"
}

@export var color_scheme: String = "random" # "random", "single", "gradient"
@export var primary_color: String = "blue"
@export var secondary_color: String = "red"

# Difficulty scaling
@export var difficulty_scale: float = 1.0
@export var scales_with_time: bool = true
@export var scales_with_kills: bool = true
@export var max_difficulty_scale: float = 3.0

# Pattern-specific parameters
@export var custom_params: Dictionary = {}

# Pattern type hints
enum PatternType {
	CIRCLE,
	SPIRAL,
	WAVE,
	STAR,
	RANDOM,
	BURST,
	WALL,
	MAZE,
	CUSTOM
}

@export var pattern_type: PatternType = PatternType.CIRCLE

# Behavior modifiers
@export var bounces_off_walls: bool = false
@export var wraps_around_screen: bool = false
@export var gravity_affected: bool = false
@export var gravity_strength: float = 98.0

# Timing and rhythm
@export var burst_count: int = 1 # Number of bursts
@export var burst_delay: float = 0.5 # Delay between bursts
@export var rhythm_pattern: Array[float] = [] # Custom timing pattern

# Advanced behaviors
@export var bullet_lifetime: float = 10.0 # How long bullets live
@export var fade_out_time: float = 1.0 # Fade out duration
@export var collision_groups: Array[String] = ["enemy_bullets"]

func _init():
	"""Initialize with default values"""
	setup_default_colors()

func setup_default_colors():
	"""Set up default color scheme"""
	if bullet_colors.is_empty():
		bullet_colors = {
			"blue": "res://assets/textures/bullets/bullet_Blueshot1.png",
			"red": "res://assets/textures/bullets/bullet_Redshot1.png",
			"yellow": "res://assets/textures/bullets/bullet_Yellowshot1.png",
			"green": "res://assets/textures/bullets/bullet_Greenshot1.png",
			"purple": "res://assets/textures/bullets/bullet_Purpleshot.png"
		}

func clone() -> PatternParameters:
	"""Create a copy of this pattern parameters"""
	var new_params = PatternParameters.new()

	# Copy all properties
	new_params.bullet_speed = bullet_speed
	new_params.bullet_density = bullet_density
	new_params.spawn_rate = spawn_rate
	new_params.pattern_duration = pattern_duration
	new_params.spawn_delay = spawn_delay

	new_params.rotation_speed = rotation_speed
	new_params.movement_speed = movement_speed
	new_params.scale_factor = scale_factor
	new_params.acceleration = acceleration

	new_params.spread_angle = spread_angle
	new_params.radius = radius
	new_params.frequency = frequency
	new_params.amplitude = amplitude

	new_params.target_player = target_player
	new_params.track_player = track_player
	new_params.lead_target = lead_target
	new_params.homing_strength = homing_strength

	new_params.bullet_colors = bullet_colors.duplicate()
	new_params.color_scheme = color_scheme
	new_params.primary_color = primary_color
	new_params.secondary_color = secondary_color

	new_params.difficulty_scale = difficulty_scale
	new_params.scales_with_time = scales_with_time
	new_params.scales_with_kills = scales_with_kills
	new_params.max_difficulty_scale = max_difficulty_scale

	new_params.custom_params = custom_params.duplicate()
	new_params.pattern_type = pattern_type

	new_params.bounces_off_walls = bounces_off_walls
	new_params.wraps_around_screen = wraps_around_screen
	new_params.gravity_affected = gravity_affected
	new_params.gravity_strength = gravity_strength

	new_params.burst_count = burst_count
	new_params.burst_delay = burst_delay
	new_params.rhythm_pattern = rhythm_pattern.duplicate()

	new_params.bullet_lifetime = bullet_lifetime
	new_params.fade_out_time = fade_out_time
	new_params.collision_groups = collision_groups.duplicate()

	return new_params

func apply_difficulty_scaling(scale: float):
	"""Apply difficulty scaling to parameters"""
	scale = min(scale, max_difficulty_scale)

	if scales_with_time or scales_with_kills:
		difficulty_scale = scale

		# Scale various parameters
		bullet_speed *= scale
		bullet_density = int(bullet_density * scale)
		spawn_rate *= scale

		# Some parameters scale differently
		rotation_speed *= sqrt(scale) # Slower scaling for rotation
		homing_strength = min(homing_strength * scale, 1.0) # Cap at 1.0

func set_custom_param(key: String, value):
	"""Set a custom parameter"""
	custom_params[key] = value

func get_custom_param(key: String, default_value = null):
	"""Get a custom parameter with optional default"""
	return custom_params.get(key, default_value)

func has_custom_param(key: String) -> bool:
	"""Check if custom parameter exists"""
	return key in custom_params

# Preset configurations
static func create_circle_preset() -> PatternParameters:
	"""Create preset for circle patterns"""
	var params = PatternParameters.new()
	params.pattern_type = PatternType.CIRCLE
	params.bullet_density = 18
	params.bullet_speed = 200.0
	params.spread_angle = 360.0
	return params

static func create_spiral_preset() -> PatternParameters:
	"""Create preset for Archimedean spiral patterns"""
	var params = PatternParameters.new()
	params.pattern_type = PatternType.SPIRAL
	params.bullet_density = 40 # More bullets for smooth spiral
	params.bullet_speed = 120.0 # Moderate speed
	params.spawn_rate = 60.0 # Fast spawning for smooth spiral
	params.pattern_duration = 10.0 # Shorter duration per attack

	# Set custom parameters for Archimedean spiral
	params.set_custom_param("spiral_arms", 1)
	params.set_custom_param("spiral_expansion_factor", 8.0)
	params.set_custom_param("initial_radius", 20.0)

	return params

static func create_wave_preset() -> PatternParameters:
	"""Create preset for wave patterns"""
	var params = PatternParameters.new()
	params.pattern_type = PatternType.WAVE
	params.bullet_density = 12
	params.bullet_speed = 180.0
	params.frequency = 2.0
	params.amplitude = 100.0
	return params

static func create_star_preset() -> PatternParameters:
	"""Create preset for star patterns"""
	var params = PatternParameters.new()
	params.pattern_type = PatternType.STAR
	params.bullet_density = 148 # Bullets per star point/ray
	params.bullet_speed = 80.0 # Moderate speed for visibility
	params.spread_angle = 360.0 # Full circle for proper star formation
	params.spawn_rate = 1.0 # Single burst spawn
	params.pattern_duration = 10.0 # Longer duration for bullets to travel

	# Star-specific parameters
	params.set_custom_param("star_points", 6) # 6-pointed star
	params.set_custom_param("ray_length", 220) # 5-pointed star
	params.set_custom_param("inner_radius_factor", 0.25) # Controls how deep the inner valleys go
	params.set_custom_param("bullets_per_ray", 3) # Number of bullets per tip/valley
	params.set_custom_param("outer_radius", 85.0) # Initial outer radius (close to enemy)
	params.set_custom_param("ray_spread_factor", 1.5) # How much bullets spread out as they travel
	params.set_custom_param("bullet_spacing", 20.0) # Distance between bullets along each ray
	params.set_custom_param("complex_star", false) # Simple star by default
	params.set_custom_param("rotating_bullets", false) # Static bullets


	return params

static func create_star_outline_preset() -> PatternParameters:
	var params = PatternParameters.new()
	params.pattern_type = PatternType.STAR
	params.bullet_speed = 80.0
	params.pattern_duration = 8.0
	params.spawn_rate = 1.0
	params.set_custom_param("star_points", 6)
	params.set_custom_param("outer_radius", 85.0)
	params.set_custom_param("inner_radius_factor", 0.25)
	params.set_custom_param("outline_thickness", 3)
	return params
	return params


static func create_random_preset() -> PatternParameters:
	"""Create preset for random patterns"""
	var params = PatternParameters.new()
	params.pattern_type = PatternType.RANDOM
	params.bullet_density = 8
	params.bullet_speed = 250.0
	params.target_player = true
	params.spawn_rate = 2.0
	return params
