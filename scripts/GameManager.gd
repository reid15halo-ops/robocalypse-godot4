extends Node

# Route modifiers for route selection system
enum RouteModifier {
	NONE,
	SKYWARD_RUSH,    # Green - Bounce pads, updrafts, smoke bombs
	STORMFRONT,      # Yellow - Lightning rods, puddles, electrified trails
	EMP_OVERLOAD     # Red - EMP pulses, magnetic shields, Tesla coils
}

# Signals
signal score_changed(new_score: int)
signal game_over
signal route_selected(route: RouteModifier)

# Game state
var score: int = 0
var is_game_over: bool = false
var is_paused: bool = false
var wave_count: int = 0
var current_route: RouteModifier = RouteModifier.NONE

# Player reference
var player: CharacterBody2D = null


func _ready() -> void:
	# Initialize game state
	reset_game()


func reset_game() -> void:
	"""Reset all game variables to initial state"""
	score = 0
	is_game_over = false
	is_paused = false
	player = null
	wave_count = 0
	current_route = RouteModifier.NONE
	score_changed.emit(score)


func add_score(points: int) -> void:
	"""Add points to the score"""
	if is_game_over:
		return

	score += points
	score_changed.emit(score)


func trigger_game_over() -> void:
	"""Trigger game over state"""
	if is_game_over:
		return

	is_game_over = true
	game_over.emit()
	print("Game Over! Final Score: ", score)


func toggle_pause() -> void:
	"""Toggle pause state"""
	is_paused = not is_paused
	get_tree().paused = is_paused


func set_player(player_node: CharacterBody2D) -> void:
	"""Set reference to player node"""
	player = player_node


func get_player() -> CharacterBody2D:
	"""Get reference to player node"""
	return player
