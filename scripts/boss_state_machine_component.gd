extends Node
class_name BossStateMachineComponent

## Boss State Machine Component
## Verwaltet Boss-States und Transitions
## Kommuniziert mit BossCore via Signals

#region STATE_ENUM
enum State {
	IDLE,
	CHASE,
	ATTACK,
	SPECIAL_ATTACK,
	RETREAT,
	STUNNED
}
#endregion

#region VARIABLES
var boss: Node = null  # BossCore reference
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

## Timers
var state_timer: float = 0.0
var attack_decision_timer: float = 0.0
const ATTACK_DECISION_INTERVAL: float = 2.0
#endregion

#region INITIALIZATION
func initialize(boss_ref: Node) -> void:
	boss = boss_ref

	# Connect to boss signals
	if boss:
		boss.phase_changed.connect(_on_boss_phase_changed)
		boss.health_changed.connect(_on_boss_health_changed)

	# Start in CHASE state
	_change_state(State.CHASE)
#endregion

#region MAIN_UPDATE
func update(delta: float) -> void:
	if boss == null:
		return

	state_timer += delta
	attack_decision_timer += delta

	# Update current state
	match current_state:
		State.IDLE:
			_update_idle(delta)
		State.CHASE:
			_update_chase(delta)
		State.ATTACK:
			_update_attack(delta)
		State.SPECIAL_ATTACK:
			_update_special_attack(delta)
		State.RETREAT:
			_update_retreat(delta)
		State.STUNNED:
			_update_stunned(delta)
#endregion

#region STATE_UPDATES
func _update_idle(delta: float) -> void:
	# Idle state: Boss doesn't do much
	if state_timer > 2.0:
		_change_state(State.CHASE)

func _update_chase(delta: float) -> void:
	# Chase state: Move towards player
	var player: CharacterBody2D = boss.get_player()
	if player == null or not is_instance_valid(player):
		_change_state(State.IDLE)
		return

	var distance_to_player: float = boss.global_position.distance_to(player.global_position)

	# Check if should attack
	if attack_decision_timer > ATTACK_DECISION_INTERVAL:
		attack_decision_timer = 0.0

		# Close enough to attack?
		if distance_to_player < 300.0:
			_decide_attack()

func _update_attack(delta: float) -> void:
	# Attack state: Perform attack then return to chase
	if state_timer > 1.5:
		_change_state(State.CHASE)

func _update_special_attack(delta: float) -> void:
	# Special attack state: Perform special attack then return to chase
	if state_timer > 2.5:
		_change_state(State.CHASE)

func _update_retreat(delta: float) -> void:
	# Retreat state: Move away from player
	if state_timer > 3.0:
		_change_state(State.CHASE)

func _update_stunned(delta: float) -> void:
	# Stunned state: Can't do anything
	if state_timer > 2.0:
		_change_state(State.CHASE)
#endregion

#region STATE_TRANSITIONS
func _change_state(new_state: State) -> void:
	if new_state == current_state:
		return

	# Exit current state
	_exit_state(current_state)

	# Change state
	previous_state = current_state
	current_state = new_state
	state_timer = 0.0

	# Enter new state
	_enter_state(current_state)

func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.CHASE:
			pass
		State.ATTACK:
			_perform_attack()
		State.SPECIAL_ATTACK:
			_perform_special_attack()
		State.RETREAT:
			pass
		State.STUNNED:
			pass

func _exit_state(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.CHASE:
			pass
		State.ATTACK:
			pass
		State.SPECIAL_ATTACK:
			pass
		State.RETREAT:
			pass
		State.STUNNED:
			pass
#endregion

#region ATTACK_LOGIC
func _decide_attack() -> void:
	var phase: int = boss.get_current_phase()
	var random_value: float = randf()

	# Phase-based attack selection
	match phase:
		1:
			# Phase 1: Simple attacks
			if random_value < 0.5:
				_change_state(State.ATTACK)
			else:
				_change_state(State.SPECIAL_ATTACK)
		2:
			# Phase 2: More special attacks
			if random_value < 0.3:
				_change_state(State.ATTACK)
			else:
				_change_state(State.SPECIAL_ATTACK)
		3:
			# Phase 3: Mostly special attacks
			if random_value < 0.2:
				_change_state(State.ATTACK)
			else:
				_change_state(State.SPECIAL_ATTACK)

func _perform_attack() -> void:
	# Request basic attack
	boss.request_attack("basic_laser")

func _perform_special_attack() -> void:
	var phase: int = boss.get_current_phase()
	var random_value: float = randf()

	# Choose special attack based on phase
	if phase == 1:
		boss.request_attack("minion_spawn")
	elif phase == 2:
		if random_value < 0.5:
			boss.request_attack("gravity_well")
		else:
			boss.request_attack("minion_spawn")
	else:  # Phase 3
		if random_value < 0.4:
			boss.request_attack("plasma_walls")
		elif random_value < 0.7:
			boss.request_attack("gravity_well")
		else:
			boss.request_attack("minion_spawn")
#endregion

#region SIGNAL_HANDLERS
func _on_boss_phase_changed(new_phase: int, old_phase: int) -> void:
	# React to phase change
	attack_decision_timer = 0.0  # Immediately consider new attack

func _on_boss_health_changed(current_health: int, max_health: int) -> void:
	# React to health change
	var health_percent: float = float(current_health) / float(max_health)

	# Maybe retreat when low health?
	if health_percent < 0.15 and current_state != State.RETREAT:
		# Low health - could trigger retreat or desperate attack
		pass
#endregion

#region PUBLIC_API
## Public method to get current state
func get_state() -> State:
	return current_state

## Force a state change (for testing or special conditions)
func force_state(new_state: State) -> void:
	_change_state(new_state)
#endregion
