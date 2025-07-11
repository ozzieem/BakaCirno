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
	music_player.bus = "Master" # Ensure it's on the Master bus
	add_child(music_player)
	print("🎵 Music player created and added to scene")

	# Create multiple SFX players for simultaneous sounds
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "Master" # Ensure SFX players are on Master bus
		add_child(sfx_player)
		sfx_players.append(sfx_player)

	print("🔊 Created ", MAX_SFX_PLAYERS, " SFX players")

	# Load sounds
	load_sounds()

func load_sounds():
	# Only load sounds once
	if sounds_loaded:
		return

	print("🔊 Loading sound files...")

	# Load audio files
	playing_song = load("res://assets/sounds/CirnoThemeSong.wav") # Use the actual WAV file
	button_play_select = load("res://assets/sounds/ButtonPlaySelectSFX.wav")

	player_shoot = load("res://assets/sounds/PlayershotSFX.wav")
	player_death = load("res://assets/sounds/DeathSFX.wav")

	enemy_circle_shoot = load("res://assets/sounds/EnemyShootSFX1.wav")
	enemy_random_shoot = load("res://assets/sounds/EnemyShootSFX2.wav")
	enemy_death = load("res://assets/sounds/enemyDeathSFX.wav")

	# Debug: Check if main music loaded (only print once)
	if playing_song:
		print("✅ Successfully loaded music: CirnoThemeSong.wav")
		print("   Music stream type: ", playing_song.get_class())
		if playing_song.has_method("get_length"):
			print("   Music duration: ", playing_song.get_length(), " seconds")
	else:
		print("❌ ERROR: Failed to load CirnoThemeSong.wav")

	# Debug: Check other sound files
	print("🔊 Sound loading status:")
	print("   Button select: ", button_play_select != null)
	print("   Player shoot: ", player_shoot != null)
	print("   Player death: ", player_death != null)
	print("   Enemy circle shoot: ", enemy_circle_shoot != null)
	print("   Enemy random shoot: ", enemy_random_shoot != null)
	print("   Enemy death: ", enemy_death != null)

	sounds_loaded = true
	print("🔊 Sound loading completed")

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
	print("🎵 get_playing_song() called")
	print("   music_player exists: ", music_player != null)
	print("   playing_song exists: ", playing_song != null)

	if music_player and playing_song:
		music_player.stream = playing_song
		# In Godot 4, set looping on the AudioStreamPlayer itself
		music_player.autoplay = false

		# Check if the stream supports looping and enable it
		if playing_song is AudioStreamWAV:
			(playing_song as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			print("   Set loop mode for WAV file")

		# Debug stream info
		print("   Music player configured - Stream type: ", playing_song.get_class())
		print("   Music player ready: ", music_player != null)
		print("   Stream assigned successfully")

		# Additional diagnostics
		print("   AudioStreamPlayer bus: ", music_player.bus)
		print("   AudioStreamPlayer volume_db: ", music_player.volume_db)
		print("   AudioStreamPlayer pitch_scale: ", music_player.pitch_scale)
		print("   Stream duration: ", playing_song.get_length() if playing_song.has_method("get_length") else "Unknown")

	else:
		print("❌ ERROR: music_player or playing_song is null")
		print("   music_player: ", music_player)
		print("   playing_song: ", playing_song)

	return music_player

func play_button_select():
	print("🔊 play_button_select() called")
	if button_play_select:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = button_play_select
		sfx_player.volume_db = -10 # Louder for testing
		sfx_player.play()
		print("   Button sound played - status: ", sfx_player.playing)
	else:
		print("❌ Button sound not loaded")

func play_player_shoot():
	if player_shoot:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = player_shoot
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.pitch_scale = 1.8 # Equivalent to 0.8f pitch
		sfx_player.play()

func play_player_death():
	if player_death:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = player_death
		sfx_player.volume_db = -40 # Equivalent to 0.01f volume
		sfx_player.play()

func play_enemy_circle_shoot():
	if enemy_circle_shoot:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = enemy_circle_shoot
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.play()

func play_enemy_random_shoot():
	if enemy_random_shoot:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = enemy_random_shoot
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.pitch_scale = 2.0 # Equivalent to 1.0f pitch
		sfx_player.play()

func play_enemy_death():
	if enemy_death:
		var sfx_player = get_available_sfx_player()
		sfx_player.stream = enemy_death
		sfx_player.volume_db = -35 # Equivalent to 0.005f volume
		sfx_player.play()

# Test function to force music playback at maximum volume
func force_music_test():
	print("🎵 FORCE MUSIC TEST - Maximum volume test")
	if music_player and playing_song:
		music_player.stop() # Stop any current playback
		music_player.stream = playing_song
		music_player.volume_db = 0 # Maximum volume (no reduction)
		music_player.pitch_scale = 1.0 # Normal pitch
		music_player.bus = "Master" # Ensure correct bus

		print("   Music player settings:")
		print("   - Volume: ", music_player.volume_db)
		print("   - Bus: ", music_player.bus)
		print("   - Stream: ", music_player.stream != null)
		print("   - Pitch: ", music_player.pitch_scale)

		music_player.play()

		# Wait a frame and check
		await get_tree().process_frame
		print("   After play() call:")
		print("   - Playing: ", music_player.playing)
		print("   - Stream playback: ", music_player.get_stream_playback() != null)

		# Try to get playback position
		var playback = music_player.get_stream_playback()
		if playback:
			print("   - Playback position: ", playback.get_position())
		else:
			print("   - No stream playback object")
	else:
		print("❌ Cannot force music - player or stream is null")

# Simple audio system test using button sound as music
func test_audio_system():
	print("🔊 AUDIO SYSTEM TEST - Playing button sound as music")
	if button_play_select:
		# Use the music player to play the button sound
		music_player.stop()
		music_player.stream = button_play_select
		music_player.volume_db = 0 # Maximum volume
		music_player.play()

		await get_tree().process_frame
		print("   Button sound as music - playing: ", music_player.playing)
		print("   This tests if the music player itself works")
	else:
		print("❌ Button sound not available for audio test")

# Test function to play button sound as music (file format test)
func test_button_as_music():
	print("🎵 TESTING: Playing button sound as music to test file format")
	if button_play_select and music_player:
		music_player.stop()
		music_player.stream = button_play_select
		music_player.volume_db = 0 # Maximum volume

		# Set up looping for the button sound
		if button_play_select is AudioStreamWAV:
			(button_play_select as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			print("   Set button sound to loop")

		music_player.play()

		await get_tree().process_frame
		print("   Button sound as music - playing: ", music_player.playing)
		print("   Button sound duration: ", button_play_select.get_length(), " seconds")
		print("   If you hear this LOOPING, the music player works but CirnoThemeSong.wav has issues")
		print("   If you hear nothing, there's a deeper audio system issue")
	else:
		print("❌ Cannot test - button_play_select or music_player is null")

# Test function to force music file settings and try again
func fix_and_test_music():
	print("🔧 ATTEMPTING TO FIX MUSIC FILE SETTINGS")
	if playing_song and playing_song is AudioStreamWAV:
		var wav_stream = playing_song as AudioStreamWAV
		print("   Original settings:")
		print("   - Loop mode: ", wav_stream.loop_mode)
		print("   - Duration: ", wav_stream.get_length())

		# Force correct settings
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav_stream.loop_begin = 0
		wav_stream.loop_end = -1

		print("   Applied settings:")
		print("   - Loop mode: ", wav_stream.loop_mode)
		print("   - Loop begin: ", wav_stream.loop_begin)
		print("   - Loop end: ", wav_stream.loop_end)

		# Now try to play with the music player
		if music_player:
			music_player.stop()
			music_player.stream = wav_stream
			music_player.volume_db = 0 # Maximum volume
			music_player.play()

			await get_tree().process_frame
			print("   Music with fixed settings - playing: ", music_player.playing)
			print("   Stream playback exists: ", music_player.get_stream_playback() != null)

			# Check playback position
			var playback = music_player.get_stream_playback()
			if playback:
				await get_tree().process_frame
				print("   Playback position after 2 frames: ", playback.get_position())
				if playback.get_position() > 0:
					print("   ✅ Music is actually playing! (position advancing)")
				else:
					print("   ❌ Music not playing (position stuck at 0)")
			else:
				print("   ❌ No stream playback object")
	else:
		print("❌ Cannot fix - playing_song is not AudioStreamWAV or is null")
