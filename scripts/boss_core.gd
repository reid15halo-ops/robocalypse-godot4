extends CharacterBody2D
class_name BossCore

## Boss Core Controller
## Hybrid-Architektur: Kern-Logik hier, Komponenten als Child-Nodes
## Kommunikation via Signals (kein direkter Variablen-Zugriff)

#region SIGNALS
## Emitted when boss takes damage
signal health_changed(current_health: int, max_health: int)

## Emitted when boss dies
signal boss_died()

## Emitted when boss changes phase
signal phase_changed(new_phase: int, old_phase: int)

## Emitted when boss wants to perform an attack
signal attack_requested(attack_type: String)

## Emitted when boss activates an effect
signal effect_activated(effect_type: String, data: Dictionary)

## Emitted when boss deactivates an effect
signal effect_deactivated(effect_type: String)

## Emitted when movement state changes
signal movement_changed(target_position: Vector2, speed: float)
#endregion

#region CONFIGURATION
## Stats Resource - kann im Editor zugewiesen werden
@export var stats: Resource

## Scene References - werden im Editor zugewiesen
@export var enemy_scene: PackedScene
@export var enemy_projectile_scene: PackedScene
#endregion

#region COMPONENT_REFERENCES
## Komponenten werden im Editor als Child-Nodes hinzugefügt
@onready var state_machine: Node = $StateMachine if has_node("StateMachine") else null
@onready var attack_controller: Node = $AttackController if has_node("AttackController") else null
@onready var effect_manager: Node = $EffectManager if has_node("EffectManager") else null
@onready var visuals: Node2D = $Visuals if has_node("Visuals") else null
@onready var health_bar: Control = $HealthBar if has_node("HealthBar") else null
#endregion

#region STATE
## Current State
var current_health: int = 0
var current_phase: int = 1
var is_dead: bool = false

## References
var player: CharacterBody2D = null
var game_scene: Node = null

## Movement
var current_speed: float = 0.0
var target_direction: Vector2 = Vector2.ZERO
#endregion

#region INITIALIZATION
func _ready() -> void:
	# Fallback: Load default stats if none assigned
	if stats == null:
		stats = load("res://resources/boss_stats_default.tres")
		if stats == null:
			push_error("BossCore: Failed to load default stats!")
			return

	# Initialize health
	current_health = stats.max_health

	# Setup collision
	collision_layer = stats.collision_layer
	collision_mask = stats.collision_mask

	# Setup groups
	add_to_group("enemies")
	add_to_group("bosses")

	# Initialize speed
	current_speed = stats.base_speed

	# Find player reference
	_find_player_reference()

	# Find game scene reference
	_find_game_scene_reference()

	# Connect component signals
	_connect_component_signals()

	# Initialize components
	_initialize_components()

	# Initial phase setup
	_update_phase(1)

func _find_player_reference() -> void:
	# Try multiple methods to find player
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as CharacterBody2D
	elif get_parent():
		player = get_parent().get_node_or_null("Player") as CharacterBody2D

func _find_game_scene_reference() -> void:
	# Walk up tree to find game scene
	var current_node: Node = get_parent()
	while current_node:
		if current_node.has_method("get_arena_bounds") or current_node.name == "Game":
			game_scene = current_node
			break
		current_node = current_node.get_parent()

func _connect_component_signals() -> void:
	# Components will connect to our signals
	# We might also want to listen to component signals here
	pass

func _initialize_components() -> void:
	# Let components know they can initialize
	if state_machine and state_machine.has_method("initialize"):
		state_machine.initialize(self)
	if attack_controller and attack_controller.has_method("initialize"):
		attack_controller.initialize(self)
	if effect_manager and effect_manager.has_method("initialize"):
		effect_manager.initialize(self)
	if visuals and visuals.has_method("initialize"):
		visuals.initialize(self)
#endregion

#region MAIN_LOOP
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Update state machine (determines behavior)
	if state_machine and state_machine.has_method("update"):
		state_machine.update(delta)

	# Update attack controller (handles attack cooldowns)
	if attack_controller and attack_controller.has_method("update"):
		attack_controller.update(delta)

	# Update effect manager (handles active effects)
	if effect_manager and effect_manager.has_method("update"):
		effect_manager.update(delta)

	# Apply movement
	_apply_movement(delta)

	# Move and handle collisions
	move_and_slide()

func _apply_movement(delta: float) -> void:
	# Basic movement logic - can be overridden by state machine
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	# Calculate direction to player
	var direction: Vector2 = (player.global_position - global_position).normalized()

	# Apply speed
	velocity = direction * current_speed

	# Notify about movement
	movement_changed.emit(player.global_position, current_speed)
#endregion

#region HEALTH_SYSTEM
## Deals damage to the boss
func take_damage(damage: int, damaging_entity: Node = null) -> void:
	if is_dead:
		return

	# Check shield absorption
	var actual_damage: int = damage
	if effect_manager and effect_manager.has_method("absorb_damage"):
		actual_damage = effect_manager.absorb_damage(damage)

	# Apply damage
	current_health -= actual_damage
	current_health = max(0, current_health)

	# Emit signal
	health_changed.emit(current_health, stats.max_health)

	# Update health bar
	_update_health_bar()

	# Check for phase change
	_check_phase_transition()

	# Check for death
	if current_health <= 0:
		_handle_death()

## Returns current health percentage (0.0 to 1.0)
func get_health_percent() -> float:
	if stats.max_health <= 0:
		return 0.0
	return float(current_health) / float(stats.max_health)

func _update_health_bar() -> void:
	if health_bar == null:
		return

	if health_bar.has_method("update_health"):
		health_bar.update_health(current_health, stats.max_health)
	elif health_bar.has_node("Bar"):
		var bar: Control = health_bar.get_node("Bar")
		if bar:
			var health_percent: float = get_health_percent()
			bar.scale.x = health_percent

func _handle_death() -> void:
	if is_dead:
		return

	is_dead = true

	# Emit death signal
	boss_died.emit()

	# Award score if game scene exists
	if game_scene and game_scene.has_method("add_score"):
		game_scene.add_score(stats.score_value)

	# Award scrap via GameManager
	if GameManager and GameManager.has_method("add_scrap"):
		GameManager.add_scrap(stats.scrap_award)

	# Cleanup
	queue_free()
#endregion

#region PHASE_SYSTEM
func _check_phase_transition() -> void:
	var health_percent: float = get_health_percent()
	var new_phase: int = stats.get_phase_from_health_percent(health_percent)

	if new_phase != current_phase:
		_update_phase(new_phase)

func _update_phase(new_phase: int) -> void:
	var old_phase: int = current_phase
	current_phase = new_phase

	# Update speed based on phase
	current_speed = stats.base_speed * stats.get_speed_multiplier(current_phase)

	# Emit phase change signal
	if old_phase != new_phase:
		phase_changed.emit(new_phase, old_phase)

## Public API: Get current phase
func get_current_phase() -> int:
	return current_phase
#endregion

#region ATTACK_SYSTEM
## Request an attack (components call this)
func request_attack(attack_type: String) -> void:
	attack_requested.emit(attack_type)
#endregion

#region EFFECT_SYSTEM
## Activate an effect
func activate_effect(effect_type: String, data: Dictionary = {}) -> void:
	effect_activated.emit(effect_type, data)

## Deactivate an effect
func deactivate_effect(effect_type: String) -> void:
	effect_deactivated.emit(effect_type)
#endregion

#region UTILITY
## Get arena bounds from map generator
func get_arena_bounds() -> Rect2:
	if game_scene and game_scene.has_node("MapGenerator"):
		var generator: Node = game_scene.get_node("MapGenerator")
		if generator and generator.has_method("get_arena_bounds"):
			return generator.get_arena_bounds()
	# Fallback
	return Rect2(Vector2.ZERO, Vector2(stats.arena_size, stats.arena_size))

## Get player reference (public API for components)
func get_player() -> CharacterBody2D:
	return player

## Get game scene reference (public API for components)
func get_game_scene() -> Node:
	return game_scene

## Get stats (public API for components)
func get_stats() -> Resource:
	return stats
#endregion
