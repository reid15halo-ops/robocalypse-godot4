extends Node

# Drone-specific upgrades database
var drone_upgrades = {
	"energy_shield": {
		"name": "Energy Shield",
		"description": "Generates a shield that reflects 30% projectiles",
		"icon_color": Color(0.3, 0.8, 1.0),
		"effects": {
			"projectile_reflect": 0.3,
			"shield_hp": 50
		},
		"rarity": "rare"
	},
	"dual_weapons": {
		"name": "Dual Weapon System",
		"description": "Fire two weapons simultaneously",
		"icon_color": Color(1.0, 0.5, 0.0),
		"effects": {
			"dual_fire": true,
			"fire_rate_penalty": 0.2  # 20% slower
		},
		"rarity": "epic"
	},
	"overcharge": {
		"name": "Overcharge Protocol",
		"description": "+100% Damage for 10s, then cooldown",
		"icon_color": Color(1.0, 0.2, 0.2),
		"effects": {
			"overcharge_damage": 2.0,
			"overcharge_duration": 10.0,
			"overcharge_cooldown": 30.0
		},
		"rarity": "epic"
	},
	"nano_repair": {
		"name": "Nano-Repair System",
		"description": "Regenerate 5 HP/second",
		"icon_color": Color(0.2, 1.0, 0.2),
		"effects": {
			"hp_regen": 5.0
		},
		"rarity": "rare"
	},
	"scan_pulse": {
		"name": "Tactical Scanner",
		"description": "Reveals enemies, +25% Crit Chance",
		"icon_color": Color(1.0, 1.0, 0.3),
		"effects": {
			"enemy_reveal": true,
			"crit_chance": 0.25,
			"crit_multiplier": 1.5
		},
		"rarity": "rare"
	},
	"speed_boost": {
		"name": "Thruster Upgrade",
		"description": "+40% Movement Speed",
		"icon_color": Color(0.0, 1.0, 1.0),
		"effects": {
			"speed_multiplier": 1.4
		},
		"rarity": "common"
	},
	"damage_amp": {
		"name": "Damage Amplifier",
		"description": "+30% Weapon Damage",
		"icon_color": Color(1.0, 0.3, 0.3),
		"effects": {
			"damage_multiplier": 1.3
		},
		"rarity": "common"
	},
	"rapid_fire": {
		"name": "Rapid Fire Module",
		"description": "+50% Attack Speed",
		"icon_color": Color(1.0, 0.7, 0.0),
		"effects": {
			"attack_speed_multiplier": 1.5
		},
		"rarity": "common"
	},
	"emp_burst": {
		"name": "EMP Burst",
		"description": "Stun nearby enemies every 15s",
		"icon_color": Color(0.5, 0.5, 1.0),
		"effects": {
			"emp_radius": 200.0,
			"emp_stun_duration": 2.0,
			"emp_cooldown": 15.0
		},
		"rarity": "epic"
	},
	"adaptive_armor": {
		"name": "Adaptive Plating",
		"description": "+25% Damage Reduction",
		"icon_color": Color(0.6, 0.6, 0.6),
		"effects": {
			"damage_reduction": 0.25
		},
		"rarity": "rare"
	}
}


func get_random_drone_upgrades(count: int) -> Array:
	"""Get random drone upgrades"""
	var available = drone_upgrades.keys()
	var selected = []

	# Shuffle and pick
	available.shuffle()

	for i in range(min(count, available.size())):
		var upgrade_id = available[i]
		var upgrade_data = drone_upgrades[upgrade_id].duplicate(true)
		upgrade_data["id"] = upgrade_id
		selected.append(upgrade_data)

	return selected


func get_upgrade(upgrade_id: String) -> Dictionary:
	"""Get specific upgrade data"""
	if drone_upgrades.has(upgrade_id):
		var data = drone_upgrades[upgrade_id].duplicate(true)
		data["id"] = upgrade_id
		return data
	return {}
