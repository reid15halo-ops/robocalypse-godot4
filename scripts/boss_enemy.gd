extends CharacterBody2D

# Constants
const INITIAL_SPEED: float = 140.0
const MAX_HEALTH: int = 6000
const SCORE_VALUE: int = 100
const MINION_SPAWN_COOLDOWN: float = 6.0
const SHIELD_MAX_VALUE: float = 900.0
const SHIELD_DURATION_VALUE: float = 7.0
const GRAVITY_WELL_STRENGTH: float = 450.0
const ARENA_SIZE: int = 1792
const ENEMY_COLLISION_LAYER: int = 2
const ENEMY_COLLISION_MASK: int = 14
const GRAVITY_WELL_PULL_DISTANCE: float = 120.0
const GRAVITY_WELL_DAMAGE: int = 35
const PLASMA_WALL_DAMAGE_RADIUS: float = 140.0
const PLASMA_WALL_BASE_DAMAGE: int = 30
const PLASMA_WALL_DAMAGE_PER_PHASE: int = 10
const MINION_SPAWN_COUNT_BASE: int = 3
const MINION_SPAWN_MIN_DISTANCE: float = 120.0
const MINION_SPAWN_MAX_DISTANCE: float = 240.0
const HEALTH_BAR_MAX_WIDTH: float = 60.0
const SCRAP_AWARD_AMOUNT: int = 50

# Components
var state_machine: Node
var attacks: Node
var visuals: Node

# Movement
@export var speed: float = INITIAL_SPEED  # Base speed before phase modifiers

# Health
@export var max_health: int = MAX_HEALTH  # Drastically increased survivability
var current_health: int = MAX_HEALTH
@export var hp_regen_rate: float = 0.0

# Navigation
var player: CharacterBody2D = null
var game_scene: Node

# Score value
@export var score_value: int = SCORE_VALUE

# Minion spawning
var minion_spawn_cooldown: float = MINION_SPAWN_COOLDOWN
var minion_spawn_timer: float = 0.0
@export var enemy_scene: PackedScene
@export var enemy_projectile_scene: PackedScene

# Attack cooldowns
var special_attack_cooldown: float = 4.5

@onready var health_bar: Control = $HealthBar

# Visual
var sprite: AnimatedSprite2D = null
var visual_node: Node2D = null
var use_sprites: bool = true  # Sprites are now available!

# Defensive systems
var shield_active: bool = false
var shield_value: float = 0.0
const SHIELD_MAX: float = SHIELD_MAX_VALUE
const SHIELD_DURATION: float = SHIELD_DURATION_VALUE
var shield_timer: float = 0.0
var shield_visual: Node2D = null

# Gravity well effect
var gravity_well_timer: float = 0.0
var gravity_well_duration: float = 0.0
var gravity_well_position: Vector2 = Vector2.ZERO
var gravity_well_strength: float = GRAVITY_WELL_STRENGTH
var gravity_damage_timer: float = 0.0
var gravity_well_visual: Node2D = null

# Plasma wall tracking
var plasma_walls: Array[Dictionary] = []

func _get_arena_rect() -> Rect2:
	if game_scene and game_scene.has_node("MapGenerator"):
		var generator: Node = game_scene.get_node("MapGenerator")
		if generator and generator.has_method("get_arena_bounds"):
			return generator.get_arena_bounds()
	return Rect2(Vector2.ZERO, Vector2(ARENA_SIZE, ARENA_SIZE))


func _ready() -> void:
	# Set collision layer and mask
	collision_layer = ENEMY_COLLISION_LAYER
	collision_mask = ENEMY_COLLISION_MASK

	# Add to enemies group
	add_to_group("enemies")
	add_to_group("bosses")

	# Initialize health
	current_health = max_health

	# Get references
	player = GameManager.get_player()
	game_scene = get_tree().get_first_node_in_group("game_scene")

	# Initialize components
	state_machine = load("res://scripts/boss_state_machine.gd").new(self)
	attacks = load("res://scripts/boss_attacks.gd").new(self)
	visuals = load("res://scripts/boss_visuals.gd").new(self)
	add_child(state_machine)
	add_child(attacks)
	add_child(visuals)

	state_machine._set_phase_stats()

	# Create visual
	visuals._create_boss_visual()

	# Play boss spawn sound
	AudioManager.play_boss_spawn_sound()


func _physics_process(delta: float) -> void:
	# Refresh player reference if needed
	if not player:
		player = GameManager.get_player()

	if not player or GameManager.is_game_over:
		return

	if hp_regen_rate > 0.0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)
		_update_health_bar()

	state_machine._physics_process(delta)
	
	_update_active_effects(delta)


func _update_active_effects(delta: float) -> void:
	# Shield decay
	if shield_active:
		shield_timer -= delta
		if shield_timer <= 0.0:
			_deactivate_shield()
		else:
			shield_value = max(0.0, shield_value - (SHIELD_MAX / SHIELD_DURATION) * 0.2 * delta)

	# Gravity well pull
	if gravity_well_timer > 0.0:
		gravity_well_timer -= delta
		gravity_damage_timer += delta
		if player and is_instance_valid(player):
			var to_well: Vector2 = gravity_well_position - player.global_position
			var distance: float = to_well.length()
			if distance > 0.1:
				var pull: Vector2 = to_well.normalized() * gravity_well_strength * delta
				if player.has_variable("external_velocity"):
					player.external_velocity += pull
			if distance <= GRAVITY_WELL_PULL_DISTANCE and gravity_damage_timer >= 0.5:
				gravity_damage_timer = 0.0
				if player.has_method("take_damage"):
					player.take_damage(GRAVITY_WELL_DAMAGE)
		if gravity_well_timer <= 0.0:
			gravity_well_duration = 0.0
			if gravity_well_visual and is_instance_valid(gravity_well_visual):
				gravity_well_visual.queue_free()
				gravity_well_visual = null
	else:
		if gravity_well_visual and is_instance_valid(gravity_well_visual):
			gravity_well_visual.queue_free()
			gravity_well_visual = null

	# Plasma wall management
	if plasma_walls.size() > 0:
		for i in range(plasma_walls.size() - 1, -1, -1):
			var wall_entry: Dictionary = plasma_walls[i]
			var node: Node2D = wall_entry.get("node")
			if not is_instance_valid(node):
				plasma_walls.remove_at(i)
				continue

			var lifespan: float = wall_entry.get("lifespan", 0.0) - delta
			var damage_timer: float = wall_entry.get("damage_timer", 0.0) + delta

			if player and is_instance_valid(player) and damage_timer >= 0.4:
				if player.global_position.distance_to(node.global_position) <= wall_entry.get("damage_radius", PLASMA_WALL_DAMAGE_RADIUS):
					if player.has_method("take_damage"):
						player.take_damage(PLASMA_WALL_BASE_DAMAGE + PLASMA_WALL_DAMAGE_PER_PHASE * (state_machine.phase - 1))
					damage_timer = 0.0

			if lifespan <= 0.0:
				node.queue_free()
				plasma_walls.remove_at(i)
			else:
				wall_entry["lifespan"] = lifespan
				wall_entry["damage_timer"] = damage_timer
				plasma_walls[i] = wall_entry


func _spawn_minions() -> void:
	var minion_count: int = MINION_SPAWN_COUNT_BASE + state_machine.phase
	for i in range(minion_count):
		var minion: Node2D = enemy_scene.instantiate()
		var angle: float = randf_range(0.0, TAU)
		var distance: float = randf_range(MINION_SPAWN_MIN_DISTANCE, MINION_SPAWN_MAX_DISTANCE)
		minion.global_position = global_position + Vector2(cos(angle), sin(angle)) * distance
		get_parent().add_child(minion)


func take_damage(damage: int) -> void:
	if damage <= 0:
		return

	if shield_active and shield_value > 0.0:
		var absorbed: float = min(float(damage), shield_value)
		shield_value -= absorbed
		damage -= int(absorbed)
		visuals._flash_shield_hit()
		if shield_value <= 0.0:
			_deactivate_shield()

	if damage <= 0:
		return

	current_health -= damage
	_update_health_bar()
	visuals._flash_damage()

	if current_health <= 0:
		die()


func _deactivate_shield() -> void:
	if not shield_active:
		return
	shield_active = false
	shield_value = 0.0
	shield_timer = 0.0
	if shield_visual and is_instance_valid(shield_visual):
		shield_visual.queue_free()
	shield_visual = null
	visuals._apply_phase_color()


func _clear_plasma_walls() -> void:
	for entry in plasma_walls:
		var node: Node = entry.get("node")
		if node and is_instance_valid(node):
			node.queue_free()
	plasma_walls.clear()


func _update_health_bar() -> void:
	"""Update boss health bar visual"""
	if not is_instance_valid(health_bar):
		return

	var health_percent: float = float(current_health) / float(max_health)
	health_bar.size.x = HEALTH_BAR_MAX_WIDTH * health_percent


func die() -> void:
	"""Handle boss death"""
	if is_queued_for_deletion():
		return

	_deactivate_shield()
	_clear_plasma_walls()
	if gravity_well_visual and is_instance_valid(gravity_well_visual):
		gravity_well_visual.queue_free()
		gravity_well_visual = null

	# Add big score bonus
	GameManager.add_score(score_value)

	# Award scrap
	var scrap_amount: int = int(SCRAP_AWARD_AMOUNT * MetaProgression.get_scrap_multiplier())
	_award_scrap(scrap_amount)

	# Spawn multiple rewards (could be items/powerups)
	print("Boss defeated! Major rewards!")

	# Remove from scene
	queue_free()


func _award_scrap(amount: int) -> void:
	"""Award scrap to game scene"""
	if not game_scene:
		return
	if game_scene.has_method("register_kill"):
		game_scene.register_kill()
	if amount > 0 and game_scene.has_method("spawn_scrap_pickups"):
		game_scene.spawn_scrap_pickups(global_position, amount)