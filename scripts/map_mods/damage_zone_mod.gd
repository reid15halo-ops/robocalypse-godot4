extends Area2D

## Damage Zone Map Modification
## Continuously damages enemies in range

@export var damage: int = 10
@export var damage_interval: float = 0.5
@export var damage_radius: float = 150.0
@export var lifetime: float = 30.0

@onready var damage_timer: Timer = $DamageTimer
@onready var visual: ColorRect = $Visual

var enemies_in_zone: Array[Node2D] = []


func _ready() -> void:
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Set damage interval
	damage_timer.wait_time = damage_interval

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func _process(_delta: float) -> void:
	# Pulse visual effect
	var time = Time.get_ticks_msec() / 1000.0
	visual.color.a = 0.2 + sin(time * 4.0) * 0.1


func _on_body_entered(body: Node2D) -> void:
	"""Enemy entered damage zone"""
	if body.is_in_group("enemies"):
		enemies_in_zone.append(body)


func _on_body_exited(body: Node2D) -> void:
	"""Enemy left damage zone"""
	if body in enemies_in_zone:
		enemies_in_zone.erase(body)


func _on_damage_timer_timeout() -> void:
	"""Damage all enemies in zone"""
	# Clean up invalid enemies
	enemies_in_zone = enemies_in_zone.filter(func(e): return is_instance_valid(e))

	# Damage each enemy
	for enemy in enemies_in_zone:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
