extends Node

# Time Control - Manages slow motion and pause states
# Autoload singleton for centralized time management

# Time control
var normal_time_scale: float = 1.0
var slow_mo_time_scale: float = 0.15
var is_slow_motion: bool = false

# Pause reasons
enum PauseReason {
	NONE,
	MANUAL_PAUSE,
	WAVE_COMPLETE,
	LEVEL_UP,
	GAME_OVER
}

var current_pause_reason: PauseReason = PauseReason.NONE

# Signals
signal slow_motion_started()
signal slow_motion_ended()
signal time_paused(reason: PauseReason)
signal time_resumed()


func activate_slow_motion(duration: float = 0.0) -> void:
	"""Activate slow motion effect"""
	if is_slow_motion:
		return

	is_slow_motion = true
	Engine.time_scale = slow_mo_time_scale
	slow_motion_started.emit()
	print("Slow motion activated (", slow_mo_time_scale, "x speed)")

	# Auto-disable after duration (using unscaled time)
	if duration > 0:
		# Wait for real seconds, not scaled time
		var start_time = Time.get_ticks_msec()
		var wait_ms = duration * 1000

		while is_slow_motion and (Time.get_ticks_msec() - start_time) < wait_ms:
			await get_tree().process_frame

		if is_slow_motion:  # Check if still in slow-mo
			deactivate_slow_motion()


func deactivate_slow_motion() -> void:
	"""Deactivate slow motion"""
	if not is_slow_motion:
		return

	is_slow_motion = false
	Engine.time_scale = normal_time_scale
	slow_motion_ended.emit()
	print("Slow motion deactivated")


func pause_game(reason: PauseReason) -> void:
	"""Pause the game with reason"""
	current_pause_reason = reason
	get_tree().paused = true
	time_paused.emit(reason)
	print("Game paused: ", PauseReason.keys()[reason])


func resume_game() -> void:
	"""Resume the game"""
	if current_pause_reason == PauseReason.NONE:
		return

	current_pause_reason = PauseReason.NONE
	get_tree().paused = false
	time_resumed.emit()
	print("Game resumed")


func is_paused() -> bool:
	"""Check if game is paused"""
	return current_pause_reason != PauseReason.NONE


func get_pause_reason() -> PauseReason:
	"""Get current pause reason"""
	return current_pause_reason


func _exit_tree() -> void:
	"""Clean up on exit"""
	# Reset time scale
	Engine.time_scale = normal_time_scale
	is_slow_motion = false
