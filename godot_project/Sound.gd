extends Node
class_name Sound

# Audio streams
var playing_song: AudioStream
var button_play_select: AudioStream
var enemy_death: AudioStream
var enemy_circle_shoot: AudioStream
var enemy_random_shoot: AudioStream
var player_shoot: AudioStream
var player_death: AudioStream

# Audio players
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready():
	# Create audio players
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	add_child(music_player)
	add_child(sfx_player)

	# Load sounds
	load_sounds()

func load_sounds():
	# Load audio files
	playing_song = load("res://assets/sounds/CirnoThemeSongWMA.ogg") # Convert to OGG for web
	button_play_select = load("res://assets/sounds/ButtonPlaySelectSFX.wav")

	player_shoot = load("res://assets/sounds/PlayershotSFX.wav")
	player_death = load("res://assets/sounds/DeathSFX.wav")

	enemy_circle_shoot = load("res://assets/sounds/EnemyShootSFX1.wav")
	enemy_random_shoot = load("res://assets/sounds/EnemyShootSFX2.wav")
	enemy_death = load("res://assets/sounds/enemyDeathSFX.wav")

func get_playing_song() -> AudioStreamPlayer:
	if music_player and playing_song:
		music_player.stream = playing_song
		music_player.loop = true
	return music_player

func play_button_select():
	if sfx_player and button_play_select:
		sfx_player.stream = button_play_select
		sfx_player.volume_db = -25 # Equivalent to 0.05f volume
		sfx_player.play()

func play_player_shoot():
	if sfx_player and player_shoot:
		sfx_player.stream = player_shoot
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.pitch_scale = 1.8 # Equivalent to 0.8f pitch
		sfx_player.play()

func play_player_death():
	if sfx_player and player_death:
		sfx_player.stream = player_death
		sfx_player.volume_db = -40 # Equivalent to 0.01f volume
		sfx_player.play()

func play_enemy_circle_shoot():
	if sfx_player and enemy_circle_shoot:
		sfx_player.stream = enemy_circle_shoot
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.play()

func play_enemy_random_shoot():
	if sfx_player and enemy_random_shoot:
		sfx_player.stream = enemy_random_shoot
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.pitch_scale = 2.0 # Equivalent to 1.0f pitch
		sfx_player.play()

func play_enemy_death():
	if sfx_player and enemy_death:
		sfx_player.stream = enemy_death
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.play()
