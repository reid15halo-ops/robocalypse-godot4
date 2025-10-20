@tool
class_name SFXManager
extends Node

## SFXManager - V1
## Verwaltet und spielt Meme-basierte Soundeffekte ab.
## Sollte als Autoload/Singleton konfiguriert werden, um global verfügbar zu sein.

@export_group("Configuration")
@export var sfx_directory: String = "res://sounds/sfx/"
@export_group("Audio Bus")
@export var sfx_bus_name: String = "SFX"
@export_range(-80.0, 0.0) var volume_db: float = 0.0

# Enum für einfachen und fehlerfreien Zugriff auf die Sounds.
# Die Namen sollten den Dateinamen (ohne Endung) entsprechen.
enum Sound {
	PLAYER_DEATH,       # z.B. sad_violin.ogg
	PLAYER_DAMAGE,      # z.B. emotional_damage.ogg
	ENEMY_DEATH_STD,    # z.B. oof.ogg
	ENEMY_DEATH_ELITE,  # z.B. vine_boom.ogg
	MULTI_KILL,         # z.B. pog.ogg
	RELOAD,             # z.B. hello_darkness.ogg
	HEAL,               # z.B. lets_go.ogg
	WAVE_START,         # z.B. here_we_go_again.ogg
	WAVE_CLEAR,         # z.B. victory_fanfare.ogg
	CRITICAL_HIT        # z.B. wow.ogg
}

# Ein Dictionary, das die Enum-Werte auf die geladenen AudioStreams abbildet.
var _sound_library: Dictionary = {}
# Ein Pool von AudioStreamPlayern, um mehrere Sounds gleichzeitig abspielen zu können.
var _player_pool: Array[AudioStreamPlayer] = []
var _pool_size: int = 10 # Erlaubt bis zu 10 Sounds gleichzeitig

func _ready() -> void:
	# Lade alle Sounds beim Start
	_load_sfx_from_directory()
	
	# Erstelle den Player-Pool
	for i in range(_pool_size):
		var player = AudioStreamPlayer.new()
		player.bus = sfx_bus_name
		player.volume_db = volume_db
		add_child(player)
		_player_pool.append(player)


func _load_sfx_from_directory() -> void:
	"""Lädt alle .ogg und .mp3 Dateien aus dem SFX-Verzeichnis."""
	var dir = DirAccess.open(sfx_directory)
	if not dir:
		push_warning("SFXManager: SFX directory not found at '%s'." % sfx_directory)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".ogg") or file_name.ends_with(".mp3")):
			var sound_name = file_name.get_basename().to_upper()
			# Prüfe, ob der Dateiname einem Enum-Wert entspricht
			if Sound.has(sound_name):
				var key = Sound.get(sound_name)
				_sound_library[key] = load(sfx_directory.path_join(file_name))
			else:
				push_warning("SFXManager: Found sound file '%s' but it has no corresponding enum in SFXManager.Sound." % file_name)
		file_name = dir.get_next()
	
	print("SFXManager: Loaded %d sounds from '%s'." % [_sound_library.size(), sfx_directory])


func play(sound_id: Sound) -> void:
	"""Spielt einen Sound aus der Bibliothek ab."""
	if not _sound_library.has(sound_id):
		push_warning("SFXManager: Sound with ID '%s' not found in library." % Sound.keys()[sound_id])
		return

	# Finde einen freien Player im Pool
	for player in _player_pool:
		if not player.is_playing():
			player.stream = _sound_library[sound_id]
			player.play()
			return
	
	# Wenn kein Player frei ist, wird der Sound nicht abgespielt (verhindert Audio-Spam)
	print("SFXManager: No available AudioStreamPlayer in the pool.")
