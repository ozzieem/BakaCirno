extends Control
class_name PatternDebugUI

# Main pattern debug UI - manages all pattern debuggers
# Allows testing all patterns with real-time parameter adjustment and saving/loading

# References to UI elements
@onready var pattern_tabs = $VBoxContainer/PatternTabs
@onready var global_controls = $VBoxContainer/GlobalControls
@onready var save_button = $VBoxContainer/GlobalControls/SaveLoadContainer/SaveButton
@onready var load_button = $VBoxContainer/GlobalControls/SaveLoadContainer/LoadButton
@onready var preset_selector = $VBoxContainer/GlobalControls/PresetContainer/PresetSelector
@onready var info_label = $VBoxContainer/GlobalControls/InfoLabel

# Pattern debuggers
var pattern_debuggers: Dictionary = {}
var current_pattern_debugger: PatternDebuggerBase = null

# Reference to main scene
var main_scene: Node2D

# Debug enemy for testing patterns
var debug_enemy: Enemy
var debug_enemy_active: bool = false

# Timer for delayed pattern firing after parameter changes
var pattern_fire_timer: Timer
var pattern_fire_delay: float = 0.5

# Current pattern being tested
var current_pattern: String = "circle"

# Available patterns
var available_patterns: Array[String] = ["circle", "spiral", "wave", "star", "star_outline", "burst", "random"]

# Save/Load system
var save_file_path: String = "user://pattern_debug_presets.json"
var current_preset_name: String = "Default"

func _ready():
	# Initialize pattern fire timer
	pattern_fire_timer = Timer.new()
	pattern_fire_timer.wait_time = pattern_fire_delay
	pattern_fire_timer.one_shot = true
	pattern_fire_timer.timeout.connect(_on_pattern_fire_timer_timeout)
	add_child(pattern_fire_timer)

	# Create pattern debuggers
	create_pattern_debuggers()

	# Setup UI
	setup_tabs()
	setup_global_controls()
	load_presets()

	# Initially hidden
	visible = false

func create_pattern_debuggers():
	"""Create debugger instances for each pattern"""
	pattern_debuggers["circle"] = CirclePatternDebugger.new()
	pattern_debuggers["spiral"] = SpiralPatternDebugger.new()
	pattern_debuggers["wave"] = WavePatternDebugger.new()
	pattern_debuggers["star"] = StarPatternDebugger.new()
	pattern_debuggers["star_outline"] = StarOutlinePatternDebugger.new()
	pattern_debuggers["burst"] = BurstPatternDebugger.new()
	pattern_debuggers["random"] = RandomPatternDebugger.new()

	# Connect each debugger to the main system
	for pattern_name in pattern_debuggers:
		var debugger = pattern_debuggers[pattern_name]
		debugger.pattern_debug_ui = self
		debugger.pattern_name = pattern_name
		debugger.parameter_changed.connect(_on_parameter_changed)

func setup_tabs():
	"""Setup tab container for different patterns"""
	if not pattern_tabs:
		return

	# Clear existing tabs
	for child in pattern_tabs.get_children():
		child.queue_free()

	# Create tab for each pattern
	for pattern_name in available_patterns:
		var tab_content = ScrollContainer.new()
		tab_content.name = pattern_name.capitalize()
		pattern_tabs.add_child(tab_content)

		var debugger = pattern_debuggers[pattern_name]
		debugger.create_ui(tab_content)

	# Connect tab change
	pattern_tabs.tab_changed.connect(_on_tab_changed)

func setup_global_controls():
	"""Setup global controls (save/load, presets, etc.)"""
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if preset_selector:
		preset_selector.item_selected.connect(_on_preset_selected)

func load_presets():
	"""Load saved presets from file"""
	if not FileAccess.file_exists(save_file_path):
		create_default_presets()
		return

	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open preset file: " + save_file_path)
		create_default_presets()
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse preset file: " + json_string)
		create_default_presets()
		return

	var presets = json.data
	if not presets is Dictionary:
		push_error("Invalid preset file format")
		create_default_presets()
		return

	# Load presets into debuggers
	for preset_name in presets:
		var preset_data = presets[preset_name]
		if preset_data.has("patterns"):
			for pattern_name in preset_data["patterns"]:
				if pattern_name in pattern_debuggers:
					var debugger = pattern_debuggers[pattern_name]
					debugger.load_parameters(preset_data["patterns"][pattern_name])

	# Update preset selector
	update_preset_selector(presets.keys())

func create_default_presets():
	"""Create default presets"""
	var default_presets = {
		"Default": {
			"patterns": {}
		}
	}

	# Save default presets
	save_presets_to_file(default_presets)
	update_preset_selector(["Default"])

func save_presets_to_file(presets: Dictionary):
	"""Save presets to file"""
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to create preset file: " + save_file_path)
		return

	var json_string = JSON.stringify(presets, "\t")
	file.store_string(json_string)
	file.close()

func update_preset_selector(preset_names: Array):
	"""Update preset selector with available presets"""
	if not preset_selector:
		return

	preset_selector.clear()
	for preset_name in preset_names:
		preset_selector.add_item(preset_name)

func set_main_scene(main: Node2D):
	"""Set reference to main scene"""
	main_scene = main

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
		print("Pattern Debug UI opened - Debug enemy spawned - Player invincible")
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
		print("Pattern Debug UI closed - Debug enemy removed - Player vulnerability restored")

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

	# Add to scene
	main_scene.add_child(debug_enemy)

	# Configure for debug mode
	debug_enemy.set_sound_manager(main_scene.sound_manager)
	debug_enemy.set_difficulty(main_scene.enemy_difficulty)
	debug_enemy.set_texture("res://assets/textures/enemies/enemy_green_enemy_flap_strip.png")
	debug_enemy.is_visible = true
	debug_enemy.health = 999999.0 # Make invincible

	# Disable auto-firing
	debug_enemy.shot_delay = 999999.0
	debug_enemy.max_shot_delay = 999999.0

	# Mark as debug enemy
	debug_enemy.set_meta("is_debug_enemy", true)

	# Set pattern and disable auto-spawn
	debug_enemy.assigned_pattern = current_pattern
	debug_enemy.single_pattern_mode = true

	if debug_enemy.pattern_manager:
		debug_enemy.pattern_manager.auto_spawn_enabled = false

	debug_enemy_active = true
	print("Debug enemy spawned at center with pattern: ", current_pattern)

func despawn_debug_enemy():
	"""Remove the debug enemy from the scene"""
	if debug_enemy and is_instance_valid(debug_enemy):
		debug_enemy.queue_free()
		debug_enemy = null
	debug_enemy_active = false

func fire_debug_pattern():
	"""Fire the current pattern on the debug enemy"""
	if not debug_enemy or not is_instance_valid(debug_enemy):
		return

	if not debug_enemy.pattern_manager:
		return

	# Get current pattern debugger
	var debugger = pattern_debuggers.get(current_pattern)
	if not debugger:
		return

	# Get parameters from debugger
	var params = debugger.get_current_parameters()
	if not params:
		return

	# Set the enemy position for patterns that need it (like spiral)
	params.set_custom_param("enemy_position", debug_enemy.global_position)

	# Get player position for targeting
	var player_pos = Vector2.ZERO
	if main_scene and main_scene.has_method("get_player_position"):
		player_pos = main_scene.get_player_position()

	# Fire the pattern
	debug_enemy.pattern_manager.spawn_pattern(current_pattern, debug_enemy.global_position, player_pos, params, debug_enemy.assigned_bullet_color)
	print("Debug enemy fired pattern: ", current_pattern)

# Event handlers
func _on_tab_changed(tab: int):
	"""Handle tab change"""
	if tab >= 0 and tab < available_patterns.size():
		current_pattern = available_patterns[tab]
		current_pattern_debugger = pattern_debuggers[current_pattern]

		# Update debug enemy pattern
		if debug_enemy and is_instance_valid(debug_enemy):
			debug_enemy.assigned_pattern = current_pattern

		print("Switched to pattern: ", current_pattern)

func _on_parameter_changed():
	"""Handle parameter change from any debugger"""
	start_pattern_fire_timer()

func _on_save_pressed():
	"""Handle save button press"""
	save_current_preset()

func _on_load_pressed():
	"""Handle load button press"""
	load_current_preset()

func _on_preset_selected(index: int):
	"""Handle preset selection"""
	if index >= 0 and index < preset_selector.get_item_count():
		current_preset_name = preset_selector.get_item_text(index)
		load_current_preset()

func save_current_preset():
	"""Save current parameters as preset"""
	var presets = load_presets_from_file()
	var preset_data = {
		"patterns": {}
	}

	# Collect parameters from all debuggers
	for pattern_name in pattern_debuggers:
		var debugger = pattern_debuggers[pattern_name]
		preset_data["patterns"][pattern_name] = debugger.save_parameters()

	presets[current_preset_name] = preset_data
	save_presets_to_file(presets)
	print("Saved preset: ", current_preset_name)

func load_current_preset():
	"""Load current preset"""
	var presets = load_presets_from_file()
	if not presets.has(current_preset_name):
		return

	var preset_data = presets[current_preset_name]
	if preset_data.has("patterns"):
		for pattern_name in preset_data["patterns"]:
			if pattern_name in pattern_debuggers:
				var debugger = pattern_debuggers[pattern_name]
				debugger.load_parameters(preset_data["patterns"][pattern_name])

	print("Loaded preset: ", current_preset_name)

func load_presets_from_file() -> Dictionary:
	"""Load presets from file"""
	if not FileAccess.file_exists(save_file_path):
		return {}

	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return {}

	var presets = json.data
	if not presets is Dictionary:
		return {}

	return presets

func start_pattern_fire_timer():
	"""Start or restart the timer for delayed pattern firing"""
	if pattern_fire_timer:
		pattern_fire_timer.start()

func _on_pattern_fire_timer_timeout():
	"""Fire a pattern when the timer expires"""
	fire_debug_pattern()

func _process(_delta):
	"""Update info display"""
	if info_label:
		var debug_status = "Debug Enemy: " + ("Active" if debug_enemy_active else "Inactive")
		var pattern_info = "Current Pattern: " + current_pattern.capitalize()
		info_label.text = "Press F3 to toggle this panel\n" + pattern_info + "\n" + debug_status

func _exit_tree():
	"""Clean up when UI is destroyed"""
	despawn_debug_enemy()
