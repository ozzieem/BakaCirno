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
var sfx_players: Array[AudioStreamPlayer] = []
var current_sfx_index: int = 0
const MAX_SFX_PLAYERS = 8 # Allow up to 8 simultaneous sound effects

# Load flag to prevent repeated loading
var sounds_loaded: bool = false

func _ready():
	# Create audio players
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	# Create multiple SFX players for simultaneous sounds
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

	# Load sounds
	load_sounds()

func load_sounds():
	# Only load sounds once
	if sounds_loaded:
		return

	# Load audio files
	playing_song = load("res://assets/sounds/music/music_CirnoThemeSong.ogg")
	button_play_select = load("res://assets/sounds/sfx/sfx_ButtonPlaySelectSFX.wav")

	player_shoot = load("res://assets/sounds/sfx/sfx_PlayershotSFX.wav")
	player_death = load("res://assets/sounds/sfx/sfx_DeathSFX.wav")

	enemy_circle_shoot = load("res://assets/sounds/sfx/sfx_EnemyShootSFX1.wav")
	enemy_random_shoot = load("res://assets/sounds/sfx/sfx_EnemyShootSFX2.wav")
	enemy_death = load("res://assets/sounds/sfx/sfx_enemyDeathSFX.wav")

	# Debug: Check if main music loaded
	if playing_song:
		print("✅ Successfully loaded music: CirnoThemeSong.ogg")
	else:
		print("❌ ERROR: Failed to load CirnoThemeSong.ogg")

	sounds_loaded = true

func get_available_sfx_player() -> AudioStreamPlayer:
	# Find an available (not playing) SFX player, or use round-robin if all are busy
	for i in range(MAX_SFX_PLAYERS):
		var player = sfx_players[i]
		if not player.playing:
			return player

	# If all players are busy, use round-robin
	var player = sfx_players[current_sfx_index]
	current_sfx_index = (current_sfx_index + 1) % MAX_SFX_PLAYERS
	return player

func get_playing_song() -> AudioStreamPlayer:
	if music_player and playing_song:
		music_player.stream = playing_song
		music_player.autoplay = false

		# Check if the stream supports looping and enable it
		if playing_song is AudioStreamWAV:
			(playing_song as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif playing_song is AudioStreamOggVorbis:
			# OGG files use the loop property in their import settings
			pass

	return music_player

func play_button_select():
	if button_play_select:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = button_play_select
		sfx_player.volume_db = -10
		sfx_player.play()

func play_player_shoot(power_shot: bool = false):
	if player_shoot:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = player_shoot
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.pitch_scale = 1.5 if power_shot else 1.8
		sfx_player.play()

func play_player_death():
	if player_death:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = player_death
		sfx_player.volume_db = -20 # Equivalent to 0.01f volume
		sfx_player.play()

func play_enemy_circle_shoot():
	if enemy_circle_shoot:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = enemy_circle_shoot
		sfx_player.volume_db = -25 # Equivalent to 0.005f volume
		sfx_player.play()

func play_enemy_random_shoot():
	if enemy_random_shoot:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = enemy_random_shoot
		sfx_player.volume_db = -20 # Equivalent to 0.005f volume
		sfx_player.pitch_scale = 2.0 # Equivalent to 1.0f pitch
		sfx_player.play()

func play_enemy_death():
	if enemy_death:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = enemy_death
		sfx_player.volume_db = -30 # Equivalent to 0.005f volume
		sfx_player.play()
