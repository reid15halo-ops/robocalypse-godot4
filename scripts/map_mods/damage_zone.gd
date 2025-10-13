extends Area2D

var damage_per_second: float = 15.0
var radius: float = 200.0
var damage_timer: float = 0.0
var damage_interval: float = 0.5


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2  # Enemies

	modulate = Color(1, 0.3, 0, 0.5)
	add_to_group("damage_zones")


func _physics_process(delta: float) -> void:
	"""Damage enemies in range"""
	damage_timer += delta

	if damage_timer >= damage_interval:
		damage_timer = 0.0
		_apply_damage()


func _apply_damage() -> void:
	"""Damage all enemies in radius"""
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(int(damage_per_second * damage_interval))
