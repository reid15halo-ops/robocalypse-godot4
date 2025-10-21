extends Node
class_name BossAttackControllerComponent

## Boss Attack Controller Component
## Verwaltet alle Angriffe und deren Cooldowns
## Kommuniziert mit BossCore via Signals

#region VARIABLES
var boss: Node = null  # BossCore reference

## Cooldown Trackers
var attack_cooldowns: Dictionary = {
	"basic_laser": 0.0,
	"minion_spawn": 0.0,
	"gravity_well": 0.0,
	"plasma_walls": 0.0,
	"shield": 0.0
}

## Minion spawn tracking
var minion_spawn_timer: float = 0.0
#endregion

#region INITIALIZATION
func initialize(boss_ref: Node) -> void:
	boss = boss_ref

	# Connect to boss signals
	if boss:
		boss.attack_requested.connect(_on_attack_requested)
		boss.phase_changed.connect(_on_phase_changed)
#endregion

#region MAIN_UPDATE
func update(delta: float) -> void:
	if boss == null:
		return

	# Update all cooldowns
	for attack_type in attack_cooldowns.keys():
		if attack_cooldowns[attack_type] > 0.0:
			attack_cooldowns[attack_type] -= delta

	# Update minion spawn timer
	minion_spawn_timer += delta

	# Auto-spawn minions based on timer
	_check_auto_minion_spawn()
#endregion

#region ATTACK_HANDLING
func _on_attack_requested(attack_type: String) -> void:
	# Check if attack is off cooldown
	if not is_attack_ready(attack_type):
		return

	# Perform the attack
	match attack_type:
		"basic_laser":
			_perform_laser_attack()
		"minion_spawn":
			_perform_minion_spawn()
		"gravity_well":
			_perform_gravity_well()
		"plasma_walls":
			_perform_plasma_walls()
		"shield":
			_perform_shield_activation()
		_:
			push_warning("Unknown attack type requested: " + attack_type)

func is_attack_ready(attack_type: String) -> bool:
	if not attack_cooldowns.has(attack_type):
		return false
	return attack_cooldowns[attack_type] <= 0.0

func _start_cooldown(attack_type: String, cooldown_time: float) -> void:
	attack_cooldowns[attack_type] = cooldown_time
#endregion

#region LASER_ATTACK
func _perform_laser_attack() -> void:
	var stats: Resource = boss.get_stats()
	var player: CharacterBody2D = boss.get_player()

	if player == null or not is_instance_valid(player):
		return

	# Create projectile
	if boss.enemy_projectile_scene:
		var projectile: Node2D = boss.enemy_projectile_scene.instantiate()
		boss.get_parent().add_child(projectile)

		# Position and aim projectile
		projectile.global_position = boss.global_position
		var direction: Vector2 = (player.global_position - boss.global_position).normalized()

		# Set projectile properties if it has them
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)
		elif projectile.has("velocity"):
			projectile.velocity = direction * stats.laser_speed

		if projectile.has("damage"):
			projectile.damage = stats.laser_damage

	# Start cooldown
	_start_cooldown("basic_laser", stats.laser_cooldown)
#endregion

#region MINION_SPAWN
func _check_auto_minion_spawn() -> void:
	var stats: Resource = boss.get_stats()

	if minion_spawn_timer >= stats.minion_cooldown:
		if is_attack_ready("minion_spawn"):
			_perform_minion_spawn()

func _perform_minion_spawn() -> void:
	var stats: Resource = boss.get_stats()
	var phase: int = boss.get_current_phase()
	var minion_count: int = stats.get_minion_count(phase)

	# Spawn minions
	for i in range(minion_count):
		_spawn_single_minion()

	# Reset timers
	minion_spawn_timer = 0.0
	_start_cooldown("minion_spawn", stats.minion_cooldown)

func _spawn_single_minion() -> void:
	if boss.enemy_scene == null:
		return

	var stats: Resource = boss.get_stats()

	# Random spawn position around boss
	var angle: float = randf() * TAU
	var distance: float = randf_range(stats.minion_min_distance, stats.minion_max_distance)
	var spawn_offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance
	var spawn_position: Vector2 = boss.global_position + spawn_offset

	# Create minion
	var minion: Node = boss.enemy_scene.instantiate()
	boss.get_parent().add_child(minion)
	minion.global_position = spawn_position
#endregion

#region GRAVITY_WELL
func _perform_gravity_well() -> void:
	var stats: Resource = boss.get_stats()
	var player: CharacterBody2D = boss.get_player()

	if player == null or not is_instance_valid(player):
		return

	# Create gravity well at player's position
	var gravity_data: Dictionary = {
		"position": player.global_position,
		"duration": stats.gravity_well_duration,
		"strength": stats.gravity_well_strength,
		"damage": stats.gravity_well_damage,
		"radius": stats.gravity_well_pull_distance
	}

	boss.activate_effect("gravity_well", gravity_data)

	# Start cooldown
	_start_cooldown("gravity_well", stats.gravity_well_cooldown)
#endregion

#region PLASMA_WALLS
func _perform_plasma_walls() -> void:
	var stats: Resource = boss.get_stats()
	var phase: int = boss.get_current_phase()
	var wall_count: int = stats.get_plasma_wall_count(phase)

	# Create plasma walls
	var plasma_data: Dictionary = {
		"count": wall_count,
		"duration": stats.plasma_wall_duration,
		"damage": stats.get_plasma_wall_damage(phase),
		"radius": stats.plasma_wall_damage_radius
	}

	boss.activate_effect("plasma_walls", plasma_data)

	# Start cooldown
	_start_cooldown("plasma_walls", stats.plasma_wall_cooldown)
#endregion

#region SHIELD
func _perform_shield_activation() -> void:
	var stats: Resource = boss.get_stats()

	# Activate shield
	var shield_data: Dictionary = {
		"max_value": stats.shield_max_value,
		"duration": stats.shield_duration
	}

	boss.activate_effect("shield", shield_data)

	# Start cooldown
	_start_cooldown("shield", stats.shield_cooldown)

## Check if shield should auto-activate based on health
func check_auto_shield() -> void:
	var stats: Resource = boss.get_stats()
	var health_percent: float = boss.get_health_percent()

	if health_percent <= stats.shield_activation_health_percent:
		if is_attack_ready("shield"):
			_perform_shield_activation()
#endregion

#region SIGNAL_HANDLERS
func _on_phase_changed(new_phase: int, old_phase: int) -> void:
	# Reset some cooldowns on phase change?
	# Could give boss a "power surge" on phase transition
	pass
#endregion

#region PUBLIC_API
## Get remaining cooldown for an attack
func get_cooldown(attack_type: String) -> float:
	if attack_cooldowns.has(attack_type):
		return max(0.0, attack_cooldowns[attack_type])
	return 0.0
#endregion
