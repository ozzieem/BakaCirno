extends Enemy
class_name BossEnemy

# Boss-specific properties
var boss_health: float = 600.0
var max_boss_health: float = 600.0
var boss_level: int = 1
var boss_phase: int = 1
var max_phases: int = 3
var phase_transition_health: float = 400.0

# Boss entry system
var is_entering: bool = true
var entry_start_position: Vector2
var entry_target_position: Vector2
var entry_speed: float = 80.0
var entry_delay_after_arrival: float = 2.0
var entry_delay_timer: float = 0.0
var is_invulnerable: bool = true
var entry_delay_started: bool = false

# Boss attack patterns
var current_attack_pattern: int = 0
var attack_patterns: Array[String] = ["circle", "spiral", "star", "star_outline"]
var pattern_switch_timer: float = 0.0
var pattern_switch_delay: float = 4.0

# Boss movement
var movement_pattern: int = 0
var movement_timer: float = 0.0
var movement_speed: float = 100.0
var center_position: Vector2
var movement_amplitude: float = 200.0

# Boss visual effects
var boss_scale: float = 3.0
var flash_timer: float = 0.0
var is_flashing: bool = false

# Boss rewards
var boss_score_reward: int = 5000
var boss_point_bullets: int = 50

func _ready():
	# Call parent ready
	super._ready()

	# Set boss-specific properties
	health = boss_health
	max_boss_health = boss_health
	enemy_speed = 30.0 # Slower than regular enemies

	# Scale up the boss visually
	scale = Vector2(boss_scale, boss_scale)

	# Set entry positions
	entry_target_position = Vector2(460, 150) # Center top of screen
	entry_start_position = Vector2(460, -100) # Start above screen
	center_position = entry_target_position
	position = entry_start_position # Start above screen

	# Initialize entry state
	is_entering = true
	is_invulnerable = true
	entry_delay_timer = 0.0
	entry_delay_started = false

	# Configure boss-specific shooting
	shot_delay = 1.5 # Slower shooting than regular enemies
	max_shot_delay = 1.5

	# Set boss as invincible to debug enemies
	set_meta("is_boss_enemy", true)

	# Initialize boss pattern manager settings
	if pattern_manager:
		pattern_manager.auto_spawn_enabled = false # Disable until entry complete
		pattern_manager.set_boss_mode(true)

	# Set boss texture (use scaled up enemy sprite)
	set_boss_texture()

	print("Boss enemy spawning - Level: ", boss_level, " Health: ", health, " - Starting entry sequence")

func set_boss_level(level: int):
	"""Set the boss level and scale difficulty accordingly"""
	boss_level = level

	# Scale health based on boss level (more gradual increase)
	boss_health = 600.0 * (1.0 + (level - 1) * 0.3)
	max_boss_health = boss_health
	health = boss_health

	# Scale movement speed more gradually
	movement_speed = 100.0 * (1.0 + (level - 1) * 0.1)

	# Reduce pattern switch delay for higher levels (more gradual)
	pattern_switch_delay = max(2.0, 4.0 - (level - 1) * 0.2)

	# Update phase transition points
	phase_transition_health = boss_health * 0.66

	print("Boss level set to: ", level, " - Health: ", health, " - Speed: ", movement_speed)

func update_movement(delta: float, player: Player):
	"""Override parent movement with boss-specific movement patterns"""
	if not is_visible:
		return

	# Handle entry phase
	if is_entering:
		handle_entry_movement(delta)
		return

	# Regular boss movement patterns
	movement_timer += delta

	# Boss movement patterns
	match movement_pattern:
		0: # Horizontal figure-8 pattern
			var x_offset = sin(movement_timer * 2.0) * movement_amplitude
			var y_offset = sin(movement_timer * 4.0) * 50.0
			position = center_position + Vector2(x_offset, y_offset)
		1: # Circular pattern
			var angle = movement_timer * 1.5
			var radius = movement_amplitude * 0.7
			position = center_position + Vector2(cos(angle) * radius, sin(angle) * radius * 0.5)
		2: # Side-to-side with vertical bob
			var x_offset = sin(movement_timer * 1.5) * movement_amplitude
			var y_offset = sin(movement_timer * 3.0) * 30.0
			position = center_position + Vector2(x_offset, y_offset)

	# Switch movement pattern every 8 seconds
	if movement_timer > 8.0:
		movement_pattern = (movement_pattern + 1) % 3
		movement_timer = 0.0

	# Update debug display
	update_debug_display()

func handle_entry_movement(delta: float):
	"""Handle boss entry movement from top of screen"""
	# Move toward target position
	var direction = (entry_target_position - position).normalized()
	position += direction * entry_speed * delta

	# Check if reached target position
	if position.distance_to(entry_target_position) < 10.0:
		position = entry_target_position

		# Only start the timer once when reaching the target
		if not entry_delay_started:
			entry_delay_timer = entry_delay_after_arrival
			entry_delay_started = true
			print("Boss reached target position - starting entry delay timer: ", entry_delay_after_arrival, " seconds")

	# Update entry delay timer if at target and timer has started
	if entry_delay_started and position.distance_to(entry_target_position) < 10.0:
		entry_delay_timer -= delta
		if entry_delay_timer <= 0.0:
			complete_entry_sequence()

func complete_entry_sequence():
	"""Complete the boss entry sequence and begin normal behavior"""
	is_entering = false
	is_invulnerable = false

	# Enable pattern manager
	if pattern_manager:
		pattern_manager.auto_spawn_enabled = true

	# Reset movement timer for patterns
	movement_timer = 0.0

	print("Boss entry sequence complete - now vulnerable and active!")

func update_shooting(delta: float, player: Player):
	"""Override parent shooting with boss-specific attack patterns"""
	if not is_visible:
		return

	# Don't shoot during entry phase
	if is_entering:
		return

	# Don't shoot if boss is above viewport
	if position.y < -50:
		return

	# Update pattern switching
	pattern_switch_timer += delta
	if pattern_switch_timer >= pattern_switch_delay:
		switch_attack_pattern()
		pattern_switch_timer = 0.0

	# Update shot delay
	if shot_delay > 0:
		shot_delay -= delta

	# Fire boss attacks
	if shot_delay <= 0:
		fire_boss_attack(player)
		shot_delay = max_shot_delay

	# Update flash effect
	if is_flashing:
		flash_timer += delta
		if flash_timer >= 0.1:
			is_flashing = false
			flash_timer = 0.0
			modulate = Color.WHITE

func switch_attack_pattern():
	"""Switch to the next attack pattern"""
	current_attack_pattern = (current_attack_pattern + 1) % attack_patterns.size()
	var pattern_name = attack_patterns[current_attack_pattern]

	# Change assigned pattern for variety
	assigned_pattern = pattern_name

	print("Boss switched to attack pattern: ", pattern_name)

func fire_boss_attack(player: Player):
	"""Fire boss-specific attack patterns"""
	if not pattern_manager:
		return

	# Get current attack pattern
	var pattern_name = attack_patterns[current_attack_pattern]
	var params = pattern_manager.get_default_params_for_pattern(pattern_name)

	# Apply boss-specific modifications to pattern parameters
	match pattern_name:
		"circle":
			params.bullet_density = 12 + (boss_level * 1)
			params.bullet_speed = 80.0 + (boss_level * 2)
		"spiral":
			params.bullet_density = 6 + boss_level
			params.bullet_speed = 70.0 + (boss_level * 3)
			params.set_custom_param("attack_count", attack_count)
			params.set_custom_param("enemy_position", position)
		"wave":
			params.bullet_density = 8 + boss_level
			params.bullet_speed = 75.0 + (boss_level * 4)
		"star":
			params.bullet_density = 8 + boss_level
			params.bullet_speed = 65.0 + (boss_level * 4)
		"star_outline":
			params.bullet_density = 10 + boss_level
			params.bullet_speed = 70.0 + (boss_level * 4)
			params.set_custom_param("outline_thickness", 2 + (boss_level / 2))

	# Apply difficulty scaling
	params.apply_difficulty_scaling(1.0 + enemy_deaths * 0.1)

	# Get player position for targeting
	var player_pos = Vector2.ZERO
	if get_parent().has_method("get_player_position"):
		player_pos = get_parent().get_player_position()

	# Fire multiple patterns in higher phases
	if boss_phase >= 2:
		# Fire secondary pattern
		var secondary_pattern = attack_patterns[(current_attack_pattern + 2) % attack_patterns.size()]
		pattern_manager.spawn_pattern(secondary_pattern, position, player_pos, params, assigned_bullet_color)

	if boss_phase >= 3:
		# Fire tertiary pattern
		var tertiary_pattern = attack_patterns[(current_attack_pattern + 4) % attack_patterns.size()]
		pattern_manager.spawn_pattern(tertiary_pattern, position, player_pos, params, assigned_bullet_color)

	# Fire main pattern
	pattern_manager.spawn_pattern(pattern_name, position, player_pos, params, assigned_bullet_color)

	# Increment attack count
	attack_count += 1

func take_damage(damage: int, is_power_shot: bool = false):
	"""Override parent damage handling with boss-specific effects"""
	# Ignore damage during entry phase
	if is_invulnerable or is_entering:
		print("Boss is invulnerable during entry phase - damage ignored")
		return

	var actual_damage = damage
	if is_power_shot:
		actual_damage = 30

	health -= actual_damage

	# Flash effect when taking damage
	is_flashing = true
	flash_timer = 0.0
	modulate = Color.RED

	# Check for phase transitions
	check_phase_transition()

	# Boss is defeated
	if health <= 0:
		is_visible = false
		print("Boss defeated! Level: ", boss_level, " Final Phase: ", boss_phase)

func check_phase_transition():
	"""Check if boss should transition to next phase"""
	if boss_phase == 1 and health <= phase_transition_health:
		transition_to_phase(2)
	elif boss_phase == 2 and health <= phase_transition_health * 0.33:
		transition_to_phase(3)

func transition_to_phase(new_phase: int):
	"""Transition boss to a new phase"""
	boss_phase = new_phase

	# Increase attack frequency
	max_shot_delay = max(0.3, max_shot_delay * 0.7)
	shot_delay = max_shot_delay

	# Reduce pattern switch delay
	pattern_switch_delay = max(1.0, pattern_switch_delay * 0.8)

	# Increase movement speed
	movement_speed *= 1.2

	# Flash effect for phase transition
	is_flashing = true
	flash_timer = 0.0
	modulate = Color.YELLOW

	print("Boss entered phase ", new_phase, "! Increased aggression.")

func get_health_percentage() -> float:
	"""Get boss health as a percentage for UI display"""
	return health / max_boss_health

func is_boss() -> bool:
	"""Identify this as a boss enemy"""
	return true

func get_boss_info() -> Dictionary:
	"""Get boss information for UI display"""
	return {
		"level": boss_level,
		"phase": boss_phase,
		"health": health,
		"max_health": max_boss_health,
		"health_percentage": get_health_percentage(),
		"current_pattern": attack_patterns[current_attack_pattern] if current_attack_pattern < attack_patterns.size() else "unknown",
		"is_entering": is_entering,
		"is_invulnerable": is_invulnerable
	}

func update_debug_display():
	"""Override parent debug display with boss information"""
	if not show_debug_info or not debug_label:
		return

	var status = "ACTIVE"
	if is_entering:
		status = "ENTERING"
	elif is_invulnerable:
		status = "INVULNERABLE"

	var debug_text = "BOSS LV%d (Phase %d) - %s\nHealth: %d/%d\nPattern: %s\nPhase: %d/%d" % [
		boss_level,
		boss_phase,
		status,
		int(health),
		int(max_boss_health),
		attack_patterns[current_attack_pattern] if current_attack_pattern < attack_patterns.size() else "unknown",
		boss_phase,
		max_phases
	]

	debug_label.text = debug_text
	debug_label.visible = true

func set_boss_texture():
	"""Set boss texture using a scaled up enemy sprite"""
	# Use a distinctive enemy color for the boss (red for danger)
	var boss_texture_path = "res://assets/textures/enemies/enemy_red_enemy_flap_strip.png"

	# Use the existing set_texture method from parent Enemy class
	set_texture(boss_texture_path)

	# The scale is already set in _ready(), so the texture will appear larger
