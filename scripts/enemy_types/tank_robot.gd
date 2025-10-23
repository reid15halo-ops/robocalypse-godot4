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


func _set_sprite_frames() -> void:
	"""Override to load tank-specific sprite frames"""
	var sprite_path = "res://assets/anim/drone_heavy.tres"
	if ResourceLoader.exists(sprite_path):
		sprite.sprite_frames = load(sprite_path)
	else:
		push_warning("Tank robot sprite frames not found: " + sprite_path)
