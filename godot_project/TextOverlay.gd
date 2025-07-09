extends Node2D
class_name TextOverlay

# Game statistics
var score: float = 0.0
var time: float = 0.0
var enemies_killed: float = 0.0

# UI positions
var score_position: Vector2 = Vector2(0, 100)
var time_position: Vector2 = Vector2(0, 130)
var enemies_killed_position: Vector2 = Vector2(0, 150)
var control_info_position: Vector2 = Vector2(0, 900)
var info_position: Vector2 = Vector2(250, 700)

# Font resource
var font: Font

func _ready():
	load_font()

func load_font():
	# Try multiple font options in order of preference
	var font_paths = [
		"res://assets/fonts/OpenSans-Semibold.ttf",
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
				print("Loaded font: " + font_path)
				return

	# Fallback to system default font
	font = ThemeDB.fallback_font
	print("Using fallback system font - consider adding a TTF font to assets/fonts/")

func update_time(delta: float):
	time += delta

func add_score(points: int):
	score += points

func add_enemies_killed(count: int):
	enemies_killed += count

func reset_stats():
	score = 0.0
	time = 0.0
	enemies_killed = 0.0

func _draw():
	if not font:
		return

	var font_size = 24
	var color = Color.WHITE

	# Draw score
	draw_string(font, score_position, "Score: " + str(int(score)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

	# Draw time
	draw_string(font, time_position, "Time: " + str(int(time)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

	# Draw enemies killed
	draw_string(font, enemies_killed_position, "Enemies Killed: " + str(int(enemies_killed)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

	# Draw control instructions at game start
	if time < 5.0: # Show instructions for first 5 seconds
		var instructions = "WASD/Arrow Keys to Move\nSpace to Shoot\nHold Shift for Power Shot"
		draw_string(font, info_position, instructions, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)

	# Draw control info at bottom
	var control_text = "ESC: Menu | ESC+F1: Exit"
	draw_string(font, control_info_position, control_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)

# Force redraw each frame to update the text
func _process(delta):
	queue_redraw()
