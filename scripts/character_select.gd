extends Control

@onready var characters_container = $VBoxContainer/ScrollContainer/CharactersGrid
@onready var selected_label = $VBoxContainer/SelectedLabel
@onready var start_button = $VBoxContainer/ButtonsContainer/StartButton
@onready var back_button = $VBoxContainer/ButtonsContainer/BackButton


func _ready() -> void:
	# Create character cards
	_create_character_cards()

	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Update selected label
	_update_selected_label()


func _create_character_cards() -> void:
	"""Create UI cards for all characters"""
	# Clear existing
	for child in characters_container.get_children():
		child.queue_free()

	# Get all characters
	var all_chars = ["hacker", "technician", "soldier"]

	for char_id in all_chars:
		var char_data = CharacterSystem.get_character(char_id)
		var is_unlocked = CharacterSystem.is_character_unlocked(char_id)
		var is_selected = CharacterSystem.current_character == char_id

		var card = _create_character_card(char_id, char_data, is_unlocked, is_selected)
		characters_container.add_child(card)


func _create_character_card(char_id: String, char_data: Dictionary, is_unlocked: bool, is_selected: bool) -> Control:
	"""Create a single character card"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 250)

	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	# Character icon (color)
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(280, 100)
	icon.color = char_data.icon_color if is_unlocked else Color(0.3, 0.3, 0.3)
	vbox.add_child(icon)

	# Character name
	var name_label = Label.new()
	name_label.text = char_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)

	# Character description
	var desc_label = Label.new()
	desc_label.text = char_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(280, 0)
	vbox.add_child(desc_label)

	# Stats display
	var stats = char_data.stats
	var stats_text = "HP: %d | Speed: %.0f | Damage: %d" % [stats.max_hp, stats.speed, stats.melee_damage]
	var stats_label = Label.new()
	stats_label.text = stats_text
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(stats_label)

	# Button
	var button = Button.new()

	if is_selected:
		button.text = "SELECTED"
		button.disabled = true
	elif is_unlocked:
		button.text = "SELECT"
		button.pressed.connect(_on_character_selected.bind(char_id))
	else:
		var cost = char_data.get("cost", 0)
		button.text = "UNLOCK (" + str(cost) + " Scrap)"
		button.pressed.connect(_on_character_unlock.bind(char_id, cost))

	vbox.add_child(button)

	return card


func _on_character_selected(char_id: String) -> void:
	"""Handle character selection"""
	if CharacterSystem.select_character(char_id):
		print("Selected: ", char_id)
		_update_selected_label()
		# Recreate cards to update selection
		_create_character_cards()


func _on_character_unlock(char_id: String, cost: int) -> void:
	"""Handle character unlock purchase"""
	var current_scrap = SaveManager.get_scrap()

	if current_scrap < cost:
		print("Not enough scrap! Need ", cost, " but have ", current_scrap)
		return

	if SaveManager.spend_scrap(cost):
		SaveManager.unlock_character(char_id)
		print("Unlocked character: ", char_id)
		# Recreate cards
		_create_character_cards()


func _update_selected_label() -> void:
	"""Update the selected character label"""
	var char_data = CharacterSystem.get_current_character()
	selected_label.text = "Selected: " + char_data.name


func _on_start_pressed() -> void:
	"""Start game with selected character"""
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_back_pressed() -> void:
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
