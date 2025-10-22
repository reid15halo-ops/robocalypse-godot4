extends CanvasLayer
## SceneTransition - Handles smooth fade in/out transitions between scenes

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_transitioning: bool = false


func _ready() -> void:
	# Initially invisible
	color_rect.visible = false


func change_scene_to_file(scene_path: String) -> void:
	"""Change scene with fade transition"""
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# Fade out
	color_rect.visible = true
	animation_player.play("fade_out")
	await animation_player.animation_finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)
	
	# Fade in
	animation_player.play("fade_in")
	await animation_player.animation_finished
	
	color_rect.visible = false
	is_transitioning = false


func fade_out() -> void:
	"""Fade to black"""
	if is_transitioning:
		return
	
	is_transitioning = true
	color_rect.visible = true
	animation_player.play("fade_out")
	await animation_player.animation_finished
	is_transitioning = false


func fade_in() -> void:
	"""Fade from black"""
	if is_transitioning:
		return
	
	is_transitioning = true
	color_rect.visible = true
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.visible = false
	is_transitioning = false
