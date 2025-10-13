extends Control


func _ready() -> void:
	# Connect button signals
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/CharacterSelectButton.pressed.connect(_on_character_select_pressed)
	$VBoxContainer/MetaUpgradesButton.pressed.connect(_on_meta_upgrades_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


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


func _on_quit_pressed() -> void:
	"""Quit the application"""
	get_tree().quit()
