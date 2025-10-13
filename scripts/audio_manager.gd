extends Node

# Audio Manager - Handles all meme sound effects with volume control
# Sounds will be added as .ogg files in res://sounds/

enum SoundType {
	VINE_BOOM,      # Big damage/boss spawn
	BRUH,           # Player death
	WINDOWS_ERROR,  # Item pickup fail/error
	OOF,            # Taking damage
	METAL_PIPE,     # Enemy death/hit
	NOKIA,          # Wave complete
	DISCORD_JOIN,   # Item pickup success
	WILHELM_SCREAM, # Kamikaze explosion
	QUACK,          # Ability verwendet (Ente)
	WINDOWS_SHUTDOWN, # Game Over
	WAS_IST_GESCHEHEN, # Boss erscheint (UT Kid)
	MLG_AIRHORN,    # Kritischer Treffer / Multi-Kill
	SCREAMING_GOAT, # Großer Schaden
	NEIN,           # Ability auf Cooldown
	DISCORD_PING    # Portal erscheint / Level Up
}

# Sound file paths
var sound_paths: Dictionary = {
	SoundType.VINE_BOOM: "res://sounds/vine_boom.ogg",
	SoundType.BRUH: "res://sounds/bruh.ogg",
	SoundType.WINDOWS_ERROR: "res://sounds/windows_error.ogg",
	SoundType.OOF: "res://sounds/oof.ogg",
	SoundType.METAL_PIPE: "res://sounds/metal_pipe.ogg",
	SoundType.NOKIA: "res://sounds/nokia.ogg",
	SoundType.DISCORD_JOIN: "res://sounds/discord_join.ogg",
	SoundType.WILHELM_SCREAM: "res://sounds/wilhelm_scream.ogg",
	SoundType.QUACK: "res://sounds/quack.ogg",
	SoundType.WINDOWS_SHUTDOWN: "res://sounds/windows_shutdown.ogg",
	SoundType.WAS_IST_GESCHEHEN: "res://sounds/was_ist_geschehen.ogg",
	SoundType.MLG_AIRHORN: "res://sounds/mlg_airhorn.ogg",
	SoundType.SCREAMING_GOAT: "res://sounds/screaming_goat.ogg",
	SoundType.NEIN: "res://sounds/nein.ogg",
	SoundType.DISCORD_PING: "res://sounds/discord_ping.ogg"
}

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var meme_sounds_enabled: bool = true

# Audio player pool (for overlapping sounds)
var audio_players: Array[AudioStreamPlayer] = []
var max_audio_players: int = 12  # Increased for more overlapping sounds
var current_player_index: int = 0

# Cooldown for meme spam prevention
var last_meme_time: Dictionary = {}
var meme_cooldown: float = 0.5  # 0.5 seconds between same sound

# Signals
signal volume_changed(master: float, sfx: float)


func _ready() -> void:
	# Create audio player pool
	for i in range(max_audio_players):
		var player = AudioStreamPlayer.new()
		add_child(player)
		audio_players.append(player)


func play_sound(sound_type: SoundType, volume_db: float = 0.0, force: bool = false) -> void:
	"""Play a sound effect from the pool with volume control"""

	# Check if meme sounds are enabled
	if not meme_sounds_enabled and not force:
		return

	# Check cooldown to prevent spam
	if not force and last_meme_time.has(sound_type):
		var time_since = Time.get_ticks_msec() / 1000.0 - last_meme_time[sound_type]
		if time_since < meme_cooldown:
			return

	var sound_path = sound_paths.get(sound_type, "")

	if sound_path.is_empty():
		print("Sound path not found for type: ", sound_type)
		return

	# Check if file exists
	if not FileAccess.file_exists(sound_path):
		# Silently fail if sound doesn't exist (not critical)
		return

	# Load sound
	var sound = load(sound_path) as AudioStream
	if not sound:
		return

	# Get next available player
	var player = audio_players[current_player_index]
	current_player_index = (current_player_index + 1) % max_audio_players

	# Apply volume settings
	var final_volume = volume_db + linear_to_db(master_volume * sfx_volume)

	# Play sound
	player.stream = sound
	player.volume_db = final_volume
	player.play()

	# Update cooldown
	last_meme_time[sound_type] = Time.get_ticks_msec() / 1000.0


func set_master_volume(volume: float) -> void:
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	volume_changed.emit(master_volume, sfx_volume)

	# Also update music manager
	if MusicManager:
		MusicManager.set_music_volume(master_volume)


func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	volume_changed.emit(master_volume, sfx_volume)


func set_meme_sounds_enabled(enabled: bool) -> void:
	"""Enable or disable meme sounds"""
	meme_sounds_enabled = enabled


func play_damage_sound() -> void:
	"""Play damage sound (Oof)"""
	play_sound(SoundType.OOF, -5.0)


func play_death_sound() -> void:
	"""Play death sound (Bruh)"""
	play_sound(SoundType.BRUH, 0.0)


func play_enemy_death_sound() -> void:
	"""Play enemy death sound (Metal Pipe)"""
	play_sound(SoundType.METAL_PIPE, -8.0)


func play_boss_spawn_sound() -> void:
	"""Play boss spawn sound (Vine Boom)"""
	play_sound(SoundType.VINE_BOOM, 2.0)


func play_wave_complete_sound() -> void:
	"""Play wave complete sound (Nokia)"""
	play_sound(SoundType.NOKIA, -3.0)


func play_item_pickup_sound() -> void:
	"""Play item pickup sound (Discord Join)"""
	play_sound(SoundType.DISCORD_JOIN, -5.0)


func play_explosion_sound() -> void:
	"""Play explosion sound (Wilhelm Scream)"""
	play_sound(SoundType.WILHELM_SCREAM, -3.0)


func play_error_sound() -> void:
	"""Play error sound (Windows Error)"""
	play_sound(SoundType.WINDOWS_ERROR, -5.0)


func play_ability_sound() -> void:
	"""Play ability cast sound (Quack)"""
	play_sound(SoundType.QUACK, -3.0)


func play_ability_cooldown_sound() -> void:
	"""Play ability on cooldown sound (NEIN)"""
	play_sound(SoundType.NEIN, -2.0)


func play_game_over_sound() -> void:
	"""Play game over sound (Windows Shutdown)"""
	play_sound(SoundType.WINDOWS_SHUTDOWN, 0.0, true)  # Force play


func play_big_damage_sound() -> void:
	"""Play big damage sound (Screaming Goat)"""
	play_sound(SoundType.SCREAMING_GOAT, -1.0)


func play_multi_kill_sound() -> void:
	"""Play multi-kill sound (MLG Airhorn)"""
	play_sound(SoundType.MLG_AIRHORN, 2.0)


func play_portal_spawn_sound() -> void:
	"""Play portal spawn sound (Discord Ping)"""
	play_sound(SoundType.DISCORD_PING, -3.0)


func play_boss_rage_sound() -> void:
	"""Play boss rage sound (Was ist geschehen?)"""
	play_sound(SoundType.WAS_IST_GESCHEHEN, 1.0)


func stop_all_sounds() -> void:
	for player in audio_players:
		if player and player.playing:
			player.stop()


func _exit_tree() -> void:
	stop_all_sounds()
	for player in audio_players:
		if player and player.is_inside_tree():
			player.queue_free()
	audio_players.clear()
