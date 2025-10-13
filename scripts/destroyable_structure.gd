extends StaticBody2D

# Destroyable Structure - Can be damaged by player


func take_damage(damage: int) -> void:
	"""Take damage and update health bar"""
	var current_hp = get_meta("current_hp", 0)
	var max_hp = get_meta("max_hp", 100)

	current_hp -= damage
	current_hp = max(0, current_hp)
	set_meta("current_hp", current_hp)

	# Update health bar
	var health_bar = get_node_or_null("HealthBar")
	if health_bar and health_bar is ColorRect:
		var health_percent = float(current_hp) / float(max_hp)
		health_bar.size.x = 80 * health_percent

	# Visual feedback - flash white
	modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color.WHITE

	# Check if destroyed
	if current_hp <= 0:
		_on_destroyed()


func _on_destroyed() -> void:
	"""Handle structure destruction"""
	print("Structure destroyed!")

	# Notify ObjectiveSystem
	ObjectiveSystem.structure_destroyed()

	# Visual effect - explosion
	modulate = Color(2.0, 0.5, 0.0)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(self):
		queue_free()
