extends Node

# Ability System - Manages active abilities (Q,W,E,R)
# Autoload singleton inspired by MOBA games like League of Legends

# Ability data structure
class AbilityData:
	var id: String
	var name: String
	var description: String
	var keybind: String  # "Q", "W", "E", "R"
	var cooldown: float
	var mana_cost: int
	var ability_type: String  # "dash", "aoe_damage", "shield", etc.
	var parameters: Dictionary  # Custom parameters per ability

	func _init(p_id: String, p_name: String, p_desc: String, p_key: String, p_cd: float, p_mana: int, p_type: String, p_params: Dictionary):
		id = p_id
		name = p_name
		description = p_desc
		keybind = p_key
		cooldown = p_cd
		mana_cost = p_mana
		ability_type = p_type
		parameters = p_params

# Player ability slots (Q, W, E, R)
var ability_slots: Dictionary = {
	"Q": null,  # AbilityData or null
	"W": null,
	"E": null,
	"R": null
}

# Cooldown tracking
var ability_cooldowns: Dictionary = {
	"Q": 0.0,
	"W": 0.0,
	"E": 0.0,
	"R": 0.0
}

# Mana system
var current_mana: float = 100.0
var max_mana: int = 100
var mana_regen_rate: float = 5.0  # per second

# Active buff tracking (prevent stacking)
var active_buffs: Dictionary = {}  # buff_type -> is_active

# Signals
signal ability_used(slot: String)
signal ability_cooldown_started(slot: String, duration: float)
signal mana_changed(current: int, max_val: int)

# Available abilities database
var abilities_database: Array = []


func _ready() -> void:
	_initialize_abilities()
	# Equip default starter abilities (can be unlocked later through gameplay)
	equip_starter_abilities()


func _initialize_abilities() -> void:
	"""Initialize all available abilities"""

	# DASH ABILITY
	abilities_database.append(AbilityData.new(
		"dash",
		"Combat Roll",
		"Dash 200 units in movement direction (3s CD)",
		"Q",
		3.0,  # 3 second cooldown
		10,   # 10 mana cost
		"dash",
		{
			"distance": 200.0,
			"speed": 1000.0
		}
	))

	# AOE DAMAGE
	abilities_database.append(AbilityData.new(
		"shockwave",
		"Shockwave",
		"Deal 80 damage in 150 radius (8s CD)",
		"W",
		8.0,
		20,
		"aoe_damage",
		{
			"damage": 80,
			"radius": 150.0,
			"knockback": 50.0
		}
	))

	# SHIELD
	abilities_database.append(AbilityData.new(
		"energy_shield",
		"Energy Barrier",
		"Gain 100 shield for 5s (12s CD)",
		"E",
		12.0,
		15,
		"shield",
		{
			"shield_amount": 100,
			"duration": 5.0
		}
	))

	# TURRET SPAWN
	abilities_database.append(AbilityData.new(
		"auto_turret",
		"Deploy Turret",
		"Spawn turret that lasts 10s (15s CD)",
		"W",
		15.0,
		25,
		"spawn_turret",
		{
			"turret_damage": 30,
			"turret_range": 400.0,
			"duration": 10.0
		}
	))

	# HEAL
	abilities_database.append(AbilityData.new(
		"heal",
		"Nano-Repair",
		"Heal 60 HP instantly (10s CD)",
		"E",
		10.0,
		20,
		"heal",
		{
			"heal_amount": 60
		}
	))

	# RAGE MODE (ULTIMATE)
	abilities_database.append(AbilityData.new(
		"rage_mode",
		"Overdrive",
		"+100% Damage, +50% Speed for 8s (30s CD)",
		"R",
		30.0,
		50,
		"buff",
		{
			"damage_mult": 2.0,
			"speed_mult": 1.5,
			"duration": 8.0
		}
	))


func _process(delta: float) -> void:
	"""Update cooldowns and mana regen"""
	# Cooldowns
	for slot in ability_cooldowns.keys():
		if ability_cooldowns[slot] > 0:
			ability_cooldowns[slot] -= delta
			ability_cooldowns[slot] = max(0, ability_cooldowns[slot])

	# Mana regen
	if current_mana < max_mana:
		current_mana = min(current_mana + (mana_regen_rate * delta), max_mana)
		mana_changed.emit(int(current_mana), max_mana)

	# Safety: Ensure mana never goes negative
	if current_mana < 0:
		current_mana = 0.0
		mana_changed.emit(0, max_mana)


func equip_ability(ability_id: String, slot: String) -> bool:
	"""Equip an ability to a slot"""
	if not slot in ability_slots:
		return false

	var ability = get_ability_by_id(ability_id)
	if not ability:
		return false

	ability_slots[slot] = ability
	print("Equipped ", ability.name, " to slot ", slot)
	return true


func use_ability(slot: String, player: Node) -> bool:
	"""Use ability in slot"""
	if not slot in ability_slots:
		return false

	var ability = ability_slots[slot]
	if not ability:
		print("No ability in slot ", slot)
		return false

	# Check cooldown
	if ability_cooldowns[slot] > 0:
		print("Ability on cooldown: ", ability_cooldowns[slot], "s remaining")
		AudioManager.play_ability_cooldown_sound()  # NEIN sound
		return false

	# Check mana
	if int(current_mana) < ability.mana_cost:
		print("Not enough mana! Need ", ability.mana_cost, ", have ", int(current_mana))
		AudioManager.play_error_sound()  # Windows error
		return false

	# Special check for buffs - prevent using if already active
	if ability.ability_type == "buff":
		if active_buffs.get(ability.id, false):
			print("Buff already active! Cannot recast until it expires.")
			AudioManager.play_error_sound()
			return false

	# IMPORTANT: Set cooldown BEFORE executing ability to prevent spam
	ability_cooldowns[slot] = ability.cooldown
	ability_cooldown_started.emit(slot, ability.cooldown)

	# Deduct mana BEFORE executing ability
	current_mana = max(0.0, current_mana - ability.mana_cost)
	mana_changed.emit(int(current_mana), max_mana)

	# Emit signal
	ability_used.emit(slot)

	print("Used ability: ", ability.name)

	# Play ability cast sound (Quack)
	AudioManager.play_ability_sound()

	# Execute ability (async)
	_execute_ability(ability, player)

	return true


func _execute_ability(ability: AbilityData, player: Node) -> bool:
	"""Execute specific ability effect"""
	match ability.ability_type:
		"dash":
			await _execute_dash(ability, player)
			return true
		"aoe_damage":
			return _execute_aoe_damage(ability, player)
		"shield":
			await _execute_shield(ability, player)
			return true
		"spawn_turret":
			return _execute_spawn_turret(ability, player)
		"heal":
			await _execute_heal(ability, player)
			return true
		"buff":
			await _execute_buff(ability, player)
			return true

	return false


func _execute_dash(ability: AbilityData, player: Node) -> bool:
	"""Dash in direction"""
	var direction = Vector2.ZERO

	# Get input direction
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() == 0:
		# If no input, dash forward (use last velocity direction)
		if player.velocity.length() > 0:
			direction = player.velocity.normalized()
		else:
			return false  # No direction to dash

	direction = direction.normalized()

	# Perform dash
	var distance = ability.parameters.get("distance", 200.0)
	var target_pos = player.global_position + direction * distance

	# Clamp to arena bounds
	target_pos.x = clamp(target_pos.x, 50, 1230)
	target_pos.y = clamp(target_pos.y, 50, 670)

	# Dash animation (tween)
	var tween = player.create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.2)

	# Visual effect
	player.modulate = Color(0.5, 0.5, 2.0)
	await player.get_tree().create_timer(0.2).timeout
	if is_instance_valid(player):
		player.modulate = Color.WHITE

	return true


func _execute_aoe_damage(ability: AbilityData, player: Node) -> bool:
	"""Deal AoE damage"""
	var damage = ability.parameters.get("damage", 80)
	var radius = ability.parameters.get("radius", 150.0)

	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var hit_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist = player.global_position.distance_to(enemy.global_position)
		if dist <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			hit_count += 1

	# Visual effect (explosion)
	_create_explosion_effect(player.global_position, radius)

	print("AoE hit ", hit_count, " enemies!")
	return true


func _create_explosion_effect(position: Vector2, radius: float) -> void:
	"""Create visual explosion effect"""
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if not game_scene:
		return

	# Create explosion circle
	var explosion = ColorRect.new()
	explosion.size = Vector2(radius * 2, radius * 2)
	explosion.position = position - Vector2(radius, radius)
	explosion.color = Color(1, 0.5, 0, 0.6)
	explosion.z_index = 100
	game_scene.add_child(explosion)

	# Fade out
	var tween = explosion.create_tween()
	tween.tween_property(explosion, "modulate:a", 0.0, 0.5)
	tween.tween_callback(explosion.queue_free)


func _execute_shield(ability: AbilityData, player: Node) -> bool:
	"""Grant shield"""
	var shield_amount = ability.parameters.get("shield_amount", 100)

	if player.has_method("add_shield"):
		player.add_shield(shield_amount)
	else:
		player.shield_hp += shield_amount

	# Visual effect
	player.modulate = Color(0.5, 0.5, 1.5)
	await player.get_tree().create_timer(0.3).timeout
	if is_instance_valid(player):
		player.modulate = Color.WHITE

	print("Shield granted: +", shield_amount, " HP")
	return true


func _execute_spawn_turret(ability: AbilityData, player: Node) -> bool:
	"""Spawn temporary turret"""
	var turret_scene = preload("res://scenes/AutoTurret.tscn")
	var turret = turret_scene.instantiate()

	# Set position at player location
	turret.global_position = player.global_position

	# Override turret properties with ability parameters
	turret.damage = ability.parameters.get("turret_damage", 30)
	turret.detection_radius = ability.parameters.get("turret_range", 400.0)
	turret.lifetime = ability.parameters.get("duration", 10.0)

	# Add turret to game scene
	var game_scene = player.get_tree().get_first_node_in_group("game_scene")
	if game_scene:
		game_scene.add_child(turret)
		print("Auto-Turret deployed! (", turret.lifetime, "s)")
		return true

	return false


func _execute_heal(ability: AbilityData, player: Node) -> bool:
	"""Heal player"""
	var heal_amount = ability.parameters.get("heal_amount", 60)

	if player.has_method("heal"):
		player.heal(heal_amount)

		# Visual effect
		player.modulate = Color(0.5, 1.5, 0.5)
		await player.get_tree().create_timer(0.3).timeout
		if is_instance_valid(player):
			player.modulate = Color.WHITE

		return true

	return false


func _execute_buff(ability: AbilityData, player: Node) -> bool:
	"""Apply buff to player"""
	# Prevent stacking - if buff is already active, don't apply again
	var buff_id = ability.id
	if active_buffs.get(buff_id, false):
		print("Buff already active: ", ability.name, " - Stacking prevented!")
		return false

	var damage_mult = ability.parameters.get("damage_mult", 2.0)
	var speed_mult = ability.parameters.get("speed_mult", 1.5)
	var duration = ability.parameters.get("duration", 8.0)

	# Mark buff as active
	active_buffs[buff_id] = true

	# Store original values (from base_speed if available)
	var original_damage = player.melee_damage
	var original_speed = player.base_speed if player.get("base_speed") != null else player.speed

	# Apply buff
	player.melee_damage = int(original_damage * damage_mult)
	player.speed = original_speed * speed_mult
	player.modulate = Color(2.0, 0.5, 0.5)  # Red glow

	print("OVERDRIVE ACTIVATED! +", int((damage_mult - 1) * 100), "% Damage, +", int((speed_mult - 1) * 100), "% Speed")

	# Remove buff after duration
	await player.get_tree().create_timer(duration).timeout

	if is_instance_valid(player):
		player.melee_damage = original_damage
		player.speed = original_speed
		player.modulate = Color.WHITE
		active_buffs[buff_id] = false  # Mark as inactive
		print("Overdrive ended")

	return true


func get_ability_by_id(id: String) -> AbilityData:
	"""Get ability by ID"""
	for ability in abilities_database:
		if ability.id == id:
			return ability
	return null


func get_cooldown_percent(slot: String) -> float:
	"""Get cooldown as percentage (0-1)"""
	var ability = ability_slots[slot]
	if not ability:
		return 0.0

	var remaining = ability_cooldowns[slot]
	if remaining <= 0:
		return 0.0

	return remaining / ability.cooldown


func get_cooldown_remaining(slot: String) -> float:
	"""Get remaining cooldown in seconds"""
	return ability_cooldowns[slot]


func equip_starter_abilities() -> void:
	"""Equip default starter abilities for new players"""
	# Q - Combat Roll (Dash)
	equip_ability("dash", "Q")

	# E - Energy Shield
	equip_ability("energy_shield", "E")

	# R - Overdrive (Ultimate)
	equip_ability("rage_mode", "R")

	print("Starter abilities equipped: Q-Dash, E-Shield, R-Overdrive")
