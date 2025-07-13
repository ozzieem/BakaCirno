extends Node

# Test script to debug the Pattern Debug UI issue

func _ready():
	print("Starting Pattern Debug UI Test")

	# Create a simple test of the debugger
	var circle_debugger = CirclePatternDebugger.new()
	circle_debugger.pattern_name = "circle"
	circle_debugger.pattern_debug_ui = null

	# Create a test container
	var test_container = VBoxContainer.new()
	add_child(test_container)

	# Create UI
	circle_debugger.create_ui(test_container)

	# Test parameter changes
	print("Testing parameter changes...")

	# Wait a bit then test
	await get_tree().create_timer(0.1).timeout

	# Test changing a parameter
	var bullet_speed_slider = circle_debugger.ui_elements["bullet_speed"]["slider"]
	print("Initial bullet speed slider value: ", bullet_speed_slider.value)
	print("Initial bullet speed parameter: ", circle_debugger.parameters["bullet_speed"])

	# Change the slider value
	bullet_speed_slider.value = 300.0
	print("After setting slider to 300:")
	print("Bullet speed slider value: ", bullet_speed_slider.value)
	print("Bullet speed parameter: ", circle_debugger.parameters["bullet_speed"])

	# Test the reset function
	circle_debugger.reset_to_defaults()
	print("After reset_to_defaults:")
	print("Bullet speed slider value: ", bullet_speed_slider.value)
	print("Bullet speed parameter: ", circle_debugger.parameters["bullet_speed"])

	print("Test completed")
