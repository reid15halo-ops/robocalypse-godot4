extends StaticBody2D

## Health Station Map Modification
## Heals player over time when in range

@export var heal_amount: int = 5
@export var heal_interval: float = 1.0
@export var heal_radius: float = 100.0
@export var lifetime: float = 60.0

@onready var heal_area: Area2D = $HealArea
@onready var heal_timer: Timer = $HealTimer

var player_in_range: bool = false
var player: Node2D = null


func _ready() -> void:
	# Connect signals
	heal_area.body_entered.connect(_on_heal_area_body_entered)
	heal_area.body_exited.connect(_on_heal_area_body_exited)

	# Set heal interval
	heal_timer.wait_time = heal_interval

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func _on_heal_area_body_entered(body: Node2D) -> void:
	"""Player entered heal range"""
	if body.is_in_group("player"):
		player_in_range = true
		player = body


func _on_heal_area_body_exited(body: Node2D) -> void:
	"""Player left heal range"""
	if body.is_in_group("player"):
		player_in_range = false
		player = null


func _on_heal_timer_timeout() -> void:
	"""Heal player if in range"""
	if player_in_range and player and is_instance_valid(player):
		if player.has_method("heal"):
			player.heal(heal_amount)
