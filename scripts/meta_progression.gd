extends Node

# Meta upgrade definitions
var upgrades = {
	"max_hp_level": {
		"name": "Vitality Boost",
		"description": "+5% Max HP per level",
		"max_level": 10,
		"base_cost": 500,
		"cost_scaling": 1.2,  # Reduced from 1.3 for better progression
		"value_per_level": 0.05  # 5% per level
	},
	"speed_level": {
		"name": "Speed Enhancement",
		"description": "+3% Movement Speed per level",
		"max_level": 8,
		"base_cost": 400,
		"cost_scaling": 1.2,  # Reduced from 1.25
		"value_per_level": 0.03
	},
	"damage_level": {
		"name": "Damage Amplifier",
		"description": "+5% Damage per level",
		"max_level": 10,
		"base_cost": 600,
		"cost_scaling": 1.2,  # Reduced from 1.4
		"value_per_level": 0.05
	},
	"scrap_gain_level": {
		"name": "Scrap Collector",
		"description": "+10% Scrap Gain per level",
		"max_level": 5,
		"base_cost": 800,
		"cost_scaling": 1.25,  # Reduced from 1.5
		"value_per_level": 0.10
	}
}


func get_upgrade_cost(upgrade_id: String) -> int:
	"""Calculate cost for next level of upgrade"""
	if not upgrades.has(upgrade_id):
		return 0

	var upgrade = upgrades[upgrade_id]
	var current_level = SaveManager.get_upgrade_level(upgrade_id)

	if current_level >= upgrade.max_level:
		return -1  # Max level reached

	# Cost increases with level
	var cost = upgrade.base_cost * pow(upgrade.cost_scaling, current_level)
	return int(cost)


func can_purchase_upgrade(upgrade_id: String) -> bool:
	"""Check if player can afford and hasn't maxed upgrade"""
	var cost = get_upgrade_cost(upgrade_id)
	if cost <= 0:
		return false

	return SaveManager.get_scrap() >= cost


func purchase_upgrade(upgrade_id: String) -> bool:
	"""Purchase an upgrade level"""
	if not can_purchase_upgrade(upgrade_id):
		return false

	var cost = get_upgrade_cost(upgrade_id)

	if SaveManager.spend_scrap(cost):
		SaveManager.purchase_upgrade(upgrade_id)
		print("Purchased ", upgrades[upgrade_id].name, " level ", SaveManager.get_upgrade_level(upgrade_id))
		return true

	return false


func get_total_upgrade_bonus(upgrade_id: String) -> float:
	"""Get total bonus from upgrade levels"""
	if not upgrades.has(upgrade_id):
		return 0.0

	var level = SaveManager.get_upgrade_level(upgrade_id)
	var value_per_level = upgrades[upgrade_id].value_per_level

	return level * value_per_level


func apply_meta_upgrades_to_player(player: Node) -> void:
	"""Apply all meta upgrades to player stats"""
	if not player:
		return

	# Max HP boost
	var hp_bonus = get_total_upgrade_bonus("max_hp_level")
	var new_max_health = int(100 * (1.0 + hp_bonus))  # Base 100 HP

	# If max health increased, add the difference to current health
	if new_max_health > player.max_health:
		var hp_increase = new_max_health - player.max_health
		player.current_health += hp_increase

	player.max_health = new_max_health
	player.current_health = min(player.current_health, player.max_health)

	# Speed boost
	var speed_bonus = get_total_upgrade_bonus("speed_level")
	player.speed = 200.0 * (1.0 + speed_bonus)  # Base 200 speed

	# Damage boost
	var damage_bonus = get_total_upgrade_bonus("damage_level")
	player.melee_damage = int(20 * (1.0 + damage_bonus))  # Base 20 damage

	print("Meta upgrades applied to player")
	print("Max HP: ", player.max_health)
	print("Current HP: ", player.current_health)
	print("Speed: ", player.speed)
	print("Damage: ", player.melee_damage)


func get_scrap_multiplier() -> float:
	"""Get scrap gain multiplier from upgrades"""
	return 1.0 + get_total_upgrade_bonus("scrap_gain_level")


# Character unlocks
var characters = {
	"hacker": {
		"name": "Hacker",
		"cost": 0,  # Default character
		"description": "Balanced stats, Pet system",
		"unlocked_by_default": true
	},
	"technician": {
		"name": "Technician",
		"cost": 3000,
		"description": "+50% Drone damage, -20% HP",
		"unlocked_by_default": false
	},
	"soldier": {
		"name": "Soldier",
		"cost": 4000,
		"description": "+30% HP, +20% Damage, -15% Speed",
		"unlocked_by_default": false
	}
}


func can_purchase_character(character_id: String) -> bool:
	"""Check if character can be purchased"""
	if not characters.has(character_id):
		return false

	if SaveManager.is_character_unlocked(character_id):
		return false  # Already unlocked

	var cost = characters[character_id].cost
	return SaveManager.get_scrap() >= cost


func purchase_character(character_id: String) -> bool:
	"""Purchase a character unlock"""
	if not can_purchase_character(character_id):
		return false

	var cost = characters[character_id].cost

	if SaveManager.spend_scrap(cost):
		SaveManager.unlock_character(character_id)
		print("Unlocked character: ", characters[character_id].name)
		return true

	return false
