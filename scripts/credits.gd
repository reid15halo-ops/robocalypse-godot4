extends Control
## Credits screen - Shows game credits and attribution

func _ready() -> void:
	# Update text with translations
	$MarginContainer/VBoxContainer/Title.text = tr("CREDITS_TITLE")
	$MarginContainer/VBoxContainer/BackButton.text = tr("CREDITS_BACK")
	
	# Build credits text with translations
	var credits_text = "[center][font_size=24][b]" + tr("CREDITS_TITLE") + "[/b][/font_size]\n\n"
	credits_text += "[font_size=18][b]" + tr("CREDITS_DEVELOPMENT") + "[/b][/font_size]\n"
	credits_text += "reid15halo-ops\n\n"
	credits_text += "[font_size=18][b]" + tr("CREDITS_ART") + "[/b][/font_size]\n"
	credits_text += "OpenGameArt.org\nKenney.nl\n\n"
	credits_text += "[font_size=18][b]" + tr("CREDITS_MUSIC") + "[/b][/font_size]\n"
	credits_text += "Freesound.org\n\n"
	credits_text += "[font_size=18][b]" + tr("CREDITS_SFX") + "[/b][/font_size]\n"
	credits_text += "Freesound.org\nVarious meme sounds\n\n"
	credits_text += "[font_size=18][b]" + tr("CREDITS_ENGINE") + "[/b][/font_size]\n"
	credits_text += "Godot 4.5\n\n"
	credits_text += "[font_size=18][b]" + tr("CREDITS_THANKS") + "[/b][/font_size]\n"
	credits_text += tr("CREDITS_COMMUNITY") + "\nGitHub Copilot\nAll playtesters and contributors[/center]"
	
	$MarginContainer/VBoxContainer/ScrollContainer/CreditsText.text = credits_text


func _on_back_pressed() -> void:
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _input(event: InputEvent) -> void:
	"""Handle keyboard input for navigation"""
	if event.is_action_pressed("ui_cancel"):  # Escape key
		_on_back_pressed()
