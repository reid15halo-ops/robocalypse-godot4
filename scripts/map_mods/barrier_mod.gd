extends StaticBody2D

## Barrier Map Modification
## Blocks enemy movement, destructible

@export var max_health: int = 200
@export var lifetime: float = 45.0

@onready var health_bar: ProgressBar = $HealthBar
@onready var visual: ColorRect = $Visual

var current_health: int = max_health


func _ready() -> void:
	# Initialize health bar
	health_bar.max_value = max_health
	health_bar.value = current_health

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func take_damage(amount: int) -> void:
	"""Take damage from enemies"""
	current_health -= amount
	current_health = max(0, current_health)

	# Update visual
	_update_visual()

	# Check if destroyed
	if current_health <= 0:
		_on_destroyed()


func _update_visual() -> void:
	"""Update health bar and visual alpha"""
	health_bar.value = current_health

	# Fade out as health decreases
	var health_percent = float(current_health) / float(max_health)
	visual.color.a = 0.3 + (health_percent * 0.5)


func _on_destroyed() -> void:
	"""Called when barrier is destroyed"""
	queue_free()
