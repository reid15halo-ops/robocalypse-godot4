extends "res://scripts/projectile.gd"

# Rocket projectile - slow with area explosion


func _ready() -> void:
	# Rocket properties
	speed = 250.0
	damage = 50
	max_distance = 1000.0
	lifetime = 5.0

	# No penetration
	can_penetrate = false

	# Explosion
	has_explosion = true
	explosion_radius = 100.0

	# Call parent ready
	super._ready()
