extends Area2D

var speed_multiplier: float = 1.5
var radius: float = 100.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1  # Player

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	modulate = Color(1, 1, 0, 0.6)
	add_to_group("speed_pads")


func _on_body_entered(body: Node2D) -> void:
	"""Apply speed boost"""
	if body == GameManager.get_player() or body.is_in_group("player"):
		if body.has("speed"):
			body.set_meta("speed_pad_original_speed", body.speed)
			body.speed *= speed_multiplier


func _on_body_exited(body: Node2D) -> void:
	"""Remove speed boost"""
	if body == GameManager.get_player() or body.is_in_group("player"):
		if body.has_meta("speed_pad_original_speed"):
			body.speed = body.get_meta("speed_pad_original_speed")
			body.remove_meta("speed_pad_original_speed")
