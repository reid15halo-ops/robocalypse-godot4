extends Node
## LanguageManager - Handles runtime language switching and persistence
## Autoload singleton for managing TranslationServer locale

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "locale"
const KEY := "language"

## Available languages
const LANGUAGES := ["en", "de", "es"]

func _ready() -> void:
	_load_saved_language()

func _load_saved_language() -> void:
	"""Load saved language preference from config file"""
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)
	
	if err == OK and config.has_section_key(SECTION, KEY):
		var saved_locale := config.get_value(SECTION, KEY) as String
		TranslationServer.set_locale(saved_locale)
		print("Loaded saved language: ", saved_locale)
	else:
		# Use default locale from project settings or fallback to English
		var default_locale := "en"
		if ProjectSettings.has_setting("internationalization/locale/locale"):
			default_locale = ProjectSettings.get_setting("internationalization/locale/locale")
		TranslationServer.set_locale(default_locale)
		print("Using default language: ", default_locale)

func set_language(locale: String) -> void:
	"""Set the current language and persist to config file"""
	if not locale in LANGUAGES:
		push_error("Invalid locale: " + locale)
		return
	
	TranslationServer.set_locale(locale)
	print("Language changed to: ", locale)
	
	# Save to config
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)  # Load existing config if it exists
	config.set_value(SECTION, KEY, locale)
	var err := config.save(CONFIG_PATH)
	
	if err != OK:
		push_error("Failed to save language preference: " + str(err))

func get_current_language() -> String:
	"""Get the current active language"""
	return TranslationServer.get_locale()

func cycle_language() -> void:
	"""Cycle to the next available language (for debug/testing)"""
	var current := get_current_language()
	var current_index := LANGUAGES.find(current)
	var next_index := (current_index + 1) % LANGUAGES.size()
	set_language(LANGUAGES[next_index])
