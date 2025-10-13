extends CharacterBody2D

# Signals
signal health_changed(new_health: int)
signal died
signal level_up(new_level: int)
signal xp_gained(current_xp: int, xp_needed: int)

# Movement and stats
@export var base_speed: float = 250.0
@export var base_max_health: int = 80
@export var base_damage: int = 25
@export var attack_interval: float = 0.4

var current_speed: float = base_speed
var max_health: int = base_max_health
var current_health: float = float(base_max_health)
var current_damage: int = base_damage

var hp_regen_rate: float = 0.0
var damage_reduction: float = 0.0
var shield_hp: float = 0.0
var projectile_reflect_chance: float = 0.0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.5

var attack_timer: float = 0.0

# Level system
var current_level: int = 1
var current_xp: int = 0
var xp_per_level: int = 100
var xp_scaling: float = 1.3

# State
var is_player_controlled: bool = false
var invulnerable: bool = false
var invulnerability_timer: float = 0.0
var invulnerability_time: float = 0.6

var has_dual_fire: bool = false
var has_overcharge: bool = false
var overcharge_active: bool = false
var overcharge_timer: float = 0.0
var overcharge_cooldown_timer: float = 0.0
var has_emp_burst: bool = false
var emp_cooldown_timer: float = 0.0

var equipped_weapons: Array = []
var weapon_cooldowns: Dictionary = {}
var weapon_fire_rates: Dictionary = {
	"laser": 0.25,
	"rocket": 1.2,
	"shotgun": 0.6
}

var auto_follow_distance: float = 140.0
var auto_orbit_speed: float = 1.2
var auto_orbit_timer: float = 0.0
var player_ref: CharacterBody2D = null

var laser_scene: PackedScene = preload("res://scenes/LaserBullet.tscn")
var rocket_scene: PackedScene = preload("res://scenes/Rocket.tscn")
var shotgun_pellet_scene: PackedScene = preload("res://scenes/ShotgunPellet.tscn")

func _ready() -> void:
	collision_layer = 1
	collision_mask = 28
	max_health = base_max_health
	current_health = max_health
	current_speed = base_speed
	current_damage = base_damage
	health_changed.emit(int(current_health))
	equipped_weapons.clear()
	weapon_cooldowns.clear()
	add_weapon("laser")

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	if not player_ref or not is_instance_valid(player_ref):
		player_ref = GameManager.get_player()

	if invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0.0:
			invulnerable = false
			modulate = Color.WHITE

	if hp_regen_rate > 0.0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)
		health_changed.emit(int(current_health))

	if overcharge_active:
		overcharge_timer -= delta
		if overcharge_timer <= 0.0:
			_end_overcharge()
	elif overcharge_cooldown_timer > 0.0:
		overcharge_cooldown_timer = max(overcharge_cooldown_timer - delta, 0.0)

	if emp_cooldown_timer > 0.0:
		emp_cooldown_timer = max(emp_cooldown_timer - delta, 0.0)

	attack_timer += delta
	for weapon_type in weapon_cooldowns.keys():
		weapon_cooldowns[weapon_type] += delta

	if is_player_controlled:
		_handle_player_input(delta)
	else:
		_handle_auto_movement(delta)

	move_and_slide()

	_check_enemy_overlap()

	if attack_timer >= attack_interval:
		_auto_attack()
		attack_timer = 0.0

	_fire_weapons()

	if has_emp_burst and emp_cooldown_timer <= 0.0:
		_trigger_emp_burst()

func _handle_player_input(_delta: float) -> void:
	"""Handle player input when controlled"""
	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")

	if input_direction.length() > 0:
		input_direction = input_direction.normalized()

	velocity = input_direction * current_speed


func _auto_attack() -> void:
	"""Perform melee attack"""
	var attack_range = 80.0
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Enemy layer

	var results = space_state.intersect_shape(query)

	for result in results:
		var collider = result["collider"]
		if collider.is_in_group("enemies") and collider.has_method("take_damage"):
			var final_damage = _calculate_damage(current_damage)
			collider.take_damage(final_damage)
			_gain_xp(5)  # XP for melee hit
			break


func _fire_weapons() -> void:
	"""Fire equipped weapons"""
	var target = _find_nearest_enemy()
	if not target:
		return

	var weapon_range = 800.0
	if global_position.distance_to(target.global_position) > weapon_range:
		return

	for weapon_type in equipped_weapons:
		var fire_rate = weapon_fire_rates.get(weapon_type, 1.0)
		var cooldown = weapon_cooldowns.get(weapon_type, 0.0)

		if cooldown >= fire_rate:
			_fire_weapon(weapon_type, target)
			weapon_cooldowns[weapon_type] = 0.0

			# Dual fire
			if has_dual_fire:
				await get_tree().create_timer(0.05).timeout
				if is_instance_valid(target):
					_fire_weapon(weapon_type, target)


func _fire_weapon(weapon_type: String, target: Node2D) -> void:
	"""Fire a specific weapon"""
	var direction = (target.global_position - global_position).normalized()

	match weapon_type:
		"laser":
			_spawn_projectile(laser_scene, direction)
		"rocket":
			_spawn_projectile(rocket_scene, direction)
		"shotgun":
			_fire_shotgun(direction)


func _spawn_projectile(projectile_scene: PackedScene, direction: Vector2) -> void:
	"""Spawn projectile with drone damage"""
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.set_direction(direction)

	# Apply drone damage bonus
	var final_damage = _calculate_damage(projectile.damage)
	projectile.damage = final_damage

	get_parent().add_child(projectile)

	# XP on projectile spawn (will get more on kill)
	_gain_xp(1)


func _fire_shotgun(direction: Vector2) -> void:
	"""Fire shotgun spread"""
	var pellet_count = 5
	var spread_angle = deg_to_rad(30.0)

	for i in range(pellet_count):
		var angle_offset = (i - pellet_count / 2.0) * (spread_angle / pellet_count)
		var spread_direction = direction.rotated(angle_offset)
		_spawn_projectile(shotgun_pellet_scene, spread_direction)


func _calculate_damage(base: int) -> int:
	"""Calculate final damage with bonuses"""
	var damage = float(base)

	# Overcharge
	if overcharge_active:
		damage *= 2.0

	# Crit
	if randf() < crit_chance:
		damage *= crit_multiplier
		print("CRIT!")

	return int(damage)


func _find_nearest_enemy() -> Node:
	"""Find nearest enemy"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func take_damage(damage: int) -> void:
	"""Take damage"""
	if invulnerable:
		return

	var final_damage = damage * (1.0 - damage_reduction)

	# Shield first
	if shield_hp > 0:
		if shield_hp >= final_damage:
			shield_hp -= int(final_damage)
			final_damage = 0
		else:
			final_damage -= shield_hp
			shield_hp = 0

	# Health
	if final_damage > 0:
		current_health -= int(final_damage)
		current_health = max(0, current_health)
		health_changed.emit(int(current_health))

		# Invulnerability
		invulnerable = true
		invulnerability_timer = 0.5
		modulate = Color(1, 0.5, 0.5)

	if current_health <= 0:
		die()


func die() -> void:
	"""Handle drone death"""
	died.emit()
	# Drone will be removed by controller


func add_weapon(weapon_type: String) -> void:
	"""Add weapon"""
	equipped_weapons.append(weapon_type)
	weapon_cooldowns[weapon_type] = 0.0


func _gain_xp(amount: int) -> void:
	"""Gain XP and check for level up"""
	current_xp += amount
	var xp_needed = _get_xp_for_next_level()

	xp_gained.emit(current_xp, xp_needed)

	if current_xp >= xp_needed:
		_level_up()


func _get_xp_for_next_level() -> int:
	"""Calculate XP needed for next level"""
	return int(xp_per_level * pow(xp_scaling, current_level - 1))


func _level_up() -> void:
	"""Level up the drone"""
	current_xp = 0
	current_level += 1

	# Stat increases
	max_health += 10
	current_health = max_health
	current_damage += 3
	current_speed += 5

	# Update visual label
	if has_node("LevelLabel"):
		$LevelLabel.text = "LVL " + str(current_level)

	# SLOW MOTION EFFECT
	TimeControl.activate_slow_motion(1.5)  # 1.5 seconds slow-mo
	_show_level_up_notification()

	level_up.emit(current_level)
	print("Drone leveled up to ", current_level)


func _show_level_up_notification() -> void:
	"""Show level up notification"""
	# Get game scene
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if not game_scene:
		return

	# Create notification label
	var level_up_label := Label.new()
	level_up_label.text = "DRONE LEVEL UP!\nLevel " + str(current_level)
	level_up_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_up_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Styling
	level_up_label.add_theme_font_size_override("font_size", 48)
	level_up_label.add_theme_color_override("font_color", Color(0, 1, 1))
	level_up_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	level_up_label.add_theme_constant_override("outline_size", 4)

	# Position
	level_up_label.position = Vector2(640 - 200, 200)
	level_up_label.size = Vector2(400, 150)
	level_up_label.z_index = 1000

	# Add to UI
	var ui = game_scene.get_node("UI")
	ui.add_child(level_up_label)

	# Fade out animation
	var tween := create_tween()
	tween.tween_property(level_up_label, "modulate:a", 0.0, 1.0).set_delay(1.5)
	tween.tween_callback(level_up_label.queue_free)


func apply_upgrade(upgrade_data: Dictionary) -> void:
	"""Apply a drone upgrade"""
	var effects = upgrade_data.effects

	for effect_name in effects:
		var value = effects[effect_name]

		match effect_name:
			"projectile_reflect":
				projectile_reflect_chance = value
			"shield_hp":
				shield_hp += value
			"dual_fire":
				has_dual_fire = true
			"overcharge_damage":
				has_overcharge = true
			"hp_regen":
				hp_regen_rate += value
			"crit_chance":
				crit_chance += value
			"crit_multiplier":
				crit_multiplier = value
			"speed_multiplier":
				current_speed = base_speed * value
			"damage_multiplier":
				current_damage = int(base_damage * value)
			"attack_speed_multiplier":
				attack_interval /= value
			"damage_reduction":
				damage_reduction += value
				damage_reduction = min(damage_reduction, 0.75)
			"emp_radius":
				has_emp_burst = true


func activate_overcharge() -> void:
	"""Activate overcharge ability"""
	if has_overcharge and overcharge_cooldown_timer <= 0:
		overcharge_active = true
		overcharge_timer = 10.0
		overcharge_cooldown_timer = 30.0
		modulate = Color(2.0, 0.5, 0.5)
		print("Overcharge activated!")


func _end_overcharge() -> void:
	"""End overcharge"""
	overcharge_active = false
	modulate = Color.WHITE
	print("Overcharge ended")


func _trigger_emp_burst() -> void:
	"""Trigger EMP burst"""
	emp_cooldown_timer = 15.0

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= 200.0:
			# Stun enemy (would need stun system in enemy)
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(2.0)

	print("EMP Burst triggered!")


func reset_progress() -> void:
	"""Reset drone level and upgrades (called on death in control mode)"""
	current_level = 1
	current_xp = 0
	max_health = base_max_health
	current_health = max_health
	current_speed = base_speed
	current_damage = base_damage
	hp_regen_rate = 0.0
	damage_reduction = 0.0
	shield_hp = 0
	projectile_reflect_chance = 0.0
	crit_chance = 0.0
	has_dual_fire = false
	has_overcharge = false
	has_emp_burst = false
	equipped_weapons.clear()
	weapon_cooldowns.clear()

	# Re-add starting weapon
	add_weapon("laser")

	print("Drone progress reset!")


func _check_enemy_overlap() -> void:
	if invulnerable:
		return

	var shape_node := get_node_or_null("CollisionShape2D")
	if not shape_node:
		return

	var shape: Shape2D = shape_node.shape
	if not shape:
		return

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = shape_node.global_transform
	query.collision_mask = 2  # Enemy layer
	query.exclude = [get_rid()]

	var space_state := get_world_2d().direct_space_state
	var results := space_state.intersect_shape(query, 1)
	for result in results:
		var collider: Node = result.get("collider") as Node
		if collider and collider.is_in_group("enemies"):
			take_damage(10)
			break
func _handle_auto_movement(delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		velocity = Vector2.ZERO
		return

	var to_player: Vector2 = player_ref.global_position - global_position
	var distance := to_player.length()

	var desired_velocity := Vector2.ZERO

	if distance > auto_follow_distance:
		desired_velocity = to_player.normalized() * current_speed
	elif distance < auto_follow_distance * 0.6:
		desired_velocity = -to_player.normalized() * current_speed * 0.5
	else:
		desired_velocity = velocity.move_toward(Vector2.ZERO, current_speed * delta)

	# Add light orbiting behaviour around the player
	if distance > 1.0:
		auto_orbit_timer += delta * auto_orbit_speed
		var orbit_direction := Vector2(-to_player.y, to_player.x).normalized()
		desired_velocity += orbit_direction * current_speed * 0.3 * sin(auto_orbit_timer)

	velocity = desired_velocity
