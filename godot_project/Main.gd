extends Node2D

# Game state enumeration
enum GameState {
	MENU,
	PLAYING,
	GAME_OVER
}

# Game state management
var current_state: GameState = GameState.MENU
var sound_played: bool = false
var game_reset_done: bool = false
var death_transition_done: bool = false

# Game objects and references
var player: Player
var text_overlay: TextOverlay
var high_score_text: HighScoreText

# Game lists
var enemies: Array[Enemy] = []
var explosions: Array[Explosion] = []
var point_bullets: Array[PointBullet] = []

# Game constants and variables
const N_ENEMIES_SPAWN = 5
const enemy_difficulty_increase: float = 0.1
var enemy_difficulty: float = 0.0

# Audio
var game_music: AudioStreamPlayer
var sound_manager: Sound

# Backgrounds
var game_background: Background
var menu_background: Background
var high_score_background: Background

# UI References
@onready var menu_container = $UI/MenuContainer
@onready var game_over_container = $UI/GameOverContainer

# Random number generator
var rng = RandomNumberGenerator.new()

func _ready():
	# Initialize the random number generator
	rng.randomize()

	# Disable debug collision shape drawing globally
	get_tree().debug_collisions_hint = false

	# The window size is set in project settings, but we can ensure it here
	get_window().size = Vector2i(920, 950)

	# Wait one frame for window setup to complete
	await get_tree().process_frame

	# Initialize game objects
	setup_game_objects()
	load_assets()

	# Update background scaling after everything is set up
	update_background_scaling()

	# Set initial UI state
	update_ui_visibility()

	print("BakaCirno initialized - Press Enter to start!")

func setup_game_objects():
	# Create backgrounds first (so they render behind everything)
	game_background = preload("res://Background.tscn").instantiate()
	menu_background = preload("res://Background.tscn").instantiate()
	high_score_background = preload("res://Background.tscn").instantiate()
	add_child(game_background)
	add_child(menu_background)
	add_child(high_score_background)

	# Set z-index to ensure backgrounds are behind everything
	game_background.z_index = -100
	menu_background.z_index = -100
	high_score_background.z_index = -100

	# Create sound manager
	sound_manager = Sound.new()
	add_child(sound_manager)

	# Create player
	player = preload("res://Player.tscn").instantiate()
	add_child(player)

	# Create text overlay (should be on top)
	text_overlay = preload("res://TextOverlay.tscn").instantiate()
	add_child(text_overlay)
	text_overlay.z_index = 100

	# Create high score text
	high_score_text = preload("res://HighScoreText.tscn").instantiate()
	add_child(high_score_text)
	high_score_text.setup_with_overlay(text_overlay)
	high_score_text.visible = false

func load_assets():
	# Load background textures
	game_background.set_texture("res://assets/textures/spacebgtemp.png")
	menu_background.set_texture("res://assets/textures/mainbg2temp.png")
	high_score_background.set_texture("res://assets/textures/highscorebgtemp.png")

	# Load and setup audio
	sound_manager.load_sounds()
	game_music = sound_manager.get_playing_song()

func _process(delta):
	# Check if player is dead (only transition once)
	if player.is_dead and not death_transition_done:
		# Clear all game objects when player dies and transition to GAME_OVER
		clear_all_game_objects()
		current_state = GameState.GAME_OVER
		game_reset_done = false # Allow reset when going back to menu
		death_transition_done = true # Prevent repeated transitions
		print("Player died - transitioning to GAME_OVER")

	# Activate music based on game state
	activate_game_music()

	# Update based on current state
	match current_state:
		GameState.MENU:
			player._process(delta)
			if not game_reset_done:
				reset_game()
				game_reset_done = true
		GameState.PLAYING:
			update_playing_state(delta)
		GameState.GAME_OVER:
			pass

	# Handle input
	handle_input()

	# Update UI visibility
	update_ui_visibility()

func update_playing_state(delta):
	player._process(delta)
	update_enemies(delta)
	update_point_bullets(delta)
	update_explosions(delta)
	text_overlay.update_time(delta)
	text_overlay.set_difficulty_multiplier(enemy_difficulty)

func handle_input():
	# Return to menu if Escape is pressed (from any state)
	if Input.is_action_just_pressed("ui_cancel"):
		if current_state == GameState.MENU:
			# Exit game if already in menu
			print("Exiting game from menu")
			get_tree().quit()
		else:
			print("ESC pressed - returning to menu from ", current_state)
			current_state = GameState.MENU
			game_reset_done = false # Allow reset to happen when returning to menu
			# DON'T reset death_transition_done here - keep it true to prevent immediate return to GAME_OVER

	# Exit game if F12 is pressed
	if Input.is_action_just_pressed("debug_exit"):
		get_tree().quit()

	# Start game if Enter or Space is pressed (only from menu)
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("shoot")) and current_state == GameState.MENU:
		print("Starting new game")
		if not sound_played:
			sound_manager.play_button_select()
			sound_played = true

		player.stop_movement = false
		current_state = GameState.PLAYING
		game_reset_done = false # Reset flag when starting game
		death_transition_done = false # Reset death transition flag only when starting new game

func update_ui_visibility():
	# Update UI based on current state
	match current_state:
		GameState.MENU:
			if menu_container:
				menu_container.visible = true
			if game_over_container:
				game_over_container.visible = false
			if high_score_text:
				high_score_text.visible = false
			game_background.visible = false
			menu_background.visible = true
			high_score_background.visible = false
			player.visible = true # Show player in menu
		GameState.PLAYING:
			if menu_container:
				menu_container.visible = false
			if game_over_container:
				game_over_container.visible = false
			if high_score_text:
				high_score_text.visible = false
			game_background.visible = true
			menu_background.visible = false
			high_score_background.visible = false
			player.visible = true # Show player during gameplay
		GameState.GAME_OVER:
			if menu_container:
				menu_container.visible = false
			if game_over_container:
				game_over_container.visible = true
			if high_score_text:
				high_score_text.visible = true
			game_background.visible = false
			menu_background.visible = false
			high_score_background.visible = true
			player.visible = false # Hide player during game over screen

func reset_game():
	# Reset player
	player.position = Vector2(425, 725)
	player.is_colliding = false
	player.is_dead = false
	player.sound_played = false
	player.stop_movement = true
	player.reset_animation()

	# Clear player bullets
	player.clear_bullets()

	# Clear game objects
	clear_enemies()
	clear_point_bullets()
	clear_explosions()

	# Reset game variables
	enemy_difficulty = 0.0
	text_overlay.reset_stats()
	sound_played = false

	print("Game reset completed")

func activate_game_music():
	# Start music during gameplay
	if not player.is_dead and current_state == GameState.PLAYING:
		if game_music and not game_music.playing:
			game_music.volume_db = -25 # Equivalent to 0.05f volume
			game_music.play()

	# Stop music during menu or death
	if player.is_colliding or player.is_dead or current_state == GameState.MENU:
		if game_music and game_music.playing:
			game_music.stop()

func spawn_points():
	for enemy in enemies:
		if not enemy.is_visible:
			# Spawn points from enemy bullet patterns
			for circle_shots in enemy.circle_shots:
				for bullet in circle_shots.bullets:
					var point_bullet = preload("res://PointBullet.tscn").instantiate()
					point_bullet.setup_point_bullet(load("res://assets/textures/pointBullethalfsize.png"), bullet.position)
					add_child(point_bullet)
					point_bullets.append(point_bullet)
					text_overlay.add_score(5)

func update_point_bullets(delta):
	for i in range(point_bullets.size() - 1, -1, -1):
		var point = point_bullets[i]

		# Check if point bullet is valid and not queued for deletion
		if not point or not is_instance_valid(point):
			point_bullets.remove_at(i)
			continue

		point.update_movement(delta, player)

		if not point.is_visible:
			text_overlay.add_score(10)
			point.queue_free()
			point_bullets.remove_at(i)

func update_explosions(delta):
	for i in range(explosions.size() - 1, -1, -1):
		var explosion = explosions[i]

		# Check if explosion is valid and not queued for deletion
		if not explosion or not is_instance_valid(explosion):
			explosions.remove_at(i)
			continue

		explosion.update_animation(delta)

		if not explosion.is_visible:
			explosion.queue_free()
			explosions.remove_at(i)

func update_enemies(delta):
	var enemy_textures = [
		"res://assets/textures/greenEnemy.png",
		"res://assets/textures/redEnemy.png",
		"res://assets/textures/yellowEnemy.png",
		"res://assets/textures/blueEnemy.png"
	]

	# Update existing enemies
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]

		# Check if enemy is valid and not queued for deletion
		if not enemy or not is_instance_valid(enemy):
			enemies.remove_at(i)
			continue

		enemy.update_movement(delta, player)
		enemy.update_shooting(delta, player)

	# Spawn new enemies if needed
	if enemies.size() < N_ENEMIES_SPAWN:
		var rand_x = rng.randi_range(0, 750)
		var rand_y = rng.randi_range(-200, -50)
		var enemy_type = rng.randi_range(0, enemy_textures.size() - 1)

		var enemy = preload("res://Enemy.tscn").instantiate()
		enemy.position = Vector2(rand_x, rand_y)
		enemy.set_difficulty(enemy_difficulty)
		add_child(enemy)
		enemies.append(enemy)

		# Set texture after adding to scene tree to ensure nodes are ready
		enemy.set_texture(enemy_textures[enemy_type])

	# Remove dead enemies and create explosions
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if not enemy.is_visible:
			# Play death sound
			sound_manager.play_enemy_death()

			# Increase difficulty
			enemy_difficulty += enemy_difficulty_increase

			# Update stats
			text_overlay.add_enemies_killed(1)
			text_overlay.add_score(500)

			# Convert enemy bullets to point bullets
			convert_enemy_bullets_to_points(enemy)

			# Spawn points and explosion
			spawn_points()
			create_explosion(enemy.position)

			# Remove enemy
			enemy.queue_free()
			enemies.remove_at(i)

func create_explosion(pos: Vector2):
	var explosion = preload("res://Explosion.tscn").instantiate()
	explosion.position = pos
	add_child(explosion)
	explosions.append(explosion)

func clear_enemies():
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.clear_all_bullets() # Clear enemy bullets first
			enemy.queue_free()
	enemies.clear()

func clear_point_bullets():
	for point in point_bullets:
		if point and is_instance_valid(point):
			point.queue_free()
	point_bullets.clear()

func clear_explosions():
	for explosion in explosions:
		if explosion and is_instance_valid(explosion):
			explosion.queue_free()
	explosions.clear()

func clear_all_game_objects():
	# Clear all game objects when transitioning to GAME_OVER state
	print("Clearing all game objects for GAME_OVER state")

	# Clear player bullets using the player's method
	player.clear_bullets()

	# Clear enemies and their bullets
	clear_enemies()

	# Clear point bullets
	clear_point_bullets()

	# Clear explosions
	clear_explosions()

	print("All game objects cleared for GAME_OVER state")

func update_background_scaling():
	# Update scaling for all backgrounds to ensure they match the 920x950 window
	if game_background:
		game_background.update_scaling()
	if menu_background:
		menu_background.update_scaling()
	if high_score_background:
		high_score_background.update_scaling()

func convert_enemy_bullets_to_points(enemy: Enemy):
	# Convert all bullets from this enemy's shot patterns to point bullets
	var total_bullets_converted = 0

	# Convert circle shot bullets
	for circle_shot in enemy.circle_shots:
		if circle_shot and is_instance_valid(circle_shot):
			var bullets = circle_shot.get_bullets()
			for bullet in bullets:
				if bullet and is_instance_valid(bullet) and bullet.is_visible:
					create_point_bullet_from_bullet(bullet)
					bullet.is_visible = false # Hide original bullet
					text_overlay.add_score(5) # Bonus points like in original
					total_bullets_converted += 1

	# Convert random shot bullets
	for random_shot in enemy.random_bullets:
		if random_shot and is_instance_valid(random_shot):
			var bullets = random_shot.get_bullets()
			for bullet in bullets:
				if bullet and is_instance_valid(bullet) and bullet.is_visible:
					create_point_bullet_from_bullet(bullet)
					bullet.is_visible = false # Hide original bullet
					text_overlay.add_score(5) # Bonus points like in original
					total_bullets_converted += 1

	if total_bullets_converted > 0:
		print("Converted ", total_bullets_converted, " enemy bullets to point bullets")

func create_point_bullet_from_bullet(bullet):
	# Create a point bullet at the same position as the enemy bullet
	var point_bullet = preload("res://PointBullet.tscn").instantiate()

	# Load point bullet texture with fallback
	var point_texture: Texture2D
	if ResourceLoader.exists("res://assets/textures/pointBullethalfsize.png"):
		point_texture = load("res://assets/textures/pointBullethalfsize.png")
	else:
		# Create fallback point texture
		var image = Image.create(16, 16, false, Image.FORMAT_RGB8)
		image.fill(Color.YELLOW)
		point_texture = ImageTexture.new()
		point_texture.set_image(image)

	# Set position first
	point_bullet.position = bullet.position

	# Add to scene tree first
	add_child(point_bullet)
	point_bullets.append(point_bullet)

	# Then setup texture after nodes are ready
	point_bullet.setup_point_bullet(point_texture, bullet.position)
