extends Area2D

var heal_rate: float = 10.0  # HP per second
var radius: float = 150.0


func _ready() -> void:
	collision_layer = 8  # Items
	collision_mask = 1   # Player

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	modulate = Color(0, 1, 0.5, 0.7)
	add_to_group("health_stations")


func _on_body_entered(body: Node2D) -> void:
	"""Start healing player"""
	if body == GameManager.get_player() or body.is_in_group("player"):
		body.set_meta("in_health_station", true)


func _on_body_exited(body: Node2D) -> void:
	"""Stop healing player"""
	if body == GameManager.get_player() or body.is_in_group("player"):
		body.remove_meta("in_health_station")


func _physics_process(delta: float) -> void:
	"""Heal nearby players"""
	var player = GameManager.get_player()

	if not player or not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)
	if dist <= radius:
		if player.has_method("heal"):
			var heal_amount = int(heal_rate * delta)
			if heal_amount > 0:
				player.heal(heal_amount)
