extends Control

# Settings Menu - Volume controls with persistent storage

# UI references
var master_slider: HSlider
var sfx_slider: HSlider
var music_slider: HSlider

var master_label: Label
var sfx_label: Label
var music_label: Label

var language_option: OptionButton
var fullscreen_check: CheckButton
var vsync_check: CheckButton

# Language mappings
const LANGUAGE_NAMES = {
	"en": "English",
	"de": "Deutsch",
	"es": "Español"
}

const LANGUAGE_CODES = ["en", "de", "es"]


func _ready() -> void:
	# Get UI references
	master_slider = $VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
	sfx_slider = $VBoxContainer/SFXVolumeContainer/SFXVolumeSlider
	music_slider = $VBoxContainer/MusicVolumeContainer/MusicVolumeSlider

	master_label = $VBoxContainer/MasterVolumeContainer/MasterVolumeLabel
	sfx_label = $VBoxContainer/SFXVolumeContainer/SFXVolumeLabel
	music_label = $VBoxContainer/MusicVolumeContainer/MusicVolumeLabel
	
	language_option = $VBoxContainer/LanguageContainer/LanguageOption
	fullscreen_check = $VBoxContainer/VideoContainer/FullscreenCheck
	vsync_check = $VBoxContainer/VideoContainer/VSyncCheck
	
	# Update UI with translations
	_update_translations()
	
	# Setup language dropdown
	_setup_language_dropdown()
	
	# Load settings from SettingsManager
	_load_settings()
	
	# Set initial focus
	master_slider.grab_focus()


func _update_translations() -> void:
	"""Update all UI text with current translations"""
	$VBoxContainer/Title.text = tr("SETTINGS_TITLE")
	$VBoxContainer/LanguageContainer/LanguageLabel.text = tr("SETTINGS_LANGUAGE")
	fullscreen_check.text = tr("SETTINGS_FULLSCREEN")
	vsync_check.text = tr("SETTINGS_VSYNC")
	$VBoxContainer/BackButton.text = tr("SETTINGS_BACK")


func _setup_language_dropdown() -> void:
	"""Setup language dropdown with available languages"""
	language_option.clear()
	
	for code in LANGUAGE_CODES:
		language_option.add_item(LANGUAGE_NAMES[code])
	
	# Select current language
	var current_lang = LanguageManager.get_current_language()
	var index = LANGUAGE_CODES.find(current_lang)
	if index >= 0:
		language_option.selected = index


func _load_settings() -> void:
	"""Load settings from SettingsManager"""
	if SettingsManager:
		# Load volume settings
		master_slider.value = SettingsManager.master_volume
		sfx_slider.value = SettingsManager.sfx_volume
		music_slider.value = SettingsManager.music_volume
		
		# Load video settings
		fullscreen_check.button_pressed = SettingsManager.fullscreen
		vsync_check.button_pressed = SettingsManager.vsync
		
		# Update labels
		_update_labels()


func _update_labels() -> void:
	"""Update volume percentage labels"""
	master_label.text = tr("SETTINGS_MASTER_VOLUME") + ": %d%%" % int(master_slider.value)
	sfx_label.text = tr("SETTINGS_SFX_VOLUME") + ": %d%%" % int(sfx_slider.value)
	music_label.text = tr("SETTINGS_MUSIC_VOLUME") + ": %d%%" % int(music_slider.value)


func _on_master_volume_changed(value: float) -> void:
	"""Master volume slider changed"""
	if SettingsManager:
		SettingsManager.set_master_volume(int(value))
	_update_labels()


func _on_sfx_volume_changed(value: float) -> void:
	"""SFX volume slider changed"""
	if SettingsManager:
		SettingsManager.set_sfx_volume(int(value))
	_update_labels()
	
	# Play test sound
	if AudioManager:
		AudioManager.play_item_pickup_sound()


func _on_music_volume_changed(value: float) -> void:
	"""Music volume slider changed"""
	if SettingsManager:
		SettingsManager.set_music_volume(int(value))
	_update_labels()


func _on_language_selected(index: int) -> void:
	"""Language dropdown changed"""
	if index >= 0 and index < LANGUAGE_CODES.size():
		var new_language = LANGUAGE_CODES[index]
		if SettingsManager:
			SettingsManager.set_language(new_language)
		# Update all UI text
		_update_translations()
		_update_labels()


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	"""Fullscreen checkbox toggled"""
	if SettingsManager:
		SettingsManager.set_fullscreen(toggled_on)


func _on_vsync_toggled(toggled_on: bool) -> void:
	"""VSync checkbox toggled"""
	if SettingsManager:
		SettingsManager.set_vsync(toggled_on)


func _on_back_pressed() -> void:
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _input(event: InputEvent) -> void:
	"""Handle keyboard input for navigation"""
	if event.is_action_pressed("ui_cancel"):  # Escape key
		_on_back_pressed()
