extends Node2D
class_name HighScoreText

# Reference to the text overlay for getting final scores
var text_overlay_ref: TextOverlay
var font: Font

# Reference to main game for state checking
var main_game: Node2D

# Display positions (matching C# MonoGame version)
var score_display_position: Vector2 = Vector2(310, 400)
var enemies_display_position: Vector2 = Vector2(360, 480)
var time_display_position: Vector2 = Vector2(345, 562)

func _ready():
	load_font()
	# Get reference to the main game node
	main_game = get_parent()

func load_font():
	# Try multiple font options in order of preference
	var font_paths = [
		"res://assets/fonts/open-sans/OpenSans-Bold.ttf", # Bold for game over screen
		"res://assets/fonts/open-sans/OpenSans-Semibold.ttf",
		"res://assets/fonts/open-sans/OpenSans-Regular.ttf",
		"res://assets/fonts/Font.ttf", # Original game font replacement
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
				print("HighScoreText: Successfully loaded font: " + font_path)
				return

	# Fallback to system default font
	font = ThemeDB.fallback_font
	print("HighScoreText: Using fallback system font - OpenSans fonts not found, using system default")

func setup_with_overlay(overlay: TextOverlay):
	text_overlay_ref = overlay

func _draw():
	if not font or not text_overlay_ref:
		return

	# Only draw text when in GAME_OVER state
	if not main_game or not ("current_state" in main_game):
		return

	# Check if we're in GAME_OVER state (GameState.GAME_OVER = 2)
	if main_game.current_state != 2:
		return

	# Font settings matching C# version (1.5f scale = larger font)
	var font_size = 36 # Larger to match 1.5f scale
	var color = Color.LIGHT_SEA_GREEN # DarkTurquoise color from C# version
	var outline_color = Color.LIGHT_BLUE
	var outline_size = 1

	# Draw score (with leading space like C# version: " " + score)
	var score_text = " " + str(int(text_overlay_ref.score))
	draw_string_outline(font, score_display_position, score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
	draw_string(font, score_display_position, score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

	# Draw enemies killed (with leading space like C# version: " " + enemies)
	var enemies_text = " " + str(int(text_overlay_ref.enemies_killed))
	draw_string_outline(font, enemies_display_position, enemies_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
	draw_string(font, enemies_display_position, enemies_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

	# Draw time (with leading space and "s" suffix like C# version: " " + time + "s")
	var time_text = " " + str(int(text_overlay_ref.time)) + "s"
	draw_string_outline(font, time_display_position, time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, outline_color)
	draw_string(font, time_display_position, time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

# Force redraw to update display
func _process(delta):
	queue_redraw()
