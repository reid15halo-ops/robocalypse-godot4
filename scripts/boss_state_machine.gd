extends Node

var boss: CharacterBody2D
var phase: int = 1
var special_attack_timer: float = 0.0

const PHASE_SPEEDS := [140.0, 160.0, 185.0, 210.0]
const PHASE_COOLDOWNS := [4.5, 3.5, 2.8, 2.2]
const PHASE_MINION_COOLDOWNS := [6.0, 5.0, 4.0, 2.5]

var ability_pools: Dictionary = {
	1: ["laser_burst", "orbital_strike"],
	2: ["laser_burst", "orbital_strike", "shockwave_burst", "drone_swarm"],
	3: ["rapid_barrage", "plasma_wall", "gravity_well", "drone_swarm"],
	4: ["obliteration_beam", "gravity_well", "shield_overdrive", "plasma_wall"]
}

var states: Dictionary = {
	"idle": {
		"enter": "_idle_enter",
		"exit": "_idle_exit",
		"update": "_idle_update"
	},
	"attack": {
		"enter": "_attack_enter",
		"exit": "_attack_exit",
		"update": "_attack_update"
	},
	"special_attack": {
		"enter": "_special_attack_enter",
		"exit": "_special_attack_exit",
		"update": "_special_attack_update"
	}
}
var current_state: String = "idle"

func _init(boss_node: CharacterBody2D):
	boss = boss_node

func change_state(new_state: String) -> void:
	if not states.has(new_state):
		return

	if current_state and states[current_state].has("exit"):
		call(states[current_state]["exit"])

	current_state = new_state

	if states[current_state].has("enter"):
		call(states[current_state]["enter"])

func _physics_process(delta: float) -> void:
	# Update timers
	special_attack_timer += delta
	boss.minion_spawn_timer += delta

	# Check phase transitions
	_update_phase()

	if current_state and states[current_state].has("update"):
		call(states[current_state]["update"], delta)

	# Special attacks
	if special_attack_timer >= boss.special_attack_cooldown:
		special_attack_timer = 0.0
		change_state("special_attack")

	# Spawn minions
	if boss.minion_spawn_timer >= boss.minion_spawn_cooldown:
		boss.minion_spawn_timer = 0.0
		boss._spawn_minions()


func _idle_enter() -> void:
	print("Entering idle state")

func _idle_exit() -> void:
	print("Exiting idle state")

func _idle_update(delta: float) -> void:
	# Movement - chase player (with null check)
	if not boss.is_instance_valid(boss.player):
		return

	var direction: Vector2 = (boss.player.global_position - boss.global_position).normalized()
	boss.velocity = direction * boss.speed
	boss.move_and_slide()

func _attack_enter() -> void:
	print("Entering attack state")

func _attack_exit() -> void:
	print("Exiting attack state")

func _attack_update(delta: float) -> void:
	pass

func _special_attack_enter() -> void:
	print("Entering special attack state")
	_perform_special_attack()
	change_state("idle")

func _special_attack_exit() -> void:
	print("Exiting special attack state")

func _special_attack_update(delta: float) -> void:
	pass

func _update_phase() -> void:
	var health_percent: float = float(boss.current_health) / float(boss.max_health)
	var target_phase: int = 1

	if health_percent <= 0.20:
		target_phase = 4
	elif health_percent <= 0.45:
		target_phase = 3
	elif health_percent <= 0.75:
		target_phase = 2

	if target_phase != phase:
		phase = target_phase
		_set_phase_stats()
		AudioManager.play_boss_rage_sound()
		print("Boss shifted to phase ", phase)

func _set_phase_stats() -> void:
	var idx: int = clamp(phase - 1, 0, PHASE_SPEEDS.size() - 1)
	boss.speed = PHASE_SPEEDS[idx]
	boss.special_attack_cooldown = PHASE_COOLDOWNS[idx]
	boss.minion_spawn_cooldown = PHASE_MINION_COOLDOWNS[idx]
	special_attack_timer = 0.0
	boss.minion_spawn_timer = 0.0
	boss.visuals._apply_phase_color()

func _perform_special_attack() -> void:
	var pool: Array = ability_pools.get(phase, ability_pools.get(ability_pools.keys().max(), []))
	if pool.is_empty():
		return

	var ability_name: String = pool[randi() % pool.size()]

	if boss.attacks.has_method("_" + ability_name):
		boss.attacks.call("_" + ability_name)
