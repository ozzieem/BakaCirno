extends Control
class_name StarPatternDebugUI

# References to UI elements
@onready var star_points_slider = $VBoxContainer/StarPointsContainer/StarPointsSlider
@onready var star_points_label = $VBoxContainer/StarPointsContainer/StarPointsLabel

@onready var outer_radius_slider = $VBoxContainer/OuterRadiusContainer/OuterRadiusSlider
@onready var outer_radius_label = $VBoxContainer/OuterRadiusContainer/OuterRadiusLabel

@onready var inner_radius_factor_slider = $VBoxContainer/InnerRadiusFactorContainer/InnerRadiusFactorSlider
@onready var inner_radius_factor_label = $VBoxContainer/InnerRadiusFactorContainer/InnerRadiusFactorLabel

@onready var bullet_speed_slider = $VBoxContainer/BulletSpeedContainer/BulletSpeedSlider
@onready var bullet_speed_label = $VBoxContainer/BulletSpeedContainer/BulletSpeedLabel

@onready var bullets_per_ray_slider = $VBoxContainer/BulletsPerRayContainer/BulletsPerRaySlider
@onready var bullets_per_ray_label = $VBoxContainer/BulletsPerRayContainer/BulletsPerRayLabel

@onready var bullet_spacing_slider = $VBoxContainer/BulletSpacingContainer/BulletSpacingSlider
@onready var bullet_spacing_label = $VBoxContainer/BulletSpacingContainer/BulletSpacingLabel

@onready var outline_thickness_slider = $VBoxContainer/OutlineThicknessContainer/OutlineThicknessSlider
@onready var outline_thickness_label = $VBoxContainer/OutlineThicknessContainer/OutlineThicknessLabel

@onready var pattern_selector = $VBoxContainer/PatternSelectorContainer/PatternSelector
@onready var pattern_label = $VBoxContainer/PatternSelectorContainer/PatternLabel

@onready var reset_button = $VBoxContainer/ButtonContainer/ResetButton
@onready var force_star_button = $VBoxContainer/ButtonContainer/ForceStarButton
@onready var info_label = $VBoxContainer/InfoLabel

# Reference to main scene
var main_scene: Node2D

# Debug enemy for testing patterns
var debug_enemy: Enemy
var debug_enemy_active: bool = false

# Timer for delayed pattern firing after parameter changes
var pattern_fire_timer: Timer
var pattern_fire_delay: float = 0.5

# Current parameter values
var current_star_points: int = 6
var current_outer_radius: float = 85.0
var current_inner_radius_factor: float = 0.25
var current_bullet_speed: float = 80.0
var current_bullets_per_ray: int = 3
var current_bullet_spacing: float = 20.0
var current_outline_thickness: int = 3
var current_pattern: String = "star"

# Available patterns
var available_patterns: Array[String] = ["circle", "spiral", "wave", "star", "star_outline", "burst"]

func _ready():
	# Initialize pattern selector
	if pattern_selector:
		pattern_selector.clear()
		for pattern in available_patterns:
			pattern_selector.add_item(pattern.capitalize())
		pattern_selector.selected = available_patterns.find(current_pattern)
		pattern_selector.item_selected.connect(_on_pattern_selected)

	# Connect slider signals
	star_points_slider.value_changed.connect(_on_star_points_changed)
	outer_radius_slider.value_changed.connect(_on_outer_radius_changed)
	inner_radius_factor_slider.value_changed.connect(_on_inner_radius_factor_changed)
	bullet_speed_slider.value_changed.connect(_on_bullet_speed_changed)
	bullets_per_ray_slider.value_changed.connect(_on_bullets_per_ray_changed)
	bullet_spacing_slider.value_changed.connect(_on_bullet_spacing_changed)
	outline_thickness_slider.value_changed.connect(_on_outline_thickness_changed)

	# Connect button signals
	reset_button.pressed.connect(_on_reset_pressed)
	force_star_button.pressed.connect(_on_force_star_pressed)

	# Initialize delay timer for pattern firing
	pattern_fire_timer = Timer.new()
	pattern_fire_timer.wait_time = pattern_fire_delay
	pattern_fire_timer.one_shot = true
	pattern_fire_timer.timeout.connect(_on_pattern_fire_timer_timeout)
	add_child(pattern_fire_timer)

	# Initialize slider values
	reset_to_defaults()

	# Initially hidden
	visible = false

func set_main_scene(main: Node2D):
	"""Set reference to main scene"""
	main_scene = main

func _on_star_points_changed(value: float):
	current_star_points = int(value)
	star_points_label.text = "Star Points: " + str(current_star_points)
	update_star_patterns()
	start_pattern_fire_timer()

func _on_outer_radius_changed(value: float):
	current_outer_radius = value
	outer_radius_label.text = "Outer Radius: " + str(int(current_outer_radius))
	update_star_patterns()
	start_pattern_fire_timer()

func _on_inner_radius_factor_changed(value: float):
	current_inner_radius_factor = value
	inner_radius_factor_label.text = "Inner Radius Factor: " + str(current_inner_radius_factor).pad_decimals(2)
	update_star_patterns()
	start_pattern_fire_timer()

func _on_bullet_speed_changed(value: float):
	current_bullet_speed = value
	bullet_speed_label.text = "Bullet Speed: " + str(int(current_bullet_speed))
	update_star_patterns()
	start_pattern_fire_timer()

func _on_bullets_per_ray_changed(value: float):
	current_bullets_per_ray = int(value)
	bullets_per_ray_label.text = "Bullets Per Ray: " + str(current_bullets_per_ray)
	update_star_patterns()
	start_pattern_fire_timer()

func _on_bullet_spacing_changed(value: float):
	current_bullet_spacing = value
	bullet_spacing_label.text = "Bullet Spacing: " + str(int(current_bullet_spacing))
	update_star_patterns()
	start_pattern_fire_timer()

func _on_outline_thickness_changed(value: float):
	current_outline_thickness = int(value)
	outline_thickness_label.text = "Outline Thickness: " + str(current_outline_thickness)
	update_star_patterns()
	start_pattern_fire_timer()

func _on_pattern_selected(index: int):
	"""Handle pattern selection from dropdown"""
	if index >= 0 and index < available_patterns.size():
		current_pattern = available_patterns[index]
		pattern_label.text = "Pattern: " + current_pattern.capitalize()
		update_debug_enemy_pattern()
		update_debug_enemy_patterns()
		start_pattern_fire_timer()

func _on_reset_pressed():
	"""Reset all parameters to defaults"""
	reset_to_defaults()
	update_star_patterns()
	start_pattern_fire_timer()

func _on_force_star_pressed():
	"""Force the debug enemy to fire a pattern immediately"""
	if debug_enemy_active and debug_enemy and is_instance_valid(debug_enemy):
		fire_debug_enemy_pattern()
		print("Manual pattern fire triggered")
	else:
		# Fallback to old behavior if no debug enemy
		if main_scene:
			force_next_star_pattern()
			print("No debug enemy active, forcing next enemy pattern")

func reset_to_defaults():
	"""Reset all sliders to default values"""
	star_points_slider.value = 6
	outer_radius_slider.value = 85.0
	inner_radius_factor_slider.value = 0.25
	bullet_speed_slider.value = 80.0
	bullets_per_ray_slider.value = 3
	bullet_spacing_slider.value = 20.0
	outline_thickness_slider.value = 3

func update_star_patterns():
	"""Update star pattern parameters in all pattern managers"""
	if not main_scene:
		return

	# Update parameters for all existing enemies
	for enemy in main_scene.enemies:
		if enemy and is_instance_valid(enemy) and enemy.pattern_manager:
			update_pattern_manager_star_params(enemy.pattern_manager)

	# Update debug enemy patterns if active
	update_debug_enemy_patterns()

func update_pattern_manager_star_params(pattern_manager: PatternManager):
	"""Update star pattern parameters in a specific pattern manager"""
	if not pattern_manager:
		return

	# Update all star presets
	var star_presets = ["easy_star", "normal_star", "hard_star", "easy_star_outline", "normal_star_outline", "hard_star_outline"]

	for preset_name in star_presets:
		if preset_name in pattern_manager.pattern_presets:
			var preset = pattern_manager.pattern_presets[preset_name]

			# Update common parameters
			preset.bullet_speed = current_bullet_speed
			preset.set_custom_param("star_points", current_star_points)
			preset.set_custom_param("outer_radius", current_outer_radius)
			preset.set_custom_param("inner_radius_factor", current_inner_radius_factor)
			preset.set_custom_param("bullets_per_ray", current_bullets_per_ray)
			preset.set_custom_param("bullet_spacing", current_bullet_spacing)

			# Update outline thickness for outline variants
			if "outline" in preset_name:
				preset.set_custom_param("outline_thickness", current_outline_thickness)

func force_next_star_pattern():
	"""Force the next enemy spawn to use a star pattern"""
	if not main_scene:
		return

	# First try to force debug enemy pattern if active
	if debug_enemy_active and debug_enemy and is_instance_valid(debug_enemy):
		var pattern_choices = ["star", "star_outline"]
		var chosen_pattern = pattern_choices[randi() % pattern_choices.size()]
		debug_enemy.pattern_manager.force_next_pattern(chosen_pattern)
		print("Forced debug enemy pattern to: ", chosen_pattern)
		return

	# Find any active enemy and force its next pattern to be star
	for enemy in main_scene.enemies:
		if enemy and is_instance_valid(enemy) and enemy.pattern_manager:
			# Randomly choose between star and star_outline
			var pattern_choices = ["star", "star_outline"]
			var chosen_pattern = pattern_choices[randi() % pattern_choices.size()]
			enemy.pattern_manager.force_next_pattern(chosen_pattern)
			print("Forced next pattern to: ", chosen_pattern)
			return

	print("No active enemies found to force pattern on")

func update_info():
	"""Update the info label with current difficulty"""
	if main_scene:
		var difficulty = 1.0
		if main_scene.enemies.size() > 0:
			var enemy = main_scene.enemies[0]
			if enemy and is_instance_valid(enemy) and enemy.pattern_manager:
				difficulty = enemy.pattern_manager.current_difficulty

		var debug_status = "Debug Enemy: " + ("Active" if debug_enemy_active else "Inactive")
		info_label.text = "Press F2 to toggle this panel\nChanges apply to new star patterns\nCurrent difficulty: " + str(difficulty).pad_decimals(2) + "\n" + debug_status

func _process(_delta):
	"""Update info display"""
	update_info()

func toggle_visibility():
	"""Toggle the visibility of the debug panel"""
	visible = not visible
	if visible:
		spawn_debug_enemy()
		# Pause music when debug UI opens
		if main_scene and main_scene.has_method("pause_music"):
			main_scene.pause_music()
		# Enable player invincibility when debug UI opens
		if main_scene and main_scene.has_method("set_player_invincible"):
			main_scene.set_player_invincible(true)
		if main_scene and main_scene.has_method("set_player_can_shoot"):
			main_scene.set_player_can_shoot(false)
		if main_scene and main_scene.has_method("clear_enemies"):
			main_scene.clear_enemies()
		print("Star Pattern Tweaker opened - Debug enemy spawned in center - Player invincible - Player cannot shoot")
	else:
		despawn_debug_enemy()
		# Resume music when debug UI closes
		if main_scene and main_scene.has_method("resume_music"):
			main_scene.resume_music()
		# Disable player invincibility when debug UI closes
		if main_scene and main_scene.has_method("set_player_invincible"):
			main_scene.set_player_invincible(false)
		if main_scene and main_scene.has_method("set_player_can_shoot"):
			main_scene.set_player_can_shoot(true)
		print("Star Pattern Tweaker closed - Debug enemy removed - Player vulnerability restored - Player can shoot again")

func spawn_debug_enemy():
	"""Spawn a debug enemy in the center of the screen for testing patterns"""
	if debug_enemy_active or not main_scene:
		return

	# Load enemy scene
	var enemy_scene = preload("res://scenes/Enemy.tscn")
	debug_enemy = enemy_scene.instantiate()

	# Position in center of screen
	var viewport_size = get_viewport().get_visible_rect().size
	debug_enemy.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)

	# Make it static (no movement)
	debug_enemy.enemy_speed = 0.0

	# Add to scene first so all nodes are ready
	main_scene.add_child(debug_enemy)

	# Configure for debug mode
	debug_enemy.set_sound_manager(main_scene.sound_manager)
	debug_enemy.set_difficulty(main_scene.enemy_difficulty)

	# Set texture to make it visible
	debug_enemy.set_texture("res://assets/textures/enemies/enemy_green_enemy_flap_strip.png")

	# Make sure it's marked as visible and ready
	debug_enemy.is_visible = true
	debug_enemy.health = 999999.0 # Make invincible

	# DISABLE AUTO-FIRING - Set very high shot delays to prevent auto-firing
	debug_enemy.shot_delay = 999999.0
	debug_enemy.max_shot_delay = 999999.0

	# Mark as debug enemy for special handling
	debug_enemy.set_meta("is_debug_enemy", true)

	# Force it to use selected pattern after setup
	debug_enemy.assigned_pattern = current_pattern
	debug_enemy.single_pattern_mode = true

	# Force star pattern parameters
	update_pattern_manager_star_params(debug_enemy.pattern_manager)

	# DISABLE AUTO-SPAWN for debug mode - the enemy will only fire when we explicitly call it
	if debug_enemy.pattern_manager:
		debug_enemy.pattern_manager.auto_spawn_enabled = false

	debug_enemy_active = true
	print("Debug enemy spawned at center: ", debug_enemy.position, " with pattern: ", debug_enemy.assigned_pattern, " (auto-fire disabled)")

func despawn_debug_enemy():
	"""Remove the debug enemy from the scene"""
	if debug_enemy and is_instance_valid(debug_enemy):
		debug_enemy.queue_free()
		debug_enemy = null
	debug_enemy_active = false

func update_debug_enemy_patterns():
	"""Update debug enemy with current pattern parameters"""
	if debug_enemy_active and debug_enemy and is_instance_valid(debug_enemy):
		update_pattern_manager_star_params(debug_enemy.pattern_manager)
		# Pattern will be fired by timer after delay

func update_debug_enemy_pattern():
	"""Update debug enemy to use the selected pattern"""
	if debug_enemy_active and debug_enemy and is_instance_valid(debug_enemy):
		debug_enemy.assigned_pattern = current_pattern
		print("Debug enemy pattern changed to: ", current_pattern)
		# Pattern will be fired by timer after delay

func _exit_tree():
	"""Clean up debug enemy when UI is destroyed"""
	despawn_debug_enemy()

func start_pattern_fire_timer():
	"""Start or restart the timer for delayed pattern firing"""
	if pattern_fire_timer:
		pattern_fire_timer.start()

func _on_pattern_fire_timer_timeout():
	"""Fire a pattern when the timer expires (0.5s after last parameter change)"""
	if debug_enemy_active and debug_enemy and is_instance_valid(debug_enemy):
		fire_debug_enemy_pattern()

func fire_debug_enemy_pattern():
	"""Make the debug enemy fire its current pattern once"""
	if not debug_enemy or not is_instance_valid(debug_enemy):
		return

	if not debug_enemy.pattern_manager:
		return

	# Get player position for targeting
	var player_pos = Vector2.ZERO
	if main_scene and main_scene.has_method("get_player_position"):
		player_pos = main_scene.get_player_position()

	# Get pattern parameters
	var params = debug_enemy.pattern_manager.get_default_params_for_pattern(current_pattern)
	if params:
		params.apply_difficulty_scaling(1.0)

		# Fire the pattern
		debug_enemy.pattern_manager.spawn_pattern(current_pattern, debug_enemy.global_position, player_pos, params, debug_enemy.assigned_bullet_color)
		print("Debug enemy fired pattern: ", current_pattern)
