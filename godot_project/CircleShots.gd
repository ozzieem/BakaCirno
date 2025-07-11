extends Node2D
class_name CircleShots

# Circle pattern properties
var spawn_position: Vector2
var velocity: Vector2 = Vector2(1, 1)
var circle_speed: float = 2.0
var is_visible: bool = true
var spawn_timer: float = 0.0

# Bullet management
var bullets: Array[Bullet] = []

# Pattern constants
const SPREAD = 360
const DEGREES = 20
const CURVE_SIZE_PER_SECOND = 0.1

# Bullet color textures
var bullet_colors = [
	"res://assets/textures/Blueshot1.png",
	"res://assets/textures/Redshot1.png",
	"res://assets/textures/Yellowshot1.png",
	"res://assets/textures/Greenshot1.png",
	"res://assets/textures/Purpleshot.png"
]

# Sound manager
var sound_manager: Sound

# Random number generator
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func set_sound_manager(sound_mgr: Sound):
	sound_manager = sound_mgr

func setup(pos: Vector2, speed: float):
	spawn_position = pos
	circle_speed += speed
	is_visible = true

func update_pattern(delta: float, player: Player, enemy: Enemy):
	if not is_visible:
		return

	spawn_timer += delta

	check_collision(player)
	circle_pattern(delta, enemy)
	update_bullets(delta, player)

func circle_pattern(delta: float, enemy: Enemy):
	# Only spawn bullets once when the pattern is first created
	if bullets.size() > 0:
		return

	var rand_bullet_color = rng.randi_range(0, bullet_colors.size() - 1)
	var bullet_texture = load(bullet_colors[rand_bullet_color])

	# Create a complete circle of bullets
	for i in range(0, SPREAD, DEGREES):
		# Calculate velocity in circular pattern
		var angle_rad = deg_to_rad(i)
		velocity.x = cos(angle_rad)
		velocity.y = sin(angle_rad)

		# Create new bullet
		var bullet = preload("res://Bullet.tscn").instantiate()
		get_parent().add_child(bullet)

		# Position bullet at enemy center
		var spawn_pos = spawn_position
		var bullet_velocity = velocity * circle_speed

		bullet.setup_bullet(bullet_texture, spawn_pos, bullet_velocity, circle_speed * 60)
		bullet.set_bullet_type(false) # Mark as enemy bullet
		bullets.append(bullet)

func update_bullets(delta: float, player: Player):
	# Remove bullets that are no longer visible
	for i in range(bullets.size() - 1, -1, -1):
		var bullet = bullets[i]
		if not bullet or not bullet.is_visible:
			if bullet:
				bullet.queue_free()
			bullets.remove_at(i)

func check_collision(player: Player):
	# Collision detection is now handled by Godot's collision system
	# This function is kept for compatibility but does nothing
	pass

func _process(delta):
	# Clean up when all bullets are gone and pattern is complete
	if bullets.is_empty() and spawn_timer > 2.0: # Give time for pattern to complete
		is_visible = false
		queue_free()

func get_bullets() -> Array[Bullet]:
	return bullets

func clear_bullets():
	# Clear all bullets in this pattern
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			bullet.queue_free()
	bullets.clear()
