extends CharacterBody2D

# Movement
@export var current_speed: float = 120.0

# Health
@export var max_health: int = 30
var current_health: int = 30
@export var hp_regen_rate: float = 0.0

# Navigation
var player: CharacterBody2D = null

# Score value
@export var score_value: int = 5

# Supply drop
var supply_crate_scene = preload("res://scenes/SupplyCrate.tscn")
var supply_drop_chance: float = 0.10  # 10% chance

var is_stunned: bool = false
var stun_timer: float = 0.0
var _pre_stun_speed: float = 0.0

func _ready() -> void:
	# Set collision
	collision_layer = 2  # Enemy
	collision_mask = 14  # Updated mask per collision spec

	# Add to group
	add_to_group("enemies")

	# Initialize
	current_health = max_health
	player = GameManager.get_player()

	# Distinct visual: Small and green (weak)
	modulate = Color(0.5, 1.5, 0.5)  # Bright green
	scale = Vector2(0.6, 0.6)  # Noticeably smaller


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

	# Update player reference
	if not player or not is_instance_valid(player):
		player = GameManager.get_player()

	# Move towards player
	if player and is_instance_valid(player) and not GameManager.is_game_over:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * current_speed
		move_and_slide()


func take_damage(damage: int) -> void:
	"""Take damage"""
	current_health -= damage

	# Visual feedback
	_flash_damage()

	# Check death
	if current_health <= 0:
		die()


func _flash_damage() -> void:
	"""Visual damage feedback"""
	modulate = Color(1.5, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_queued_for_deletion():
		return
	modulate = Color.WHITE


func die() -> void:
	"""Handle death"""
	if is_queued_for_deletion():
		return

	# Add score
	GameManager.add_score(score_value)

	# Award scrap
	var scrap_amount = int(5 * MetaProgression.get_scrap_multiplier())
	_award_scrap(scrap_amount)

	# Supply drop chance
	if randf() < supply_drop_chance:
		_spawn_supply_crate()

	queue_free()

func apply_stun(duration: float) -> void:
	if duration <= 0.0:
		return
	is_stunned = true
	stun_timer = max(stun_timer, duration)
	_pre_stun_speed = current_speed
	current_speed = 0.0
	velocity = Vector2.ZERO


func _award_scrap(amount: int) -> void:
	"""Award scrap"""
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if not game_scene:
		return
	if game_scene.has_method("register_kill"):
		game_scene.register_kill()
	if amount > 0 and game_scene.has_method("spawn_scrap_pickups"):
		game_scene.spawn_scrap_pickups(global_position, amount)


func _spawn_supply_crate() -> void:
	"""Spawn supply crate at death location"""
	if not supply_crate_scene:
		return

	var crate = supply_crate_scene.instantiate()
	crate.global_position = global_position
	get_parent().call_deferred("add_child", crate)
	print("Supply crate dropped!")
