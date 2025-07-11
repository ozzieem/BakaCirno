extends Area2D
class_name PointBullet

# Point bullet properties
var texture: Texture2D
var is_visible: bool = true
var difference: Vector2

# Movement speed in pixels per second
var x_move_speed: float = 800.0 # Horizontal speed (pixels/sec)
var y_move_speed: float = x_move_speed * 2 # Vertical speed (pixels/sec)

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Flag to indicate if setup has been called
var setup_called: bool = false
var pending_texture: Texture2D
var pending_position: Vector2

func _ready():
	# Set collision layers and masks
	collision_layer = 4 # Point bullet layer
	collision_mask = 1 # Player layer

	# Connect collision signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Apply pending texture if setup was called before _ready
	if setup_called and pending_texture:
		apply_texture_setup()

func apply_texture_setup():
	texture = pending_texture
	position = pending_position

	if sprite and texture:
		sprite.texture = texture
	else:
		print("ERROR: Could not apply point bullet texture - sprite:", sprite, " texture:", texture)

	# Setup collision shape
	if collision_shape and collision_shape.shape is RectangleShape2D and texture:
		var rect_shape = collision_shape.shape as RectangleShape2D
		rect_shape.size = Vector2(texture.get_width() * 5, texture.get_height() * 5)

func setup_point_bullet(point_texture: Texture2D, start_position: Vector2):
	pending_texture = point_texture
	pending_position = start_position
	setup_called = true

	# If _ready has already been called, apply immediately
	if sprite != null:
		apply_texture_setup()

func update_movement(delta: float, player: Player):
	if not is_visible:
		return

	move_to_player(delta, player)
	check_removal(player)

func move_to_player(delta: float, player: Player):
	# Calculate direction to player
	difference = player.position - position
	difference = difference.normalized()

	# Move towards player, scaled by delta time for frame independence
	position.x += difference.x * x_move_speed * delta
	position.y += difference.y * y_move_speed * delta

func check_removal(player: Player):
	# Check if point bullet reached player
	var point_rect = Rect2(position, Vector2(texture.get_width() * 5, texture.get_height() * 5) if texture else Vector2(40, 40))
	var player_point_rect = Rect2(player.position + Vector2(40, 0), Vector2(40, 40)) # Player's point collection area

	if point_rect.intersects(player_point_rect):
		is_visible = false
		collect_point()

func collect_point():
	# Add score and remove point bullet
	var main = get_parent()
	if main.has_method("add_score"):
		main.add_score(10)

	queue_free()

func _on_area_entered(area):
	# Handle collision with player
	if area.has_method("collect_point"):
		collect_point()

func _on_body_entered(body):
	# Handle collision with player body
	if body.has_method("add_score"):
		collect_point()

func _process(delta):
	# Auto-destroy when not visible
	if not is_visible:
		queue_free()
