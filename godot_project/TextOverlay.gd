extends Node2D
class_name TextOverlay

# Game statistics
var score: float = 0.0
var time: float = 0.0
var enemies_killed: float = 0.0
var difficulty_multiplier: float = 0.0

# UI positions (matching C# MonoGame version)
var score_position: Vector2 = Vector2(0, 100)
var time_position: Vector2 = Vector2(0, 130)
var enemies_killed_position: Vector2 = Vector2(0, 150)
var difficulty_position: Vector2 = Vector2(0, 170)
var control_info_position: Vector2 = Vector2(50, 900)
var info_position: Vector2 = Vector2(150, 800)

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

# Force redraw each frame to update the text
func _process(delta):
	queue_redraw()
