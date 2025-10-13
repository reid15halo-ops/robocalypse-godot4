extends Area2D

## Speed Pad Map Modification
## Increases player movement speed while standing on it

@export var speed_multiplier: float = 1.5
@export var lifetime: float = 45.0

var player_on_pad: bool = false
var player: Node2D = null
var original_speed: float = 0.0


func _ready() -> void:
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		# Restore player speed if still on pad
		if player_on_pad and player and is_instance_valid(player):
			_remove_speed_boost()
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	"""Player stepped on speed pad"""
	if body.is_in_group("player"):
		player_on_pad = true
		player = body
		_apply_speed_boost()


func _on_body_exited(body: Node2D) -> void:
	"""Player left speed pad"""
	if body.is_in_group("player"):
		player_on_pad = false
		_remove_speed_boost()
		player = null


func _apply_speed_boost() -> void:
	"""Apply speed boost to player"""
	if player and player.has("move_speed"):
		original_speed = player.move_speed
		player.move_speed *= speed_multiplier


func _remove_speed_boost() -> void:
	"""Remove speed boost from player"""
	if player and is_instance_valid(player) and player.has("move_speed"):
		player.move_speed = original_speed
