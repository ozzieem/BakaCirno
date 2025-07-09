extends Node

# Simple test script to verify font loading
func _ready():
	print("=== Font Loading Test ===")

	var font_paths = [
		"res://assets/fonts/open-sans/OpenSans-Semibold.ttf",
		"res://assets/fonts/open-sans/OpenSans-Bold.ttf",
		"res://assets/fonts/open-sans/OpenSans-Regular.ttf"
	]

	for font_path in font_paths:
		print("Testing font path: " + font_path)
		if ResourceLoader.exists(font_path):
			var loaded_font = load(font_path)
			if loaded_font and loaded_font is Font:
				print("✅ Successfully loaded: " + font_path)
			else:
				print("❌ Failed to load as Font: " + font_path)
		else:
			print("❌ File not found: " + font_path)

	print("=== Font Test Complete ===")
