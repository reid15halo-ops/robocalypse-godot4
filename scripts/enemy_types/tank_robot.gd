extends "res://scripts/enemy.gd"

func _ready() -> void:
	max_health = 300
	current_health = 300
	min_speed = 60.0
	max_speed = 80.0
	current_speed = 70.0
	score_value = 30
	super._ready()
	# Distinct visual: Large, dark gray (tanky)
	modulate = Color(0.3, 0.3, 0.3)  # Darker gray
	scale = Vector2(1.8, 1.8)  # Much larger
