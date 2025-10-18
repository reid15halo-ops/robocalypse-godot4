extends Node

## MinibossSpawner - Pre-transition Boss Encounters
## Spawns special minibosses before route selection with route-specific rewards

# ============================================================================
# SIGNALS
# ============================================================================

signal miniboss_spawned(miniboss: CharacterBody2D)
signal miniboss_defeated(route_type: int)

# ============================================================================
# MINIBOSS TYPES
# ============================================================================

enum MinibossType {
	ELITE_DRONE,      # Green route - Fast, aerial combat
	STORM_TITAN,      # Yellow route - Electric AoE attacks
	CHAOS_WARFRAME    # Red route - High HP, explosive abilities
}

# ============================================================================
# STATE
# ============================================================================

var current_miniboss: CharacterBody2D = null
var is_miniboss_defeated: bool = false
var miniboss_type: int = MinibossType.ELITE_DRONE

# References
var game_scene: Node2D = null
var player: CharacterBody2D = null
var miniboss_scene = preload("res://scenes/Enemy.tscn")  # Will customize


# ============================================================================
# INITIALIZATION
# ============================================================================

func initialize(p_game_scene: Node2D, p_player: CharacterBody2D) -> void:
	"""Initialize miniboss spawner"""
	game_scene = p_game_scene
	player = p_player
	print("MinibossSpawner initialized")


# ============================================================================
# MINIBOSS SPAWNING
# ============================================================================

func spawn_miniboss(wave_number: int) -> void:
	return
	"""Spawn miniboss based on wave number"""
	is_miniboss_defeated = false

	# Show warning
	await _show_warning()

	# Determine miniboss type (cycles through types)
	var type_index: int = int(((wave_number - 3) / 3.0)) % 3  # Waves 3,6,9 -> 0,1,2
	miniboss_type = type_index

	# Create miniboss
	current_miniboss = _create_miniboss(miniboss_type, wave_number)

	# Spawn position (400px from player)
	var spawn_angle = randf() * TAU
	var spawn_offset = Vector2(cos(spawn_angle), sin(spawn_angle)) * 400.0
	current_miniboss.global_position = player.global_position + spawn_offset

	# Add to scene
	game_scene.add_child(current_miniboss)

	# Monitor miniboss health in _process loop instead of tree_exiting signal
	# (tree_exiting doesn't fire for pooled enemies!)
	# Health monitoring will be done in wait_for_miniboss_defeat()

	# Update UI health bar
	_setup_health_bar()

	miniboss_spawned.emit(current_miniboss)

	print("Miniboss spawned: ", MinibossType.keys()[miniboss_type])


func _show_warning() -> void:
	"""Show miniboss warning with countdown"""
	print("⚠️ MINIBOSS INCOMING!")

	# Create warning overlay
	var ui = game_scene.get_node("UI")
	var warning = Label.new()
	warning.name = "MinibossWarning"
	warning.text = "⚠️ MINIBOSS INCOMING!"
	warning.add_theme_font_size_override("font_size", 48)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Position center screen
	warning.anchor_left = 0.0
	warning.anchor_top = 0.3
	warning.anchor_right = 1.0
	warning.anchor_bottom = 0.4
	warning.z_index = 100

	ui.add_child(warning)

	# Countdown
	for i in range(3, 0, -1):
		warning.text = "⚠️ MINIBOSS INCOMING! " + str(i) + "..."

		# Screen shake effect (modify player camera if exists)
		_screen_shake()

		await game_scene.get_tree().create_timer(1.0).timeout

	warning.queue_free()


func _screen_shake() -> void:
	"""Create screen shake effect"""
	# Simple visual shake by modifying UI position
	var ui = game_scene.get_node("UI")
	if ui is CanvasLayer:
		# Cannot move CanvasLayer; move the warning label instead if present
		var warning := ui.get_node_or_null("MinibossWarning")
		if warning and warning is Control:
			var original: Vector2 = warning.position
			for i in range(5):
				warning.position = original + Vector2(randf_range(-5, 5), randf_range(-5, 5))
				await game_scene.get_tree().create_timer(0.05).timeout
			if is_instance_valid(warning):
				warning.position = original
		return

	var original_pos := Vector2.ZERO
	if ui is Node2D:
		original_pos = ui.position
	else:
		return

	for i in range(5):
		ui.position = original_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		await game_scene.get_tree().create_timer(0.05).timeout

	ui.position = original_pos


func _create_miniboss(type: int, wave_number: int) -> CharacterBody2D:
	"""Create miniboss of specific type"""
	var miniboss = miniboss_scene.instantiate()

	# Base scaling
	var base_hp: float = 300.0 * (wave_number / 3.0)  # 300, 600, 900 for waves 3, 6, 9

	match type:
		MinibossType.ELITE_DRONE:
			_setup_elite_drone(miniboss, base_hp)
		MinibossType.STORM_TITAN:
			_setup_storm_titan(miniboss, base_hp)
		MinibossType.CHAOS_WARFRAME:
			_setup_chaos_warframe(miniboss, base_hp)

	# Mark as miniboss
	miniboss.add_to_group("miniboss")
	miniboss.set_meta("is_miniboss", true)
	miniboss.set_meta("miniboss_type", type)

	return miniboss


func _setup_elite_drone(miniboss: CharacterBody2D, base_hp: int) -> void:
	"""Configure Elite Drone miniboss (Green route)"""
	miniboss.max_health = int(base_hp * 3)  # 900 HP at wave 3
	miniboss.current_health = miniboss.max_health
	miniboss.min_speed = 180.0
	miniboss.max_speed = 200.0
	miniboss.current_speed = 190.0
	miniboss.enemy_color = Color(0.2, 1.0, 0.3)  # Bright green
	miniboss.enemy_size = 1.8
	miniboss.score_value = 200

	# Special attacks
	miniboss.set_meta("dash_attack", true)
	miniboss.set_meta("aerial_spin", true)


func _setup_storm_titan(miniboss: CharacterBody2D, base_hp: int) -> void:
	"""Configure Storm Titan miniboss (Yellow route)"""
	miniboss.max_health = int(base_hp * 4)  # 1200 HP at wave 3
	miniboss.current_health = miniboss.max_health
	miniboss.min_speed = 100.0
	miniboss.max_speed = 120.0
	miniboss.current_speed = 110.0
	miniboss.enemy_color = Color(1.0, 0.9, 0.0)  # Bright yellow
	miniboss.enemy_size = 2.0
	miniboss.score_value = 250

	# Special attacks
	miniboss.set_meta("lightning_chain", true)
	miniboss.set_meta("static_aura", true)


func _setup_chaos_warframe(miniboss: CharacterBody2D, base_hp: int) -> void:
	"""Configure Chaos Warframe miniboss (Red route)"""
	miniboss.max_health = int(base_hp * 5)  # 1500 HP at wave 3
	miniboss.current_health = miniboss.max_health
	miniboss.min_speed = 120.0
	miniboss.max_speed = 140.0
	miniboss.current_speed = 130.0
	miniboss.enemy_color = Color(1.0, 0.2, 0.2)  # Bright red
	miniboss.enemy_size = 2.2
	miniboss.score_value = 300

	# Special attacks
	miniboss.set_meta("emp_blast", true)
	miniboss.set_meta("missile_barrage", true)
	miniboss.set_meta("berserk_mode", true)


func _setup_health_bar() -> void:
	"""Setup miniboss health bar UI"""
	var ui = game_scene.get_node("UI")

	# Create health bar container
	var health_container = HBoxContainer.new()
	health_container.name = "MinibossHealthBar"
	health_container.anchor_left = 0.25
	health_container.anchor_top = 0.05
	health_container.anchor_right = 0.75
	health_container.anchor_bottom = 0.10

	# Miniboss name label
	var name_label = Label.new()
	name_label.name = "MinibossName"
	var type_names = ["⚡ ELITE DRONE", "⚡ STORM TITAN", "⚡ CHAOS WARFRAME"]
	name_label.text = type_names[miniboss_type]
	name_label.add_theme_font_size_override("font_size", 24)
	health_container.add_child(name_label)

	# Health bar
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.custom_minimum_size = Vector2(400, 30)
	health_bar.max_value = current_miniboss.max_health
	health_bar.value = current_miniboss.current_health
	health_bar.show_percentage = false
	health_container.add_child(health_bar)

	ui.add_child(health_container)


func update_health_bar() -> void:
	"""Update miniboss health bar"""
	if not is_instance_valid(current_miniboss):
		return

	var ui = game_scene.get_node("UI")
	var health_bar = ui.get_node_or_null("MinibossHealthBar/HealthBar")

	if health_bar:
		health_bar.value = current_miniboss.current_health


func remove_health_bar() -> void:
	"""Remove miniboss health bar"""
	var ui = game_scene.get_node("UI")
	var health_container = ui.get_node_or_null("MinibossHealthBar")

	if health_container:
		health_container.queue_free()


# ============================================================================
# MINIBOSS DEFEAT HANDLING
# ============================================================================

func _on_miniboss_died() -> void:
	"""Handle miniboss death"""
	if is_miniboss_defeated:
		return  # Already handled

	is_miniboss_defeated = true
	print("Miniboss defeated!")

	# Remove health bar
	remove_health_bar()

	# Drop rewards
	var drop_position := player.global_position
	if current_miniboss and is_instance_valid(current_miniboss):
		drop_position = current_miniboss.global_position
	await _drop_rewards(drop_position)

	# Emit signal
	miniboss_defeated.emit(miniboss_type)


func _drop_rewards(drop_position: Vector2) -> void:
	"""Drop route-specific rewards"""
	var rewards = _get_miniboss_rewards(miniboss_type)

	# Award scrap
	var scrap_amount = rewards.scrap
	if game_scene:
		if scrap_amount > 0 and game_scene.has_method("spawn_scrap_pickups"):
			game_scene.spawn_scrap_pickups(drop_position, scrap_amount)
		elif scrap_amount > 0 and game_scene.has_method("add_scrap"):
			game_scene.add_scrap(scrap_amount)

	# Show reward notification
	_show_reward_notification(rewards)

	# Apply rewards to player
	await game_scene.get_tree().create_timer(1.0).timeout

	# Grant guaranteed item
	if rewards.guaranteed_item:
		var item = ItemDatabase.get_item_by_id(rewards.guaranteed_item)
		if item:
			game_scene.call("_apply_item_effects", item)

	print("Miniboss rewards granted!")


func _get_miniboss_rewards(type: int) -> Dictionary:
	"""Get rewards based on miniboss type"""
	match type:
		MinibossType.ELITE_DRONE:
			return _green_route_loot()
		MinibossType.STORM_TITAN:
			return _yellow_route_loot()
		MinibossType.CHAOS_WARFRAME:
			return _red_route_loot()
		_:
			return {"scrap": 50, "guaranteed_item": null}


func _green_route_loot() -> Dictionary:
	"""Green route loot table (healing, mobility)"""
	var guaranteed_items = ["hp_regen", "max_hp_boost", "stim_pack"]
	var random_item = guaranteed_items[randi() % guaranteed_items.size()]

	return {
		"scrap": 50,
		"guaranteed_item": random_item,
		"description": "Healing Item + 50 Scrap"
	}


func _yellow_route_loot() -> Dictionary:
	"""Yellow route loot table (balanced mix)"""
	var guaranteed_items = ["laser_gun", "energy_shield", "ability_dash"]
	var random_item = guaranteed_items[randi() % guaranteed_items.size()]

	# 30% chance for rare upgrade
	var bonus_scrap = 0
	if randf() < 0.3:
		bonus_scrap = 25

	return {
		"scrap": 75 + bonus_scrap,
		"guaranteed_item": random_item,
		"description": "Balanced Loot + 75 Scrap"
	}


func _red_route_loot() -> Dictionary:
	"""Red route loot table (weapons, drugs, rare items)"""
	var guaranteed_items = ["rage_serum", "overdrive_chip", "weapon_upgrade", "berserker_rage"]
	var random_item = guaranteed_items[randi() % guaranteed_items.size()]

	# 20% chance for epic upgrade
	var bonus_scrap = 0
	if randf() < 0.2:
		bonus_scrap = 50

	return {
		"scrap": 100 + bonus_scrap,
		"guaranteed_item": random_item,
		"description": "Rare Weapon/Drug + 100 Scrap"
	}


func _show_reward_notification(rewards: Dictionary) -> void:
	"""Show reward notification"""
	var ui = game_scene.get_node("UI")

	var reward_label = Label.new()
	reward_label.name = "RewardNotification"
	reward_label.text = "MINIBOSS REWARDS: " + rewards.description
	reward_label.add_theme_font_size_override("font_size", 32)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Position center screen
	reward_label.anchor_left = 0.0
	reward_label.anchor_top = 0.4
	reward_label.anchor_right = 1.0
	reward_label.anchor_bottom = 0.5
	reward_label.z_index = 100

	ui.add_child(reward_label)

	# Fade out after 2s
	await game_scene.get_tree().create_timer(2.0).timeout
	if is_instance_valid(reward_label):
		reward_label.queue_free()


# ============================================================================
# UTILITY
# ============================================================================

func is_miniboss_active() -> bool:
	"""Check if miniboss is currently active"""
	if not is_instance_valid(current_miniboss):
		return false

	# Pooled enemies are deactivated when they die (not freed)
	# Check if visible and processing to determine if still active
	if current_miniboss.get_meta("is_pooled", false):
		return current_miniboss.visible and current_miniboss.process_mode != Node.PROCESS_MODE_DISABLED

	return not is_miniboss_defeated


func wait_for_miniboss_defeat() -> void:
	"""Wait until miniboss is defeated"""
	var timeout: float = 180.0  # 3 minute timeout
	var elapsed: float = 0.0

	while is_miniboss_active() and elapsed < timeout:
		# Update health bar while miniboss is alive
		update_health_bar()

		await game_scene.get_tree().create_timer(0.1).timeout
		elapsed += 0.1

	# Check for timeout
	if elapsed >= timeout:
		print("WARNING: Miniboss wait timeout reached! Forcing defeat...")
		is_miniboss_defeated = true

	# Miniboss defeated - trigger cleanup
	if not is_miniboss_defeated:
		_on_miniboss_died()
