extends Control

# Settings Menu - Volume controls with persistent storage

# UI references
var master_slider: HSlider
var sfx_slider: HSlider
var music_slider: HSlider

var master_label: Label
var sfx_label: Label
var music_label: Label

# Settings file path
const SETTINGS_FILE = "user://settings.cfg"


func _ready() -> void:
	# Get UI references
	master_slider = $VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
	sfx_slider = $VBoxContainer/SFXVolumeContainer/SFXVolumeSlider
	music_slider = $VBoxContainer/MusicVolumeContainer/MusicVolumeSlider

	master_label = $VBoxContainer/MasterVolumeContainer/MasterVolumeLabel
	sfx_label = $VBoxContainer/SFXVolumeContainer/SFXVolumeLabel
	music_label = $VBoxContainer/MusicVolumeContainer/MusicVolumeLabel

	# Load saved settings
	_load_settings()


func _load_settings() -> void:
	"""Load settings from file"""
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)

	if err == OK:
		# Load volume settings (0-100 range)
		var master_vol = config.get_value("audio", "master_volume", 100)
		var sfx_vol = config.get_value("audio", "sfx_volume", 100)
		var music_vol = config.get_value("audio", "music_volume", 100)

		# Apply to sliders
		master_slider.value = master_vol
		sfx_slider.value = sfx_vol
		music_slider.value = music_vol

		# Apply to audio managers
		AudioManager.set_master_volume(master_vol / 100.0)
		AudioManager.set_sfx_volume(sfx_vol / 100.0)

		if MusicManager:
			MusicManager.set_music_volume(music_vol / 100.0)

		# Update labels
		_update_labels()
	else:
		# First time - use defaults (already set in scene)
		_update_labels()


func _save_settings() -> void:
	"""Save settings to file"""
	var config = ConfigFile.new()

	# Save volume settings
	config.set_value("audio", "master_volume", int(master_slider.value))
	config.set_value("audio", "sfx_volume", int(sfx_slider.value))
	config.set_value("audio", "music_volume", int(music_slider.value))

	# Save to file
	config.save(SETTINGS_FILE)


func _update_labels() -> void:
	"""Update volume percentage labels"""
	master_label.text = "Master Volume: %d%%" % int(master_slider.value)
	sfx_label.text = "SFX Volume: %d%%" % int(sfx_slider.value)
	music_label.text = "Music Volume: %d%%" % int(music_slider.value)


func _on_master_volume_changed(value: float) -> void:
	"""Master volume slider changed"""
	AudioManager.set_master_volume(value / 100.0)
	_update_labels()
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	"""SFX volume slider changed"""
	AudioManager.set_sfx_volume(value / 100.0)
	_update_labels()
	_save_settings()

	# Play test sound
	AudioManager.play_item_pickup_sound()


func _on_music_volume_changed(value: float) -> void:
	"""Music volume slider changed"""
	if MusicManager:
		MusicManager.set_music_volume(value / 100.0)
	_update_labels()
	_save_settings()


func _on_back_pressed() -> void:
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
