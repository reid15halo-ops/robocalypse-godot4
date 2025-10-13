extends StaticBody2D

## Auto-Turret - Player Ability
## Automatically fires at nearby enemies

@export var damage: int = 30
@export var fire_rate: float = 0.5
@export var detection_radius: float = 400.0
@export var projectile_speed: float = 500.0
@export var lifetime: float = 10.0

@onready var detection_area: Area2D = $DetectionArea
@onready var fire_timer: Timer = $FireTimer
@onready var visual: Node2D = $Visual

var current_target: Node2D = null
var enemies_in_range: Array[Node2D] = []


func _ready() -> void:
	# Connect signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	# Set fire rate
	fire_timer.wait_time = fire_rate

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _process(_delta: float) -> void:
	# Track nearest enemy
	_update_target()

	# Rotate turret to face target
	if current_target and is_instance_valid(current_target):
		var direction = (current_target.global_position - global_position).normalized()
		visual.rotation = direction.angle() + PI / 2


func _update_target() -> void:
	"""Find nearest enemy in range"""
	# Clean up invalid enemies
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))

	if enemies_in_range.is_empty():
		current_target = null
		return

	# Find nearest
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for enemy in enemies_in_range:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	current_target = nearest


func _on_detection_area_body_entered(body: Node2D) -> void:
	"""Enemy entered detection range"""
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)


func _on_detection_area_body_exited(body: Node2D) -> void:
	"""Enemy left detection range"""
	if body in enemies_in_range:
		enemies_in_range.erase(body)


func _on_fire_timer_timeout() -> void:
	"""Fire at current target"""
	if current_target and is_instance_valid(current_target):
		_fire_projectile()


func _fire_projectile() -> void:
	"""Create and fire projectile at target"""
	# Load projectile scene
	var projectile_scene = preload("res://scenes/LaserBullet.tscn")
	var projectile = projectile_scene.instantiate()

	# Set position and direction
	projectile.global_position = global_position
	var direction = (current_target.global_position - global_position).normalized()
	projectile.set_direction(direction)

	# Override damage
	projectile.damage = damage
	projectile.speed = projectile_speed

	# Add to scene
	get_tree().root.add_child(projectile)
