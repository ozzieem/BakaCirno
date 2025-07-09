extends Node2D
class_name HighScoreText

# Reference to the text overlay for getting final scores
var text_overlay_ref: TextOverlay
var font: Font

# Display positions
var score_display_position: Vector2 = Vector2(300, 300)
var time_display_position: Vector2 = Vector2(300, 350)
var enemies_display_position: Vector2 = Vector2(300, 400)
var title_position: Vector2 = Vector2(300, 200)

func _ready():
	load_font()

func load_font():
	# Try multiple font options in order of preference
	var font_paths = [
		"res://assets/fonts/Font.ttf", # Original game font replacement
		"res://assets/fonts/PressStart2P.ttf", # Popular pixel font
		"res://assets/fonts/game_font.ttf", # Generic game font
		"res://assets/fonts/pixel_font.ttf" # Another pixel option
	]

	# Try each font path
	for font_path in font_paths:
		if ResourceLoader.exists(font_path):
			var loaded_font = load(font_path)
			if loaded_font:
				font = loaded_font
				return

	# Fallback to system default font
	font = ThemeDB.fallback_font

func setup_with_overlay(overlay: TextOverlay):
	text_overlay_ref = overlay

func _draw():
	if not font or not text_overlay_ref:
		return

	var font_size = 32
	var title_size = 48
	var color = Color.WHITE
	var title_color = Color.YELLOW

	# Draw title
	draw_string(font, title_position, "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, -1, title_size, title_color)

	# Draw final statistics
	draw_string(font, score_display_position, "Final Score: " + str(int(text_overlay_ref.score)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_string(font, time_display_position, "Time Survived: " + str(int(text_overlay_ref.time)) + " seconds", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_string(font, enemies_display_position, "Enemies Destroyed: " + str(int(text_overlay_ref.enemies_killed)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

	# Instructions
	var instruction_position = Vector2(300, 500)
	draw_string(font, instruction_position, "Press ESC to return to menu", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, color)

# Force redraw to update display
func _process(delta):
	queue_redraw()
