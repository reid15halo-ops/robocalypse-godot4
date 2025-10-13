extends Area2D

# Lifetime
var lifetime: float = 30.0
var lifetime_timer: float = 0.0

# Loot table
enum LootType {
	SCRAP,
	HEALTH,
	TEMP_DAMAGE_BUFF,
	TEMP_SPEED_BUFF,
	AMMO
}

var loot_weights = {
	LootType.SCRAP: 40,
	LootType.HEALTH: 30,
	LootType.TEMP_DAMAGE_BUFF: 15,
	LootType.TEMP_SPEED_BUFF: 10,
	LootType.AMMO: 5
}


func _ready() -> void:
	# Set collision
	collision_layer = 8  # Layer 4 (Items)
	collision_mask = 1   # Layer 1 (Player)

	# Connect signal
	body_entered.connect(_on_body_entered)

	# Start blinking near end of lifetime
	_start_lifetime_warning()


func _physics_process(delta: float) -> void:
	lifetime_timer += delta

	if lifetime_timer >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	"""Handle pickup"""
	if body.is_in_group("player") or body == GameManager.get_player():
		_give_loot(body)
		queue_free()


func _give_loot(player: Node) -> void:
	"""Give random loot to player"""
	var loot_type = _roll_loot()

	if loot_type == LootType.SCRAP:
		var amount = randi_range(20, 50)
		var game_scene = get_tree().get_first_node_in_group("game_scene")
		if game_scene and game_scene.has_method("add_scrap"):
			game_scene.add_scrap(amount)
			print("Picked up ", amount, " scrap!")
	elif loot_type == LootType.HEALTH:
		if player.has_method("heal"):
			player.heal(30)
		print("Picked up health pack!")
	elif loot_type == LootType.TEMP_DAMAGE_BUFF:
		var original_damage = player.melee_damage
		player.melee_damage = int(player.melee_damage * 1.5)
		await get_tree().create_timer(15.0).timeout
		if is_instance_valid(player):
			player.melee_damage = original_damage
		print("Picked up damage buff (15s)!")
	elif loot_type == LootType.TEMP_SPEED_BUFF:
		var original_speed = player.speed
		player.speed *= 1.3
		await get_tree().create_timer(10.0).timeout
		if is_instance_valid(player):
			player.speed = original_speed
		print("Picked up speed buff (10s)!")
	elif loot_type == LootType.AMMO:
		# Could give weapon fire rate boost
		print("Picked up ammo boost!")


func _roll_loot() -> LootType:
	"""Roll for loot type based on weights"""
	var total_weight = 0
	for weight in loot_weights.values():
		total_weight += weight

	var roll = randf() * total_weight
	var current_weight = 0

	for loot_type in loot_weights:
		current_weight += loot_weights[loot_type]
		if roll <= current_weight:
			return loot_type

	return LootType.SCRAP


func _start_lifetime_warning() -> void:
	"""Start blinking when near expiration"""
	await get_tree().create_timer(lifetime - 5.0).timeout

	if is_queued_for_deletion():
		return

	# Blink
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.3, 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
