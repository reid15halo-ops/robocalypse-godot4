extends Node

# In-Game Shop - Allows players to spend scrap during waves
# Autoload singleton for shop management

# Shop configuration
var shop_visit_cost: int = 0  # Free to visit
var reroll_cost: int = 30  # Cost to reroll shop

# Current shop inventory
var current_shop_items: Array = []

# Pricing based on rarity
var price_by_rarity: Dictionary = {
	ItemDatabase.ItemRarity.COMMON: 25,
	ItemDatabase.ItemRarity.RARE: 50,
	ItemDatabase.ItemRarity.EPIC: 100
}


func generate_shop_inventory(count: int = 5, player = null) -> Array:
	"""Generate random shop inventory with upgrade awareness"""
	current_shop_items.clear()

	var available_items = ItemDatabase.items.duplicate()
	available_items.shuffle()

	# Select items
	for i in range(min(count, available_items.size())):
		var item = available_items[i]

		# Check if player already owns this item and get level
		var current_level = 0
		var can_upgrade = true

		if player and player.has_method("get_item_level"):
			current_level = player.get_item_level(item.id)

			# Skip items that are already at max level
			if current_level >= item.max_level:
				can_upgrade = false
				# Try to find a replacement item
				continue

		var price = _get_item_price(item, current_level)

		current_shop_items.append({
			"item": item,
			"price": price,
			"current_level": current_level,
			"next_level": current_level + 1,
			"is_upgrade": current_level > 0
		})

	return current_shop_items


func _get_item_price(item: ItemDatabase.ItemData, current_level: int = 0) -> int:
	"""Calculate item price with level scaling"""
	var base_price = price_by_rarity.get(item.rarity, 50)

	# Adjust price based on type
	match item.type:
		ItemDatabase.ItemType.WEAPON:
			base_price += 10
		ItemDatabase.ItemType.DRUG:
			base_price = int(base_price * 0.6)  # Drugs are cheaper but risky
		ItemDatabase.ItemType.DRONE_UPGRADE:
			base_price += 20
		ItemDatabase.ItemType.WEAPON_UPGRADE:
			base_price += 15

	# Scale price based on upgrade level
	# Level 1: 100% base price
	# Level 2: 150% base price
	# Level 3: 200% base price
	if current_level > 0:
		base_price = int(base_price * (1.0 + current_level * 0.5))

	return base_price


func can_afford(price: int, current_scrap: int) -> bool:
	"""Check if player can afford item"""
	return current_scrap >= price


func purchase_item(item_index: int, player_scrap: int) -> Dictionary:
	"""Purchase item from shop"""
	if item_index < 0 or item_index >= current_shop_items.size():
		return {"success": false, "message": "Invalid item"}

	var shop_item = current_shop_items[item_index]
	var price = shop_item.price

	if not can_afford(price, player_scrap):
		return {"success": false, "message": "Not enough scrap"}

	return {
		"success": true,
		"item": shop_item.item,
		"price": price
	}
