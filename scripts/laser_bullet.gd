extends "res://scripts/projectile.gd"

# Laser projectile - fast and penetrating


func _ready() -> void:
	# Laser properties
	speed = 600.0
	damage = 15
	max_distance = 1200.0
	lifetime = 3.0

	# Penetration
	can_penetrate = true
	max_penetrations = 3

	# No explosion
	has_explosion = false

	# Call parent ready
	super._ready()
