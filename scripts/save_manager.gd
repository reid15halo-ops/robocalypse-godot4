extends Node

# Save file path
const SAVE_PATH = "user://roboclaust_save.json"
const SAVE_VERSION = "1.0"

# Default save data structure
var default_save_data = {
	"version": SAVE_VERSION,
	"scrap": 0,
	"selected_character": "hacker",  # Currently selected character
	"meta_upgrades": {
		"max_hp_level": 0,
		"speed_level": 0,
		"damage_level": 0,
		"scrap_gain_level": 0
	},
	"unlocked_items": [],
	"unlocked_characters": ["hacker"],  # Hacker is default
	"stats": {
		"total_kills": 0,
		"highest_wave": 0,
		"total_runs": 0,
		"total_scrap_earned": 0
	},
	"addiction": {
		"is_addicted": false,
		"drug_uses": 0,
		"detoxed_count": 0
	}
}

# Current save data
var save_data: Dictionary = {}


func _ready() -> void:
	load_game()


func load_game() -> void:
	"""Load save data from file"""
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, creating new save")
		save_data = default_save_data.duplicate(true)
		save_game()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("Error opening save file")
		save_data = default_save_data.duplicate(true)
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		print("Error parsing save file")
		save_data = default_save_data.duplicate(true)
		return

	save_data = json.data

	# Validate version
	if save_data.get("version", "") != SAVE_VERSION:
		print("Save version mismatch, using defaults")
		save_data = default_save_data.duplicate(true)
		return

	print("Save loaded successfully")
	print("Scrap: ", save_data.scrap)


func save_game() -> void:
	"""Save data to file"""
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("Error creating save file")
		return

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print("Game saved successfully")


func reset_save() -> void:
	"""Reset save to defaults (for debugging)"""
	save_data = default_save_data.duplicate(true)
	save_game()
	print("Save reset to defaults")


# Scrap functions
func get_scrap() -> int:
	return save_data.get("scrap", 0)


func add_scrap(amount: int) -> void:
	save_data.scrap += amount
	save_data.stats.total_scrap_earned += amount
	save_game()
	print("Added ", amount, " scrap. Total: ", save_data.scrap)


func spend_scrap(amount: int) -> bool:
	if save_data.scrap >= amount:
		save_data.scrap -= amount
		save_game()
		return true
	return false


# Meta upgrade functions
func get_upgrade_level(upgrade_name: String) -> int:
	return save_data.meta_upgrades.get(upgrade_name, 0)


func purchase_upgrade(upgrade_name: String) -> bool:
	"""Increment upgrade level (cost handled externally)"""
	if save_data.meta_upgrades.has(upgrade_name):
		save_data.meta_upgrades[upgrade_name] += 1
		save_game()
		return true
	return false


# Unlock functions
func is_item_unlocked(item_id: String) -> bool:
	return item_id in save_data.unlocked_items


func unlock_item(item_id: String) -> void:
	if not is_item_unlocked(item_id):
		save_data.unlocked_items.append(item_id)
		save_game()


func is_character_unlocked(character_name: String) -> bool:
	return character_name in save_data.unlocked_characters


func unlock_character(character_name: String) -> void:
	if not is_character_unlocked(character_name):
		save_data.unlocked_characters.append(character_name)
		save_game()


# Stats functions
func update_stats(kills: int, wave: int) -> void:
	save_data.stats.total_kills += kills
	save_data.stats.total_runs += 1

	if wave > save_data.stats.highest_wave:
		save_data.stats.highest_wave = wave

	save_game()


func get_stat(stat_name: String) -> int:
	return save_data.stats.get(stat_name, 0)


# Addiction functions
func get_addiction_status() -> Dictionary:
	return save_data.addiction


func increment_drug_uses() -> void:
	save_data.addiction.drug_uses += 1

	# Become addicted after 3 uses
	if save_data.addiction.drug_uses >= 3:
		save_data.addiction.is_addicted = true

	save_game()


func cure_addiction() -> void:
	save_data.addiction.is_addicted = false
	save_data.addiction.drug_uses = 0
	save_data.addiction.detoxed_count += 1
	save_game()


# Character selection functions
func get_selected_character() -> String:
	return save_data.get("selected_character", "hacker")


func set_selected_character(character_id: String) -> void:
	save_data.selected_character = character_id
	save_game()
