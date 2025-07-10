extends Area2D
class_name Enemy

# Enemy properties
var texture: Texture2D
var enemy_speed: float = 0.5 * 60.0 # Adjusted for delta time
var health: float = 100.0
var is_visible: bool = true

# Movement and targeting
var difference: Vector2
var origin: Vector2

# Shooting properties
var shot_delay: float = 0.0
var max_shot_delay: float = 1.67 # 100 frames at 60fps converted to seconds
var n_circle_spawns: int = 0
var max_circle_spawns: int = 5
var max_random_bullets: int = 10
var random_bullets_spawned: int = 0

# Bullet patterns
var random_bullets: Array[RandomShots] = []
var circle_shots: Array[CircleShots] = []

# Difficulty scaling
var speed_increase: float = 0.0
var enemy_deaths: float = 0.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Sound manager
var sound_manager: Sound

# Random number generator
var rng = RandomNumberGenerator.new()

# Screen bounds
var screen_size: Vector2

func _ready():
	# Initialize random generator
	rng.randomize()

	# Get screen size
	screen_size = get_viewport().get_visible_rect().size

	# Set collision layers and masks
	collision_layer = 8 # Enemy layer
	collision_mask = 1 # Player layer

	# Connect collision signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Initialize shooting properties
	shot_delay = max_shot_delay
	n_circle_spawns = rng.randi_range(2, max_circle_spawns)
	random_bullets_spawned = 0

	# Create sound manager
	sound_manager = Sound.new()
	add_child(sound_manager)

func set_texture(texture_path: String):
	# Load texture with fallback
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path)
	else:
		# Create fallback texture based on enemy type
		var color = Color.GREEN
		if "red" in texture_path.to_lower():
			color = Color.RED
		elif "yellow" in texture_path.to_lower():
			color = Color.YELLOW
		elif "blue" in texture_path.to_lower():
			color = Color.BLUE

		var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
		image.fill(color)
		texture = ImageTexture.new()
		texture.set_image(image)

	if sprite and texture:
		sprite.texture = texture

		# Update collision shape based on texture size
		if collision_shape and collision_shape.shape is RectangleShape2D:
			var rect_shape = collision_shape.shape as RectangleShape2D
			rect_shape.size = Vector2(texture.get_width() * 2, texture.get_height())
	else:
		print("ERROR: Failed to assign enemy texture - sprite:", sprite, " texture:", texture)
		if not sprite:
			sprite = get_node_or_null("Sprite2D")
			if sprite:
				sprite.texture = texture

func set_difficulty(deaths: float):
	enemy_deaths = deaths

func clear_all_bullets():
	# Clear all circle shot patterns and their bullets
	for circle_shot in circle_shots:
		if circle_shot and is_instance_valid(circle_shot):
			circle_shot.clear_bullets()
			circle_shot.queue_free()
	circle_shots.clear()

	# Clear all random bullet patterns and their bullets
	for random_shot in random_bullets:
		if random_shot and is_instance_valid(random_shot):
			random_shot.clear_bullets()
			random_shot.queue_free()
	random_bullets.clear()

func update_movement(delta: float, player: Player):
	if not is_visible:
		return

	follow_player(delta, player)
	update_enemy_position(delta)
	check_collision(player)

func follow_player(delta: float, player: Player):
	# Gradually follow player's x position
	difference = player.position - position
	difference = difference.normalized()
	position.x += difference.x * delta * 6.0 # 0.1 * 60 for delta conversion
	position.y += enemy_speed * delta

func update_enemy_position(delta: float):
	# Update origin for bullet spawning
	origin = Vector2(position.x - 32, position.y)

	# Remove enemy if it goes off screen
	if position.y >= screen_size.y:
		is_visible = false

	# Remove enemy if health is depleted
	if health <= 0:
		is_visible = false

func update_shooting(delta: float, player: Player):
	if not is_visible:
		return

	# Increase speed based on enemy deaths
	speed_increase += delta * enemy_deaths

	# Update shot delay
	if shot_delay > 0:
		shot_delay -= delta

	# Fire shots when delay reaches zero
	if shot_delay <= 0:
		enemy_shot()
		shot_delay = max_shot_delay

	# Update existing bullets
	update_shots(delta, player)

func enemy_shot():
	# Fire circle shots
	if n_circle_spawns > 0:
		var circle_shot = CircleShots.new()
		circle_shot.setup(origin, speed_increase)
		get_parent().add_child(circle_shot)
		circle_shots.append(circle_shot)

		# Play sound
		if sound_manager:
			sound_manager.play_enemy_circle_shoot()

		n_circle_spawns -= 1

	# Fire random bullets
	if random_bullets_spawned < max_random_bullets:
		var random_shot = RandomShots.new()
		random_shot.setup(origin)
		get_parent().add_child(random_shot)
		random_bullets.append(random_shot)

		random_bullets_spawned += 1

func update_shots(delta: float, player: Player):
	# Update circle shots
	for i in range(circle_shots.size() - 1, -1, -1):
		var circle_shot = circle_shots[i]
		if not circle_shot or not circle_shot.is_visible:
			if circle_shot:
				circle_shot.queue_free()
			circle_shots.remove_at(i)
		else:
			circle_shot.update_pattern(delta, player, self)

	# Update random bullets
	for i in range(random_bullets.size() - 1, -1, -1):
		var random_bullet = random_bullets[i]
		if not random_bullet or not random_bullet.is_visible:
			if random_bullet:
				random_bullet.queue_free()
			random_bullets.remove_at(i)
		else:
			random_bullet.update_pattern(delta, player)

func check_collision(player: Player):
	# Remove enemy if it goes off screen
	if position.y >= screen_size.y:
		is_visible = false
		return

	# Check collision with player body
	var collision_area = Rect2(position - Vector2(60, 0), Vector2(texture.get_width() * 2, texture.get_height()) if texture else Vector2(64, 64))
	var player_area = Rect2(player.position, Vector2(64, 128))

	if collision_area.intersects(player_area):
		is_visible = false
		player.take_damage()

func take_damage(damage: int, is_power_shot: bool = false):
	if is_power_shot:
		health -= 30
	else:
		health -= damage

	if health <= 0:
		is_visible = false

func _on_area_entered(area):
	# Handle collision with player bullets
	if area.has_method("get_damage"):
		var damage = area.get_damage()
		var is_power = area.has_method("is_power_shot") and area.is_power_shot()
		take_damage(damage, is_power)
		area.destroy_bullet()

func _on_body_entered(body):
	# Handle collision with player body
	if body.has_method("take_damage"):
		body.take_damage()
		is_visible = false

func _process(delta):
	# Auto-destroy when not visible
	if not is_visible:
		queue_free()
