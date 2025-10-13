extends Control

# UI References
@onready var scrap_label = $VBoxContainer/Header/ScrapLabel
@onready var upgrades_grid = $VBoxContainer/ScrollContainer/UpgradesGrid
@onready var back_button = $VBoxContainer/BackButton


func _ready() -> void:
	# Update scrap display
	_update_scrap_label()

	# Populate upgrades
	_populate_upgrades()

	# Connect back button
	back_button.pressed.connect(_on_back_pressed)


func _update_scrap_label() -> void:
	"""Update scrap amount display"""
	scrap_label.text = "Scrap: " + str(SaveManager.get_scrap())


func _populate_upgrades() -> void:
	"""Create upgrade buttons"""
	# Clear existing children
	for child in upgrades_grid.get_children():
		child.queue_free()

	# Create upgrade cards
	for upgrade_id in MetaProgression.upgrades:
		_create_upgrade_card(upgrade_id)


func _create_upgrade_card(upgrade_id: String) -> void:
	"""Create an upgrade card UI element"""
	var upgrade_data = MetaProgression.upgrades[upgrade_id]
	var current_level = SaveManager.get_upgrade_level(upgrade_id)
	var cost = MetaProgression.get_upgrade_cost(upgrade_id)

	# Container
	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(300, 150)

	# Background
	var bg = ColorRect.new()
	bg.custom_minimum_size = Vector2(300, 150)
	bg.color = Color(0.2, 0.2, 0.25, 1.0)
	card.add_child(bg)

	# Name
	var name_label = Label.new()
	name_label.text = upgrade_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = upgrade_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(desc_label)

	# Level
	var level_label = Label.new()
	level_label.text = "Level: " + str(current_level) + " / " + str(upgrade_data.max_level)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(level_label)

	# Purchase button
	var buy_button = Button.new()

	if cost < 0:
		buy_button.text = "MAX LEVEL"
		buy_button.disabled = true
	else:
		buy_button.text = "Purchase (" + str(cost) + " Scrap)"
		buy_button.disabled = not MetaProgression.can_purchase_upgrade(upgrade_id)

	buy_button.pressed.connect(_on_upgrade_purchased.bind(upgrade_id))
	card.add_child(buy_button)

	upgrades_grid.add_child(card)


func _on_upgrade_purchased(upgrade_id: String) -> void:
	"""Handle upgrade purchase"""
	if MetaProgression.purchase_upgrade(upgrade_id):
		print("Upgrade purchased: ", upgrade_id)
		_update_scrap_label()
		_populate_upgrades()  # Refresh UI
	else:
		print("Cannot purchase upgrade")


func _on_back_pressed() -> void:
	"""Return to main menu"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
