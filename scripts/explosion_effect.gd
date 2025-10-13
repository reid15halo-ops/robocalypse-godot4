extends Node2D

# Explosion effect - can use AnimatedSprite2D or ColorRect fallback

@export var explosion_radius: float = 150.0
@export var explosion_color: Color = Color(1.0, 0.5, 0.0, 0.7)
@export var fade_duration: float = 0.5

var sprite: AnimatedSprite2D = null
var color_rect: ColorRect = null
var use_sprites: bool = false


func _ready() -> void:
	if use_sprites:
		_create_sprite_explosion()
	else:
		_create_colorrect_explosion()


func _create_sprite_explosion() -> void:
	"""Create sprite-based explosion"""
	var sprite_path = "res://assets/sprites/effects/explosion.tres"

	if not ResourceLoader.exists(sprite_path):
		# Fallback to ColorRect
		use_sprites = false
		_create_colorrect_explosion()
		return

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load(sprite_path)
	sprite.z_index = 100
	add_child(sprite)

	sprite.play("explode")
	sprite.animation_finished.connect(_on_animation_finished)


func _create_colorrect_explosion() -> void:
	"""Create ColorRect-based explosion (fallback)"""
	color_rect = ColorRect.new()
	color_rect.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	color_rect.position = -color_rect.size / 2
	color_rect.color = explosion_color
	color_rect.z_index = 100
	add_child(color_rect)

	# Fade out
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(_on_fade_complete)


func _on_animation_finished() -> void:
	"""Called when sprite animation finishes"""
	queue_free()


func _on_fade_complete() -> void:
	"""Called when ColorRect fade finishes"""
	queue_free()
