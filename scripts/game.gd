extends Node2D

# Preload scenes
var enemy_scene = preload("res://scenes/Enemy.tscn")
var boss_scene = preload("res://scenes/BossEnemy.tscn")
var drone_scene = preload("res://scenes/SupportDrone.tscn")
var scrap_pickup_scene = preload("res://scenes/ScrapPickup.tscn")
var player_scene: PackedScene = preload("res://scenes/Player.tscn")

# Spawning
@export var spawn_interval: float = 2.0
@export var spawn_distance: float = 700.0
var spawn_timer: float = 0.0

# Wave system
@export var wave_duration: float = 60.0  # 60 seconds per wave
var current_wave: int = 1
var wave_timer: float = 0.0
var in_wave_break: bool = false

# Difficulty scaling
var time_elapsed: float = 0.0
var difficulty_multiplier: float = 1.0

# Console system for Hacker character
var console_scene = preload("res://scenes/HackerConsole.tscn")
var active_consoles: Array = []
var console_spawned: bool = false

# Scrap tracking
const SCRAP_CHUNK_MIN: int = 5
const SCRAP_CHUNK_MAX: int = 15
const SCRAP_SCATTER_RADIUS: float = 60.0
var scrap_earned_this_run: int = 0
var kills_this_run: int = 0
var scrap_container: Node2D = null

# Enemy Pooling for performance
const ENEMY_POOL_SIZE: int = 30
var enemy_pool: Array[CharacterBody2D] = []
var active_enemies: Array[CharacterBody2D] = []

# References
var player: CharacterBody2D = null
@onready var ui = $UI
@onready var health_bar = $UI/HealthBar
@onready var shield_bar = $UI/ShieldBar
@onready var score_label = $UI/ScoreLabel
@onready var wave_label = $UI/WaveLabel
@onready var wave_timer_label = $UI/WaveTimerLabel
@onready var scrap_label = $UI/ScrapLabel  # New scrap display
@onready var pause_menu = $UI/PauseMenu
@onready var wave_complete_screen = $UI/WaveCompleteScreen
@onready var game_over_screen = $UI/GameOverScreen
@onready var route_selection_screen = $UI/RouteSelection
@onready var drone_panel = $UI/DronePanel
@onready var drone_level_label = $UI/DronePanel/VBoxContainer/DroneLevelLabel
@onready var drone_health_bar = $UI/DronePanel/VBoxContainer/DroneHealthBar
@onready var drone_xp_bar = $UI/DronePanel/VBoxContainer/DroneXPBar
@onready var drone_xp_label = $UI/DronePanel/VBoxContainer/DroneXPLabel
@onready var mode_label = $UI/DronePanel/VBoxContainer/ModeLabel

# Route selection helpers
var route_selection_active: bool = false
var route_portal_container: Node2D = null

# Ability HUD (will be created dynamically)
var ability_hud: Control = null

# Affix Indicator (shows active route effects)
var affix_indicator: Control = null

# Admin/cheat overlay (optional, toggled at runtime)
var admin_tool: Control = null

# Affix Manager & Miniboss Spawner
var affix_manager: Node = null
var miniboss_spawner: Node = null
var map_generator: Node = null


func _ready() -> void:
	# Add to game_scene group for scrap tracking
	add_to_group("game_scene")
	active_consoles.clear()
	console_spawned = false

	var player_instance := player_scene.instantiate()
	var player_body := player_instance as CharacterBody2D
	if player_body == null:
		push_error("Failed to instance player scene")
		return
	else:
		player = player_body
		player.name = "Player"
		add_child(player)
		GameManager.set_player(player)

	# Generate procedural map
	map_generator = preload("res://scripts/MapGenerator.gd").new()
	map_generator.name = "MapGenerator"
	add_child(map_generator)
	map_generator.generate_map()

	# Container for scrap pickups
	scrap_container = Node2D.new()
	scrap_container.name = "ScrapDrops"
	add_child(scrap_container)

	# Position player at center spawn
	if player:
		player.global_position = map_generator.get_spawn_position()

	# Initialize Affix Manager
	affix_manager = preload("res://scripts/AffixManager.gd").new()
	affix_manager.name = "AffixManager"
	add_child(affix_manager)
	affix_manager.initialize(self, player)

	# Initialize Miniboss Spawner
	miniboss_spawner = preload("res://scripts/MinibossSpawner.gd").new()
	miniboss_spawner.name = "MinibossSpawner"
	add_child(miniboss_spawner)
	miniboss_spawner.initialize(self, player)

	# Connect MapSystem signals
	MapSystem.area_changed.connect(_on_area_changed)
	MapSystem.portal_appeared.connect(_on_portal_appeared)

	# Hide menus
	pause_menu.visible = false
	wave_complete_screen.visible = false
	game_over_screen.visible = false

	# Connect GameManager signals
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)

	# Connect player signals
	player.health_changed.connect(_on_player_health_changed)
	player.shield_changed.connect(_on_player_shield_changed)

	_configure_health_and_shield_bars()

	# Apply character stats first (base stats)
	CharacterSystem.apply_character_to_player(player)

	# Then apply meta upgrades (on top of character stats)
	MetaProgression.apply_meta_upgrades_to_player(player)

	# Add drone controller if playing as Hacker
	if CharacterSystem.current_character == "hacker":
		var drone_controller = preload("res://scripts/hacker_drone_controller.gd").new()
		drone_controller.name = "HackerDroneController"
		player.add_child(drone_controller)
		# Connect drone signals
		drone_controller.drone_spawned.connect(_on_drone_spawned)
		drone_controller.mode_switched.connect(_on_drone_mode_switched)

	# Initialize weapon progression (start with screwdriver)
	WeaponProgression.reset_weapon()
	WeaponProgression.apply_weapon_to_player(player)

	# Initialize UI
	_update_health_bar()
	_update_score_label()
	_update_wave_label()
	_update_wave_timer()
	_update_scrap_label()

	# Set process modes
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	wave_complete_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	route_selection_screen.process_mode = Node.PROCESS_MODE_ALWAYS

	# Create Ability HUD
	_create_ability_hud()

	# Create Affix Indicator
	_create_affix_indicator()

	# Attach admin tool overlay (cheat interface toggled with F1)
	var admin_tool_script = load("res://scripts/admin_tool.gd")
	if admin_tool_script:
		admin_tool = admin_tool_script.new()
		admin_tool.name = "AdminTool"
		ui.add_child(admin_tool)

	# Initialize enemy pool for better performance
	_initialize_enemy_pool()


func _initialize_enemy_pool() -> void:
	"""Pre-instantiate enemies for object pooling"""
	for i in range(ENEMY_POOL_SIZE):
		var enemy = enemy_scene.instantiate()
		enemy.visible = false
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.set_physics_process(false)
		enemy.set_meta("is_pooled", true)  # Mark as pooled enemy
		add_child(enemy)
		enemy_pool.append(enemy)
	print("Enemy pool initialized with ", ENEMY_POOL_SIZE, " enemies")


func _get_pooled_enemy() -> CharacterBody2D:
	"""Get an enemy from the pool or create new one if pool exhausted"""
	var enemy: CharacterBody2D = null

	# Keep trying to get a valid enemy from pool
	while enemy_pool.size() > 0:
		var candidate = enemy_pool.pop_back()
		if is_instance_valid(candidate):
			enemy = candidate
			break
		else:
			print("Warning: Found invalid enemy in pool, skipping")

	# If no valid enemy found in pool, create new one
	if enemy == null:
		enemy = enemy_scene.instantiate()
		enemy.set_meta("is_pooled", true)  # Mark as pooled
		add_child(enemy)
		print("Warning: Enemy pool exhausted, creating new enemy")

	# Reset enemy state
	enemy.current_health = enemy.max_health
	enemy.attack_cooldown = 0.0
	enemy.dash_cooldown = 0.0
	enemy.modulate = Color.WHITE

	# Clear any metadata that might persist (but keep is_pooled!)
	enemy.remove_meta("is_kamikaze")
	enemy.remove_meta("is_sniper")
	enemy.remove_meta("is_miniboss")

	# Reset and activate enemy
	enemy.visible = true
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	enemy.set_physics_process(true)
	active_enemies.append(enemy)

	return enemy


func _return_enemy_to_pool(enemy: CharacterBody2D) -> void:
	"""Return enemy to pool (called by enemy.gd die() function)"""
	if not is_instance_valid(enemy):
		print("Warning: Tried to return invalid enemy to pool")
		return

	# Remove from active list
	var idx = active_enemies.find(enemy)
	if idx >= 0:
		active_enemies.remove_at(idx)
	else:
		print("Warning: Enemy not found in active_enemies list")

	# Enemy should already be deactivated by die() function
	# Just add back to pool if space available
	if enemy_pool.size() < ENEMY_POOL_SIZE:
		enemy_pool.append(enemy)
	else:
		# Pool full - free the enemy
		enemy.set_meta("is_pooled", false)  # Unmark so it can be freed
		enemy.queue_free()
		print("Warning: Enemy pool full, freeing enemy")


func _process(delta: float) -> void:
	# Check for pause input
	if Input.is_action_just_pressed("pause") and not GameManager.is_game_over and not in_wave_break:
		GameManager.toggle_pause()
		pause_menu.visible = GameManager.is_paused
		return

	# Don't process game logic if paused, game over, or in wave break
	if GameManager.is_paused or GameManager.is_game_over or in_wave_break:
		return

	# Update timers
	time_elapsed += delta
	spawn_timer += delta
	wave_timer += delta

	# Update UI
	_update_wave_timer()
	_update_drone_ui()

	# Update affixes
	if affix_manager:
		affix_manager._process(delta)

	# Check for wave completion
	if wave_timer >= wave_duration:
		_complete_wave()
		return

	# Increase difficulty over time + area difficulty
	var area_difficulty = MapSystem.get_difficulty_multiplier()
	difficulty_multiplier = (1.0 + (time_elapsed / 60.0) * 0.5) * area_difficulty

	# Spawn enemies
	if spawn_timer >= spawn_interval / difficulty_multiplier:
		spawn_timer = 0.0
		spawn_enemy()


func _complete_wave() -> void:
	"""Handle wave completion and show item selection"""
	in_wave_break = true

	# Increment global wave counter
	GameManager.wave_count += 1

	# Check for route selection (every 3 waves)
	if GameManager.wave_count % 3 == 0:
		# SPAWN MINIBOSS FIRST - must be defeated before route selection
		if miniboss_spawner:
			miniboss_spawner.spawn_miniboss(GameManager.wave_count)
			await miniboss_spawner.wait_for_miniboss_defeat()

		# THEN show route selection
		_show_route_selection()
		return  # Skip normal wave completion flow

	# SLOW MOTION EFFECT
	TimeControl.activate_slow_motion(2.0)  # 2 seconds slow-mo

	# Wait for slow-mo to finish before showing screen
	await TimeControl.slow_motion_ended

	# Check if an objective should spawn
	if ObjectiveSystem.should_spawn_objective(current_wave):
		ObjectiveSystem.spawn_random_objective(self)

	# Notify MapSystem of wave completion (for portal spawning)
	MapSystem.complete_wave()

	# Spawn consoles for Hacker character
	if CharacterSystem.current_character == "hacker":
		_spawn_consoles()

	# NOW show wave complete screen
	wave_complete_screen.visible = true

	# Update wave complete label
	var wave_text = "WAVE " + str(current_wave) + " COMPLETE!"

	# Check if next wave is a boss wave (every 10 waves)
	var is_boss_wave = ((current_wave + 1) % 10) == 0
	if is_boss_wave:
		wave_text += "\n\nBOSS INCOMING!"

	$UI/WaveCompleteScreen/VBoxContainer/WaveCompleteLabel.text = wave_text

	# Get random items
	var random_items = ItemDatabase.get_random_items(3)

	# Clear previous items
	var items_container = $UI/WaveCompleteScreen/VBoxContainer/ItemsContainer
	for child in items_container.get_children():
		child.queue_free()

	# Create item buttons
	for item in random_items:
		var item_button = _create_item_button(item)
		items_container.add_child(item_button)


func _create_item_button(item) -> Button:
	"""Create a button for an item"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(180, 200)

	# Create VBox for item content
	var vbox = VBoxContainer.new()
	button.add_child(vbox)

	# Item icon - use sprite if available, fallback to color rect
	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.custom_minimum_size = Vector2(80, 80)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(icon)
	else:
		# Fallback to color indicator
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(160, 60)
		color_rect.color = item.icon_color
		vbox.add_child(color_rect)

	# Item name
	var name_label = Label.new()
	name_label.text = item.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Item description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(160, 0)
	vbox.add_child(desc_label)

	# Connect button press
	button.pressed.connect(_on_item_selected.bind(item))

	return button


func _on_item_selected(item) -> void:
	"""Handle item selection"""
	# Apply item effects to player
	_apply_item_effects(item)

	# Start next wave
	current_wave += 1
	wave_timer = 0.0
	in_wave_break = false
	wave_complete_screen.visible = false
	_update_wave_label()

	# Spawn boss if it's a boss wave (every 10 waves)
	if (current_wave % 10) == 0:
		_spawn_boss()


func _apply_item_effects(item) -> void:
	"""Apply item effects to the player"""
	for effect_name in item.effects:
		var effect_value = item.effects[effect_name]

		match effect_name:
			"speed_multiplier":
				player.speed *= effect_value
			"damage_multiplier":
				player.melee_damage = int(player.melee_damage * effect_value)
			"attack_speed_multiplier":
				player.melee_interval /= effect_value
			"max_hp_bonus":
				player.max_health += effect_value
				if item.effects.get("heal_full", false):
					player.current_health = player.max_health
					player.health_changed.emit(player.current_health)
			"shield":
				player.add_shield(effect_value)
			"damage_reduction":
				player.damage_reduction += effect_value
				player.damage_reduction = min(player.damage_reduction, 0.75)  # Cap at 75%
			"hp_regen":
				player.hp_regen_rate += effect_value
			"drone_type":
				_spawn_drone(effect_value)
			"weapon_type":
				player.add_weapon(effect_value)
			"drug_id":
				DrugSystem.consume_drug(effect_value, player)
			"spawn_drone":
				_spawn_hacker_drone()
			"drone_upgrade_id":
				_apply_drone_upgrade(effect_value)
			"upgrade_weapon":
				_upgrade_player_weapon()
			"extra_pets":
				# TODO: Implement extra pet system
				pass
			"unlock_ability":
				var ability_id = item.effects.get("unlock_ability", "")
				var slot = item.effects.get("ability_slot", "Q")
				if ability_id:
					AbilitySystem.equip_ability(ability_id, slot)
					print("Unlocked ability: ", ability_id, " on slot ", slot)
			"active_item":
				# Handle active items with special functions
				_activate_active_item(effect_value, item.effects)

	print("Applied item: ", item.name)


func admin_grant_item(item_id: String) -> bool:
	"""Grant an item directly to the player (cheat/admin helper)"""
	var item = ItemDatabase.get_item_by_id(item_id)
	if not item:
		print("AdminTool: Unknown item id ", item_id)
		return false

	_apply_item_effects(item)
	return true


func _spawn_drone(drone_type_name: String) -> void:
	"""Spawn a support drone"""
	var drone = drone_scene.instantiate()

	# Set drone type
	match drone_type_name:
		"attack":
			drone.drone_type = drone.DroneType.ATTACK
		"shield":
			drone.drone_type = drone.DroneType.SHIELD
		"repair":
			drone.drone_type = drone.DroneType.REPAIR
		"scanner":
			drone.drone_type = drone.DroneType.SCANNER

	# Position near player
	drone.global_position = player.global_position

	add_child(drone)


func spawn_enemy() -> void:
	"""Spawn an enemy at a fixed street spawn point"""
	var enemy = _create_random_enemy_type()

	# Get random spawn point on streets (fixed positions)
	var spawn_points = _get_street_spawn_points()
	if spawn_points.size() > 0:
		var spawn_pos = spawn_points[randi() % spawn_points.size()]
		enemy.global_position = spawn_pos
	else:
		# Fallback to old random spawning if no spawn points available
		var angle = randf() * TAU
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance
		enemy.global_position = spawn_pos


func _get_street_spawn_points() -> Array[Vector2]:
	"""Get list of fixed spawn points on the generated streets"""
	if map_generator and map_generator.has_method("get_spawn_points"):
		var generated: Array[Vector2] = map_generator.get_spawn_points()
		if generated.size() > 0:
			return generated

	# Fallback: compute default cross-street points
	var points: Array[Vector2] = []
	const CELL_SIZE = 128
	const GRID_WIDTH = 14
	const GRID_HEIGHT = 14

	for street_col in [4, 5, 9, 10]:
		for y in range(GRID_HEIGHT):
			if y not in [4, 5, 9, 10]:
				points.append(Vector2((street_col + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE))

	for street_row in [4, 5, 9, 10]:
		for x in range(GRID_WIDTH):
			if x not in [4, 5, 9, 10]:
				points.append(Vector2((x + 0.5) * CELL_SIZE, (street_row + 0.5) * CELL_SIZE))

	return points


func _create_random_enemy_type() -> CharacterBody2D:
	"""Create a random enemy type based on current wave"""
	var enemy = _get_pooled_enemy()

	# Wave-based spawn chances
	var wave = current_wave
	var roll = randf()

	# Early waves (1-5): Mostly standard, some fast
	if wave <= 5:
		if roll < 0.7:
			_setup_standard_drone(enemy)
		else:
			_setup_fast_drone(enemy)

	# Mid waves (6-15): Mixed with heavies
	elif wave <= 15:
		if roll < 0.4:
			_setup_standard_drone(enemy)
		elif roll < 0.7:
			_setup_fast_drone(enemy)
		elif roll < 0.9:
			_setup_heavy_drone(enemy)
		else:
			_setup_kamikaze_drone(enemy)

	# Late waves (16+): All types, more dangerous
	else:
		if roll < 0.25:
			_setup_standard_drone(enemy)
		elif roll < 0.45:
			_setup_fast_drone(enemy)
		elif roll < 0.65:
			_setup_heavy_drone(enemy)
		elif roll < 0.85:
			_setup_kamikaze_drone(enemy)
		else:
			_setup_sniper_drone(enemy)

	return enemy


func _setup_standard_drone(enemy: CharacterBody2D) -> void:
	"""Standard red drone - balanced"""
	enemy.enemy_color = Color(1.0, 0.2, 0.2)  # Red
	enemy.enemy_size = 1.0
	enemy.max_health = 100
	enemy.min_speed = 100.0
	enemy.max_speed = 150.0
	enemy.score_value = 10
	enemy.has_pulse_animation = true
	enemy.has_rotation_animation = true


func _setup_fast_drone(enemy: CharacterBody2D) -> void:
	"""Fast cyan drone - quick and fragile"""
	enemy.enemy_color = Color(0.2, 0.8, 1.0)  # Cyan
	enemy.enemy_size = 0.7
	enemy.max_health = 60
	enemy.min_speed = 200.0
	enemy.max_speed = 250.0
	enemy.score_value = 15
	enemy.has_pulse_animation = false
	enemy.has_rotation_animation = true


func _setup_heavy_drone(enemy: CharacterBody2D) -> void:
	"""Heavy brown drone - slow and tanky"""
	enemy.enemy_color = Color(0.6, 0.3, 0.2)  # Brown
	enemy.enemy_size = 1.5
	enemy.max_health = 300
	enemy.min_speed = 60.0
	enemy.max_speed = 80.0
	enemy.score_value = 25
	enemy.has_pulse_animation = true
	enemy.has_rotation_animation = false


func _setup_kamikaze_drone(enemy: CharacterBody2D) -> void:
	"""Kamikaze orange drone - explodes on contact"""
	enemy.enemy_color = Color(1.0, 0.6, 0.0)  # Orange
	enemy.enemy_size = 0.8
	enemy.max_health = 40
	enemy.min_speed = 180.0
	enemy.max_speed = 220.0
	enemy.score_value = 20
	enemy.has_pulse_animation = true
	enemy.has_rotation_animation = false
	enemy.set_meta("is_kamikaze", true)
	enemy.set_meta("explosion_damage", 80)
	enemy.set_meta("explosion_radius", 150.0)


func _setup_sniper_drone(enemy: CharacterBody2D) -> void:
	"""Sniper green drone - keeps distance"""
	enemy.enemy_color = Color(0.2, 0.8, 0.3)  # Green
	enemy.enemy_size = 1.0
	enemy.max_health = 80
	enemy.min_speed = 90.0
	enemy.max_speed = 110.0
	enemy.score_value = 30
	enemy.has_pulse_animation = false
	enemy.has_rotation_animation = true
	enemy.set_meta("is_sniper", true)
	enemy.set_meta("attack_range", 400.0)


func spawn_enemy_at_position(pos: Vector2) -> void:
	"""Spawn an enemy at a specific position (used by objectives)"""
	var enemy = _get_pooled_enemy()
	enemy.global_position = pos
	enemy.visible = true
	enemy.set_physics_process(true)
	enemy.set_process(true)


func _spawn_boss() -> void:
	"""Spawn a boss enemy"""
	var boss = boss_scene.instantiate()

	# Random angle around the player, further away than regular enemies
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * (spawn_distance + 200)

	boss.global_position = spawn_pos
	add_child(boss)
	print("Boss spawned for wave ", current_wave)

	# Play boss spawn sound
	AudioManager.play_boss_rage_sound()  # "Was ist geschehen?"


func _on_score_changed(_new_score: int) -> void:
	"""Update score label when score changes"""
	_update_score_label()


func _on_player_health_changed(_new_health: int) -> void:
	"""Update health bar when player health changes"""
	_update_health_bar()


func _on_game_over() -> void:
	"""Show game over screen"""
	_cleanup_route_portals()
	route_selection_active = false
	_set_enemies_frozen(false)

	game_over_screen.visible = true
	$UI/GameOverScreen/VBoxContainer/FinalScoreLabel.text = "Final Score: " + str(GameManager.score)

	# Play game over sound
	AudioManager.play_game_over_sound()  # Windows Shutdown

	# Award wave completion bonus scrap
	var wave_bonus = current_wave * 10
	add_scrap(wave_bonus)  # Wave bonus is not a kill

	# Save stats
	SaveManager.update_stats(kills_this_run, current_wave)
	print("Run complete - Earned ", scrap_earned_this_run, " scrap total")


func _update_health_bar() -> void:
	"""Update health bar display"""
	if player and health_bar:
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health

	_update_shield_bar()


func _update_shield_bar() -> void:
	if not shield_bar or not player:
		return

	shield_bar.max_value = player.max_health
	shield_bar.value = clamp(float(player.shield_hp), 0.0, float(player.max_health))
	shield_bar.visible = shield_bar.value > 0.0


func _configure_health_and_shield_bars() -> void:
	if health_bar:
		var health_fg := StyleBoxFlat.new()
		health_fg.bg_color = Color(0.75, 0.15, 0.15, 0.95)
		health_fg.corner_radius_top_left = 6
		health_fg.corner_radius_top_right = 6
		health_fg.corner_radius_bottom_left = 6
		health_fg.corner_radius_bottom_right = 6
		health_fg.shadow_color = Color(0.2, 0.0, 0.0, 0.4)
		health_fg.shadow_size = 4
		health_bar.add_theme_stylebox_override("fg", health_fg)

		var health_bg := StyleBoxFlat.new()
		health_bg.bg_color = Color(0.05, 0.05, 0.05, 0.7)
		health_bg.corner_radius_top_left = 6
		health_bg.corner_radius_top_right = 6
		health_bg.corner_radius_bottom_left = 6
		health_bg.corner_radius_bottom_right = 6
		health_bar.add_theme_stylebox_override("bg", health_bg)
		health_bar.show_percentage = false

	if shield_bar:
		var shield_fg := StyleBoxFlat.new()
		shield_fg.bg_color = Color(0.25, 0.7, 1.0, 0.85)
		shield_fg.corner_radius_top_left = 6
		shield_fg.corner_radius_top_right = 6
		shield_fg.corner_radius_bottom_left = 6
		shield_fg.corner_radius_bottom_right = 6
		shield_fg.shadow_color = Color(0.2, 0.6, 1.0, 0.45)
		shield_fg.shadow_size = 6
		shield_bar.add_theme_stylebox_override("fg", shield_fg)

		var shield_bg := StyleBoxFlat.new()
		shield_bg.bg_color = Color(0, 0, 0, 0)
		shield_bg.corner_radius_top_left = 6
		shield_bg.corner_radius_top_right = 6
		shield_bg.corner_radius_bottom_left = 6
		shield_bg.corner_radius_bottom_right = 6
		shield_bar.add_theme_stylebox_override("bg", shield_bg)

		shield_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shield_bar.show_percentage = false
		shield_bar.visible = false
		if player:
			shield_bar.max_value = player.max_health
		shield_bar.value = 0
		if health_bar:
			shield_bar.z_index = health_bar.z_index + 1
		else:
			shield_bar.z_index = 1
		shield_bar.move_to_front()

		if health_bar:
			shield_bar.offset_left = health_bar.offset_left
			shield_bar.offset_right = health_bar.offset_right
			shield_bar.offset_top = health_bar.offset_top
			shield_bar.offset_bottom = health_bar.offset_bottom

	_update_shield_bar()


func _on_player_shield_changed(_new_value: int) -> void:
	_update_shield_bar()


func _update_score_label() -> void:
	"""Update score label display"""
	if score_label:
		score_label.text = "Score: " + str(GameManager.score)


func _update_wave_label() -> void:
	"""Update wave label display"""
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave)


func _update_wave_timer() -> void:
	"""Update wave timer display"""
	if wave_timer_label:
		var time_remaining = int(wave_duration - wave_timer)
		wave_timer_label.text = "Time: " + str(max(0, time_remaining)) + "s"


func _update_scrap_label() -> void:
	"""Update scrap display"""
	if scrap_label:
		scrap_label.text = "Scrap: " + str(scrap_earned_this_run)


func _on_resume_pressed() -> void:
	"""Resume game from pause menu"""
	GameManager.toggle_pause()
	pause_menu.visible = false


func _on_pause_quit_pressed() -> void:
	"""Return to main menu from pause"""
	GameManager.toggle_pause()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_restart_pressed() -> void:
	"""Restart the game"""
	GameManager.reset_game()
	get_tree().reload_current_scene()


func _on_gameover_quit_pressed() -> void:
	"""Return to main menu from game over"""
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func add_scrap(amount: int) -> void:
	"""Add scrap directly to the player's total"""
	if amount <= 0:
		return
	scrap_earned_this_run += amount
	SaveManager.add_scrap(amount)
	_update_scrap_label()


func on_scrap_collected(amount: int) -> void:
	add_scrap(amount)


func register_kill() -> void:
	kills_this_run += 1


func spawn_scrap_pickups(spawn_position: Vector2, amount: int) -> void:
	if amount <= 0 or not scrap_pickup_scene:
		return

	if not scrap_container or not is_instance_valid(scrap_container):
		scrap_container = Node2D.new()
		scrap_container.name = "ScrapDrops"
		add_child(scrap_container)

	var remaining: int = amount
	while remaining > 0:
		var chunk: int = clampi(SCRAP_CHUNK_MIN + randi_range(0, SCRAP_CHUNK_MAX - SCRAP_CHUNK_MIN), 1, remaining)
		var pickup: Area2D = scrap_pickup_scene.instantiate()
		pickup.amount = chunk
		pickup.game = self
		scrap_container.add_child(pickup)
		var offset := Vector2(
			randf_range(-SCRAP_SCATTER_RADIUS, SCRAP_SCATTER_RADIUS),
			randf_range(-SCRAP_SCATTER_RADIUS, SCRAP_SCATTER_RADIUS)
		)
		pickup.global_position = spawn_position + offset
		remaining -= chunk


func _spawn_hacker_drone() -> void:
	"""Spawn the Hacker's controllable combat drone"""
	# Get drone controller
	var drone_controller = player.get_node_or_null("HackerDroneController")
	if not drone_controller:
		print("Error: No HackerDroneController found! Are you playing as Hacker?")
		return

	drone_controller.spawn_drone()
	print("Hacker Combat Drone spawned! Press E to switch control.")


func _apply_drone_upgrade(upgrade_id: String) -> void:
	"""Apply upgrade to Hacker's drone"""
	var drone_controller = player.get_node_or_null("HackerDroneController")
	if not drone_controller:
		print("No drone controller - this item is for Hacker only!")
		return

	var upgrade_data = DroneUpgradeDatabase.get_upgrade(upgrade_id)
	if upgrade_data.is_empty():
		print("Unknown drone upgrade: ", upgrade_id)
		return

	drone_controller.apply_drone_upgrade(upgrade_data)


func _upgrade_player_weapon() -> void:
	"""Upgrade player weapon to next tier"""
	var next_weapon = WeaponProgression.get_next_weapon()

	if next_weapon.is_empty():
		print("Already at max weapon tier!")
		return

	# Upgrade weapon
	if WeaponProgression.upgrade_weapon(player):
		print("Weapon upgraded to: ", next_weapon.name, " (", next_weapon.damage, " damage)")


func _update_drone_ui() -> void:
	"""Update drone UI panel"""
	var drone_controller = player.get_node_or_null("HackerDroneController")
	if not drone_controller:
		return

	var drone_stats = drone_controller.get_drone_stats()

	if drone_stats.exists:
		drone_panel.visible = true
		drone_level_label.text = "Level: " + str(drone_stats.level)
		drone_health_bar.max_value = drone_stats.max_hp
		drone_health_bar.value = drone_stats.hp
		drone_xp_bar.max_value = drone_stats.xp_needed
		drone_xp_bar.value = drone_stats.xp
		drone_xp_label.text = "XP: " + str(drone_stats.xp) + "/" + str(drone_stats.xp_needed)

		# Update mode label
		if drone_controller.is_drone_mode:
			mode_label.text = "[CONTROLLING DRONE]"
			mode_label.add_theme_color_override("font_color", Color(0, 1, 1))
		else:
			mode_label.text = "[Press E to Control]"
			mode_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		drone_panel.visible = false


func _on_drone_spawned() -> void:
	"""Handle drone spawn"""
	print("Drone spawned! UI updated.")
	_update_drone_ui()


func _on_drone_mode_switched(is_drone_mode: bool) -> void:
	"""Handle mode switch"""
	if is_drone_mode:
		print("Now controlling DRONE!")
	else:
		print("Now controlling HACKER!")
	_update_drone_ui()


# OLD COLORRECT BACKGROUND SYSTEM REMOVED
# Now using TileMap-based GameMap.tscn


func _on_area_changed(area) -> void:
	"""Handle area change"""
	print("Entered new area: ", area.name)
	print("Difficulty: ", area.difficulty_multiplier, "x")

	# Update UI with area name
	if wave_label:
		wave_label.text = "Wave: " + str(current_wave) + " | " + area.name


func _on_portal_appeared(portal_position: Vector2) -> void:
	"""Handle portal spawn"""
	print("Portal appeared at: ", portal_position)
	MapSystem.create_portal_visual(self, portal_position)
	AudioManager.play_portal_spawn_sound()


func _create_ability_hud() -> void:
	"""Create the ability HUD"""
	var hud_script = load("res://scripts/ability_hud.gd")
	ability_hud = Control.new()
	ability_hud.set_script(hud_script)
	ability_hud.name = "AbilityHUD"
	ui.add_child(ability_hud)


func _create_affix_indicator() -> void:
	"""Create the affix indicator HUD"""
	var affix_scene = load("res://scenes/AffixIndicator.tscn")
	affix_indicator = affix_scene.instantiate()
	ui.add_child(affix_indicator)
	print("Affix indicator created")


# ============================================================================
# ACTIVE ITEM FUNCTIONS
# ============================================================================

func _activate_active_item(item_id: String, effects: Dictionary) -> void:
	"""Route active item to appropriate handler"""
	match item_id:
		"time_bomb":
			_use_time_bomb(effects)
		"ghost_mode":
			_use_ghost_mode(effects)
		"magnet_field":
			_use_magnet_field(effects)
		"shotgun_spin":
			_use_shotgun_spin(effects)
		"black_hole":
			_use_black_hole(effects)
		_:
			print("Unknown active item: ", item_id)


func _use_time_bomb(effects: Dictionary) -> void:
	"""Time Bomb - Spawn explosive barrel with timer"""
	var duration = effects.get("duration", 3.0)
	var damage = effects.get("damage", 200)
	var radius = effects.get("radius", 200.0)
	var bomb_count = effects.get("bomb_count", 1)
	
	print("Spawning ", bomb_count, " time bomb(s)!")
	
	for i in range(bomb_count):
		# Spawn bomb at player position with slight offset
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50)) if bomb_count > 1 else Vector2.ZERO
		var bomb_pos = player.global_position + offset
		
		# Create bomb visual
		var bomb = ColorRect.new()
		bomb.size = Vector2(40, 40)
		bomb.position = bomb_pos - bomb.size / 2
		bomb.color = Color(1.0, 0.3, 0.0)
		bomb.z_index = 5
		add_child(bomb)
		
		# Pulse animation
		var tween = create_tween().set_loops()
		tween.tween_property(bomb, "modulate", Color(2.0, 0.5, 0.0), 0.2)
		tween.tween_property(bomb, "modulate", Color(1.0, 0.3, 0.0), 0.2)
		
		# Timer coroutine
		_time_bomb_explode(bomb, bomb_pos, duration, damage, radius)


func _time_bomb_explode(bomb: ColorRect, bomb_pos: Vector2, delay: float, damage: int, radius: float) -> void:
	"""Handle time bomb explosion after delay"""
	await get_tree().create_timer(delay).timeout
	
	if not is_instance_valid(bomb):
		return
	
	# Remove bomb visual
	bomb.queue_free()
	
	# Create explosion effect
	var explosion_scene = load("res://scenes/ExplosionEffect.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.global_position = bomb_pos
	explosion.explosion_radius = radius
	explosion.explosion_color = Color(1.0, 0.5, 0.0, 0.7)
	add_child(explosion)
	
	# Damage enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = bomb_pos.distance_to(enemy.global_position)
		if dist <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
	
	# Sound
	AudioManager.play_explosion_sound()
	print("Time Bomb exploded! Damage: ", damage, " Radius: ", radius)


func _use_ghost_mode(effects: Dictionary) -> void:
	"""Ghost Mode - Player becomes invulnerable and semi-transparent"""
	var duration = effects.get("duration", 3.0)
	var speed_boost = effects.get("speed_boost", 1.0)
	
	print("Ghost Mode activated for ", duration, "s!")
	
	# Store original values
	var original_invulnerable = player.invulnerable
	var original_modulate = player.modulate
	var original_speed = player.speed
	
	# Apply effects
	player.invulnerable = true
	player.modulate = Color(1.0, 1.0, 1.0, 0.3)  # Semi-transparent
	player.speed *= speed_boost
	
	# Wait for duration
	await get_tree().create_timer(duration).timeout
	
	# Restore original values
	if is_instance_valid(player):
		player.invulnerable = original_invulnerable
		player.modulate = original_modulate
		player.speed = original_speed
		print("Ghost Mode ended!")


func _use_magnet_field(effects: Dictionary) -> void:
	"""Magnet Field - Pull all enemies toward player"""
	var duration = effects.get("duration", 2.0)
	var pull_strength = effects.get("pull_strength", 500.0)
	var damage_per_second = effects.get("damage_per_second", 0)
	
	print("Magnet Field activated! Pull strength: ", pull_strength)
	
	# Visual effect - ring around player
	var magnet_ring = ColorRect.new()
	magnet_ring.size = Vector2(400, 400)
	magnet_ring.position = player.global_position - magnet_ring.size / 2
	magnet_ring.color = Color(0.5, 0.5, 1.0, 0.3)
	magnet_ring.z_index = 10
	add_child(magnet_ring)
	
	# Pulse animation
	var ring_tween = create_tween()
	ring_tween.set_loops()
	ring_tween.tween_property(magnet_ring, "modulate:a", 0.5, 0.3)
	ring_tween.tween_property(magnet_ring, "modulate:a", 0.1, 0.3)
	
	# Pull enemies
	var elapsed = 0.0
	while elapsed < duration:
		if not is_instance_valid(player):
			break
			
		# Update ring position
		if is_instance_valid(magnet_ring):
			magnet_ring.position = player.global_position - magnet_ring.size / 2
		
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue

			var direction = (player.global_position - enemy.global_position).normalized()
			# Apply pull force without overwriting enemy AI velocity
			enemy.velocity += direction * pull_strength * get_process_delta_time()
			
			# Optional damage over time
			if damage_per_second > 0 and enemy.has_method("take_damage"):
				enemy.take_damage(int(damage_per_second * get_process_delta_time()))
		
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	
	# Cleanup
	if is_instance_valid(magnet_ring):
		if is_instance_valid(ring_tween):
			ring_tween.kill()  # Stop looping tween before freeing
		magnet_ring.queue_free()
	
	print("Magnet Field ended!")


func _use_shotgun_spin(effects: Dictionary) -> void:
	"""Shotgun Spin - Fire projectiles in 360° ring"""
	var projectile_count = effects.get("projectile_count", 12)
	var damage = effects.get("damage", 50)
	var speed = effects.get("speed", 400.0)
	
	print("Shotgun Spin! Firing ", projectile_count, " projectiles!")
	
	# Use existing shotgun pellet scene
	var shotgun_pellet_scene = preload("res://scenes/ShotgunPellet.tscn")
	
	for i in range(projectile_count):
		var angle = (TAU / projectile_count) * i
		var direction = Vector2(cos(angle), sin(angle))
		
		var projectile = shotgun_pellet_scene.instantiate()
		projectile.global_position = player.global_position
		projectile.set_direction(direction)
		projectile.speed = speed
		projectile.damage = damage
		add_child(projectile)
	
	# Sound
	AudioManager.play_ability_sound()


func _use_black_hole(effects: Dictionary) -> void:
	"""Black Hole - Create Area2D with pull effect and damage"""
	var duration = effects.get("duration", 4.0)
	var radius = effects.get("radius", 250.0)
	var pull_strength = effects.get("pull_strength", 300.0)
	var damage_per_second = effects.get("damage_per_second", 50)
	
	print("Black Hole created! Duration: ", duration, "s")
	
	# Create black hole at player position
	var black_hole_pos = player.global_position
	
	# Visual - dark circle
	var black_hole_visual = ColorRect.new()
	black_hole_visual.size = Vector2(radius * 2, radius * 2)
	black_hole_visual.position = black_hole_pos - black_hole_visual.size / 2
	black_hole_visual.color = Color(0.1, 0.0, 0.3, 0.7)
	black_hole_visual.z_index = 5
	add_child(black_hole_visual)
	
	# Rotation animation
	var tween = create_tween().set_loops()
	tween.tween_property(black_hole_visual, "rotation", TAU, 2.0)
	
	# Pull and damage enemies
	var elapsed = 0.0
	while elapsed < duration:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			
			var dist = black_hole_pos.distance_to(enemy.global_position)
			if dist <= radius:
				# Pull toward center
				var direction = (black_hole_pos - enemy.global_position).normalized()
				# Apply pull force without overwriting enemy AI velocity
				enemy.velocity += direction * pull_strength * get_process_delta_time()
				
				# Damage over time
				if enemy.has_method("take_damage"):
					enemy.take_damage(int(damage_per_second * get_process_delta_time()))
		
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	
	# Cleanup
	if is_instance_valid(black_hole_visual):
		black_hole_visual.queue_free()
	
	print("Black Hole dissipated!")


# ============================================================================
# ROUTE SELECTION SYSTEM
# ============================================================================

func _show_route_selection() -> void:
	"""Activate directional route selection using portals."""
	if GameManager.wave_count % 3 != 0 or route_selection_active:
		return

	route_selection_active = true
	spawn_timer = 0.0
	wave_timer = 0.0

	_set_enemies_frozen(true)

	var labels := {
		"up": "NORD (GRUEN) - SKYWARD RUSH [leicht]",
		"down": "SUED (GELB) - STORMFRONT [mittel]",
		"right": "OST (ROT) - EMP OVERLOAD [schwer]"
	}
	route_selection_screen.show_selection(GameManager.wave_count, labels)
	_spawn_route_portals()

	print("Route selection triggered at wave ", GameManager.wave_count)


func handle_route_portal_selection(route: GameManager.RouteModifier) -> void:
	if not route_selection_active:
		return

	_cleanup_route_portals()
	route_selection_screen.hide_selection()
	_set_enemies_frozen(false)
	route_selection_active = false
	_on_route_selected(route)


func _on_route_selected(route: int) -> void:
	"""Handle route selection and resume game"""
	var selected_route := route as GameManager.RouteModifier
	GameManager.current_route = selected_route
	GameManager.route_selected.emit(selected_route)

	# Start next wave
	current_wave += 1
	wave_timer = 0.0
	in_wave_break = false
	_update_wave_label()

	# Apply route-specific affixes (2-3 random affixes from route pool)
	if affix_manager:
		affix_manager.apply_route_affixes(selected_route)

		# Update affix indicator with active effects
		if affix_indicator:
			var active_affixes = affix_manager.get_active_affixes()
			if active_affixes is Dictionary:
				active_affixes = active_affixes.keys()
			affix_indicator.update_affixes(active_affixes)

	# Apply route mechanics
	_apply_route_mechanics(selected_route)

	# Spawn boss if needed
	if (current_wave % 10) == 0:
		_spawn_boss()

	print("Route selected: ", selected_route, " - Starting wave ", current_wave)


func _apply_route_mechanics(route: int) -> void:
	"""Apply route-specific environmental mechanics"""
	match route:
		GameManager.RouteModifier.SKYWARD_RUSH:
			_activate_skyward_rush()
		GameManager.RouteModifier.STORMFRONT:
			_activate_stormfront()
		GameManager.RouteModifier.EMP_OVERLOAD:
			_activate_emp_overload()


func _spawn_route_portals() -> void:
	_cleanup_route_portals()

	route_portal_container = Node2D.new()
	route_portal_container.name = "RoutePortals"
	add_child(route_portal_container)

	var arena: Rect2 = map_generator.get_arena_bounds()
	var center: Vector2 = arena.size * 0.5

	var specs := [
		{
			"route": GameManager.RouteModifier.SKYWARD_RUSH,
			"position": Vector2(center.x, arena.position.y + 140.0),
			"label": "NORD (GRUEN) - SKYWARD RUSH [leicht]",
			"color": Color(0.2, 1.0, 0.3),
			"label_offset": Vector2(-160, -120)
		},
		{
			"route": GameManager.RouteModifier.STORMFRONT,
			"position": Vector2(center.x, arena.position.y + arena.size.y - 140.0),
			"label": "SUED (GELB) - STORMFRONT [mittel]",
			"color": Color(1.0, 0.9, 0.0),
			"label_offset": Vector2(-160, 100)
		},
		{
			"route": GameManager.RouteModifier.EMP_OVERLOAD,
			"position": Vector2(arena.position.x + arena.size.x - 140.0, center.y),
			"label": "OST (ROT) - EMP OVERLOAD [schwer]",
			"color": Color(1.0, 0.2, 0.2),
			"label_offset": Vector2(40, -40)
		}
	]

	var portal_script := load("res://scripts/route_portal.gd")

	for spec in specs:
		var portal := Area2D.new()
		portal.set_script(portal_script)
		portal.route = spec["route"]
		portal.game = self
		portal.position = spec["position"]
		portal.collision_layer = 0
		portal.collision_mask = 1  # detect player on layer 1

		var collision := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 90.0
		collision.shape = circle
		portal.add_child(collision)

		var visual := Polygon2D.new()
		visual.polygon = _create_circle_points(circle.radius, 24)
		visual.color = spec["color"]
		visual.modulate = Color(spec["color"].r, spec["color"].g, spec["color"].b, 0.55)
		visual.z_index = 8
		portal.add_child(visual)

		route_portal_container.add_child(portal)

		var text_label := Label.new()
		text_label.text = spec["label"]
		text_label.position = spec["position"] + spec["label_offset"]
		text_label.theme_override_font_sizes["font_size"] = 22
		text_label.theme_override_colors["font_color"] = spec["color"]
		text_label.z_index = 9
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		route_portal_container.add_child(text_label)


func _cleanup_route_portals() -> void:
	if route_portal_container and is_instance_valid(route_portal_container):
		route_portal_container.queue_free()
	route_portal_container = null


func _set_enemies_frozen(frozen: bool) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_variable("velocity"):
			enemy.velocity = Vector2.ZERO
		enemy.set_process(not frozen)
		enemy.set_physics_process(not frozen)


func _create_circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


# ===========================================================================
# SKYWARD RUSH - Green Route
# ===========================================================================

func _activate_skyward_rush() -> void:
	"""Skyward Rush - Bounce pads, updrafts, smoke bombs"""
	print("==== SKYWARD RUSH ACTIVATED ====")

	# Spawn 6 bounce pads
	for i in range(6):
		_spawn_bounce_pad()

	# Enable smoke bomb drops from enemies
	set_meta("smoke_bomb_drops", true)


func _spawn_bounce_pad() -> void:
	"""Spawn a bounce pad that launches the player upward"""
	var pad = Area2D.new()
	pad.name = "BouncePad"

	# Random position around player
	var offset = Vector2(randf_range(-500, 500), randf_range(-500, 500))
	pad.global_position = player.global_position + offset

	# Visual - green glowing pad
	var visual = ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = -visual.size / 2
	visual.color = Color(0.2, 1.0, 0.3, 0.6)
	visual.z_index = 2
	pad.add_child(visual)

	# Collision shape
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	pad.add_child(shape)

	# Pulsing animation
	var tween = create_tween().set_loops()
	tween.tween_property(visual, "modulate:a", 0.3, 0.5)
	tween.tween_property(visual, "modulate:a", 0.8, 0.5)

	# Bounce effect on contact
	pad.body_entered.connect(func(body):
		if body == player:
			player.velocity.y = -800  # Strong upward bounce
			AudioManager.play_ability_sound()
			print("Bounce pad activated!")
	)

	# Set collision layers
	pad.collision_layer = 0
	pad.collision_mask = 1  # Only detect player

	add_child(pad)
	print("Bounce pad spawned at ", pad.global_position)


# ===========================================================================
# STORMFRONT - Yellow Route
# ===========================================================================

func _activate_stormfront() -> void:
	"""Stormfront - Lightning rods, electric puddles"""
	print("==== STORMFRONT ACTIVATED ====")

	# Spawn 5 lightning rods
	for i in range(5):
		_spawn_lightning_rod()

	# Enable electric trail on player movement
	player.set_meta("electric_trail", true)


func _spawn_lightning_rod() -> void:
	"""Spawn lightning rod that strikes nearby enemies"""
	var rod = Node2D.new()
	rod.name = "LightningRod"

	# Random position
	var offset = Vector2(randf_range(-600, 600), randf_range(-600, 600))
	rod.global_position = player.global_position + offset

	# Visual - yellow spike
	var spike = ColorRect.new()
	spike.size = Vector2(20, 100)
	spike.position = Vector2(-10, -100)
	spike.color = Color(1.0, 0.9, 0.0, 0.9)
	spike.z_index = 3
	rod.add_child(spike)

	# Glow effect
	var glow = ColorRect.new()
	glow.size = Vector2(40, 120)
	glow.position = Vector2(-20, -110)
	glow.color = Color(1.0, 0.9, 0.0, 0.3)
	glow.z_index = 2
	rod.add_child(glow)

	# Lightning strike timer
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.timeout.connect(func():
		_lightning_strike(rod.global_position)
	)
	rod.add_child(timer)

	add_child(rod)
	print("Lightning rod spawned at ", rod.global_position)


func _lightning_strike(origin: Vector2) -> void:
	"""Create lightning strike that damages enemies in 300px radius"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist = origin.distance_to(enemy.global_position)
		if dist <= 300.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(80)
				hit_count += 1

	# Visual flash effect
	var flash = ColorRect.new()
	flash.size = Vector2(600, 600)
	flash.position = origin - flash.size / 2
	flash.color = Color(1.0, 1.0, 0.5, 0.5)
	flash.z_index = 15
	add_child(flash)

	# Fade out flash
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

	AudioManager.play_explosion_sound()
	print("Lightning strike! Hit ", hit_count, " enemies")


# ===========================================================================
# EMP OVERLOAD - Red Route
# ===========================================================================

func _activate_emp_overload() -> void:
	"""EMP Overload - Periodic EMPs, Tesla coils"""
	print("==== EMP OVERLOAD ACTIVATED ====")

	# Spawn 4 Tesla coils
	for i in range(4):
		_spawn_tesla_coil()

	# Start EMP pulse timer
	_start_emp_pulses()


func _spawn_tesla_coil() -> void:
	"""Spawn Tesla coil with damage pulse"""
	var coil = Area2D.new()
	coil.name = "TeslaCoil"

	# Random position
	var offset = Vector2(randf_range(-550, 550), randf_range(-550, 550))
	coil.global_position = player.global_position + offset

	# Visual - red/purple coil
	var base = ColorRect.new()
	base.size = Vector2(60, 80)
	base.position = Vector2(-30, -80)
	base.color = Color(0.8, 0.2, 0.4, 0.8)
	base.z_index = 3
	coil.add_child(base)

	# Danger zone visual
	var danger_zone = ColorRect.new()
	danger_zone.name = "DangerZone"
	danger_zone.size = Vector2(300, 300)
	danger_zone.position = -danger_zone.size / 2
	danger_zone.color = Color(1.0, 0.2, 0.2, 0.2)
	danger_zone.z_index = 1
	coil.add_child(danger_zone)

	# Collision shape
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 150.0
	shape.shape = circle
	coil.add_child(shape)

	# Damage pulse timer
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.autostart = true
	timer.timeout.connect(func():
		_tesla_pulse(coil)
	)
	coil.add_child(timer)

	# Set collision
	coil.collision_layer = 0
	coil.collision_mask = 3  # Player + Enemies

	add_child(coil)
	print("Tesla coil spawned at ", coil.global_position)


func _tesla_pulse(coil: Area2D) -> void:
	"""Pulse damage from Tesla coil"""
	if not is_instance_valid(coil):
		return

	var bodies = coil.get_overlapping_bodies()
	for body in bodies:
		if body == player and body.has_method("take_damage"):
			body.take_damage(15)  # Damage player
		elif body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(40)  # Damage enemies too

	# Pulse visual
	var pulse_visual = coil.get_node_or_null("DangerZone")
	if pulse_visual:
		var tween = create_tween()
		tween.tween_property(pulse_visual, "modulate:a", 0.6, 0.1)
		tween.tween_property(pulse_visual, "modulate:a", 0.2, 0.4)


func _start_emp_pulses() -> void:
	"""Start periodic EMP pulses that disable abilities"""
	var emp_timer = Timer.new()
	emp_timer.name = "EMPPulseTimer"
	emp_timer.wait_time = 12.0
	emp_timer.autostart = true
	emp_timer.timeout.connect(_trigger_emp_pulse)
	add_child(emp_timer)

	print("EMP pulse timer started (every 12s)")


func _trigger_emp_pulse() -> void:
	"""Trigger EMP pulse - disables abilities briefly"""
	print("⚡ EMP PULSE! Abilities disabled!")

	# Disable player abilities temporarily
	player.set_meta("emp_disabled", true)

	# Screen flash
	var flash = ColorRect.new()
	flash.size = get_viewport_rect().size
	flash.color = Color(0.5, 0.1, 0.1, 0.4)
	flash.z_index = 100
	ui.add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 1.0)
	tween.tween_callback(flash.queue_free)

	AudioManager.play_damage_sound()

	# Re-enable after 2 seconds
	await get_tree().create_timer(2.0).timeout

	if is_instance_valid(player):
		player.set_meta("emp_disabled", false)
		print("Abilities restored!")


# ============================================================================
# CONSOLE SPAWNING SYSTEM (Hacker character)
# ============================================================================

func _spawn_consoles() -> void:
	"""Spawn a single hackable console per map"""
	if console_spawned:
		return

	var arena_rect: Rect2 = map_generator.get_arena_bounds()
	print("Spawning console for Hacker")

	var console = console_scene.instantiate()
	var spawn_margin := 180.0
	var spawn_x := randf_range(arena_rect.position.x + spawn_margin, arena_rect.position.x + arena_rect.size.x - spawn_margin)
	var spawn_y := randf_range(arena_rect.position.y + spawn_margin, arena_rect.position.y + arena_rect.size.y - spawn_margin)
	console.global_position = Vector2(spawn_x, spawn_y)
	console.console_hacked.connect(_on_console_hacked)
	add_child(console)
	active_consoles.append(console)
	console_spawned = true
	print("Console spawned at ", console.global_position)


func _on_console_hacked(console: Node, _mod_type: int, mod_scene_path: String) -> void:
	"""Handle console hack notification"""
	print("Console hacked! Mod applied: ", mod_scene_path)
	if console and active_consoles.has(console):
		active_consoles.erase(console)
	if active_consoles.is_empty():
		console_spawned = false
