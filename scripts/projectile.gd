extends Area2D

# Base class for all projectiles

# Movement
@export var speed: float = 400.0
@export var damage: int = 10
@export var max_distance: float = 1000.0
@export var lifetime: float = 5.0

# Tracking
var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO

# Penetration
@export var can_penetrate: bool = false
@export var max_penetrations: int = 0
var penetration_count: int = 0

# Explosion
@export var has_explosion: bool = false
@export var explosion_radius: float = 0.0

var _enemy_overlap_shape := CircleShape2D.new()


func _ready() -> void:
	# Set collision
	collision_layer = 8  # Dedicated projectile layer
	collision_mask = 4   # Only collide physically with walls

	# Track spawn position
	spawn_position = global_position

	# Connect area entered
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	# Move in direction
	var velocity = direction * speed * delta
	global_position += velocity
	_check_enemy_overlap()

	# Track distance
	traveled_distance += velocity.length()

	# Check max distance
	if traveled_distance >= max_distance:
		_on_max_distance_reached()


func _on_area_entered(area: Area2D) -> void:
	# Override in child classes if needed
	pass


func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with enemies and boundaries"""
	if body is StaticBody2D:
		# Hit boundary wall
		_on_impact(global_position)


func _hit_enemy(enemy: Node2D) -> void:
	"""Apply damage to enemy"""
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# Check penetration
	if can_penetrate and penetration_count < max_penetrations:
		penetration_count += 1
	else:
		# Destroy projectile
		_on_impact(enemy.global_position)


func _on_impact(impact_position: Vector2) -> void:
	"""Called when projectile hits something"""
	if has_explosion:
		_create_explosion(impact_position)

	queue_free()


func _on_max_distance_reached() -> void:
	"""Called when projectile reaches max distance"""
	queue_free()


func _create_explosion(center: Vector2) -> void:
	"""Create explosion damage area"""
	# Find all enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = center.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

	# Visual feedback
	_spawn_explosion_visual(center)


func _spawn_explosion_visual(center: Vector2) -> void:
	"""Create visual explosion effect"""
	var explosion = ColorRect.new()
	explosion.color = Color(1.0, 0.5, 0.0, 0.7)
	explosion.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	explosion.position = center - explosion.size / 2

	# Add to game scene (not projectile parent which may be freed)
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene:
		game_scene.add_child(explosion)
	else:
		get_tree().root.add_child(explosion)

	# Fade out and destroy with safe callback
	var tween = get_tree().create_tween()
	tween.tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(explosion):
			explosion.queue_free()
	)


func set_direction(new_direction: Vector2) -> void:
	"""Set the direction of the projectile"""
	direction = new_direction.normalized()
	# Rotate sprite to face direction
	rotation = direction.angle()


func _check_enemy_overlap() -> void:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	_enemy_overlap_shape.radius = 12.0
	query.shape = _enemy_overlap_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2  # Enemy layer
	query.exclude = []

	var results := space_state.intersect_shape(query, 4)
	for result in results:
		var collider: Node = result.get("collider") as Node
		if collider and collider.is_in_group("enemies"):
			_hit_enemy(collider)
			break
