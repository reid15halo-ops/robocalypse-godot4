extends "res://scripts/enemy.gd"

func _ready() -> void:
	max_health = 60
	current_health = 60
	min_speed = 200.0
	max_speed = 240.0
	current_speed = 220.0
	score_value = 12
	super._ready()
	# Distinct visual: Bright yellow/orange, elongated (fast)
	modulate = Color(1.5, 1.0, 0)  # Bright yellow-orange
	scale = Vector2(0.7, 1.2)  # Elongated for speed look
