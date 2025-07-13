extends Node2D
class_name TextOverlay

# Game statistics
var score: float = 0.0
var time: float = 0.0
var enemies_killed: float = 0.0
var difficulty_multiplier: float = 0.0

# UI positions (moved to bottom of screen - 920x950 window)
var score_position: Vector2 = Vector2(10, 850)
var time_position: Vector2 = Vector2(10, 880)
var enemies_killed_position: Vector2 = Vector2(10, 910)
var difficulty_position: Vector2 = Vector2(10, 940)
var control_info_position: Vector2 = Vector2(10, 780)
var info_position: Vector2 = Vector2(10, 810)

# Font resource
var font: Font

# Reference to main game for state checking
var main_game: Node2D

func _ready():
	load_font()
	# Get reference to the main game node
	main_game = get_parent()

func load_font():
	# Try multiple font options in order of preference
	var font_paths = [
		"res://assets/fonts/open-sans/OpenSans-Semibold.ttf",
		"res://assets/fonts/open-sans/OpenSans-Bold.ttf",
		"res://assets/fonts/open-sans/OpenSans-Regular.ttf",
		"res://assets/fonts/PressStart2P.ttf", # Popular pixel font
		"res://assets/fonts/game_font.ttf", # Generic game font
		"res://assets/fonts/pixel_font.ttf" # Another pixel option
	]

	# Try each font path
	for font_path in font_paths:
		if ResourceLoader.exists(font_path):
			var loaded_font = load(font_path)
			if loaded_font and loaded_font is Font:
				font = loaded_font
				print("Successfully loaded font: " + font_path)
				return

	# Fallback to system default font
	font = ThemeDB.fallback_font
	print("Using fallback system font - OpenSans fonts not found, using system default")

func update_time(delta: float):
	time += delta

func add_score(points: int):
	score += points

func add_enemies_killed(count: int):
	enemies_killed += count

func set_difficulty_multiplier(multiplier: float):
	difficulty_multiplier = multiplier

func reset_stats():
	score = 0.0
	time = 0.0
	enemies_killed = 0.0
	difficulty_multiplier = 0.0

func draw_boss_info(font_size: int, outline_size: int, outline_color: Color):
	"""Draw boss-related information on screen"""
	if not main_game or not main_game.has_method("is_boss_active"):
		return

	var boss_info_position = Vector2(500, 850)
	var boss_health_position = Vector2(500, 880)
	var boss_phase_position = Vector2(500, 910)
	var next_boss_position = Vector2(500, 940)

	# Check if boss is active
	if main_game.is_boss_active():
		var boss_info = main_game.get_boss_info()
		if boss_info.has("level"):
			# Draw boss level
			var boss_level_text = "BOSS LEVEL " + str(boss_info.level)
			var boss_color = Color.RED
			draw_string_outline(font, boss_info_position, boss_level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
			draw_string(font, boss_info_position, boss_level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, boss_color)

			# Draw boss health bar
			if boss_info.has("health_percentage"):
				var health_percent = boss_info.health_percentage
				var health_text = "BOSS HP: " + str(int(boss_info.health)) + "/" + str(int(boss_info.max_health))
				var health_color = Color.ORANGE_RED

				# Show invulnerable status during entry
				if boss_info.has("is_entering") and boss_info.is_entering:
					health_text += " (ENTERING - INVULNERABLE)"
					health_color = Color.YELLOW
				elif boss_info.has("is_invulnerable") and boss_info.is_invulnerable:
					health_text += " (INVULNERABLE)"
					health_color = Color.YELLOW

				draw_string_outline(font, boss_health_position, health_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
				draw_string(font, boss_health_position, health_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, health_color)

				# Draw health bar
				var bar_width = 200
				var bar_height = 8
				var bar_pos = Vector2(boss_health_position.x, boss_health_position.y + 25)

				# Background bar
				draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.DARK_RED)

				# Health bar
				var health_bar_width = bar_width * health_percent
				draw_rect(Rect2(bar_pos, Vector2(health_bar_width, bar_height)), Color.RED)

			# Draw boss phase
			if boss_info.has("phase"):
				var phase_text = "Phase " + str(boss_info.phase) + "/3"
				var phase_color = Color.YELLOW
				draw_string_outline(font, boss_phase_position, phase_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
				draw_string(font, boss_phase_position, phase_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, phase_color)
	else:
		# Check if boss warning is active
		if main_game.has_method("is_boss_warning_active") and main_game.is_boss_warning_active():
			var warning_time = main_game.get_boss_warning_time_left()
			var warning_text = "WARNING: BOSS INCOMING IN " + str(ceil(warning_time)) + " SECONDS!"
			var warning_color = Color.RED

			# Calculate proper centered position
			var screen_size = get_viewport().get_visible_rect().size
			font_size = 32
			var text_size = font.get_string_size(warning_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var warning_position = Vector2(
				(screen_size.x - text_size.x) / 2, # Center horizontally
				screen_size.y / 2 - 50 # Center vertically with slight offset up
			)

			# Make warning text flash
			var flash_alpha = 0.5 + 0.5 * sin(Time.get_time_dict_from_system().second * 8)
			warning_color.a = flash_alpha

			draw_string_outline(font, warning_position, warning_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color.BLACK)
			draw_string(font, warning_position, warning_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, warning_color)
		else:
			# Show kills until next boss
			if main_game.has_method("get_kills_until_next_boss"):
				var kills_remaining = main_game.get_kills_until_next_boss()
				if kills_remaining > 0:
					var next_boss_text = "Next Boss in: " + str(kills_remaining) + " kills"
					var next_boss_color = Color.CYAN
					draw_string_outline(font, next_boss_position, next_boss_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
					draw_string(font, next_boss_position, next_boss_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, next_boss_color)

func _draw():
	if not font:
		return

	# Only draw text when in PLAYING state
	if not main_game or not ("current_state" in main_game):
		return

	# Check if we're in PLAYING state (GameState.PLAYING = 1)
	if main_game.current_state != 1:
		return

	var font_size = 24
	var outline_size = 2
	var outline_color = Color.BLACK

	# Draw score (Yellow in C# version)
	var score_color = Color.YELLOW
	draw_string_outline(font, score_position, "Score: " + str(int(score)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
	draw_string(font, score_position, "Score: " + str(int(score)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, score_color)

	# Draw time (FloralWhite in C# version)
	var time_color = Color.FLORAL_WHITE
	draw_string_outline(font, time_position, "Time: " + str(int(time)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
	draw_string(font, time_position, "Time: " + str(int(time)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, time_color)

	# Draw enemies killed (AliceBlue in C# version)
	var enemies_color = Color.ALICE_BLUE
	draw_string_outline(font, enemies_killed_position, "Enemies Killed: " + str(int(enemies_killed)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
	draw_string(font, enemies_killed_position, "Enemies Killed: " + str(int(enemies_killed)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, enemies_color)

	# Draw difficulty multiplier (Orange for visibility)
	var difficulty_color = Color.ORANGE
	var difficulty_display = 1.0 + difficulty_multiplier
	draw_string_outline(font, difficulty_position, "Difficulty: x" + str(difficulty_display, 2), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
	draw_string(font, difficulty_position, "Difficulty: x" + str(difficulty_display, 2), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, difficulty_color)

	# Draw control instructions (matching C# timing: Time <= 4)
	if time <= 4.0:
		var control_text = "Control character with WASD, shoot by holding down SPACE"
		var control_color = Color.FOREST_GREEN
		draw_string_outline(font, control_info_position, control_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
		draw_string(font, control_info_position, control_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, control_color)

	# Draw gameplay tip (matching C# timing: Time >= 2 && Time <= 6)
	if time >= 2.0 and time <= 6.0:
		var tip_text = "Try to kill as many enemies as you can while avoiding bullets!"
		var tip_color = Color.PALE_VIOLET_RED
		draw_string_outline(font, info_position, tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
		draw_string(font, info_position, tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tip_color)

	# Draw boss information
	draw_boss_info(font_size, outline_size, outline_color)

	# Draw life-bubble information if active
	if main_game.player and main_game.player.has_method("get_life_bubble_info"):
		var bubble_info = main_game.player.get_life_bubble_info()
		if bubble_info.active:
			var bubble_text = "LIFE BUBBLE: " + str(bubble_info.health) + "/" + str(bubble_info.max_health)
			var bubble_color = Color.CYAN
			var bubble_pos = Vector2(10, 750) # Above other UI elements

			draw_string_outline(font, bubble_pos, bubble_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
			draw_string(font, bubble_pos, bubble_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, bubble_color)

			# Draw bubble health bar
			var bar_width = 150
			var bar_height = 6
			var bar_pos = Vector2(bubble_pos.x, bubble_pos.y + 20)

			# Background bar
			draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.DARK_BLUE)

			# Health bar
			var health_percent = float(bubble_info.health) / float(bubble_info.max_health)
			var health_bar_width = bar_width * health_percent
			draw_rect(Rect2(bar_pos, Vector2(health_bar_width, bar_height)), Color.CYAN)

			# Show recovery timer if applicable
			if bubble_info.recovery_time > 0:
				var recovery_text = "Recovery: " + str(int(bubble_info.recovery_time)) + "s"
				var recovery_pos = Vector2(bubble_pos.x + 160, bubble_pos.y)
				draw_string_outline(font, recovery_pos, recovery_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, outline_size, outline_color)
				draw_string(font, recovery_pos, recovery_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color.LIGHT_BLUE)

# Force redraw each frame to update the text
func _process(delta):
	queue_redraw()
