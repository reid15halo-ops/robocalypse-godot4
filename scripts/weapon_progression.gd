extends Node

# Weapon progression tree
var weapons = {
	"screwdriver": {
		"name": "Schraubenzieher",
		"description": "Improvisierte Nahkampfwaffe",
		"damage": 5,
		"range": 60.0,
		"interval": 0.8,
		"cost": 0,
		"tier": 0,
		"next_upgrade": "wrench",
		"texture": "res://assets/sprites/weapons/weapon_screwdriver.png"
	},
	"wrench": {
		"name": "Schraubenschluessel",
		"description": "Schwerer Nahkampf",
		"damage": 10,
		"range": 70.0,
		"interval": 0.7,
		"cost": 200,
		"tier": 1,
		"next_upgrade": "electro_shocker",
		"texture": "res://assets/sprites/weapons/weapon_wrench.png"
	},
	"electro_shocker": {
		"name": "Elektroschocker",
		"description": "Elektrifizierter Nahkampf mit kleinem AoE",
		"damage": 15,
		"range": 80.0,
		"interval": 0.6,
		"cost": 500,
		"tier": 2,
		"next_upgrade": "plasma_cutter",
		"texture": "res://assets/sprites/weapons/weapon_electro_shocker.png",
		"has_aoe": true,
		"aoe_radius": 30.0
	},
	"plasma_cutter": {
		"name": "Plasma-Schneider",
		"description": "Heisse Plasmaklinge",
		"damage": 25,
		"range": 90.0,
		"interval": 0.5,
		"cost": 1000,
		"tier": 3,
		"next_upgrade": "energy_blade",
		"texture": "res://assets/sprites/weapons/weapon_plasma_cutter.png"
	},
	"energy_blade": {
		"name": "Energie-Klinge",
		"description": "Hochenergetische Klinge",
		"damage": 40,
		"range": 100.0,
		"interval": 0.4,
		"cost": 2000,
		"tier": 4,
		"next_upgrade": "plasma_sword",
		"texture": "res://assets/sprites/weapons/weapon_energy_blade.png"
	},
	"plasma_sword": {
		"name": "Plasma-Schwert",
		"description": "Ultimative Nahkampfwaffe",
		"damage": 60,
		"range": 120.0,
		"interval": 0.3,
		"cost": 4000,
		"tier": 5,
		"next_upgrade": null,
		"texture": "res://assets/sprites/weapons/weapon_plasma_sword.png",
		"has_aoe": true,
		"aoe_radius": 50.0
	}
}

# Current weapon for each player (stored by character ID or run)
var current_weapon: String = "screwdriver"


func get_weapon_data(weapon_id: String) -> Dictionary:
	"""Get weapon data"""
	if weapons.has(weapon_id):
		var data = weapons[weapon_id].duplicate()
		data["id"] = weapon_id
		return data
	return {}


func get_current_weapon() -> Dictionary:
	"""Get currently equipped weapon"""
	return get_weapon_data(current_weapon)


func can_upgrade(player_scrap: int) -> bool:
	"""Check if current weapon can be upgraded"""
	var weapon = get_current_weapon()
	if not weapon.has("next_upgrade") or weapon.next_upgrade == null:
		return false

	var next_weapon = get_weapon_data(weapon.next_upgrade)
	if next_weapon.is_empty():
		return false

	return player_scrap >= next_weapon.cost


func get_next_weapon() -> Dictionary:
	"""Get next weapon in upgrade path"""
	var weapon = get_current_weapon()
	if weapon.has("next_upgrade") and weapon.next_upgrade:
		return get_weapon_data(weapon.next_upgrade)
	return {}


func upgrade_weapon(player: Node) -> bool:
	"""Upgrade to next weapon tier"""
	var next_weapon = get_next_weapon()
	if next_weapon.is_empty():
		print("Already at max weapon tier!")
		return false

	# Apply new weapon stats
	current_weapon = next_weapon.id
	apply_weapon_to_player(player)

	print("Upgraded to: ", next_weapon.name)
	return true


func apply_weapon_to_player(player: Node) -> void:
	"""Apply current weapon stats to player"""
	var weapon = get_current_weapon()
	if weapon.is_empty():
		return

	# Apply weapon stats (properties exist on player CharacterBody2D)
	player.melee_damage = weapon.damage
	player.melee_range = weapon.range
	player.melee_interval = weapon.interval

	# Store weapon data for special effects
	player.set_meta("current_weapon", weapon)
	if player.has_method("update_weapon_visual"):
		player.update_weapon_visual(weapon)

	print("Applied weapon: ", weapon.name)
	print("  Damage: ", weapon.damage)
	print("  Range: ", weapon.range)
	print("  Speed: ", 1.0 / weapon.interval, " hits/s")


func reset_weapon() -> void:
	"""Reset to starting weapon (for new run)"""
	current_weapon = "screwdriver"


func get_all_weapons() -> Array:
	"""Get all weapons sorted by tier"""
	var all_weapons = []
	for weapon_id in weapons:
		var weapon = get_weapon_data(weapon_id)
		all_weapons.append(weapon)

	all_weapons.sort_custom(func(a, b): return a.tier < b.tier)
	return all_weapons
