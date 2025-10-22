extends Control


func _ready() -> void:
	# Update UI with translations
	$VBoxContainer/Title.text = tr("MENU_TITLE")
	$VBoxContainer/StartButton.text = tr("MENU_PLAY")
	$VBoxContainer/CharacterSelectButton.text = tr("MENU_CHARACTER_SELECT")
	$VBoxContainer/MetaUpgradesButton.text = tr("MENU_META_UPGRADES")
	$VBoxContainer/SettingsButton.text = tr("MENU_SETTINGS")
	$VBoxContainer/CreditsButton.text = tr("MENU_CREDITS")
	$VBoxContainer/QuitButton.text = tr("MENU_QUIT")
	
	# Connect button signals
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/CharacterSelectButton.pressed.connect(_on_character_select_pressed)
	$VBoxContainer/MetaUpgradesButton.pressed.connect(_on_meta_upgrades_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Set initial focus
	$VBoxContainer/StartButton.grab_focus()


func _input(event: InputEvent) -> void:
	"""Handle keyboard input for navigation"""
	if event.is_action_pressed("ui_cancel"):  # Escape key
		_on_quit_pressed()


func _on_start_pressed() -> void:
	"""Start the game"""
	# Reset game state
	GameManager.reset_game()

	# Load game scene
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_character_select_pressed() -> void:
	"""Open character selection screen"""
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")


func _on_meta_upgrades_pressed() -> void:
	"""Open meta upgrades shop"""
	get_tree().change_scene_to_file("res://scenes/MetaUpgradeShop.tscn")


func _on_settings_pressed() -> void:
	"""Open settings menu"""
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_credits_pressed() -> void:
	"""Open credits screen"""
	get_tree().change_scene_to_file("res://scenes/Credits.tscn")


func _on_quit_pressed() -> void:
	"""Quit the application"""
	get_tree().quit()
