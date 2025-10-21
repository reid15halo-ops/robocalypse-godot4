extends Node
class_name BossEffectManagerComponent

## Boss Effect Manager Component
## Verwaltet aktive Effekte (Shield, Gravity Well, Plasma Walls)
## Kommuniziert mit BossCore via Signals

#region EFFECT_DATA
class ActiveEffect:
	var effect_type: String
	var duration: float
	var timer: float = 0.0
	var data: Dictionary = {}

	func _init(type: String, dur: float, effect_data: Dictionary = {}):
		effect_type = type
		duration = dur
		data = effect_data
#endregion

#region VARIABLES
var boss: Node = null  # BossCore reference
var active_effects: Array[ActiveEffect] = []

## Shield
var shield_active: bool = false
var shield_value: float = 0.0
var shield_visual: Node2D = null

## Gravity Well
var gravity_well_active: bool = false
var gravity_well_position: Vector2 = Vector2.ZERO
var gravity_well_visual: Node2D = null
var gravity_damage_timer: float = 0.0

## Plasma Walls
var plasma_walls: Array[Dictionary] = []
#endregion

#region INITIALIZATION
func initialize(boss_ref: Node) -> void:
	boss = boss_ref

	# Connect to boss signals
	if boss:
		boss.effect_activated.connect(_on_effect_activated)
		boss.effect_deactivated.connect(_on_effect_deactivated)
#endregion

#region MAIN_UPDATE
func update(delta: float) -> void:
	if boss == null:
		return

	# Update all active effects
	var effects_to_remove: Array[ActiveEffect] = []

	for effect in active_effects:
		effect.timer += delta

		# Update effect logic
		_update_effect(effect, delta)

		# Check if effect expired
		if effect.timer >= effect.duration:
			effects_to_remove.append(effect)

	# Remove expired effects
	for effect in effects_to_remove:
		_remove_effect(effect)
		active_effects.erase(effect)

	# Update specific effect systems
	_update_shield(delta)
	_update_gravity_well(delta)
	_update_plasma_walls(delta)
#endregion

#region EFFECT_MANAGEMENT
func _on_effect_activated(effect_type: String, data: Dictionary) -> void:
	match effect_type:
		"shield":
			_activate_shield(data)
		"gravity_well":
			_activate_gravity_well(data)
		"plasma_walls":
			_activate_plasma_walls(data)
		_:
			push_warning("Unknown effect type: " + effect_type)

func _on_effect_deactivated(effect_type: String) -> void:
	# Manually deactivate an effect
	for effect in active_effects:
		if effect.effect_type == effect_type:
			_remove_effect(effect)
			active_effects.erase(effect)
			break

func _update_effect(effect: ActiveEffect, delta: float) -> void:
	# Generic effect update
	pass

func _remove_effect(effect: ActiveEffect) -> void:
	# Cleanup when effect ends
	match effect.effect_type:
		"shield":
			_deactivate_shield()
		"gravity_well":
			_deactivate_gravity_well()
		"plasma_walls":
			_deactivate_plasma_walls()
#endregion

#region SHIELD_EFFECT
func _activate_shield(data: Dictionary) -> void:
	if shield_active:
		return  # Shield already active

	shield_active = true
	shield_value = data.get("max_value", 900.0)

	# Create visual
	_create_shield_visual()

	# Add to active effects
	var effect: ActiveEffect = ActiveEffect.new("shield", data.get("duration", 7.0), data)
	active_effects.append(effect)

func _deactivate_shield() -> void:
	shield_active = false
	shield_value = 0.0

	# Remove visual
	if shield_visual and is_instance_valid(shield_visual):
		shield_visual.queue_free()
		shield_visual = null

func _update_shield(delta: float) -> void:
	if not shield_active:
		return

	# Shield visual pulsing effect
	if shield_visual and is_instance_valid(shield_visual):
		var pulse: float = sin(Time.get_ticks_msec() * 0.005) * 0.2 + 0.8
		shield_visual.modulate.a = pulse

func _create_shield_visual() -> void:
	# Create shield visual node
	shield_visual = Node2D.new()
	boss.add_child(shield_visual)

	# Create circle polygon for shield
	var polygon: Polygon2D = Polygon2D.new()
	shield_visual.add_child(polygon)

	# Create circle shape
	var points: PackedVector2Array = []
	var segments: int = 32
	var radius: float = 70.0

	for i in range(segments):
		var angle: float = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	polygon.polygon = points
	polygon.color = Color(0.3, 0.6, 1.0, 0.3)

func absorb_damage(damage: int) -> int:
	if not shield_active:
		return damage

	# Shield absorbs damage
	var absorbed: int = mini(damage, int(shield_value))
	shield_value -= absorbed
	var remaining_damage: int = damage - absorbed

	# Deactivate shield if depleted
	if shield_value <= 0:
		_deactivate_shield()

	return remaining_damage
#endregion

#region GRAVITY_WELL_EFFECT
func _activate_gravity_well(data: Dictionary) -> void:
	if gravity_well_active:
		return

	gravity_well_active = true
	gravity_well_position = data.get("position", boss.global_position)
	gravity_damage_timer = 0.0

	# Create visual
	_create_gravity_well_visual()

	# Add to active effects
	var effect: ActiveEffect = ActiveEffect.new("gravity_well", data.get("duration", 4.0), data)
	active_effects.append(effect)

func _deactivate_gravity_well() -> void:
	gravity_well_active = false

	# Remove visual
	if gravity_well_visual and is_instance_valid(gravity_well_visual):
		gravity_well_visual.queue_free()
		gravity_well_visual = null

func _update_gravity_well(delta: float) -> void:
	if not gravity_well_active:
		return

	var stats: Resource = boss.get_stats()
	var player: CharacterBody2D = boss.get_player()

	if player == null or not is_instance_valid(player):
		return

	# Pull player towards well
	var to_well: Vector2 = gravity_well_position - player.global_position
	var distance: float = to_well.length()

	if distance < stats.gravity_well_pull_distance:
		# Apply pull force
		var pull_strength: float = stats.gravity_well_strength * (1.0 - distance / stats.gravity_well_pull_distance)
		var pull_direction: Vector2 = to_well.normalized()

		# Apply to player velocity if possible
		if player.has("velocity"):
			player.velocity += pull_direction * pull_strength * delta

		# Deal damage periodically
		gravity_damage_timer += delta
		if gravity_damage_timer >= stats.gravity_damage_tick_rate:
			gravity_damage_timer = 0.0
			if player.has_method("take_damage"):
				player.take_damage(stats.gravity_well_damage)

	# Update visual
	if gravity_well_visual and is_instance_valid(gravity_well_visual):
		gravity_well_visual.global_position = gravity_well_position
		var pulse: float = sin(Time.get_ticks_msec() * 0.01) * 0.3 + 0.7
		gravity_well_visual.scale = Vector2.ONE * pulse

func _create_gravity_well_visual() -> void:
	# Create gravity well visual
	gravity_well_visual = Node2D.new()
	boss.get_parent().add_child(gravity_well_visual)
	gravity_well_visual.global_position = gravity_well_position

	# Create circle polygon
	var polygon: Polygon2D = Polygon2D.new()
	gravity_well_visual.add_child(polygon)

	# Create circle shape
	var points: PackedVector2Array = []
	var segments: int = 32
	var stats: Resource = boss.get_stats()
	var radius: float = stats.gravity_well_pull_distance

	for i in range(segments):
		var angle: float = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	polygon.polygon = points
	polygon.color = Color(0.8, 0.2, 0.8, 0.2)
#endregion

#region PLASMA_WALLS_EFFECT
func _activate_plasma_walls(data: Dictionary) -> void:
	var wall_count: int = data.get("count", 2)
	var duration: float = data.get("duration", 6.0)
	var damage: int = data.get("damage", 30)

	# Clear old walls
	_deactivate_plasma_walls()

	# Create new walls
	var arena_bounds: Rect2 = boss.get_arena_bounds()

	for i in range(wall_count):
		var wall_data: Dictionary = _create_plasma_wall(arena_bounds, damage)
		plasma_walls.append(wall_data)

	# Add to active effects
	var effect: ActiveEffect = ActiveEffect.new("plasma_walls", duration, data)
	active_effects.append(effect)

func _deactivate_plasma_walls() -> void:
	# Remove all walls
	for wall_data in plasma_walls:
		if wall_data.has("visual") and is_instance_valid(wall_data["visual"]):
			wall_data["visual"].queue_free()

	plasma_walls.clear()

func _update_plasma_walls(delta: float) -> void:
	if plasma_walls.is_empty():
		return

	var player: CharacterBody2D = boss.get_player()
	if player == null or not is_instance_valid(player):
		return

	# Check collision with player
	for wall_data in plasma_walls:
		var wall_pos: Vector2 = wall_data["position"]
		var wall_size: Vector2 = wall_data["size"]
		var wall_rect: Rect2 = Rect2(wall_pos - wall_size / 2.0, wall_size)

		if wall_rect.has_point(player.global_position):
			# Player is in wall - deal damage
			if player.has_method("take_damage"):
				# Damage every frame would be too much, use timer
				if not wall_data.has("damage_timer"):
					wall_data["damage_timer"] = 0.0

				wall_data["damage_timer"] += delta
				if wall_data["damage_timer"] >= 0.5:  # Damage every 0.5s
					wall_data["damage_timer"] = 0.0
					player.take_damage(wall_data["damage"])

func _create_plasma_wall(arena_bounds: Rect2, damage: int) -> Dictionary:
	# Random wall orientation
	var horizontal: bool = randf() > 0.5

	var wall_pos: Vector2
	var wall_size: Vector2

	if horizontal:
		# Horizontal wall
		var y: float = randf_range(arena_bounds.position.y + 100, arena_bounds.position.y + arena_bounds.size.y - 100)
		wall_pos = Vector2(arena_bounds.position.x + arena_bounds.size.x / 2.0, y)
		wall_size = Vector2(arena_bounds.size.x, 20.0)
	else:
		# Vertical wall
		var x: float = randf_range(arena_bounds.position.x + 100, arena_bounds.position.x + arena_bounds.size.x - 100)
		wall_pos = Vector2(x, arena_bounds.position.y + arena_bounds.size.y / 2.0)
		wall_size = Vector2(20.0, arena_bounds.size.y)

	# Create visual
	var wall_visual: Node2D = Node2D.new()
	boss.get_parent().add_child(wall_visual)
	wall_visual.global_position = wall_pos

	var polygon: Polygon2D = Polygon2D.new()
	wall_visual.add_child(polygon)

	var half_size: Vector2 = wall_size / 2.0
	polygon.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
	polygon.color = Color(1.0, 0.3, 0.3, 0.4)

	return {
		"position": wall_pos,
		"size": wall_size,
		"damage": damage,
		"visual": wall_visual
	}
#endregion

#region PUBLIC_API
## Check if a specific effect is active
func is_effect_active(effect_type: String) -> bool:
	for effect in active_effects:
		if effect.effect_type == effect_type:
			return true
	return false

## Get shield value for damage absorption
func get_shield_value() -> float:
	return shield_value if shield_active else 0.0
#endregion
