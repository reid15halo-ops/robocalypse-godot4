extends Node

# Objective System - Manages MOBA-style game objectives
# King of the Hill, Capture the Flag, Destroyable Structures, Command Center

# Objective data structure
class ObjectiveData:
	var id: String
	var name: String
	var description: String
	var objective_type: String  # "king_of_hill", "capture_flag", "destroy_structure", "command_center"
	var reward_scrap: int
	var parameters: Dictionary

	func _init(p_id: String, p_name: String, p_desc: String, p_type: String, p_reward: int, p_params: Dictionary):
		id = p_id
		name = p_name
		description = p_desc
		objective_type = p_type
		reward_scrap = p_reward
		parameters = p_params


# Current active objective
var active_objective: ObjectiveData = null
var objective_node: Node = null  # The spawned objective scene

# Objective spawn tracking
var waves_until_next_objective: int = 3
var objective_spawn_interval: int = 3  # Spawn every 3 waves

# Signals
signal objective_started(objective: ObjectiveData)
signal objective_completed(objective: ObjectiveData, scrap_reward: int)
signal objective_progress(progress: float)  # 0.0 to 1.0

# Available objectives database
var objectives_database: Array = []


func _ready() -> void:
	_initialize_objectives()


func _initialize_objectives() -> void:
	"""Initialize all available objectives"""

	# KING OF THE HILL
	objectives_database.append(ObjectiveData.new(
		"king_of_hill",
		"King of the Hill",
		"Hold the zone for 10 seconds",
		"king_of_hill",
		150,
		{
			"capture_time": 10.0,  # Seconds to hold
			"zone_radius": 120.0
		}
	))

	# CAPTURE THE FLAG
	objectives_database.append(ObjectiveData.new(
		"capture_flag",
		"Capture the Flag",
		"Pick up the flag and return to base",
		"capture_flag",
		100,
		{
			"flag_spawn_distance": 400.0  # Distance from center
		}
	))

	# DESTROY ENEMY STRUCTURE (spawns enemies)
	objectives_database.append(ObjectiveData.new(
		"destroy_structure",
		"Destroy Enemy Structure",
		"Destroy the structure (spawns enemies when destroyed)",
		"destroy_structure",
		150,
		{
			"structure_hp": 300,
			"spawn_enemy_count": 5
		}
	))

	# DESTROY COMMAND CENTER (stuns all enemies)
	objectives_database.append(ObjectiveData.new(
		"command_center",
		"Destroy Command Center",
		"Destroy the command center to stun all enemies for 3s",
		"command_center",
		200,
		{
			"structure_hp": 400,
			"stun_duration": 3.0
		}
	))


func should_spawn_objective(current_wave: int) -> bool:
	"""Check if an objective should spawn this wave"""
	waves_until_next_objective -= 1

	if waves_until_next_objective <= 0:
		waves_until_next_objective = objective_spawn_interval
		return true

	return false


func spawn_random_objective(game_scene: Node) -> void:
	"""Spawn a random objective in the game"""
	if active_objective:
		print("Objective already active!")
		return

	# Pick random objective
	var objective = objectives_database[randi() % objectives_database.size()]
	active_objective = objective

	# Spawn the objective based on type
	match objective.objective_type:
		"king_of_hill":
			_spawn_king_of_hill(game_scene, objective)
		"capture_flag":
			_spawn_capture_flag(game_scene, objective)
		"destroy_structure":
			_spawn_destroy_structure(game_scene, objective, false)
		"command_center":
			_spawn_destroy_structure(game_scene, objective, true)

	objective_started.emit(objective)
	print("Objective started: ", objective.name)


func _spawn_king_of_hill(game_scene: Node, objective: ObjectiveData) -> void:
	"""Spawn King of the Hill zone"""
	var zone = Area2D.new()
	zone.name = "KingOfHillZone"
	zone.collision_layer = 0
	zone.collision_mask = 1  # Detect player

	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = objective.parameters.get("zone_radius", 120.0)
	collision_shape.shape = circle
	zone.add_child(collision_shape)

	# Visual indicator (colored circle)
	var visual = ColorRect.new()
	var radius = objective.parameters.get("zone_radius", 120.0)
	visual.size = Vector2(radius * 2, radius * 2)
	visual.position = -visual.size / 2
	visual.color = Color(0.2, 0.8, 0.2, 0.3)  # Green transparent
	visual.z_index = -1
	zone.add_child(visual)

	# Position in random location (not too close to edges)
	zone.global_position = Vector2(
		randf_range(200, 1080),
		randf_range(200, 520)
	)

	# Add script behavior
	zone.set_meta("capture_time", objective.parameters.get("capture_time", 10.0))
	zone.set_meta("capture_progress", 0.0)
	zone.set_meta("objective_id", objective.id)

	game_scene.add_child(zone)
	objective_node = zone

	# Connect body entered/exited signals
	zone.body_entered.connect(_on_hill_zone_entered)
	zone.body_exited.connect(_on_hill_zone_exited)


func _on_hill_zone_entered(body: Node) -> void:
	"""Player entered King of Hill zone"""
	if body.is_in_group("player") or body == GameManager.player:
		objective_node.set_meta("player_in_zone", true)


func _on_hill_zone_exited(body: Node) -> void:
	"""Player exited King of Hill zone"""
	if body.is_in_group("player") or body == GameManager.player:
		objective_node.set_meta("player_in_zone", false)


func _spawn_capture_flag(game_scene: Node, objective: ObjectiveData) -> void:
	"""Spawn Capture the Flag objective"""
	var flag = Area2D.new()
	flag.name = "CaptureFlag"
	flag.collision_layer = 0
	flag.collision_mask = 1  # Detect player

	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	collision_shape.shape = circle
	flag.add_child(collision_shape)

	# Visual indicator (flag - simple colored square)
	var visual = ColorRect.new()
	visual.size = Vector2(40, 60)
	visual.position = -visual.size / 2
	visual.color = Color(1.0, 0.2, 0.2)  # Red flag
	visual.z_index = 10
	flag.add_child(visual)

	# Position far from center
	var angle = randf_range(0, TAU)
	var distance = objective.parameters.get("flag_spawn_distance", 400.0)
	flag.global_position = Vector2(640, 360) + Vector2.from_angle(angle) * distance

	# Clamp to arena bounds
	flag.global_position.x = clamp(flag.global_position.x, 100, 1180)
	flag.global_position.y = clamp(flag.global_position.y, 100, 620)

	flag.set_meta("objective_id", objective.id)
	flag.set_meta("picked_up", false)

	game_scene.add_child(flag)
	objective_node = flag

	flag.body_entered.connect(_on_flag_picked_up)


func _on_flag_picked_up(body: Node) -> void:
	"""Player picked up flag"""
	if body.is_in_group("player") or body == GameManager.player:
		if not objective_node.get_meta("picked_up", false):
			objective_node.set_meta("picked_up", true)
			print("Flag picked up! Return to center!")

			# Change flag color to indicate pickup
			var visual = objective_node.get_child(1)
			if visual is ColorRect:
				visual.color = Color(0.2, 1.0, 0.2)  # Green when picked up


func _spawn_destroy_structure(game_scene: Node, objective: ObjectiveData, is_command_center: bool) -> void:
	"""Spawn destroyable structure"""
	var structure = StaticBody2D.new()
	structure.name = "DestroyableStructure"
	structure.collision_layer = 2  # Enemy layer so player can attack it

	# Add to enemies group so player melee attacks hit it
	structure.add_to_group("enemies")

	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(80, 80)
	collision_shape.shape = rect_shape
	structure.add_child(collision_shape)

	# Visual indicator
	var visual = ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = -visual.size / 2
	visual.color = Color(0.8, 0.2, 0.2) if not is_command_center else Color(0.2, 0.2, 0.8)
	visual.z_index = 5
	structure.add_child(visual)

	# Health bar background
	var health_bg = ColorRect.new()
	health_bg.size = Vector2(80, 8)
	health_bg.position = Vector2(-40, -50)
	health_bg.color = Color(0.2, 0.2, 0.2)
	health_bg.z_index = 11
	structure.add_child(health_bg)

	# Health bar
	var health_bar = ColorRect.new()
	health_bar.size = Vector2(80, 8)
	health_bar.position = Vector2(-40, -50)
	health_bar.color = Color(0.2, 1.0, 0.2)
	health_bar.z_index = 12
	health_bar.name = "HealthBar"
	structure.add_child(health_bar)

	# Position randomly
	structure.global_position = Vector2(
		randf_range(200, 1080),
		randf_range(200, 520)
	)

	# Set metadata
	var max_hp = objective.parameters.get("structure_hp", 300)
	structure.set_meta("current_hp", max_hp)
	structure.set_meta("max_hp", max_hp)
	structure.set_meta("objective_id", objective.id)
	structure.set_meta("is_command_center", is_command_center)
	structure.set_script(preload("res://scripts/destroyable_structure.gd"))

	game_scene.add_child(structure)
	objective_node = structure


func _process(delta: float) -> void:
	"""Update active objective"""
	if not active_objective or not is_instance_valid(objective_node):
		return

	match active_objective.objective_type:
		"king_of_hill":
			_update_king_of_hill(delta)
		"capture_flag":
			_update_capture_flag(delta)


func _update_king_of_hill(delta: float) -> void:
	"""Update King of the Hill progress"""
	var player_in_zone = objective_node.get_meta("player_in_zone", false)
	var capture_progress = objective_node.get_meta("capture_progress", 0.0)
	var capture_time = objective_node.get_meta("capture_time", 10.0)

	if player_in_zone:
		capture_progress += delta
		objective_node.set_meta("capture_progress", capture_progress)

		# Emit progress
		var progress_percent = capture_progress / capture_time
		objective_progress.emit(progress_percent)

		# Check if captured
		if capture_progress >= capture_time:
			_complete_objective()
	else:
		# Lose progress when not in zone
		if capture_progress > 0:
			capture_progress -= delta * 0.5  # Lose progress slower
			capture_progress = max(0, capture_progress)
			objective_node.set_meta("capture_progress", capture_progress)


func _update_capture_flag(delta: float) -> void:
	"""Update Capture the Flag progress"""
	var picked_up = objective_node.get_meta("picked_up", false)

	if picked_up:
		# Check if player is near center (base)
		var player = GameManager.player
		if is_instance_valid(player):
			var dist_to_center = player.global_position.distance_to(Vector2(640, 360))

			if dist_to_center < 100:
				_complete_objective()


func structure_destroyed() -> void:
	"""Called when a structure is destroyed"""
	if not active_objective:
		return

	var is_command_center = objective_node.get_meta("is_command_center", false)

	if is_command_center:
		# Stun all enemies
		var stun_duration = active_objective.parameters.get("stun_duration", 3.0)
		_stun_all_enemies(stun_duration)
		print("Command Center destroyed! All enemies stunned for ", stun_duration, "s")
	else:
		# Spawn enemies
		var spawn_count = active_objective.parameters.get("spawn_enemy_count", 5)
		_spawn_enemies_at_structure(spawn_count)
		print("Structure destroyed! ", spawn_count, " enemies spawned!")

	_complete_objective()


func _stun_all_enemies(duration: float) -> void:
	"""Stun all enemies for a duration"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(duration)
		elif enemy.has_method("set_physics_process"):
			enemy.set_physics_process(false)
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(enemy):
				enemy.set_physics_process(true)


func _spawn_enemies_at_structure(count: int) -> void:
	"""Spawn enemies at structure location"""
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if not game_scene or not game_scene.has_method("spawn_enemy_at_position"):
		return

	var spawn_pos = objective_node.global_position

	for i in range(count):
		var offset = Vector2.from_angle(randf_range(0, TAU)) * randf_range(50, 150)
		game_scene.spawn_enemy_at_position(spawn_pos + offset)


func _complete_objective() -> void:
	"""Complete the current objective"""
	if not active_objective:
		return

	print("Objective completed: ", active_objective.name)
	print("Reward: ", active_objective.reward_scrap, " scrap")

	# Grant reward
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene:
		var reward := active_objective.reward_scrap
		var player_ref := GameManager.get_player()
		var drop_position := Vector2.ZERO
		if is_instance_valid(objective_node):
			drop_position = objective_node.global_position
		elif is_instance_valid(player_ref):
			drop_position = player_ref.global_position
		if reward > 0 and game_scene.has_method("spawn_scrap_pickups"):
			game_scene.spawn_scrap_pickups(drop_position, reward)
		elif reward > 0 and game_scene.has_method("add_scrap"):
			game_scene.add_scrap(reward)

	# Emit completion signal
	objective_completed.emit(active_objective, active_objective.reward_scrap)

	# Clean up objective node
	if is_instance_valid(objective_node):
		objective_node.queue_free()

	objective_node = null
	active_objective = null


func clear_objective() -> void:
	"""Clear current objective (e.g., on game over)"""
	if is_instance_valid(objective_node):
		objective_node.queue_free()

	objective_node = null
	active_objective = null
