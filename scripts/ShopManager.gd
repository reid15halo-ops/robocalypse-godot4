extends Node

# Shop Manager - Modernized with robust error handling and null-safety
# Manages all shop types with proper dependency validation

# Shop Types
enum ShopType {
	WAVE_SHOP,      # Between waves, cheap items, basic pool
	TERMINAL_SHOP,  # Random map spawns, expensive items, better pool
	DRONE_SHOP      # Hacker ability (every 3 waves), best items, normal prices
}

# Shop type modifiers
const SHOP_PRICE_MODIFIERS = {
	ShopType.WAVE_SHOP: 0.7,      # 30% discount
	ShopType.TERMINAL_SHOP: 1.5,  # 50% markup
	ShopType.DRONE_SHOP: 1.0      # Normal prices
}

# Shop type item counts
const SHOP_ITEM_COUNTS = {
	ShopType.WAVE_SHOP: 6,        # 6 items (2 rows)
	ShopType.TERMINAL_SHOP: 9,    # 9 items (full grid)
	ShopType.DRONE_SHOP: 9        # 9 items (full grid)
}

# Signals
signal shop_opened(shop_type: ShopType, items: Array)
signal shop_closed
signal item_purchased(item_data, price: int)


func open_shop(shop_type: ShopType) -> void:
	"""Open a shop of the specified type"""
	# Validate ItemDatabase availability
	if not is_instance_valid(ItemDatabase):
		push_error("[ShopManager] ItemDatabase autoload not found! Cannot open shop.")
		return

	var available_items = _get_shop_items(shop_type)
	var item_count = SHOP_ITEM_COUNTS[shop_type]

	# Validate we have items
	if available_items.is_empty():
		push_error("[ShopManager] No items available for shop type: ", ShopType.keys()[shop_type])
		return

	# Select random items from pool
	var shop_items: Array = []
	var pool = available_items.duplicate()

	for i in range(min(item_count, pool.size())):
		if pool.is_empty():
			push_warning("[ShopManager] Item pool exhausted early for ", ShopType.keys()[shop_type])
			break

		var random_index = randi() % pool.size()
		var item = pool[random_index]
		pool.remove_at(random_index)

		# Calculate shop price
		var price_modifier = SHOP_PRICE_MODIFIERS[shop_type]
		var price = item.get_shop_price(price_modifier)

		shop_items.append({
			"item": item,
			"price": price
		})

	# Validate we got at least 1 item
	if shop_items.is_empty():
		push_error("[ShopManager] Failed to generate shop items!")
		return

	shop_opened.emit(shop_type, shop_items)
	print("[ShopManager] Shop opened: ", ShopType.keys()[shop_type], " with ", shop_items.size(), " items")


func close_shop() -> void:
	"""Close the current shop"""
	shop_closed.emit()
	print("[ShopManager] Shop closed")


func purchase_item(item_data, price: int) -> bool:
	"""Attempt to purchase an item with scrap"""
	# Validate GameManager
	if not is_instance_valid(GameManager):
		push_error("[ShopManager] GameManager autoload not found!")
		return false

	# Check if player has enough scrap
	if GameManager.scrap < price:
		print("[ShopManager] Not enough scrap! Need ", price, ", have ", GameManager.scrap)
		return false

	# Spend scrap
	if GameManager.spend_scrap(price):
		item_purchased.emit(item_data, price)
		print("[ShopManager] Purchased ", item_data.name, " for ", price, " scrap")
		return true

	return false


func _get_shop_items(shop_type: ShopType) -> Array:
	"""Get available items for a shop type"""
	# Validate ItemDatabase
	if not is_instance_valid(ItemDatabase):
		push_error("[ShopManager] ItemDatabase not available in _get_shop_items")
		return []

	if not ItemDatabase.get("items"):
		push_error("[ShopManager] ItemDatabase.items not initialized!")
		return []

	var available_items: Array = []

	match shop_type:
		ShopType.WAVE_SHOP:
			# Basic items: COMMON + some RARE defensive/stat items
			for item in ItemDatabase.items:
				if item.rarity == ItemDatabase.ItemRarity.COMMON:
					available_items.append(item)
				elif item.rarity == ItemDatabase.ItemRarity.RARE and \
					 (item.type == ItemDatabase.ItemType.DEFENSIVE or \
					  item.type == ItemDatabase.ItemType.STAT):
					available_items.append(item)

			# Always include healing
			available_items.append_array(_get_healing_items())

		ShopType.TERMINAL_SHOP:
			# Better items: All RARE + EPIC items (no COMMON)
			for item in ItemDatabase.items:
				if item.rarity == ItemDatabase.ItemRarity.RARE or \
				   item.rarity == ItemDatabase.ItemRarity.EPIC:
					available_items.append(item)

			# Some healing (expensive)
			available_items.append_array(_get_healing_items())

		ShopType.DRONE_SHOP:
			# Best items: Prioritize EPIC, some RARE, weapon upgrades
			for item in ItemDatabase.items:
				if item.rarity == ItemDatabase.ItemRarity.EPIC:
					available_items.append(item)
				elif item.rarity == ItemDatabase.ItemRarity.RARE and \
					 (item.type == ItemDatabase.ItemType.WEAPON_UPGRADE or \
					  item.type == ItemDatabase.ItemType.ABILITY):
					available_items.append(item)

			# Healing + resources
			available_items.append_array(_get_healing_items())

	return available_items


func _get_healing_items() -> Array:
	"""Create temporary healing/resource items"""
	# Validate ItemDatabase and ItemData class
	if not is_instance_valid(ItemDatabase):
		push_warning("[ShopManager] ItemDatabase not available for healing items")
		return []

	if not ItemDatabase.get("ItemData"):
		push_error("[ShopManager] ItemDatabase.ItemData class not found!")
		return []

	var healing_items: Array = []

	# Create temporary ItemData for healing/resources
	var heal_small = ItemDatabase.ItemData.new(
		"heal_small",
		"Repair Kit (Small)",
		"Restore 30 HP",
		ItemDatabase.ItemType.SUPPORT,
		ItemDatabase.ItemRarity.COMMON,
		Color(0.2, 1.0, 0.2),
		{"heal": 30}
	)
	heal_small.base_price = 30

	var heal_large = ItemDatabase.ItemData.new(
		"heal_large",
		"Repair Kit (Large)",
		"Restore 60 HP",
		ItemDatabase.ItemType.SUPPORT,
		ItemDatabase.ItemRarity.RARE,
		Color(0.0, 1.0, 0.0),
		{"heal": 60}
	)
	heal_large.base_price = 50

	var shield_refill = ItemDatabase.ItemData.new(
		"shield_refill",
		"Shield Generator",
		"Restore 50 Shield",
		ItemDatabase.ItemType.DEFENSIVE,
		ItemDatabase.ItemRarity.COMMON,
		Color(0.2, 0.5, 1.0),
		{"shield": 50}
	)
	shield_refill.base_price = 40

	healing_items.append(heal_small)
	healing_items.append(heal_large)
	healing_items.append(shield_refill)

	return healing_items
