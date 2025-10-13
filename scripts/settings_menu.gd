extends PanelContainer

# Settings Menu - Volume controls and meme sounds toggle

# Volume sliders
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider

# Meme sounds toggle
var meme_toggle: CheckButton

# Labels
var master_label: Label
var music_label: Label
var sfx_label: Label

# Signals
signal settings_changed()


func _ready() -> void:
	# Setup panel
	custom_minimum_size = Vector2(400, 350)
	position = Vector2(440, 185)  # Center of screen
	visible = false

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.5, 0.5, 0.5)
	add_theme_stylebox_override("panel", style)

	# Create UI
	_create_ui()

	# Load saved settings
	_load_settings()


func _create_ui() -> void:
	"""Create settings UI elements"""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)

	# Master Volume
	master_label = Label.new()
	master_label.text = "Master Volume: 100%"
	master_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(master_label)

	master_slider = HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.step = 1
	master_slider.value = 100
	master_slider.custom_minimum_size = Vector2(360, 20)
	master_slider.value_changed.connect(_on_master_volume_changed)
	vbox.add_child(master_slider)

	# Music Volume
	music_label = Label.new()
	music_label.text = "Music Volume: 100%"
	music_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(music_label)

	music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.value = 100
	music_slider.custom_minimum_size = Vector2(360, 20)
	music_slider.value_changed.connect(_on_music_volume_changed)
	vbox.add_child(music_slider)

	# SFX Volume
	sfx_label = Label.new()
	sfx_label.text = "SFX Volume: 100%"
	sfx_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(sfx_label)

	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	sfx_slider.value = 100
	sfx_slider.custom_minimum_size = Vector2(360, 20)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	vbox.add_child(sfx_slider)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)

	# Meme Sounds Toggle
	var meme_hbox = HBoxContainer.new()
	vbox.add_child(meme_hbox)

	var meme_label = Label.new()
	meme_label.text = "Meme Sounds:"
	meme_label.add_theme_font_size_override("font_size", 16)
	meme_hbox.add_child(meme_label)

	meme_toggle = CheckButton.new()
	meme_toggle.button_pressed = true
	meme_toggle.text = "Enabled"
	meme_toggle.toggled.connect(_on_meme_sounds_toggled)
	meme_hbox.add_child(meme_toggle)

	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)

	# Close button
	var close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(200, 40)
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)


func _on_master_volume_changed(value: float) -> void:
	"""Handle master volume change"""
	var volume = value / 100.0
	AudioManager.set_master_volume(volume)
	master_label.text = "Master Volume: " + str(int(value)) + "%"
	_save_settings()


func _on_music_volume_changed(value: float) -> void:
	"""Handle music volume change"""
	var volume = value / 100.0
	MusicManager.set_music_volume(volume)
	music_label.text = "Music Volume: " + str(int(value)) + "%"
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	"""Handle SFX volume change"""
	var volume = value / 100.0
	AudioManager.set_sfx_volume(volume)
	sfx_label.text = "SFX Volume: " + str(int(value)) + "%"
	_save_settings()


func _on_meme_sounds_toggled(enabled: bool) -> void:
	"""Handle meme sounds toggle"""
	AudioManager.set_meme_sounds_enabled(enabled)
	meme_toggle.text = "Enabled" if enabled else "Disabled"
	_save_settings()


func _on_close_pressed() -> void:
	"""Close settings menu"""
	visible = false
	settings_changed.emit()


func _save_settings() -> void:
	"""Save settings to SaveManager"""
	var settings = {
		"master_volume": master_slider.value / 100.0,
		"music_volume": music_slider.value / 100.0,
		"sfx_volume": sfx_slider.value / 100.0,
		"meme_sounds_enabled": meme_toggle.button_pressed
	}

	SaveManager.save_settings(settings)


func _load_settings() -> void:
	"""Load settings from SaveManager"""
	var settings = SaveManager.load_settings()

	if settings.has("master_volume"):
		master_slider.value = settings.master_volume * 100
		AudioManager.set_master_volume(settings.master_volume)
		master_label.text = "Master Volume: " + str(int(settings.master_volume * 100)) + "%"

	if settings.has("music_volume"):
		music_slider.value = settings.music_volume * 100
		MusicManager.set_music_volume(settings.music_volume)
		music_label.text = "Music Volume: " + str(int(settings.music_volume * 100)) + "%"

	if settings.has("sfx_volume"):
		sfx_slider.value = settings.sfx_volume * 100
		AudioManager.set_sfx_volume(settings.sfx_volume)
		sfx_label.text = "SFX Volume: " + str(int(settings.sfx_volume * 100)) + "%"

	if settings.has("meme_sounds_enabled"):
		meme_toggle.button_pressed = settings.meme_sounds_enabled
		AudioManager.set_meme_sounds_enabled(settings.meme_sounds_enabled)
		meme_toggle.text = "Enabled" if settings.meme_sounds_enabled else "Disabled"


func show_settings() -> void:
	"""Show settings menu"""
	visible = true
	_load_settings()  # Refresh values
