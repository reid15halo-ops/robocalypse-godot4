extends CharacterBody2D

@export var current_speed: float = 100.0
@export var max_health: int = 80
var current_health: int = 80
@export var hp_regen_rate: float = 0.0
var player: CharacterBody2D = null
@export var score_value: int = 20

# Aura settings
var aura_radius: float = 250.0
var aura_update_interval: float = 0.5
var aura_timer: float = 0.0
var aura_type: BuffSystem.BuffType = BuffSystem.BuffType.SPEED
var aura_value: float = 50.0  # +50 speed

# Hold/Slow settings (Player debuff)
@export var hold_radius: float = 200.0
@export var slow_amount: float = 0.5  # Slow player to 50% speed
var hold_active: bool = false

# Random aura on spawn - with DISTINCT visuals
var aura_types = [
	{"type": BuffSystem.BuffType.SPEED, "value": 50.0, "color": Color(0.2, 1.8, 1.8), "scale": Vector2(0.8, 1.3)},  # Bright cyan, elongated
	{"type": BuffSystem.BuffType.DAMAGE, "value": 10.0, "color": Color(1.8, 0.5, 0), "scale": Vector2(1.4, 1.4)},  # Bright orange, larger
	{"type": BuffSystem.BuffType.SHIELD, "value": 50.0, "color": Color(0.2, 0.4, 2.0), "scale": Vector2(1.2, 1.2)}  # Bright blue, slightly larger
]

var is_stunned: bool = false
var stun_timer: float = 0.0
var _pre_stun_speed: float = 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 14
	add_to_group("enemies")
	add_to_group("support_drones")
	current_health = max_health
	player = GameManager.get_player()

	# Random aura with distinct visuals
	var aura_config = aura_types[randi() % aura_types.size()]
	aura_type = aura_config.type
	aura_value = aura_config.value
	modulate = aura_config.color
	scale = aura_config.scale  # Different shape/size per type


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if is_stunned:
		stun_timer -= delta
		velocity = Vector2.ZERO
		if stun_timer <= 0.0:
			is_stunned = false
			current_speed = max(_pre_stun_speed, 20.0)
		else:
			return

	if hp_regen_rate > 0.0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)

	if not player or not is_instance_valid(player):
		player = GameManager.get_player()

	# Keep distance from player (support role)
	if player and is_instance_valid(player) and not GameManager.is_game_over:
		var distance = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()

		# Stay at medium range
		if distance < 300:
			velocity = -direction * current_speed  # Move away
		elif distance > 400:
			velocity = direction * current_speed  # Move closer
		else:
			velocity = Vector2.ZERO

		move_and_slide()

	# Apply hold/slow effect if player is in range
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= hold_radius:
			if not hold_active:
				_apply_hold()
		else:
			if hold_active:
				_remove_hold()

	# Update aura
	aura_timer += delta
	if aura_timer >= aura_update_interval:
		aura_timer = 0.0
		_apply_aura()


func _apply_aura() -> void:
	"""Apply buff aura to nearby enemies"""
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue

		# Skip other support drones
		if enemy.is_in_group("support_drones"):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist <= aura_radius:
			# Check buff limit (max 3 of same type)
			if BuffSystem.get_buff_count(enemy, aura_type) < 3:
				BuffSystem.apply_buff(enemy, aura_type, aura_value, self, aura_update_interval * 2)


func take_damage(damage: int) -> void:
	current_health -= damage

	modulate = modulate.lightened(0.3)
	await get_tree().create_timer(0.1).timeout
	if not is_queued_for_deletion():
		# Restore aura color
		var aura_config = aura_types[0]
		for config in aura_types:
			if config.type == aura_type:
				aura_config = config
				break
		modulate = aura_config.color

	if current_health <= 0:
		die()


func _apply_hold() -> void:
	"""Apply slow effect to player when in range"""
	if player and is_instance_valid(player):
		if player.has_method("apply_slow"):
			player.apply_slow(slow_amount)
			hold_active = true


func _remove_hold() -> void:
	"""Remove slow effect from player when out of range"""
	if player and is_instance_valid(player):
		if player.has_method("remove_slow"):
			player.remove_slow()
			hold_active = false


func die() -> void:
	if is_queued_for_deletion():
		return

	# Remove slow effect if active
	if hold_active:
		_remove_hold()

	# Remove all buffs this support drone gave
	BuffSystem.remove_all_buffs_from_source(self)

	GameManager.add_score(score_value)

	var scrap_amount = int(15 * MetaProgression.get_scrap_multiplier())
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene:
		if game_scene.has_method("register_kill"):
			game_scene.register_kill()
		if scrap_amount > 0 and game_scene.has_method("spawn_scrap_pickups"):
			game_scene.spawn_scrap_pickups(global_position, scrap_amount)

	queue_free()


func apply_stun(duration: float) -> void:
	if duration <= 0.0:
		return
	is_stunned = true
	stun_timer = max(stun_timer, duration)
	_pre_stun_speed = current_speed
	current_speed = 0.0
	velocity = Vector2.ZERO
