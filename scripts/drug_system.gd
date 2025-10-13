extends Node

# Signal for drug effects
signal drug_effect_started(drug_id: String, is_positive: bool)
signal drug_effect_ended(drug_id: String)
signal side_effect_triggered(drug_id: String)
signal addiction_status_changed(is_addicted: bool)

# Active drug effects
var active_effects: Array = []

# Drug definitions
var drugs = {
	"adrenaline_shot": {
		"name": "Adrenaline Shot",
		"positive_duration": 30.0,
		"side_effect_chance": 0.30,
		"positive_effects": {
			"speed_multiplier": 1.5,
			"attack_speed_multiplier": 1.3
		},
		"negative_effects": {
			"max_hp_penalty": 20  # Permanent -20 HP
		}
	},
	"neural_enhancer": {
		"name": "Neural Enhancer",
		"positive_duration": 45.0,
		"side_effect_chance": 0.40,
		"positive_effects": {
			"damage_multiplier": 2.0
		},
		"negative_effects": {
			"inverted_controls": true,
			"invert_duration": 60.0
		}
	},
	"stim_pack": {
		"name": "Stim-Pack",
		"positive_duration": 20.0,
		"side_effect_chance": 0.25,
		"positive_effects": {
			"heal_full": true,
			"hp_regen_temp": 3.0
		},
		"negative_effects": {
			"shield_penalty": 50  # Lose 50 shield HP
		}
	},
	"rage_serum": {
		"name": "Rage Serum",
		"positive_duration": 60.0,
		"side_effect_chance": 0.50,
		"positive_effects": {
			"damage_multiplier": 3.0,
			"speed_multiplier": 1.5
		},
		"negative_effects": {
			"screen_shake": true,
			"vision_penalty": 0.5  # -50% vision
		}
	},
	"overdrive_chip": {
		"name": "Overdrive Chip",
		"positive_duration": 45.0,
		"side_effect_chance": 0.60,
		"positive_effects": {
			"weapon_fire_rate_multiplier": 3.0
		},
		"negative_effects": {
			"addiction_damage": 5.0  # 5 HP/s loss when effect ends
		}
	}
}


func consume_drug(drug_id: String, player: Node) -> void:
	"""Consume a drug with chance of side effects"""
	if not drugs.has(drug_id):
		print("Unknown drug: ", drug_id)
		return

	var drug = drugs[drug_id]

	# Increment drug use counter
	SaveManager.increment_drug_uses()

	# Roll for side effect
	var has_side_effect = randf() < drug.side_effect_chance

	# Apply positive effects
	_apply_positive_effects(drug_id, drug, player)

	# Apply side effects if triggered
	if has_side_effect:
		_apply_side_effects(drug_id, drug, player)
		side_effect_triggered.emit(drug_id)
		print("Side effect triggered for ", drug.name, "!")
	else:
		print("No side effect - lucky!")

	# Check addiction status
	var addiction = SaveManager.get_addiction_status()
	if addiction.is_addicted:
		addiction_status_changed.emit(true)

	drug_effect_started.emit(drug_id, not has_side_effect)


func _apply_positive_effects(drug_id: String, drug: Dictionary, player: Node) -> void:
	"""Apply positive temporary effects"""
	var duration = drug.positive_duration
	var effects = drug.positive_effects

	# Store original values for restoration
	var effect_data = {
		"drug_id": drug_id,
		"duration": duration,
		"timer": 0.0,
		"player": player,
		"original_values": {},
		"temp_values": effects.duplicate()
	}

	# Apply each effect
	for effect_name in effects:
		var value = effects[effect_name]

		match effect_name:
			"speed_multiplier":
				effect_data.original_values["speed"] = player.speed
				player.speed *= value
			"attack_speed_multiplier":
				effect_data.original_values["melee_interval"] = player.melee_interval
				player.melee_interval /= value
			"damage_multiplier":
				effect_data.original_values["melee_damage"] = player.melee_damage
				player.melee_damage = int(player.melee_damage * value)
			"heal_full":
				player.current_health = player.max_health
				player.health_changed.emit(player.current_health)
			"hp_regen_temp":
				effect_data.original_values["hp_regen"] = player.hp_regen_rate
				player.hp_regen_rate += value
			"weapon_fire_rate_multiplier":
				# Store original fire rates
				effect_data.original_values["weapon_fire_rates"] = player.weapon_fire_rates.duplicate()
				for weapon in player.weapon_fire_rates:
					player.weapon_fire_rates[weapon] /= value

	active_effects.append(effect_data)
	print("Applied positive effects for ", drug.name)


func _apply_side_effects(drug_id: String, drug: Dictionary, player: Node) -> void:
	"""Apply negative permanent or temporary effects"""
	if not is_instance_valid(player):
		return

	var effects = drug.negative_effects

	for effect_name in effects:
		var value = effects[effect_name]

		match effect_name:
			"max_hp_penalty":
				if not is_instance_valid(player):
					continue
				player.max_health -= value
				player.current_health = min(player.current_health, player.max_health)
				player.health_changed.emit(player.current_health)
				print("Permanent -", value, " Max HP!")

			"shield_penalty":
				if not is_instance_valid(player):
					continue
				player.shield_hp = max(0, player.shield_hp - value)
				print("Lost ", value, " shield HP!")

			"inverted_controls":
				# Store inversion status
				if not is_instance_valid(player):
					continue
				player.set_meta("controls_inverted", true)
				var invert_duration = effects.get("invert_duration", 60.0)

				# Create timer to restore
				await get_tree().create_timer(invert_duration).timeout
				if is_instance_valid(player):
					player.set_meta("controls_inverted", false)
					print("Controls restored to normal")

			"addiction_damage":
				# Apply damage over time when effect ends
				if not is_instance_valid(player):
					continue
				player.set_meta("addiction_damage_pending", value)


func _physics_process(delta: float) -> void:
	"""Update active drug effects"""
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		effect.timer += delta

		if effect.timer >= effect.duration:
			_end_drug_effect(effect)
			active_effects.remove_at(i)


func _end_drug_effect(effect: Dictionary) -> void:
	"""End a drug effect and restore original values"""
	var player = effect.player

	# Check if player still exists
	if not is_instance_valid(player):
		return

	# Restore original values
	for stat_name in effect.original_values:
		if not is_instance_valid(player):
			return

		var original_value = effect.original_values[stat_name]

		match stat_name:
			"speed":
				player.speed = original_value
			"melee_interval":
				player.melee_interval = original_value
			"melee_damage":
				player.melee_damage = original_value
			"hp_regen":
				player.hp_regen_rate = original_value
			"weapon_fire_rates":
				player.weapon_fire_rates = original_value

	# Handle addiction damage
	if is_instance_valid(player) and player.has_meta("addiction_damage_pending"):
		var damage_per_sec = player.get_meta("addiction_damage_pending")
		_apply_withdrawal_damage(player, damage_per_sec)
		player.remove_meta("addiction_damage_pending")

	drug_effect_ended.emit(effect.drug_id)
	print("Drug effect ended for ", effect.drug_id)


func _apply_withdrawal_damage(player: Node, damage_per_sec: float) -> void:
	"""Apply withdrawal damage over time"""
	print("Withdrawal symptoms! Losing ", damage_per_sec, " HP/s for 10 seconds")

	for i in range(10):
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(player) or player.is_queued_for_deletion():
			break
		if not GameManager.is_game_over:
			player.take_damage(int(damage_per_sec))


func is_addicted() -> bool:
	"""Check if player is addicted"""
	return SaveManager.get_addiction_status().is_addicted


func cure_addiction(player: Node) -> void:
	"""Cure addiction (via Detox Kit)"""
	SaveManager.cure_addiction()
	addiction_status_changed.emit(false)
	print("Addiction cured!")


func get_active_drug_count() -> int:
	"""Get number of active drug effects"""
	return active_effects.size()
