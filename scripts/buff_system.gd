extends Node

# Buff types
enum BuffType {
	SPEED,
	DAMAGE,
	SHIELD,
	DAMAGE_REDUCTION,
	HP_REGEN
}

# Active buffs structure: {entity: [{type, value, source, duration, timer}]}
var active_buffs: Dictionary = {}


func apply_buff(target: Node, buff_type: BuffType, value: float, source: Node, duration: float = -1.0) -> void:
	"""Apply a buff to a target"""
	if not target:
		return

	# Initialize array if needed
	if not active_buffs.has(target):
		active_buffs[target] = []

	# Check if buff from same source already exists
	for buff in active_buffs[target]:
		if buff.type == buff_type and buff.source == source:
			# Refresh duration
			buff.timer = duration
			return

	# Add new buff
	var buff_data = {
		"type": buff_type,
		"value": value,
		"source": source,
		"duration": duration,
		"timer": duration
	}

	active_buffs[target].append(buff_data)
	_apply_buff_effect(target, buff_type, value)


func remove_buff(target: Node, buff_type: BuffType, source: Node) -> void:
	"""Remove a specific buff"""
	if not active_buffs.has(target):
		return

	for i in range(active_buffs[target].size() - 1, -1, -1):
		var buff = active_buffs[target][i]
		if buff.type == buff_type and buff.source == source:
			_remove_buff_effect(target, buff_type, buff.value)
			active_buffs[target].remove_at(i)
			break


func remove_all_buffs_from_source(source: Node) -> void:
	"""Remove all buffs from a specific source (when source dies)"""
	for target in active_buffs.keys():
		if not is_instance_valid(target):
			active_buffs.erase(target)
			continue

		for i in range(active_buffs[target].size() - 1, -1, -1):
			var buff = active_buffs[target][i]
			if buff.source == source:
				_remove_buff_effect(target, buff.type, buff.value)
				active_buffs[target].remove_at(i)


func _physics_process(delta: float) -> void:
	"""Update buff timers"""
	for target in active_buffs.keys():
		# Clean up invalid targets
		if not is_instance_valid(target) or (target.has_method("is_queued_for_deletion") and target.is_queued_for_deletion()):
			active_buffs.erase(target)
			continue

		# Update timers
		for i in range(active_buffs[target].size() - 1, -1, -1):
			var buff = active_buffs[target][i]

			# Permanent buffs (duration = -1) don't expire
			if buff.duration < 0:
				continue

			buff.timer -= delta
			if buff.timer <= 0:
				_remove_buff_effect(target, buff.type, buff.value)
				active_buffs[target].remove_at(i)


func _apply_buff_effect(target: Node, buff_type: BuffType, value: float) -> void:
	"""Apply buff stat changes"""
	if not target:
		return

	match buff_type:
		BuffType.SPEED:
			if target.has("current_speed"):
				target.current_speed += value
		BuffType.DAMAGE:
			if target.has("melee_damage"):
				target.melee_damage += int(value)
			elif target.has("damage"):
				target.damage += int(value)
		BuffType.SHIELD:
			if target.has_method("add_shield"):
				target.add_shield(int(value))
			elif target.has("shield_hp"):
				target.shield_hp += int(value)
		BuffType.DAMAGE_REDUCTION:
			if target.has("damage_reduction"):
				target.damage_reduction = min(target.damage_reduction + value, 0.9)
		BuffType.HP_REGEN:
			var current = target.get("hp_regen_rate")
			if typeof(current) == TYPE_NIL:
				return
			target.set("hp_regen_rate", float(current) + value)


func _remove_buff_effect(target: Node, buff_type: BuffType, value: float) -> void:
	"""Remove buff stat changes"""
	if not is_instance_valid(target):
		return

	match buff_type:
		BuffType.SPEED:
			if target.has("current_speed"):
				target.current_speed -= value
				target.current_speed = max(target.current_speed, 10.0)  # Min speed
		BuffType.DAMAGE:
			if target.has("melee_damage"):
				target.melee_damage -= int(value)
				target.melee_damage = max(target.melee_damage, 1)
			elif target.has("damage"):
				target.damage -= int(value)
				target.damage = max(target.damage, 1)
		BuffType.SHIELD:
			if target.has_method("add_shield"):
				target.add_shield(-int(value))
			elif target.has("shield_hp"):
				target.shield_hp -= int(value)
				target.shield_hp = max(target.shield_hp, 0)
		BuffType.DAMAGE_REDUCTION:
			if target.has("damage_reduction"):
				target.damage_reduction -= value
				target.damage_reduction = max(target.damage_reduction, 0.0)
		BuffType.HP_REGEN:
			var current = target.get("hp_regen_rate")
			if typeof(current) == TYPE_NIL:
				return
			var new_value = max(float(current) - value, 0.0)
			target.set("hp_regen_rate", new_value)


func get_buff_count(target: Node, buff_type: BuffType) -> int:
	"""Get number of active buffs of a type on target"""
	if not active_buffs.has(target):
		return 0

	var count = 0
	for buff in active_buffs[target]:
		if buff.type == buff_type:
			count += 1

	return count


func has_buff(target: Node, buff_type: BuffType) -> bool:
	"""Check if target has a specific buff"""
	return get_buff_count(target, buff_type) > 0
