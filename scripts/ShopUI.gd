extends Control

# Shop UI - 3x3 Grid (Binding of Isaac style)
# Modernized with robust error handling and null-safety

@onready var shop_grid: GridContainer = $Panel/VBoxContainer/ShopGrid
@onready var shop_title: Label = $Panel/VBoxContainer/TitleLabel
@onready var scrap_label: Label = $Panel/VBoxContainer/ScrapLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

# Shop state
var current_shop_type: int = 0
var shop_items: Array = []


func _ready() -> void:
	# Validate all UI nodes
	if not shop_grid:
		push_error("[ShopUI] shop_grid node not found!")
		return
	if not shop_title:
		push_error("[ShopUI] shop_title node not found!")
		return
	if not scrap_label:
		push_error("[ShopUI] scrap_label node not found!")
		return
	if not close_button:
		push_error("[ShopUI] close_button node not found!")
		return

	# Validate ShopManager autoload
	if not is_instance_valid(ShopManager):
		push_error("[ShopUI] ShopManager autoload not found!")
		return

	# Validate GameManager autoload
	if not is_instance_valid(GameManager):
		push_error("[ShopUI] GameManager autoload not found!")
		return

	# Connect to ShopManager signals
	ShopManager.shop_opened.connect(_on_shop_opened)
	ShopManager.shop_closed.connect(_on_shop_closed)

	# Connect close button
	close_button.pressed.connect(_on_close_pressed)

	# Connect to GameManager for scrap updates
	GameManager.scrap_changed.connect(_update_scrap_display)

	# Hide initially
	hide()

	print("[ShopUI] Initialized successfully")


func _on_shop_opened(shop_type: int, items: Array) -> void:
	"""Called when shop opens"""
	if items.is_empty():
		push_warning("[ShopUI] Received empty items array!")
		return

	current_shop_type = shop_type
	shop_items = items

	# Set title based on shop type (with validation)
	if shop_title:
		match shop_type:
			0:  # WAVE_SHOP
				shop_title.text = "SUPPLY DROP"
			1:  # TERMINAL_SHOP
				shop_title.text = "PREMIUM VENDOR"
			2:  # DRONE_SHOP
				shop_title.text = "DRONE NETWORK SHOP"
			_:
				shop_title.text = "UNKNOWN SHOP"

	# Clear existing items (with validation)
	if shop_grid:
		for child in shop_grid.get_children():
			child.queue_free()

	# Create item cards
	for item_data in items:
		if item_data.has("item") and item_data.has("price"):
			_create_item_card(item_data["item"], item_data["price"])
		else:
			push_warning("[ShopUI] Invalid item_data structure: ", item_data)

	# Update scrap display (with validation)
	if is_instance_valid(GameManager):
		_update_scrap_display(GameManager.scrap)

	show()
	get_tree().paused = true


func _on_shop_closed() -> void:
	"""Called when shop closes"""
	hide()
	get_tree().paused = false


func _on_close_pressed() -> void:
	"""Close button pressed"""
	if is_instance_valid(ShopManager):
		ShopManager.close_shop()
	else:
		push_error("[ShopUI] ShopManager not available for close_shop()")


func _create_item_card(item, price: int) -> void:
	"""Create an item card in the grid"""
	if not shop_grid:
		push_error("[ShopUI] shop_grid not available for item card creation")
		return

	# Create container
	var card = Panel.new()
	card.custom_minimum_size = Vector2(150, 180)

	var vbox = VBoxContainer.new()
	card.add_child(vbox)

	# Item icon (colored rect for now)
	var icon = ColorRect.new()
	icon.color = item.icon_color if item.get("icon_color") else Color.WHITE
	icon.custom_minimum_size = Vector2(80, 80)
	vbox.add_child(icon)

	# Item name
	var name_label = Label.new()
	name_label.text = item.name if item.get("name") else "Unknown Item"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)

	# Item price
	var price_label = Label.new()
	price_label.text = str(price) + " Scrap"
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(price_label)

	# Buy button
	var buy_button = Button.new()
	buy_button.text = "BUY"
	buy_button.custom_minimum_size = Vector2(100, 30)

	# Connect purchase
	buy_button.pressed.connect(func():
		_purchase_item(item, price, card)
	)

	vbox.add_child(buy_button)

	shop_grid.add_child(card)


func _purchase_item(item, price: int, card: Panel) -> void:
	"""Attempt to purchase an item"""
	# Validate ShopManager
	if not is_instance_valid(ShopManager):
		push_error("[ShopUI] ShopManager not available for purchase")
		return

	if ShopManager.purchase_item(item, price):
		# Apply item to player
		var game = get_tree().get_first_node_in_group("game")
		if game and game.has_method("apply_item_effects"):
			game.apply_item_effects(item)
		else:
			push_warning("[ShopUI] Game scene not found or apply_item_effects() missing")

		# Disable card (sold out)
		card.modulate = Color(0.5, 0.5, 0.5, 0.7)
		for child in card.get_children():
			if child is VBoxContainer:
				for button in child.get_children():
					if button is Button:
						button.disabled = true
						button.text = "SOLD"
	else:
		# Not enough scrap - flash red
		card.modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(card):
			card.modulate = Color.WHITE


func _update_scrap_display(new_scrap: int) -> void:
	"""Update scrap display"""
	if scrap_label:
		scrap_label.text = "Scrap: " + str(new_scrap)


func _input(event: InputEvent) -> void:
	"""Handle input"""
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close_pressed()
