extends Node2D

## Boss Test Scene
## Simple test environment for Boss debugging

var boss: Node = null
var player: Node = null

func _ready() -> void:
	# Get references
	player = get_node_or_null("Player")
	boss = get_node_or_null("Boss")

	if player:
		player.add_to_group("player")
		print("Player ready at: ", player.global_position)

	if boss:
		print("Boss ready at: ", boss.global_position)
		print("Boss stats: ", boss.stats if "stats" in boss else "No stats")

	# Initialize GameManager if needed
	if not GameManager:
		print("WARNING: GameManager not available")
	else:
		print("GameManager available")

func _process(_delta: float) -> void:
	# Simple debug info
	if boss and is_instance_valid(boss):
		if boss.has_method("get_health_percent"):
			var hp_percent: float = boss.get_health_percent()
			if Input.is_action_just_pressed("ui_accept"):  # Space key
				print("Boss Health: %.1f%%" % (hp_percent * 100.0))
				print("Boss Phase: ", boss.get_current_phase() if boss.has_method("get_current_phase") else "Unknown")

	# Press T to damage boss
	if Input.is_action_just_pressed("ui_text_completion_replace"):  # T key
		if boss and boss.has_method("take_damage"):
			boss.take_damage(500)
			print("Boss took 500 damage!")

	# Press K to kill boss
	if Input.is_key_pressed(KEY_K):
		if boss and boss.has_method("take_damage"):
			boss.take_damage(99999)
			print("Boss killed!")
