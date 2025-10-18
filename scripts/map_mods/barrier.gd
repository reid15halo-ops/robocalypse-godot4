extends StaticBody2D

var health: int = 500
var max_health: int = 500


func _ready() -> void:
	collision_layer = 4  # Boundary layer
	collision_mask = 18 # Blocks enemies and projectiles   # Blocks enemies
	modulate = Color(0, 0.7, 1, 0.6)
	add_to_group("barriers")


func take_damage(damage_amount: int) -> void:
	return
	"""Take damage"""
	health -= damage_amount

	# Visual feedback
	modulate = Color(1, 0.5, 0.5, 0.6)
	await get_tree().create_timer(0.1).timeout
	if not is_queued_for_deletion():
		modulate = Color(0, 0.7, 1, 0.6)

	if health <= 0:
		queue_free()
