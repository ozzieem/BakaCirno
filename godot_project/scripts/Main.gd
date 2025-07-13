extends Node2D
class_name Main

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
const N_ENEMIES_SPAWN = 3
const enemy_difficulty_increase: float = 0.1
var enemy_difficulty: float = 0.0

# Boss system variables
var boss_spawn_threshold: int = 10 # Spawn boss every 10 kills
var current_boss: BossEnemy = null
var boss_active: bool = false
var boss_level: int = 1
var kills_since_last_boss: int = 0

# Boss warning system variables
var boss_warning_active: bool = false
var boss_warning_time: float = 5.0 # 5 seconds warning time (increased from 3)
var boss_warning_timer: float = 0.0

# Boss spawn delay system variables
var boss_spawn_delay_active: bool = false
var boss_spawn_delay_time: float = 2.0 # 2 seconds delay after last enemy kill
var boss_spawn_delay_timer: float = 0.0

# Audio
var game_music: AudioStreamPlayer
var sound_manager: Sound
var music_started: bool = false

# Backgrounds
var game_background: Background
var menu_background: Background
var high_score_background: Background

# UI References
@onready var menu_container = $UI/MenuContainer
@onready var game_over_container = $UI/GameOverContainer

# Debug UI
var pattern_debug_ui: PatternDebugUI

# Random number generator
var rng = RandomNumberGenerator.new()

# Debug state
var debug_mode_active: bool = false
var player_invincible: bool = false
var player_can_shoot: bool = true

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

	# Initialize debug UI
	setup_debug_ui()

	print("BakaCirno initialized - Press Enter to start!")

func setup_game_objects():
	# Create backgrounds first (so they render behind everything)
	game_background = preload("res://scenes/Background.tscn").instantiate()
	menu_background = preload("res://scenes/Background.tscn").instantiate()
	high_score_background = preload("res://scenes/Background.tscn").instantiate()
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
	player = preload("res://scenes/Player.tscn").instantiate()
	add_child(player)
	# Pass sound manager to player
	player.set_sound_manager(sound_manager)

	# Create text overlay (should be on top)
	text_overlay = preload("res://scenes/TextOverlay.tscn").instantiate()
	add_child(text_overlay)
	text_overlay.z_index = 100

	# Create high score text
	high_score_text = preload("res://scenes/HighScoreText.tscn").instantiate()
	add_child(high_score_text)
	high_score_text.setup_with_overlay(text_overlay)
	high_score_text.visible = false

func load_assets():
	# Load background textures
	game_background.set_texture("res://assets/textures/backgrounds/bg_spacebgtemp.png")
	menu_background.set_texture("res://assets/textures/backgrounds/bg_mainbg2temp.png")
	high_score_background.set_texture("res://assets/textures/backgrounds/bg_highscorebgtemp.png")

	# Load and setup audio
	sound_manager.load_sounds()
	game_music = sound_manager.get_playing_song()

	# Debug: Check if music is properly loaded
	if game_music:
		print("Game music loaded successfully")
		if game_music.stream:
			print("Music stream assigned: ", game_music.stream.resource_path if game_music.stream.has_method("get_path") else "stream loaded")
		else:
			print("WARNING: Music stream is null!")
	else:
		print("ERROR: Failed to get game music!")

func _process(delta):
	# Check if player is dead (only transition once)
	if player.is_dead and not death_transition_done:
		# Disable shooting when player dies
		player.set_can_shoot(false)
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
	update_boss_spawn_delay(delta)
	update_boss_warning(delta)
	text_overlay.update_time(delta)
	text_overlay.set_difficulty_multiplier(enemy_difficulty)

func handle_input():
	# Handle debug input first
	handle_debug_input()

	# Return to menu if Escape is pressed (from any state)
	if Input.is_action_just_pressed("ui_cancel"):
		if current_state == GameState.MENU:
			# Exit game if already in menu
			print("Exiting game from menu")
			get_tree().quit()
		else:
			print("ESC pressed - returning to menu from ", current_state)
			player.set_can_shoot(false) # Disable shooting when returning to menu
			current_state = GameState.MENU
			game_reset_done = false # Allow reset to happen when returning to menu
			# DON'T reset death_transition_done here - keep it true to prevent immediate return to GAME_OVER

	# Start game if Enter or Space is pressed (only from menu)
	if Input.is_action_just_pressed("ui_accept") and current_state == GameState.MENU:
		print("Starting new game")
		if not sound_played:
			sound_manager.play_button_select()
			sound_played = true

		player.stop_movement = false
		player.set_can_shoot(true) # Enable shooting when game starts
		current_state = GameState.PLAYING
		game_reset_done = false # Reset flag when starting game
		death_transition_done = false # Reset death transition flag only when starting new game

		# # Force music to start immediately
		# if game_music and game_music.stream and not music_started:
		# 	game_music.volume_db = -25
		# 	game_music.play()
		# 	music_started = true
		# 	print("Force started game music on game start")

func handle_debug_input():
	"""Handle debug input actions"""
	# Toggle debug enemy info with I key
	if Input.is_action_just_pressed("debug_enemy_info"):
		toggle_enemy_debug_info()

	# Exit game with F12 key
	if Input.is_action_just_pressed("debug_exit"):
		get_tree().quit()

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

	# Maintain debug invincibility state during reset
	if debug_mode_active or is_debug_ui_active():
		player.set_invincible(true)

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

	# Reset boss system
	boss_active = false
	current_boss = null
	boss_level = 1
	kills_since_last_boss = 0

	# Reset boss warning system
	boss_warning_active = false
	boss_warning_timer = 0.0

	# Reset boss spawn delay system
	boss_spawn_delay_active = false
	boss_spawn_delay_timer = 0.0

	# Reset life-bubble system to full health (permanent now)
	player.restore_life_bubble_full()

	# TESTING: Reset music state so it can start in menu
	if game_music and game_music.playing:
		game_music.stop()
	music_started = false
	print("🎵 Music state reset - ready to start in menu")

	print("Game reset completed")

func activate_game_music():
	# Also try to start music during gameplay (original logic)
	if current_state == GameState.PLAYING and not player.is_dead and not music_started:
		if game_music and game_music.stream:
			game_music.volume_db = -20
			game_music.play()
			music_started = true
			print("🎵 Started game music during gameplay")
			print("Music playing status: ", game_music.playing)
		else:
			print("❌ ERROR: Cannot start music during gameplay - game_music or stream is null")

	# Stop music during game over or when player dies
	if current_state == GameState.GAME_OVER and music_started:
		if game_music and game_music.playing:
			game_music.stop()
		music_started = false
		print("🎵 Stopped game music (game over)")

func spawn_points():
	for enemy in enemies:
		if not enemy.is_visible:
			# Spawn points from enemy bullet patterns
			for circle_shots in enemy.circle_shots:
				for bullet in circle_shots.bullets:
					var point_bullet = preload("res://scenes/PointBullet.tscn").instantiate()
					point_bullet.setup_point_bullet(load("res://assets/textures/bullets/bullet_pointBullethalfsize.png"), bullet.position)
					add_child(point_bullet)
					point_bullets.append(point_bullet)
					text_overlay.add_score(5)

func spawn_life_bubble_refill(enemy_position: Vector2, is_boss: bool = false):
	"""Spawn a life bubble refill at the given position"""
	var refill = preload("res://scenes/LifeBubbleRefill.tscn").instantiate()
	refill.position = enemy_position

	if is_boss:
		# Boss drops full restore
		refill.setup_refill(0, true)
		add_child(refill)
	else:
		# Regular enemy drops single refill (chance based)
		var drop_chance = rng.randf()
		if drop_chance < 0.3: # 30% chance to drop refill
			refill.setup_refill(1, false)
			add_child(refill)
		else:
			refill.queue_free()
			return

	print("Life bubble refill spawned at position: ", enemy_position, " (boss: ", is_boss, ")")

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
		"res://assets/textures/enemies/enemy_green_enemy_flap_strip.png",
		"res://assets/textures/enemies/enemy_red_enemy_flap_strip.png",
		"res://assets/textures/enemies/enemy_yellow_enemy_flap_strip.png",
		"res://assets/textures/enemies/enemy_blue_enemy_flap_strip.png"
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

	# Check if we should trigger boss spawn delay
	if should_trigger_boss_spawn_delay() and not is_debug_ui_active():
		trigger_boss_spawn_delay()
	# Spawn new enemies if needed (but not when debug UI is active, boss is active, or boss delay/warning is active)
	elif enemies.size() < N_ENEMIES_SPAWN and not is_debug_ui_active() and not boss_active and not boss_warning_active and not boss_spawn_delay_active:
		# Spawn multiple enemies to reach N_ENEMIES_SPAWN
		var enemies_to_spawn = N_ENEMIES_SPAWN - enemies.size()
		for i in range(enemies_to_spawn):
			var rand_x = rng.randi_range(0, 750)
			var rand_y = rng.randi_range(-200, -50)
			var enemy_type = rng.randi_range(0, enemy_textures.size() - 1)

			var enemy = preload("res://scenes/Enemy.tscn").instantiate()
			enemy.position = Vector2(rand_x, rand_y)
			add_child(enemy)
			enemy.set_difficulty(enemy_difficulty)
			enemies.append(enemy)

			# Pass sound manager to enemy
			enemy.set_sound_manager(sound_manager)

			# Set texture after adding to scene tree to ensure nodes are ready
			enemy.set_texture(enemy_textures[enemy_type])

			# Set debug info state if debug mode is active
			if debug_mode_active || is_debug_ui_active():
				enemy.set_debug_info(true)

	# Remove dead enemies and create explosions
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		if not enemy.is_visible:
			# Play death sound
			sound_manager.play_enemy_death()

			# Check if this is a boss enemy
			var is_boss = enemy.has_method("is_boss") and enemy.is_boss()

			if is_boss:
				# Boss defeated
				boss_active = false
				current_boss = null
				boss_level += 1
				kills_since_last_boss = 0

				# Spawn life bubble full restore from boss
				spawn_life_bubble_refill(enemy.position, true)

				# Give bonus rewards for boss
				text_overlay.add_enemies_killed(1)
				text_overlay.add_score(5000 + (boss_level * 1000)) # Bonus score for boss

				print("Boss defeated! Next boss level: ", boss_level, " - Life bubble full restore dropped!")
			else:
				# Regular enemy defeated
				text_overlay.add_enemies_killed(1)
				text_overlay.add_score(500)
				kills_since_last_boss += 1

				# Spawn life bubble refill (chance based)
				spawn_life_bubble_refill(enemy.position, false)

				print("Regular enemy defeated. Kills since last boss: ", kills_since_last_boss, "/", boss_spawn_threshold)

			# Increase difficulty
			enemy_difficulty += enemy_difficulty_increase

			# IMPORTANT: First stop enemy from spawning new bullets
			if enemy.pattern_manager:
				enemy.pattern_manager.auto_spawn_enabled = false

			# Spawn points and explosion
			spawn_points()
			create_explosion(enemy.position)

			# Clear remaining bullets and remove enemy
			# NOTE: clear_all_bullets() will handle bullet conversion internally
			enemy.clear_all_bullets()
			enemy.queue_free()
			enemies.remove_at(i)

func create_explosion(pos: Vector2):
	var explosion = preload("res://scenes/Explosion.tscn").instantiate()
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
	"""Clear all point bullets from the game"""
	for point in point_bullets:
		if point and is_instance_valid(point):
			point.queue_free()
	point_bullets.clear()

func clear_explosions():
	"""Clear all explosions from the game"""
	for explosion in explosions:
		if explosion and is_instance_valid(explosion):
			explosion.queue_free()
	explosions.clear()

func clear_all_game_objects():
	"""Clear all game objects when transitioning to GAME_OVER state"""
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

func should_spawn_boss() -> bool:
	"""Check if a boss should be spawned"""
	return (
		kills_since_last_boss >= boss_spawn_threshold and
		not boss_active and
		current_boss == null and
		not boss_warning_active
		# Note: Removed enemies.size() == 0 condition to allow boss spawning
	)

func should_trigger_boss_warning() -> bool:
	"""Check if a boss warning should be triggered"""
	return (
		kills_since_last_boss >= boss_spawn_threshold and
		not boss_active and
		current_boss == null and
		not boss_warning_active and
		not boss_spawn_delay_active
	)

func should_trigger_boss_spawn_delay() -> bool:
	"""Check if boss spawn delay should be triggered"""
	return (
		kills_since_last_boss >= boss_spawn_threshold and
		not boss_active and
		current_boss == null and
		not boss_warning_active and
		not boss_spawn_delay_active
	)

func trigger_boss_spawn_delay():
	"""Trigger the boss spawn delay system"""
	boss_spawn_delay_active = true
	boss_spawn_delay_timer = boss_spawn_delay_time
	print("Boss spawn delay triggered! Warning will start in ", boss_spawn_delay_time, " seconds")

func update_boss_spawn_delay(delta: float):
	"""Update the boss spawn delay timer"""
	if boss_spawn_delay_active:
		boss_spawn_delay_timer -= delta
		if boss_spawn_delay_timer <= 0:
			boss_spawn_delay_active = false
			boss_spawn_delay_timer = 0.0
			trigger_boss_warning()
			print("Boss spawn delay finished - starting warning now!")

func trigger_boss_warning():
	"""Trigger the boss warning system"""
	boss_warning_active = true
	boss_warning_timer = boss_warning_time
	print("Boss warning triggered! Boss will spawn in ", boss_warning_time, " seconds")

func update_boss_warning(delta: float):
	"""Update the boss warning timer"""
	if boss_warning_active:
		boss_warning_timer -= delta
		if boss_warning_timer <= 0:
			boss_warning_active = false
			boss_warning_timer = 0.0
			spawn_boss()
			print("Boss warning finished - spawning boss now!")

func spawn_boss():
	"""Spawn a boss enemy"""
	if boss_active or current_boss != null:
		return

	print("Spawning boss level ", boss_level, " after ", kills_since_last_boss, " kills")

	# Clear any remaining enemies before spawning boss
	clear_enemies()

	# Create boss enemy
	var boss_scene = preload("res://scenes/BossEnemy.tscn")
	current_boss = boss_scene.instantiate()

	# Set boss properties
	current_boss.set_boss_level(boss_level)
	current_boss.set_difficulty(enemy_difficulty)
	current_boss.set_sound_manager(sound_manager)

	# Set debug info if active
	if debug_mode_active || is_debug_ui_active():
		current_boss.set_debug_info(true)

	# Add to scene
	add_child(current_boss)
	enemies.append(current_boss)

	# Mark boss as active
	boss_active = true

	# Play boss music or sound effect here if desired
	print("Boss spawned! Level: ", boss_level, " - Life bubble is always active!")

func get_boss_info() -> Dictionary:
	"""Get current boss information for UI display"""
	if current_boss and is_instance_valid(current_boss):
		return current_boss.get_boss_info()
	return {}

func is_boss_active() -> bool:
	"""Check if a boss is currently active"""
	return boss_active and current_boss != null and is_instance_valid(current_boss)

func get_kills_until_next_boss() -> int:
	"""Get the number of kills until the next boss spawns"""
	if boss_active:
		return 0
	return boss_spawn_threshold - kills_since_last_boss

func is_boss_warning_active() -> bool:
	"""Check if boss warning is currently active"""
	return boss_warning_active

func get_boss_warning_time_left() -> float:
	"""Get the remaining time for boss warning"""
	return boss_warning_timer

func is_boss_spawn_delay_active() -> bool:
	"""Check if boss spawn delay is currently active"""
	return boss_spawn_delay_active

func get_boss_spawn_delay_time_left() -> float:
	"""Get the remaining time for boss spawn delay"""
	return boss_spawn_delay_timer

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

	# Convert bullets from new pattern manager system
	if enemy.pattern_manager:
		var bullet_creator = func(bullet: Bullet):
			create_point_bullet_from_bullet(bullet)
			text_overlay.add_score(5) # Bonus points like in original

		total_bullets_converted += enemy.pattern_manager.convert_all_bullets_to_points(bullet_creator)

	# Convert legacy pattern bullets (for backward compatibility)
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
	var point_bullet = preload("res://scenes/PointBullet.tscn").instantiate()

	# Load point bullet texture with fallback
	var point_texture: Texture2D
	if ResourceLoader.exists("res://assets/textures/bullets/bullet_pointBullethalfsize.png"):
		point_texture = load("res://assets/textures/bullets/bullet_pointBullethalfsize.png")
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

func toggle_enemy_debug_info():
	"""Toggle debug information display for all enemies"""
	debug_mode_active = not debug_mode_active
	player_invincible = debug_mode_active

	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.set_debug_info(debug_mode_active)

	# Update player invincibility based on debug mode
	if player:
		player.set_invincible(player_invincible)

	var status = "enabled" if debug_mode_active else "disabled"
	print("Debug mode ", status, " - Player invincibility ", status)

func setup_debug_ui():
	"""Initialize the debug UI"""
	# Load and instantiate the PatternDebugUI
	var debug_ui_scene = preload("res://scenes/PatternDebugUI.tscn")
	pattern_debug_ui = debug_ui_scene.instantiate()

	# Add to UI layer
	$UI.add_child(pattern_debug_ui)

	# Set reference to main scene
	pattern_debug_ui.set_main_scene(self)

	print("PatternDebugUI initialized - Press F3 to toggle")

func is_debug_ui_active() -> bool:
	"""Check if the pattern debug UI is currently active"""
	return pattern_debug_ui != null and pattern_debug_ui.visible

func pause_music():
	"""Pause the game music"""
	if game_music and game_music.playing:
		game_music.stream_paused = true
		print("🎵 Music paused for debug mode")

func resume_music():
	"""Resume the game music"""
	if game_music and game_music.stream_paused:
		game_music.stream_paused = false
		print("🎵 Music resumed from debug mode")

func get_player_position() -> Vector2:
	"""Get the player position for enemy targeting"""
	if player and is_instance_valid(player):
		return player.position
	return Vector2.ZERO

func set_player_invincible(invincible: bool):
	"""Set player invincibility state"""
	player_invincible = invincible
	if player:
		player.set_invincible(player_invincible)
	var status = "enabled" if invincible else "disabled"
	print("Player invincibility ", status, " by debug UI")

func set_player_can_shoot(can_shoot: bool):
	"""Set player shooting state"""
	player_can_shoot = can_shoot
	if player:
		player.set_can_shoot(player_can_shoot)
	var status = "enabled" if can_shoot else "disabled"
	print("Player shooting ", status, " by debug UI")

func _unhandled_input(event):
	"""Handle unhandled input events"""
	if event is InputEventKey and event.pressed:
		# Toggle pattern debug UI with F3
		if event.keycode == KEY_F3:
			if pattern_debug_ui:
				pattern_debug_ui.toggle_visibility()
			get_viewport().set_input_as_handled()
