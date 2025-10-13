extends Node2D

# Stats
var health: int = 200
var max_health: int = 200
var damage: int = 20
var fire_rate: float = 0.5
var range: float = 400.0
var fire_timer: float = 0.0

# Projectile
var laser_scene = preload("res://scenes/LaserBullet.tscn")


func _ready() -> void:
	modulate = Color(1, 0.5, 0)
	add_to_group("turrets")


func _physics_process(delta: float) -> void:
	fire_timer += delta

	if fire_timer >= fire_rate:
		fire_timer = 0.0
		_try_fire()


func _try_fire() -> void:
	"""Try to fire at nearest enemy"""
	var target = _find_nearest_enemy()

	if not target:
		return

	var dist = global_position.distance_to(target.global_position)
	if dist > range:
		return

	# Fire projectile
	var projectile = laser_scene.instantiate()
	projectile.global_position = global_position
	projectile.damage = damage

	var direction = (target.global_position - global_position).normalized()
	projectile.set_direction(direction)

	get_parent().add_child(projectile)


func _find_nearest_enemy() -> Node:
	"""Find nearest enemy in range"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist and dist <= range:
			nearest_dist = dist
			nearest = enemy

	return nearest


func take_damage(damage_amount: int) -> void:
	"""Take damage"""
	health -= damage_amount

	if health <= 0:
		queue_free()
