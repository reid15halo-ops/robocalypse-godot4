@tool
class_name MusicManager
extends Node

## MusicManager - V2
## Verwaltet die Hintergrundmusik mit dynamischer Playlist, Cross-Fading und Shuffle-Modus.
## Dieses Skript sollte als Autoload/Singleton konfiguriert werden, um über Szenen hinweg zu bestehen.

@export_group("Configuration")
@export var music_directory: String = "res://sounds/"
@export_range(0.0, 5.0, 0.1) var fade_duration: float = 2.0
@export var shuffle_mode: bool = true
@export var autoplay: bool = true

@export_group("Audio Bus")
@export var music_bus_name: String = "Master"
@export_range(-80.0, 0.0) var volume_db: float = -5.0:
	set(value):
		volume_db = value
		if _player_a and is_instance_valid(_player_a):
			_player_a.volume_db = volume_db
		if _player_b and is_instance_valid(_player_b):
			_player_b.volume_db = volume_db

# Interne Variablen
var _playlist: Array[AudioStream] = []
var _shuffled_indices: Array[int] = []
var _current_playlist_index: int = -1

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _fade_tween: Tween

var _is_stopping: bool = false


func _ready() -> void:
	# Initialisiert die beiden AudioStreamPlayer für das Cross-Fading.
	_player_a = _create_player()
	_player_b = _create_player()
	_active_player = _player_a

	# Lade die Playlist und starte die Wiedergabe, wenn gewünscht.
	_load_playlist_from_directory()
	if not Engine.is_editor_hint() and autoplay and not _playlist.is_empty():
		play_music()


func _load_playlist_from_directory() -> void:
	"""Durchsucht das `music_directory` nach OGG- und MP3-Dateien und lädt sie."""
	_playlist.clear()
	
	var dir = DirAccess.open(music_directory)
	if not dir:
		push_warning("MusicManager: Music directory not found at '%s'." % music_directory)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".ogg") or file_name.ends_with(".mp3"):
				var stream = load(music_directory.path_join(file_name))
				if stream:
					_playlist.append(stream)
		file_name = dir.get_next()
	
	print("MusicManager: Loaded %d tracks from '%s'." % [_playlist.size(), music_directory])
	_prepare_shuffled_indices()


func play_music() -> void:
	"""Startet die Musikwiedergabe."""
	if _playlist.is_empty():
		print("MusicManager: Playlist is empty. Cannot play music.")
		return
	
	if _active_player.is_playing():
		print("MusicManager: Music is already playing.")
		return
		
	_is_stopping = false
	_play_next_track()


func stop_music() -> void:
	"""Stoppt die Musikwiedergabe mit einem Fade-Out."""
	if not _active_player or not _active_player.is_playing():
		return

	_is_stopping = true
	_fade_out(_active_player)
	print("MusicManager: Stopping music.")


func skip_track() -> void:
	"""Überspringt den aktuellen Titel und startet den nächsten mit einem Cross-Fade."""
	if not _active_player or not _active_player.is_playing():
		return
	
	print("MusicManager: Skipping track.")
	_on_track_finished()


func set_volume_linear(linear_volume: float) -> void:
	"""Setzt die Lautstärke über einen linearen Wert (0.0 bis 1.0)."""
	self.volume_db = linear_to_db(clamp(linear_volume, 0.0001, 1.0))


# ============================================================================
# Private Methoden
# ============================================================================

func _create_player() -> AudioStreamPlayer:
	"""Erstellt und konfiguriert einen neuen AudioStreamPlayer."""
	var player = AudioStreamPlayer.new()
	player.bus = music_bus_name
	player.volume_db = volume_db
	player.finished.connect(_on_track_finished)
	add_child(player)
	return player


func _play_next_track() -> void:
	"""Wählt den nächsten Titel aus und startet das Cross-Fading."""
	if _playlist.is_empty() or _is_stopping:
		return

	_current_playlist_index = _get_next_track_index()
	if _current_playlist_index == -1:
		print("MusicManager: No valid next track found.")
		return

	var next_stream = _playlist[_current_playlist_index]
	
	# Wechsle zum inaktiven Player für den neuen Titel
	var new_player = _player_b if _active_player == _player_a else _player_a
	
	# Starte den Cross-Fade-Prozess
	_cross_fade(_active_player, new_player, next_stream)
	_active_player = new_player
	
	print("MusicManager: Now playing '%s'." % next_stream.resource_path.get_file())


func _get_next_track_index() -> int:
	"""Ermittelt den Index des nächsten Titels basierend auf dem Shuffle-Modus."""
	if _playlist.is_empty():
		return -1

	if shuffle_mode:
		if _shuffled_indices.is_empty():
			_prepare_shuffled_indices()
		return _shuffled_indices.pop_front() if not _shuffled_indices.is_empty() else 0
	else:
		return (_current_playlist_index + 1) % _playlist.size()


func _prepare_shuffled_indices() -> void:
	"""Erstellt eine zufällige Liste von Indizes für den Shuffle-Modus."""
	if _playlist.is_empty():
		return
		
	_shuffled_indices = range(_playlist.size())
	_shuffled_indices.shuffle()
	print("MusicManager: Playlist shuffled.")


func _on_track_finished() -> void:
	"""Wird aufgerufen, wenn ein Titel endet. Startet den nächsten."""
	if _is_stopping:
		_active_player.stream = null
		return
		
	_play_next_track()


# ============================================================================
# Fading-Logik
# ============================================================================

func _cross_fade(old_player: AudioStreamPlayer, new_player: AudioStreamPlayer, new_stream: AudioStream) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	_fade_tween = create_tween().set_parallel(true)

	# Fade-Out für den alten Player (nur wenn er gerade spielt)
	if old_player.is_playing():
		_fade_tween.tween_property(old_player, "volume_db", -80.0, fade_duration)
		_fade_tween.tween_callback(old_player.stop)

	# Fade-In für den neuen Player
	new_player.stream = new_stream
	new_player.volume_db = -80.0
	new_player.play()
	_fade_tween.tween_property(new_player, "volume_db", volume_db, fade_duration)


func _fade_out(player: AudioStreamPlayer) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(player, "volume_db", -80.0, fade_duration)
	_fade_tween.tween_callback(player.stop)
	_fade_tween.tween_callback(func(): _is_stopping = false)
