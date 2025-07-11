extends Node2D
class_name RandomShots

# Random shot properties
var spawn_position: Vector2
var velocity: Vector2 = Vector2.ZERO
var difference: Vector2
var is_visible: bool = true
var spawn_timer: float = 0.0

# Bullet management
var bullets: Array[Bullet] = []
var bullet_speed: float = 200.0 # Speed of the bullets

# Pattern constants
var limit_speed: int = 10
var n_bullet_spawn: int = 1
var bullets_spawned: int = 0 # Track how many bullets have been spawned total
var spawn_interval: float = 1.0 # Spawn every 1 second

# Bullet color textures
var bullet_colors = [
	"res://assets/textures/bullets/bullet_randomShot.png",
	"res://assets/textures/bullets/bullet_randomShot2.png",
	"res://assets/textures/bullets/bullet_randomShot3.png",
	"res://assets/textures/bullets/bullet_randomShot4.png"
]

# Random number generator
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()

func setup(pos: Vector2):
	spawn_position = pos
	velocity = Vector2.ZERO
	is_visible = true

func update_pattern(delta: float, player: Player):
	if not is_visible:
		return

	spawn_timer += delta

	update_bullets(delta, player)
	random_pattern(delta, player)

func random_pattern(delta: float, player: Player):
	# Spawn bullets at interval
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0

		# Only spawn if we haven't reached the total spawn limit
		if bullets_spawned < n_bullet_spawn:
			var color_index = rng.randi_range(0, bullet_colors.size() - 1)
			var spawn_pos_x = int(spawn_position.x)
			var spawn_pos_y = int(spawn_position.y)

			# Calculate direction towards player when spawning bullet
			difference = player.position - spawn_position
			difference = difference.normalized()

			# Create bullet velocity directly towards player
			var bullet_velocity = difference * 180.0 # Direct velocity towards player
			bullet_velocity.y += 30.0 # Add slight downward bias

			# Create new bullet
			var bullet = preload("res://Bullet.tscn").instantiate()
			get_parent().add_child(bullet)

			var bullet_texture = load(bullet_colors[color_index])
			var spawn_pos = Vector2(spawn_pos_x, spawn_pos_y)

			bullet.setup_bullet(bullet_texture, spawn_pos, bullet_velocity, bullet_speed)
			bullet.set_bullet_type(false) # Mark as enemy bullet
			bullets.append(bullet)
			bullets_spawned += 1 # Increment total spawned count

func update_bullets(delta: float, player: Player):
	# Remove bullets that are no longer visible
	for i in range(bullets.size() - 1, -1, -1):
		var bullet = bullets[i]
		if not bullet or not bullet.is_visible:
			if bullet:
				bullet.queue_free()
			bullets.remove_at(i)

func _process(delta):
	# Clean up when bullets are gone and enough time has passed
	if bullets.is_empty() and spawn_timer > 3.0:
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
