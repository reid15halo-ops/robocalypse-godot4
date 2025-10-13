extends Node

# Music Manager - Handles background music playlist
# Automatically plays all OGG files from sounds/ directory in a loop

var music_player: AudioStreamPlayer
var playlist: Array[String] = []
var remaining_tracks: Array[String] = []  # Tracks in current shuffle cycle
var current_track_index: int = 0
var is_playing: bool = false

# Music volume (in dB)
var music_volume: float = -5.0

# Sounds directory
var sounds_dir: String = "res://sounds/"

# Shuffle mode
var shuffle_mode: bool = true  # Shuffle enabled by default

# Loop protection
var failed_load_count: int = 0
var max_failed_loads: int = 10
var music_system_disabled: bool = false


func _ready() -> void:
	# Create audio player for music
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = music_volume
	add_child(music_player)

	# Connect finished signal
	music_player.finished.connect(_on_track_finished)

	# Load all MP3 files from sounds directory
	_load_playlist()

	# Start playing music
	if playlist.size() > 0:
		play_music()


func _load_playlist() -> void:
	"""Load all OGG files from sounds directory"""
	# Manually add all known OGG files (Godot doesn't support runtime directory scanning easily)
	var music_files = [
		"Digital Showdown.ogg",
		"Robo Clash.ogg",
		"RoboRumble.ogg",
		"Robot Rumble.ogg",
		"Rogue Against Robots.ogg",
		"Song 1.ogg"
	]

	# Verify files exist and add to playlist
	for file in music_files:
		var full_path = sounds_dir + file
		if FileAccess.file_exists(full_path):
			playlist.append(full_path)
			print("Added to playlist: ", file)
		else:
			print("Music file not found: ", file)

	print("Playlist loaded: ", playlist.size(), " tracks")

	# Initialize shuffle
	if shuffle_mode:
		_refill_remaining_tracks()


func play_music() -> void:
	"""Start playing music from current track"""
	# Check if music system is disabled due to too many failures
	if music_system_disabled:
		return

	if playlist.size() == 0:
		print("No music files in playlist!")
		return

	# Check if we've exceeded max failed loads
	if failed_load_count >= max_failed_loads:
		print("ERROR: Music system disabled - too many failed loads (", failed_load_count, ")")
		music_system_disabled = true
		is_playing = false
		return

	if current_track_index >= playlist.size():
		current_track_index = 0

	var track_path = playlist[current_track_index]
	var stream = load(track_path) as AudioStream

	if stream:
		music_player.stream = stream
		music_player.play()
		is_playing = true
		failed_load_count = 0  # Reset on successful load
		print("Now playing: ", track_path.get_file())
	else:
		print("Failed to load music: ", track_path)
		failed_load_count += 1

		# Try next track, but with protection
		if failed_load_count < max_failed_loads:
			_play_next_track()
		else:
			print("ERROR: Too many consecutive failed loads - disabling music system")
			music_system_disabled = true
			is_playing = false


func _on_track_finished() -> void:
	"""Called when current track finishes - play next track"""
	_play_next_track()


func _play_next_track() -> void:
	"""Play the next track in playlist (with shuffle support)"""
	if shuffle_mode:
		# Shuffle mode: Get next track from remaining_tracks
		if remaining_tracks.size() == 0:
			_refill_remaining_tracks()  # Refill when empty

		if remaining_tracks.size() == 0:
			print("No tracks available!")
			return

		# Get next track from remaining
		var next_track = remaining_tracks.pop_front()
		current_track_index = playlist.find(next_track)
	else:
		# Normal mode: Sequential playback
		current_track_index += 1

		# Loop back to start
		if current_track_index >= playlist.size():
			current_track_index = 0

	play_music()


func _refill_remaining_tracks() -> void:
	"""Refill remaining tracks with shuffled playlist"""
	remaining_tracks = playlist.duplicate()
	remaining_tracks.shuffle()
	print("Playlist shuffled - ", remaining_tracks.size(), " tracks ready")


func pause_music() -> void:
	"""Pause the music"""
	if music_player and not music_player.stream_paused:
		music_player.stream_paused = true
		print("Music paused")


func resume_music() -> void:
	"""Resume the music"""
	if music_player and music_player.stream_paused:
		music_player.stream_paused = false
		print("Music resumed")


func stop_music() -> void:
	"""Stop the music"""
	music_player.stop()
	music_player.stream = null
	is_playing = false
	current_track_index = 0
	print("Music stopped")


func set_volume(volume_db: float) -> void:
	"""Set music volume in decibels (-80 to 0)"""
	music_volume = clamp(volume_db, -80.0, 0.0)
	if music_player:
		music_player.volume_db = music_volume
	print("Music volume set to: ", music_volume, " dB")


func set_music_volume(volume: float) -> void:
	"""Set music volume (0.0 to 1.0)"""
	var db_volume = linear_to_db(clamp(volume, 0.0, 1.0)) - 5.0  # Offset for balance
	set_volume(db_volume)


func skip_track() -> void:
	"""Skip to next track"""
	if music_player:
		music_player.stop()
	_play_next_track()
	print("Skipped to next track")


func get_current_track_name() -> String:
	"""Get the name of the currently playing track"""
	if current_track_index < playlist.size():
		return playlist[current_track_index].get_file()
	return "No track playing"


func _exit_tree() -> void:
	"""Clean up resources before exit"""
	# Disconnect signal
	if music_player and music_player.finished.is_connected(_on_track_finished):
		music_player.finished.disconnect(_on_track_finished)

	# Stop playback
	if music_player:
		music_player.stop()
		music_player.queue_free()

	# Clear references
	music_player = null
	playlist.clear()
	remaining_tracks.clear()
