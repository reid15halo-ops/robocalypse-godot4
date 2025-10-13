extends "res://scripts/projectile.gd"

# Shotgun pellet - medium speed, short range


func _ready() -> void:
	# Pellet properties
	speed = 400.0
	damage = 8
	max_distance = 400.0  # Shorter range for shotgun
	lifetime = 2.0

	# No penetration
	can_penetrate = false

	# No explosion
	has_explosion = false

	# Call parent ready
	super._ready()
