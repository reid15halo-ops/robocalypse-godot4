extends Node
## SettingsManager - Centralized settings persistence and management
## Handles audio, video, and language settings

const CONFIG_PATH := "user://settings.cfg"

# Audio settings (0-100 range for UI)
var master_volume: int = 80
var music_volume: int = 70
var sfx_volume: int = 80

# Video settings
var fullscreen: bool = false
var vsync: bool = true

# Language setting (handled by LanguageManager, but we store it here too)
var language: String = "en"

# Signals for UI updates
signal settings_changed()
signal volume_changed(master: float, music: float, sfx: float)
signal video_changed(fullscreen_enabled: bool, vsync_enabled: bool)
signal language_changed(new_language: String)


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	"""Load all settings from config file"""
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	
	if err == OK:
		# Load audio settings
		master_volume = config.get_value("audio", "master_volume", 80)
		music_volume = config.get_value("audio", "music_volume", 70)
		sfx_volume = config.get_value("audio", "sfx_volume", 80)
		
		# Load video settings
		fullscreen = config.get_value("video", "fullscreen", false)
		vsync = config.get_value("video", "vsync", true)
		
		# Load language setting
		language = config.get_value("locale", "language", "en")
		
		print("Settings loaded successfully")
	else:
		print("No settings file found, using defaults")


func save_settings() -> void:
	"""Save all settings to config file"""
	var config := ConfigFile.new()
	
	# Save audio settings
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# Save video settings
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync", vsync)
	
	# Save language
	config.set_value("locale", "language", language)
	
	var err := config.save(CONFIG_PATH)
	if err == OK:
		print("Settings saved successfully")
	else:
		push_error("Failed to save settings: " + str(err))


func apply_settings() -> void:
	"""Apply all settings to their respective systems"""
	apply_audio_settings()
	apply_video_settings()
	# Language is applied by LanguageManager


func apply_audio_settings() -> void:
	"""Apply audio settings to AudioManager and MusicManager"""
	if AudioManager:
		AudioManager.set_master_volume(master_volume / 100.0)
		AudioManager.set_sfx_volume(sfx_volume / 100.0)
	
	if MusicManager:
		MusicManager.set_volume_linear(music_volume / 100.0)
	
	volume_changed.emit(master_volume / 100.0, music_volume / 100.0, sfx_volume / 100.0)


func apply_video_settings() -> void:
	"""Apply video settings to DisplayServer"""
	# Apply fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Apply VSync
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	video_changed.emit(fullscreen, vsync)


func set_master_volume(value: int) -> void:
	"""Set master volume (0-100)"""
	master_volume = clamp(value, 0, 100)
	if AudioManager:
		AudioManager.set_master_volume(master_volume / 100.0)
	save_settings()
	volume_changed.emit(master_volume / 100.0, music_volume / 100.0, sfx_volume / 100.0)


func set_music_volume(value: int) -> void:
	"""Set music volume (0-100)"""
	music_volume = clamp(value, 0, 100)
	if MusicManager:
		MusicManager.set_volume_linear(music_volume / 100.0)
	save_settings()
	volume_changed.emit(master_volume / 100.0, music_volume / 100.0, sfx_volume / 100.0)


func set_sfx_volume(value: int) -> void:
	"""Set SFX volume (0-100)"""
	sfx_volume = clamp(value, 0, 100)
	if AudioManager:
		AudioManager.set_sfx_volume(sfx_volume / 100.0)
	save_settings()
	volume_changed.emit(master_volume / 100.0, music_volume / 100.0, sfx_volume / 100.0)


func set_fullscreen(enabled: bool) -> void:
	"""Toggle fullscreen mode"""
	fullscreen = enabled
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()
	video_changed.emit(fullscreen, vsync)


func set_vsync(enabled: bool) -> void:
	"""Toggle VSync"""
	vsync = enabled
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	save_settings()
	video_changed.emit(fullscreen, vsync)


func set_language(locale: String) -> void:
	"""Set language and persist"""
	language = locale
	if LanguageManager:
		LanguageManager.set_language(locale)
	save_settings()
	language_changed.emit(locale)
