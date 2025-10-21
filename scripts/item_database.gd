extends Node

# Item types
enum ItemType {
	WEAPON,
	DEFENSIVE,
	SUPPORT,
	STAT,
	DRUG,
	DRONE_SUMMON,
	DRONE_UPGRADE,
	WEAPON_UPGRADE,
	ABILITY
}

# Item rarity
enum ItemRarity {
	COMMON,
	RARE,
	EPIC
}

# Item data structure
class ItemData:
	var id: String
	var name: String
	var description: String
	var type: ItemType
	var rarity: ItemRarity
	var icon_color: Color
	var icon_path: String  # Path to sprite icon
	var effects: Dictionary  # stat_name: value (Level 1 effects or fallback)
	var max_level: int = 1  # Max upgrade level (1 = not upgradable, 3 = up to level 3)
	var level_effects: Array = []  # Array of Dictionaries for level 1, 2, 3 effects
	var level_descriptions: Array = []  # Descriptions for each level
	var base_price: int = 0  # Base shop price in Scrap

	func _init(p_id: String, p_name: String, p_desc: String, p_type: ItemType, p_rarity: ItemRarity, p_color: Color, p_effects: Dictionary, p_icon_path: String = ""):
		id = p_id
		name = p_name
		description = p_desc
		type = p_type
		rarity = p_rarity
		icon_color = p_color
		icon_path = p_icon_path
		effects = p_effects

		# Auto-calculate base price from rarity and type
		base_price = _calculate_base_price()

	func _calculate_base_price() -> int:
		"""Calculate base price from rarity and type"""
		var price = 0

		# Base price by rarity
		match rarity:
			ItemRarity.COMMON:
				price = 50
			ItemRarity.RARE:
				price = 150
			ItemRarity.EPIC:
				price = 400

		# Type modifiers
		match type:
			ItemType.WEAPON:
				price = int(price * 1.5)  # Weapons cost more
			ItemType.DEFENSIVE:
				price = int(price * 1.2)
			ItemType.SUPPORT:
				price = int(price * 1.3)
			ItemType.STAT:
				price = int(price * 1.1)
			ItemType.DRUG:
				price = int(price * 0.8)  # Drugs cost less (risk/reward)
			ItemType.DRONE_SUMMON:
				price = int(price * 2.0)  # Drones expensive
			ItemType.DRONE_UPGRADE:
				price = int(price * 1.2)
			ItemType.WEAPON_UPGRADE:
				price = int(price * 1.4)
			ItemType.ABILITY:
				price = int(price * 1.6)

		return price

	func get_effects_for_level(level: int) -> Dictionary:
		"""Get effects for specific level"""
		if level_effects.size() > 0 and level >= 1 and level <= level_effects.size():
			return level_effects[level - 1]
		return effects  # Fallback to base effects

	func get_description_for_level(level: int) -> String:
		"""Get description for specific level"""
		if level_descriptions.size() > 0 and level >= 1 and level <= level_descriptions.size():
			return level_descriptions[level - 1]
		return description  # Fallback to base description

	func get_shop_price(shop_type_modifier: float = 1.0) -> int:
		"""Get price for a specific shop type (with modifier)"""
		return int(base_price * shop_type_modifier)

# All available items
var items: Array[ItemData] = []

func _ready() -> void:
	_initialize_items()

func _initialize_items() -> void:
	"""Initialize all game items"""

	# WEAPONS
	items.append(ItemData.new(
		"laser_gun",
		"Laser Gun",
		"Rapid-fire laser weapon",
		ItemType.WEAPON,
		ItemRarity.COMMON,
		Color(0.2, 0.8, 1.0),
		{"weapon_type": "laser"}
	))

	# TEMPORARILY DISABLED: Other weapons (potential crash risk)
	# TODO: Re-enable once stability is confirmed
	# items.append(ItemData.new(
	# 	"rocket_launcher",
	# 	"Rocket Launcher",
	# 	"Explosive area damage",
	# 	ItemType.WEAPON,
	# 	ItemRarity.RARE,
	# 	Color(1.0, 0.4, 0.0),
	# 	{"weapon_type": "rocket"}
	# ))

	# items.append(ItemData.new(
	# 	"shotgun",
	# 	"Shotgun",
	# 	"Close range spread damage",
	# 	ItemType.WEAPON,
	# 	ItemRarity.COMMON,
	# 	Color(1.0, 1.0, 0.2),
	# 	{"weapon_type": "shotgun"}
	# ))

	# DEFENSIVE
	items.append(ItemData.new(
		"energy_shield",
		"Energy Shield",
		"Absorbs next 50 damage",
		ItemType.DEFENSIVE,
		ItemRarity.COMMON,
		Color(0.0, 0.8, 1.0),
		{"shield": 50}
	))

	items.append(ItemData.new(
		"armor_plating",
		"Armor Plating",
		"Reduces damage by 25%",
		ItemType.DEFENSIVE,
		ItemRarity.RARE,
		Color(0.5, 0.5, 0.5),
		{"damage_reduction": 0.25}
	))

	items.append(ItemData.new(
		"hp_regen",
		"HP Regeneration",
		"Heal 2 HP per second",
		ItemType.DEFENSIVE,
		ItemRarity.COMMON,
		Color(0.0, 1.0, 0.3),
		{"hp_regen": 2.0}
	))

	# ACTIVE/FUN ITEMS (NEW!) - All upgradable to Level 3
	var time_bomb = ItemData.new(
		"time_bomb",
		"Zeitbombe",
		"[USE] Place explosive barrel (3s delay, 200 DMG, 200px radius)",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(1.0, 0.3, 0.0),
		{"active_item": "time_bomb", "duration": 3.0, "damage": 200, "radius": 200.0}
	)
	time_bomb.max_level = 3
	time_bomb.level_effects = [
		{"active_item": "time_bomb", "duration": 3.0, "damage": 200, "radius": 200.0},
		{"active_item": "time_bomb", "duration": 2.0, "damage": 350, "radius": 250.0},
		{"active_item": "time_bomb", "duration": 2.0, "damage": 500, "radius": 300.0, "bomb_count": 3}
	]
	time_bomb.level_descriptions = [
		"[LV1] 200 DMG, 200px, 3s delay",
		"[LV2] 350 DMG, 250px, 2s delay",
		"[LV3] 500 DMG, 300px, spawn 3 bombs"
	]
	items.append(time_bomb)

	var magnet_field = ItemData.new(
		"magnet_field",
		"Magnetfeld",
		"[USE] Pull all enemies towards you for 5s",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.8, 0.2, 1.0),
		{"active_item": "magnet_field", "duration": 5.0, "pull_strength": 300.0}
	)
	magnet_field.max_level = 3
	magnet_field.level_effects = [
		{"active_item": "magnet_field", "duration": 5.0, "pull_strength": 300.0},
		{"active_item": "magnet_field", "duration": 8.0, "pull_strength": 500.0, "slow": 0.5},
		{"active_item": "magnet_field", "duration": 10.0, "pull_strength": 700.0, "slow": 0.5, "damage_per_sec": 15}
	]
	magnet_field.level_descriptions = [
		"[LV1] Pull 5s, 300 strength",
		"[LV2] Pull 8s, 500 strength, 50% slow",
		"[LV3] Pull 10s, 700 strength, slow + 15 DPS"
	]
	items.append(magnet_field)

	var ghost_mode = ItemData.new(
		"ghost_mode",
		"Geistmodus",
		"[USE] Become invisible and invulnerable for 3s",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.5, 0.5, 0.5, 0.3),
		{"active_item": "ghost_mode", "duration": 3.0}
	)
	ghost_mode.max_level = 3
	ghost_mode.level_effects = [
		{"active_item": "ghost_mode", "duration": 3.0},
		{"active_item": "ghost_mode", "duration": 5.0, "speed_boost": 1.5},
		{"active_item": "ghost_mode", "duration": 7.0, "speed_boost": 2.0, "phase_damage": 50}
	]
	ghost_mode.level_descriptions = [
		"[LV1] 3s invulnerability",
		"[LV2] 5s invulnerability + 50% speed",
		"[LV3] 7s invulnerability + 100% speed + phase through enemies deals 50 DMG"
	]
	items.append(ghost_mode)

	var shock_mine = ItemData.new(
		"shock_mine",
		"Schock-Mine",
		"[USE] Place mine that stuns enemies for 2s (50 DMG)",
		ItemType.SUPPORT,
		ItemRarity.COMMON,
		Color(1.0, 1.0, 0.3),
		{"active_item": "shock_mine", "stun_duration": 2.0, "damage": 50}
	)
	shock_mine.max_level = 3
	shock_mine.level_effects = [
		{"active_item": "shock_mine", "stun_duration": 2.0, "damage": 50, "mine_count": 1},
		{"active_item": "shock_mine", "stun_duration": 3.0, "damage": 100, "mine_count": 3},
		{"active_item": "shock_mine", "stun_duration": 4.0, "damage": 150, "mine_count": 5, "chain_stun": true}
	]
	shock_mine.level_descriptions = [
		"[LV1] 1 mine, 2s stun, 50 DMG",
		"[LV2] 3 mines, 3s stun, 100 DMG",
		"[LV3] 5 mines, 4s stun, 150 DMG, chain reaction"
	]
	items.append(shock_mine)

	var time_rewind = ItemData.new(
		"time_rewind",
		"Zeitrückspulung",
		"[USE] Teleport back 3s, restore position + 50 HP",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.3, 0.8, 1.0),
		{"active_item": "time_rewind", "time_back": 3.0, "heal": 50}
	)
	time_rewind.max_level = 3
	time_rewind.level_effects = [
		{"active_item": "time_rewind", "time_back": 3.0, "heal": 50},
		{"active_item": "time_rewind", "time_back": 5.0, "heal": 100, "restore_mana": true},
		{"active_item": "time_rewind", "time_back": 7.0, "heal": 150, "restore_mana": true, "damage_immunity": 2.0}
	]
	time_rewind.level_descriptions = [
		"[LV1] Rewind 3s + 50 HP",
		"[LV2] Rewind 5s + 100 HP + restore mana",
		"[LV3] Rewind 7s + 150 HP + 2s immunity"
	]
	items.append(time_rewind)

	var clone_projection = ItemData.new(
		"clone_projection",
		"Klon-Projektion",
		"[USE] Spawn 2 decoy clones that explode after 5s",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(0.0, 1.0, 1.0),
		{"active_item": "clone_projection", "clone_count": 2, "duration": 5.0, "explosion_damage": 100}
	)
	clone_projection.max_level = 3
	clone_projection.level_effects = [
		{"active_item": "clone_projection", "clone_count": 2, "duration": 5.0, "explosion_damage": 100},
		{"active_item": "clone_projection", "clone_count": 3, "duration": 8.0, "explosion_damage": 150, "clone_ai": true},
		{"active_item": "clone_projection", "clone_count": 5, "duration": 12.0, "explosion_damage": 200, "clone_ai": true, "respawn": true}
	]
	clone_projection.level_descriptions = [
		"[LV1] 2 clones, 5s, 100 DMG explosion",
		"[LV2] 3 clones, 8s, 150 DMG, clones shoot",
		"[LV3] 5 clones, 12s, 200 DMG, auto-respawn"
	]
	items.append(clone_projection)

	var shotgun_spin = ItemData.new(
		"shotgun_spin",
		"Shotgun-Spin",
		"[USE] Fire 360° spread of 16 projectiles",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(1.0, 0.5, 0.0),
		{"active_item": "shotgun_spin", "projectile_count": 16, "damage": 30}
	)
	shotgun_spin.max_level = 3
	shotgun_spin.level_effects = [
		{"active_item": "shotgun_spin", "projectile_count": 16, "damage": 30},
		{"active_item": "shotgun_spin", "projectile_count": 24, "damage": 50, "piercing": 2},
		{"active_item": "shotgun_spin", "projectile_count": 32, "damage": 75, "piercing": 3, "explosive": 50}
	]
	shotgun_spin.level_descriptions = [
		"[LV1] 16 projectiles, 30 DMG",
		"[LV2] 24 projectiles, 50 DMG, pierce 2 enemies",
		"[LV3] 32 projectiles, 75 DMG, pierce 3 + explode"
	]
	items.append(shotgun_spin)

	var black_hole = ItemData.new(
		"black_hole",
		"Schwarzes Loch",
		"[USE] Create vortex that pulls and damages enemies (10s)",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.2, 0.0, 0.4),
		{"active_item": "black_hole", "duration": 10.0, "damage_per_sec": 20, "pull_strength": 400.0}
	)
	black_hole.max_level = 3
	black_hole.level_effects = [
		{"active_item": "black_hole", "duration": 10.0, "damage_per_sec": 20, "pull_strength": 400.0, "radius": 200.0},
		{"active_item": "black_hole", "duration": 15.0, "damage_per_sec": 40, "pull_strength": 600.0, "radius": 300.0},
		{"active_item": "black_hole", "duration": 20.0, "damage_per_sec": 60, "pull_strength": 800.0, "radius": 400.0, "crush": 200}
	]
	black_hole.level_descriptions = [
		"[LV1] 10s, 20 DPS, 200px radius",
		"[LV2] 15s, 40 DPS, 300px radius",
		"[LV3] 20s, 60 DPS, 400px + 200 crush DMG at end"
	]
	items.append(black_hole)

	var berserker_rage = ItemData.new(
		"berserker_rage",
		"Berserker-Wut",
		"[PASSIVE] Damage increases as HP decreases (up to +200% at 10% HP)",
		ItemType.STAT,
		ItemRarity.EPIC,
		Color(1.0, 0.0, 0.0),
		{"berserker_mode": true, "max_bonus": 2.0}
	)
	berserker_rage.max_level = 3
	berserker_rage.level_effects = [
		{"berserker_mode": true, "max_bonus": 2.0},
		{"berserker_mode": true, "max_bonus": 3.0, "speed_bonus": 0.5},
		{"berserker_mode": true, "max_bonus": 4.0, "speed_bonus": 1.0, "lifesteal": 0.25}
	]
	berserker_rage.level_descriptions = [
		"[LV1] Up to +200% damage",
		"[LV2] Up to +300% damage + 50% speed",
		"[LV3] Up to +400% damage + 100% speed + 25% lifesteal"
	]
	items.append(berserker_rage)

	var double_agent = ItemData.new(
		"double_agent",
		"Doppelagent",
		"[USE] Convert 1-3 random enemies to fight for you (15s)",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.5, 1.0, 0.5),
		{"active_item": "double_agent", "convert_count_min": 1, "convert_count_max": 3, "duration": 15.0}
	)
	double_agent.max_level = 3
	double_agent.level_effects = [
		{"active_item": "double_agent", "convert_count_min": 1, "convert_count_max": 3, "duration": 15.0},
		{"active_item": "double_agent", "convert_count_min": 3, "convert_count_max": 5, "duration": 25.0, "buff": 1.5},
		{"active_item": "double_agent", "convert_count_min": 5, "convert_count_max": 8, "duration": 40.0, "buff": 2.0, "permanent": true}
	]
	double_agent.level_descriptions = [
		"[LV1] Convert 1-3 enemies, 15s",
		"[LV2] Convert 3-5 enemies, 25s, +50% stronger",
		"[LV3] Convert 5-8 enemies, 40s, +100% stronger, permanent"
	]
	items.append(double_agent)

	# MOVEMENT POWER-UPS
	var ghost_protocol = ItemData.new(
		"ghost_protocol",
		"Ghost Protocol",
		"[USE] 5s invisibility - enemies lose target, leaves digital afterimages",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(0.3, 0.3, 0.3, 0.5),
		{"active_item": "ghost_protocol", "duration": 5.0}
	)
	ghost_protocol.max_level = 3
	ghost_protocol.level_effects = [
		{"active_item": "ghost_protocol", "duration": 5.0},
		{"active_item": "ghost_protocol", "duration": 8.0, "speed_boost": 1.3, "afterimage_damage": 30},
		{"active_item": "ghost_protocol", "duration": 12.0, "speed_boost": 1.6, "afterimage_damage": 60, "crit_chance": 0.5}
	]
	ghost_protocol.level_descriptions = [
		"[LV1] 5s invisibility",
		"[LV2] 8s + 30% speed + 30 DMG afterimages",
		"[LV3] 12s + 60% speed + 60 DMG afterimages + 50% crit"
	]
	items.append(ghost_protocol)

	var cyber_dash = ItemData.new(
		"cyber_dash",
		"Cyber Dash",
		"[USE] Teleport in look direction, pass through obstacles + enemies",
		ItemType.SUPPORT,
		ItemRarity.COMMON,
		Color(0.0, 0.5, 1.0),
		{"active_item": "cyber_dash", "dash_distance": 150.0}
	)
	cyber_dash.max_level = 3
	cyber_dash.level_effects = [
		{"active_item": "cyber_dash", "dash_distance": 150.0, "cooldown": 5.0},
		{"active_item": "cyber_dash", "dash_distance": 250.0, "cooldown": 3.0, "phase_damage": 50},
		{"active_item": "cyber_dash", "dash_distance": 350.0, "cooldown": 2.0, "phase_damage": 100, "charges": 3}
	]
	cyber_dash.level_descriptions = [
		"[LV1] 150px dash, 5s CD",
		"[LV2] 250px, 3s CD, 50 DMG through enemies",
		"[LV3] 350px, 2s CD, 100 DMG, 3 charges"
	]
	items.append(cyber_dash)

	var wall_phase = ItemData.new(
		"wall_phase",
		"Wall Phase",
		"[USE] Pass through walls for 8s, semi-transparent with circuit pattern",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(0.5, 0.8, 1.0, 0.6),
		{"active_item": "wall_phase", "duration": 8.0}
	)
	wall_phase.max_level = 3
	wall_phase.level_effects = [
		{"active_item": "wall_phase", "duration": 8.0},
		{"active_item": "wall_phase", "duration": 12.0, "speed_boost": 1.5},
		{"active_item": "wall_phase", "duration": 20.0, "speed_boost": 2.0, "phase_regen": 5.0}
	]
	wall_phase.level_descriptions = [
		"[LV1] 8s wall phasing",
		"[LV2] 12s + 50% speed boost",
		"[LV3] 20s + 100% speed + 5 HP/s regen"
	]
	items.append(wall_phase)

	# WEAPON POWER-UPS
	var smart_targeting = ItemData.new(
		"smart_targeting",
		"Smart Targeting System",
		"[PASSIVE] Auto-aim nearest enemy + projectiles track targets slightly",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.RARE,
		Color(1.0, 0.3, 0.3),
		{"smart_targeting": true, "tracking_strength": 0.15}
	)
	smart_targeting.max_level = 3
	smart_targeting.level_effects = [
		{"smart_targeting": true, "tracking_strength": 0.15},
		{"smart_targeting": true, "tracking_strength": 0.30, "show_crosshair": true},
		{"smart_targeting": true, "tracking_strength": 0.30, "show_crosshair": true, "auto_fire": true}
	]
	smart_targeting.level_descriptions = [
		"[LV1] 15% tracking",
		"[LV2] 30% tracking + crosshair overlay",
		"[LV3] Auto-fire when enemy in crosshair"
	]
	items.append(smart_targeting)

	var multishot = ItemData.new(
		"multishot_matrix",
		"Multishot Matrix",
		"[PASSIVE] Fire 5 projectiles in fan pattern, each deals full damage",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.EPIC,
		Color(1.0, 0.8, 0.0),
		{"multishot": true, "projectile_count": 5, "spread_angle": 30.0}
	)
	multishot.max_level = 3
	multishot.level_effects = [
		{"multishot": true, "projectile_count": 5, "spread_angle": 30.0},
		{"multishot": true, "projectile_count": 7, "spread_angle": 35.0},
		{"multishot": true, "projectile_count": 9, "spread_angle": 40.0, "homing": 0.1}
	]
	multishot.level_descriptions = [
		"[LV1] 5 projectiles, 30° spread",
		"[LV2] 7 projectiles, 35° spread",
		"[LV3] 9 projectiles + slight homing"
	]
	items.append(multishot)

	var ricochet = ItemData.new(
		"ricochet_protocol",
		"Ricochet Protocol",
		"[PASSIVE] Projectiles bounce off walls up to 3 times, glow brighter each bounce",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.RARE,
		Color(0.0, 1.0, 0.8),
		{"ricochet": true, "max_bounces": 3}
	)
	ricochet.max_level = 3
	ricochet.level_effects = [
		{"ricochet": true, "max_bounces": 3},
		{"ricochet": true, "max_bounces": 5, "damage_per_bounce": 1.1},
		{"ricochet": true, "max_bounces": 7, "damage_per_bounce": 1.2, "chain_damage": 20}
	]
	ricochet.level_descriptions = [
		"[LV1] 3 bounces",
		"[LV2] 5 bounces, +10% damage per bounce",
		"[LV3] 7 bounces, +20% damage, chain explosion"
	]
	items.append(ricochet)

	# ENVIRONMENTAL POWER-UPS
	var hijack_network = ItemData.new(
		"hijack_network",
		"Drone Hijack Network",
		"[USE] Place 3 invisible hacking nodes - drones in range switch sides",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.0, 1.0, 1.0, 0.7),
		{"active_item": "hijack_network", "node_count": 3, "radius": 200.0, "duration": 30.0}
	)
	hijack_network.max_level = 3
	hijack_network.level_effects = [
		{"active_item": "hijack_network", "node_count": 3, "radius": 200.0, "duration": 30.0},
		{"active_item": "hijack_network", "node_count": 5, "radius": 250.0, "duration": 45.0},
		{"active_item": "hijack_network", "node_count": 7, "radius": 300.0, "duration": 60.0, "permanent_convert": true}
	]
	hijack_network.level_descriptions = [
		"[LV1] 3 nodes, 200px radius, 30s",
		"[LV2] 5 nodes, 250px radius, 45s",
		"[LV3] 7 nodes, 300px, 60s, permanent conversion"
	]
	items.append(hijack_network)

	var env_overload = ItemData.new(
		"env_overload",
		"Environmental Overload",
		"[USE] Lights blink, enemies confused for 3s with random movement",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(1.0, 1.0, 0.3),
		{"active_item": "env_overload", "confuse_duration": 3.0, "blink_intensity": 5.0}
	)
	env_overload.max_level = 3
	env_overload.level_effects = [
		{"active_item": "env_overload", "confuse_duration": 3.0, "blink_intensity": 5.0},
		{"active_item": "env_overload", "confuse_duration": 5.0, "blink_intensity": 8.0, "damage": 50},
		{"active_item": "env_overload", "confuse_duration": 7.0, "blink_intensity": 10.0, "damage": 100, "stun": true}
	]
	env_overload.level_descriptions = [
		"[LV1] 3s confusion",
		"[LV2] 5s confusion + 50 DMG",
		"[LV3] 7s confusion + 100 DMG + stun"
	]
	items.append(env_overload)

	var scrap_magnet = ItemData.new(
		"scrap_magnetism",
		"Scrap Magnetism",
		"[USE] All scrap in 400px flies to you for 10s",
		ItemType.SUPPORT,
		ItemRarity.COMMON,
		Color(0.8, 0.0, 1.0),
		{"active_item": "scrap_magnet", "magnet_radius": 400.0, "duration": 10.0}
	)
	scrap_magnet.max_level = 3
	scrap_magnet.level_effects = [
		{"active_item": "scrap_magnet", "magnet_radius": 400.0, "duration": 10.0},
		{"active_item": "scrap_magnet", "magnet_radius": 600.0, "duration": 15.0, "bonus_scrap": 1.2},
		{"active_item": "scrap_magnet", "magnet_radius": 999.0, "duration": 20.0, "bonus_scrap": 1.5, "passive": true}
	]
	scrap_magnet.level_descriptions = [
		"[LV1] 400px radius, 10s",
		"[LV2] 600px, 15s, +20% scrap value",
		"[LV3] Map-wide, 20s, +50% scrap, passive pull"
	]
	items.append(scrap_magnet)

	# TACTICAL POWER-UPS
	var holo_decoy = ItemData.new(
		"holo_decoy",
		"Holographic Decoy",
		"[USE] Create 2 holographic copies that enemies attack",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(0.3, 0.8, 1.0, 0.6),
		{"active_item": "holo_decoy", "decoy_count": 2, "duration": 8.0}
	)
	holo_decoy.max_level = 3
	holo_decoy.level_effects = [
		{"active_item": "holo_decoy", "decoy_count": 2, "duration": 8.0},
		{"active_item": "holo_decoy", "decoy_count": 3, "duration": 12.0, "decoy_hp": 100},
		{"active_item": "holo_decoy", "decoy_count": 4, "duration": 15.0, "decoy_hp": 150, "explosive": 100}
	]
	holo_decoy.level_descriptions = [
		"[LV1] 2 decoys, 8s",
		"[LV2] 3 decoys, 12s, 100 HP each",
		"[LV3] 4 decoys, 15s, 150 HP, explode for 100 DMG"
	]
	items.append(holo_decoy)

	var temporal_rewind = ItemData.new(
		"temporal_rewind_tactical",
		"Temporal Rewind",
		"[USE] Rewind to position 3s ago, keep HP/items, slow-mo effect",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.3, 1.0, 1.0),
		{"active_item": "temporal_rewind", "rewind_time": 3.0, "slowmo_factor": 0.3}
	)
	temporal_rewind.max_level = 3
	temporal_rewind.level_effects = [
		{"active_item": "temporal_rewind", "rewind_time": 3.0, "slowmo_factor": 0.3},
		{"active_item": "temporal_rewind", "rewind_time": 5.0, "slowmo_factor": 0.2, "invulnerable": true},
		{"active_item": "temporal_rewind", "rewind_time": 7.0, "slowmo_factor": 0.1, "invulnerable": true, "clone_attack": true}
	]
	temporal_rewind.level_descriptions = [
		"[LV1] Rewind 3s, 30% slow-mo",
		"[LV2] Rewind 5s, 20% slow-mo, invulnerable during",
		"[LV3] Rewind 7s, 10% slow-mo, invulnerable, leave attacking clone"
	]
	items.append(temporal_rewind)

	var quantum_link = ItemData.new(
		"quantum_entanglement",
		"Quantum Entanglement",
		"[USE] Mark enemy - 50% of your damage is reflected back to them",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.6, 0.0, 1.0),
		{"active_item": "quantum_link", "damage_share": 0.5, "duration": 15.0}
	)
	quantum_link.max_level = 3
	quantum_link.level_effects = [
		{"active_item": "quantum_link", "damage_share": 0.5, "duration": 15.0},
		{"active_item": "quantum_link", "damage_share": 0.75, "duration": 20.0, "heal_share": 0.25},
		{"active_item": "quantum_link", "damage_share": 1.0, "duration": 30.0, "heal_share": 0.5, "multi_target": 3}
	]
	quantum_link.level_descriptions = [
		"[LV1] 50% damage shared, 15s",
		"[LV2] 75% damage shared, 20s, heal 25% of their damage",
		"[LV3] 100% damage shared, 30s, heal 50%, link 3 enemies"
	]
	items.append(quantum_link)

	# SUPPORT (OLD - kept for drone items)
	items.append(ItemData.new(
		"attack_drone",
		"Attack Drone",
		"Drone that shoots enemies",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(1.0, 0.0, 0.0),
		{"drone_type": "attack"}
	))

	items.append(ItemData.new(
		"shield_drone",
		"Shield Drone",
		"Drone that blocks damage",
		ItemType.SUPPORT,
		ItemRarity.RARE,
		Color(0.3, 0.3, 1.0),
		{"drone_type": "shield"}
	))

	items.append(ItemData.new(
		"hack_module",
		"Hack Module",
		"Convert 1 enemy per wave",
		ItemType.SUPPORT,
		ItemRarity.EPIC,
		Color(0.5, 1.0, 0.5),
		{"extra_pets": 1}
	))

	# PASSIVE STAT BOOSTS (REDUCED - only essential ones)
	# Removed: Speed Boost, Damage Boost, Fire Rate Boost (too boring)

	items.append(ItemData.new(
		"max_hp_boost",
		"Vitality",
		"+50 max HP and heal to full",
		ItemType.STAT,
		ItemRarity.RARE,
		Color(0.0, 1.0, 0.0),
		{"max_hp_bonus": 50, "heal_full": true}
	))

	# DRUGS (Risk/Reward) - with sprite icons!
	items.append(ItemData.new(
		"adrenaline_shot",
		"Adrenaline Shot",
		"+50% Speed, +30% Attack Speed (30s) [30% chance: -20 Max HP]",
		ItemType.DRUG,
		ItemRarity.COMMON,
		Color(1.0, 0.3, 0.3),
		{"drug_id": "adrenaline_shot"},
		"res://assets/sprites/drugs/speed_injector.png"
	))

	items.append(ItemData.new(
		"neural_enhancer",
		"Neural Enhancer",
		"+100% Damage (45s) [40% chance: Inverted Controls 60s]",
		ItemType.DRUG,
		ItemRarity.RARE,
		Color(0.5, 0.2, 1.0),
		{"drug_id": "neural_enhancer"},
		"res://assets/sprites/drugs/nano_boost.png"
	))

	items.append(ItemData.new(
		"stim_pack",
		"Stim-Pack",
		"Heal to full + 3 HP/s regen (20s) [25% chance: Lose 50 Shield]",
		ItemType.DRUG,
		ItemRarity.COMMON,
		Color(0.0, 1.0, 0.5),
		{"drug_id": "stim_pack"},
		"res://assets/sprites/drugs/stim_pack.png"
	))

	items.append(ItemData.new(
		"rage_serum",
		"Rage Serum",
		"+200% Damage, +50% Speed (60s) [50% chance: Screen shake, vision penalty]",
		ItemType.DRUG,
		ItemRarity.EPIC,
		Color(1.0, 0.0, 0.5),
		{"drug_id": "rage_serum"},
		"res://assets/sprites/drugs/rage_pill.png"
	))

	items.append(ItemData.new(
		"overdrive_chip",
		"Overdrive Chip",
		"3x Weapon Fire Rate (45s) [60% chance: 5 HP/s withdrawal damage]",
		ItemType.DRUG,
		ItemRarity.EPIC,
		Color(1.0, 0.5, 0.0),
		{"drug_id": "overdrive_chip"},
		"res://assets/sprites/drugs/combat_drug.png"
	))

	# DRONE SUMMON (only for Hacker)
	items.append(ItemData.new(
		"summon_drone",
		"Summon Combat Drone",
		"[HACKER ONLY] Summon controllable combat drone (Press E to switch)",
		ItemType.DRONE_SUMMON,
		ItemRarity.EPIC,
		Color(0, 1, 1),
		{"spawn_drone": true}
	))

	# DRONE UPGRADES (only for Hacker with active drone)
	items.append(ItemData.new(
		"drone_energy_shield",
		"[DRONE] Energy Shield",
		"Drone reflects 30% projectiles + 50 Shield HP",
		ItemType.DRONE_UPGRADE,
		ItemRarity.RARE,
		Color(0.3, 0.8, 1.0),
		{"drone_upgrade_id": "energy_shield"}
	))

	items.append(ItemData.new(
		"drone_dual_weapons",
		"[DRONE] Dual Weapon System",
		"Drone fires two weapons simultaneously",
		ItemType.DRONE_UPGRADE,
		ItemRarity.EPIC,
		Color(1.0, 0.5, 0.0),
		{"drone_upgrade_id": "dual_weapons"}
	))

	items.append(ItemData.new(
		"drone_nano_repair",
		"[DRONE] Nano-Repair",
		"Drone regenerates 5 HP/s",
		ItemType.DRONE_UPGRADE,
		ItemRarity.RARE,
		Color(0.2, 1.0, 0.2),
		{"drone_upgrade_id": "nano_repair"}
	))

	items.append(ItemData.new(
		"drone_scanner",
		"[DRONE] Tactical Scanner",
		"Drone gains +25% Crit Chance",
		ItemType.DRONE_UPGRADE,
		ItemRarity.RARE,
		Color(1.0, 1.0, 0.3),
		{"drone_upgrade_id": "scan_pulse"}
	))

	items.append(ItemData.new(
		"drone_speed",
		"[DRONE] Thruster Upgrade",
		"Drone +40% Movement Speed",
		ItemType.DRONE_UPGRADE,
		ItemRarity.COMMON,
		Color(0.0, 1.0, 1.0),
		{"drone_upgrade_id": "speed_boost"}
	))

	# WEAPON UPGRADES
	items.append(ItemData.new(
		"weapon_upgrade",
		"Weapon Upgrade",
		"Upgrade to next weapon tier",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.RARE,
		Color(1.0, 0.8, 0.0),
		{"upgrade_weapon": true},
		"res://assets/sprites/items/item_weapon_upgrade_32.png"
	))

	# LASER-SPECIFIC UPGRADES
	var laser_damage = ItemData.new(
		"laser_damage_boost",
		"High-Energy Capacitors",
		"[LASER] +50% Laser Damage",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.RARE,
		Color(0.2, 0.9, 1.0),
		{"laser_damage_mult": 1.5}
	)
	laser_damage.max_level = 3
	laser_damage.level_effects = [
		{"laser_damage_mult": 1.5},
		{"laser_damage_mult": 2.0},
		{"laser_damage_mult": 3.0}
	]
	laser_damage.level_descriptions = [
		"[LV1] +50% Laser Damage",
		"[LV2] +100% Laser Damage",
		"[LV3] +200% Laser Damage"
	]
	items.append(laser_damage)

	var laser_firerate = ItemData.new(
		"laser_firerate_boost",
		"Overclocked Laser Array",
		"[LASER] +50% Fire Rate",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.RARE,
		Color(1.0, 0.3, 0.3),
		{"laser_firerate_mult": 1.5}
	)
	laser_firerate.max_level = 3
	laser_firerate.level_effects = [
		{"laser_firerate_mult": 1.5},
		{"laser_firerate_mult": 2.0},
		{"laser_firerate_mult": 3.0}
	]
	laser_firerate.level_descriptions = [
		"[LV1] +50% Fire Rate",
		"[LV2] +100% Fire Rate",
		"[LV3] +200% Fire Rate"
	]
	items.append(laser_firerate)

	var laser_penetration = ItemData.new(
		"laser_penetration_boost",
		"Quantum Penetrator",
		"[LASER] +3 Penetrations",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.EPIC,
		Color(0.8, 0.0, 1.0),
		{"laser_penetration_bonus": 3}
	)
	laser_penetration.max_level = 3
	laser_penetration.level_effects = [
		{"laser_penetration_bonus": 3},
		{"laser_penetration_bonus": 6},
		{"laser_penetration_bonus": 10, "infinite_pierce": true}
	]
	laser_penetration.level_descriptions = [
		"[LV1] +3 Penetrations",
		"[LV2] +6 Penetrations",
		"[LV3] +10 Penetrations + Infinite Pierce"
	]
	items.append(laser_penetration)

	var laser_chain = ItemData.new(
		"laser_chain_lightning",
		"Chain Lightning Protocol",
		"[LASER] Lasers chain to 2 nearby enemies",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.EPIC,
		Color(1.0, 1.0, 0.0),
		{"laser_chain_count": 2, "laser_chain_range": 150.0}
	)
	laser_chain.max_level = 3
	laser_chain.level_effects = [
		{"laser_chain_count": 2, "laser_chain_range": 150.0},
		{"laser_chain_count": 4, "laser_chain_range": 200.0},
		{"laser_chain_count": 6, "laser_chain_range": 300.0, "chain_damage_mult": 1.0}
	]
	laser_chain.level_descriptions = [
		"[LV1] Chain to 2 enemies (150px)",
		"[LV2] Chain to 4 enemies (200px)",
		"[LV3] Chain to 6 enemies (300px) + Full Damage"
	]
	items.append(laser_chain)

	var laser_split = ItemData.new(
		"laser_split_beam",
		"Prism Splitter",
		"[LASER] Lasers split into 3 beams on hit",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.EPIC,
		Color(0.0, 1.0, 1.0),
		{"laser_split_count": 3, "laser_split_angle": 45.0}
	)
	laser_split.max_level = 3
	laser_split.level_effects = [
		{"laser_split_count": 3, "laser_split_angle": 45.0},
		{"laser_split_count": 5, "laser_split_angle": 60.0},
		{"laser_split_count": 8, "laser_split_angle": 90.0, "split_homing": 0.2}
	]
	laser_split.level_descriptions = [
		"[LV1] Split into 3 beams (45°)",
		"[LV2] Split into 5 beams (60°)",
		"[LV3] Split into 8 beams (90°) + Homing"
	]
	items.append(laser_split)

	var laser_beam_mode = ItemData.new(
		"laser_beam_mode",
		"Continuous Beam Emitter",
		"[LASER] Laser becomes continuous beam",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.EPIC,
		Color(1.0, 0.0, 0.5),
		{"laser_beam_mode": true, "beam_width": 10.0, "beam_dps": 30}
	)
	laser_beam_mode.max_level = 3
	laser_beam_mode.level_effects = [
		{"laser_beam_mode": true, "beam_width": 10.0, "beam_dps": 30},
		{"laser_beam_mode": true, "beam_width": 20.0, "beam_dps": 60},
		{"laser_beam_mode": true, "beam_width": 40.0, "beam_dps": 120, "beam_push": 200.0}
	]
	laser_beam_mode.level_descriptions = [
		"[LV1] Continuous beam (30 DPS)",
		"[LV2] Wider beam (60 DPS)",
		"[LV3] Massive beam (120 DPS) + Push enemies"
	]
	items.append(laser_beam_mode)

	var laser_overcharge = ItemData.new(
		"laser_overcharge",
		"Overcharge Module",
		"[LASER] Every 5th shot deals 300% damage + AOE",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.EPIC,
		Color(1.0, 0.5, 0.0),
		{"laser_overcharge_interval": 5, "overcharge_damage_mult": 3.0, "overcharge_aoe": 100.0}
	)
	laser_overcharge.max_level = 3
	laser_overcharge.level_effects = [
		{"laser_overcharge_interval": 5, "overcharge_damage_mult": 3.0, "overcharge_aoe": 100.0},
		{"laser_overcharge_interval": 4, "overcharge_damage_mult": 5.0, "overcharge_aoe": 150.0},
		{"laser_overcharge_interval": 3, "overcharge_damage_mult": 10.0, "overcharge_aoe": 200.0, "overcharge_stun": 1.0}
	]
	laser_overcharge.level_descriptions = [
		"[LV1] Every 5th shot: 300% DMG + 100px AOE",
		"[LV2] Every 4th shot: 500% DMG + 150px AOE",
		"[LV3] Every 3rd shot: 1000% DMG + 200px AOE + 1s Stun"
	]
	items.append(laser_overcharge)

	var laser_size = ItemData.new(
		"laser_size_boost",
		"Wide-Beam Emitter",
		"[LASER] 50% Wider laser beams",
		ItemType.WEAPON_UPGRADE,
		ItemRarity.COMMON,
		Color(0.5, 0.8, 1.0),
		{"laser_width_mult": 1.5}
	)
	laser_size.max_level = 3
	laser_size.level_effects = [
		{"laser_width_mult": 1.5},
		{"laser_width_mult": 2.0},
		{"laser_width_mult": 3.0}
	]
	laser_size.level_descriptions = [
		"[LV1] +50% Beam Width",
		"[LV2] +100% Beam Width",
		"[LV3] +200% Beam Width"
	]
	items.append(laser_size)

	# ABILITIES (Q, W, E, R)
	items.append(ItemData.new(
		"ability_dash",
		"[Q] Combat Roll",
		"Unlock: Dash 200 units (3s CD, 10 mana)",
		ItemType.ABILITY,
		ItemRarity.RARE,
		Color(0.3, 0.7, 1.0),
		{"unlock_ability": "dash", "ability_slot": "Q"}
	))

	# [W] Shockwave REMOVED - W is movement key!

	items.append(ItemData.new(
		"ability_shield",
		"[E] Energy Barrier",
		"Unlock: Gain 100 shield for 5s (12s CD, 15 mana)",
		ItemType.ABILITY,
		ItemRarity.RARE,
		Color(0.2, 0.8, 1.0),
		{"unlock_ability": "energy_shield", "ability_slot": "E"}
	))

	items.append(ItemData.new(
		"ability_heal",
		"[E] Nano-Repair",
		"Unlock: Heal 60 HP instantly (10s CD, 20 mana)",
		ItemType.ABILITY,
		ItemRarity.RARE,
		Color(0.2, 1.0, 0.4),
		{"unlock_ability": "heal", "ability_slot": "E"}
	))

	items.append(ItemData.new(
		"ability_overdrive",
		"[R] Overdrive",
		"Unlock: +100% Damage +50% Speed for 8s (30s CD, 50 mana)",
		ItemType.ABILITY,
		ItemRarity.EPIC,
		Color(1.0, 0.2, 0.2),
		{"unlock_ability": "rage_mode", "ability_slot": "R"}
	))


func get_random_items(count: int) -> Array[ItemData]:
	"""Get random items from the database"""
	var available_items = items.duplicate()
	var selected: Array[ItemData] = []

	for i in range(min(count, available_items.size())):
		var random_index = randi() % available_items.size()
		selected.append(available_items[random_index])
		available_items.remove_at(random_index)

	return selected


func get_item_by_id(item_id: String) -> ItemData:
	"""Get item by ID"""
	for item in items:
		if item.id == item_id:
			return item
	return null
