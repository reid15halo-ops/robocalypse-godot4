extends Node

# Character definitions
var characters = {
	"hacker": {
		"name": "Der Hacker",
		"description": "Balanced stats with Pet system support",
		"icon_color": Color(0.0, 0.8, 1.0),  # Cyan
		"stats": {
			"max_hp": 100,
			"speed": 200.0,
			"melee_damage": 20,
			"melee_interval": 0.5,
			"starting_weapon": "laser"
		},
		"special_ability": "pet_bonus",  # Gets +20% pet damage/effectiveness
		"unlocked_by_default": true
	},
	"technician": {
		"name": "Der Techniker",
		"description": "+50% Drone damage, -20% HP",
		"icon_color": Color(1.0, 0.8, 0.0),  # Gold
		"stats": {
			"max_hp": 80,
			"speed": 200.0,
			"melee_damage": 20,
			"melee_interval": 0.5,
			"starting_weapon": "laser"
		},
		"special_ability": "drone_master",  # +50% drone damage
		"cost": 3000,
		"unlocked_by_default": false
	},
	"soldier": {
		"name": "Der Soldat",
		"description": "+30% HP, +20% Damage, -15% Speed",
		"icon_color": Color(0.2, 0.7, 0.2),  # Green
		"stats": {
			"max_hp": 130,
			"speed": 170.0,
			"melee_damage": 24,
			"melee_interval": 0.5,
			"starting_weapon": "shotgun"
		},
		"special_ability": "tank",  # Natural 10% damage reduction
		"cost": 4000,
		"unlocked_by_default": false
	}
}

# Currently selected character
var current_character: String = "hacker"


func _ready() -> void:
	# Load selected character from save
	var saved_char = SaveManager.get_selected_character()
	if saved_char and characters.has(saved_char):
		current_character = saved_char


func get_character(character_id: String) -> Dictionary:
	"""Get character data"""
	if characters.has(character_id):
		return characters[character_id]
	return {}


func get_current_character() -> Dictionary:
	"""Get currently selected character"""
	return get_character(current_character)


func select_character(character_id: String) -> bool:
	"""Select a character to play"""
	if not characters.has(character_id):
		print("Character not found: ", character_id)
		return false

	if not is_character_unlocked(character_id):
		print("Character not unlocked: ", character_id)
		return false

	current_character = character_id
	SaveManager.set_selected_character(character_id)
	print("Selected character: ", characters[character_id].name)
	return true


func is_character_unlocked(character_id: String) -> bool:
	"""Check if character is unlocked"""
	if not characters.has(character_id):
		return false

	var char = characters[character_id]
	if char.get("unlocked_by_default", false):
		return true

	return SaveManager.is_character_unlocked(character_id)


func apply_character_to_player(player: Node) -> void:
	"""Apply character stats and abilities to player"""
	var char = get_current_character()
	if char.is_empty():
		print("No character selected!")
		return

	var stats = char.stats

	# Apply base stats
	player.max_health = stats.max_hp
	player.current_health = stats.max_hp
	player.speed = stats.speed
	player.melee_damage = stats.melee_damage
	player.melee_interval = stats.melee_interval

	# Give starting weapon
	if stats.has("starting_weapon"):
		player.add_weapon(stats.starting_weapon)

	# Apply special abilities
	match char.special_ability:
		"pet_bonus":
			player.set_meta("pet_damage_bonus", 0.2)
		"drone_master":
			player.set_meta("drone_damage_bonus", 0.5)
		"tank":
			player.damage_reduction = 0.1

	print("Applied character: ", char.name)
	print("  HP: ", player.max_health)
	print("  Speed: ", player.speed)
	print("  Damage: ", player.melee_damage)
	print("  Starting weapon: ", stats.get("starting_weapon", "none"))


func get_unlocked_characters() -> Array:
	"""Get list of unlocked character IDs"""
	var unlocked = []
	for char_id in characters:
		if is_character_unlocked(char_id):
			unlocked.append(char_id)
	return unlocked


func get_locked_characters() -> Array:
	"""Get list of locked character IDs"""
	var locked = []
	for char_id in characters:
		if not is_character_unlocked(char_id):
			locked.append(char_id)
	return locked
