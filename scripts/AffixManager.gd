extends Node

## AffixManager – handles route-based environmental modifiers

enum AffixType {
	# Green Route Affixes (Mobility/Movement)
	JUMPPADS,
	TELEPORT_PORTALS,
	UPDRAFTS,
	SMOKE_CLOUDS,

	# Yellow Route Affixes (Electrical Hazards)
	SWAMP_ZONES,
	ACID_RAIN,
	LIGHTNING_BOLTS,
	STATIC_FIELD,

	# Red Route Affixes (Chaos/Disruption)
	EMP_STORMS,
	RANDOM_LIGHTNING,
	MAGNETIC_PULSE,
	TESLA_GRID
}

const MAX_ACTIVE_NODES := 10

# Pools per route colour
const ROUTE_POOLS := {
	GameManager.RouteModifier.SKYWARD_RUSH: [AffixType.JUMPPADS, AffixType.TELEPORT_PORTALS, AffixType.UPDRAFTS, AffixType.SMOKE_CLOUDS],
	GameManager.RouteModifier.STORMFRONT: [AffixType.SWAMP_ZONES, AffixType.ACID_RAIN, AffixType.LIGHTNING_BOLTS, AffixType.STATIC_FIELD],
	GameManager.RouteModifier.EMP_OVERLOAD: [AffixType.EMP_STORMS, AffixType.RANDOM_LIGHTNING, AffixType.MAGNETIC_PULSE, AffixType.TESLA_GRID],
}

var game_scene: Node2D = null
var player: CharacterBody2D = null

var active_affixes: Dictionary = {}  # AffixType -> {nodes, timers, update, cleanup, data}
var active_node_count: int = 0

var _rain_backup: Dictionary = {}
var _audio_cooldowns: Dictionary = {}


func initialize(p_game_scene: Node2D, p_player: CharacterBody2D) -> void:
	game_scene = p_game_scene
	player = p_player
	set_process(false)


func apply_route_affixes(route: int) -> void:
	clear_all_affixes()

	var pool: Array = ROUTE_POOLS.get(route, [])
	if pool.is_empty():
		return

	for affix_type in pool:
		_activate_affix(affix_type)

	set_process(not active_affixes.is_empty())


func clear_all_affixes() -> void:
	for affix_type in active_affixes.keys():
		_deactivate_affix(affix_type)
	active_affixes.clear()
	active_node_count = 0
	set_process(false)


func shutdown() -> void:
	clear_all_affixes()


func get_active_affixes() -> Array:
	return active_affixes.keys()


func _process(delta: float) -> void:
	for entry in active_affixes.values():
		var update_callable: Callable = entry.get("update", Callable())
		if update_callable.is_valid():
			update_callable.call(delta)


func _activate_affix(affix_type: int) -> void:
	if active_affixes.has(affix_type):
		return

	var entry: Dictionary = {}
	match affix_type:
		AffixType.JUMPPADS:
			entry = _init_jump_pads()
		AffixType.TELEPORT_PORTALS:
			entry = _init_teleport_portals()
		AffixType.UPDRAFTS:
			entry = _init_updrafts()
		AffixType.SMOKE_CLOUDS:
			entry = _init_smoke_clouds()
		AffixType.SWAMP_ZONES:
			entry = _init_swamp_zones()
		AffixType.ACID_RAIN:
			entry = _init_acid_rain()
		AffixType.LIGHTNING_BOLTS:
			entry = _init_lightning_bolts()
		AffixType.STATIC_FIELD:
			entry = _init_static_field()
		AffixType.EMP_STORMS:
			entry = _init_emp_storms()
		AffixType.RANDOM_LIGHTNING:
			entry = _init_random_lightning()
		AffixType.MAGNETIC_PULSE:
			entry = _init_magnetic_pulse()
		AffixType.TESLA_GRID:
			entry = _init_tesla_grid()
		_:
			return

	if entry.is_empty():
		return

	var nodes: Array = entry.get("nodes", [])
	if active_node_count + nodes.size() > MAX_ACTIVE_NODES:
		print("AffixManager: skipping ", AffixType.keys()[affix_type], " (node cap reached)")
		for node in nodes:
			if node and node is Node:
				node.queue_free()
		return

	for node in nodes:
		if node and node is Node:
			game_scene.add_child(node)
	var timers: Array = entry.get("timers", [])
	for timer in timers:
		if timer and timer is Timer:
			game_scene.add_child(timer)
			timer.start()

	active_node_count += nodes.size()
	active_affixes[affix_type] = entry


func _deactivate_affix(affix_type: int) -> void:
	var entry: Dictionary = active_affixes.get(affix_type, {})
	if entry.is_empty():
		return

	var cleanup: Callable = entry.get("cleanup", Callable())
	if cleanup.is_valid():
		cleanup.call()

	var timers: Array = entry.get("timers", [])
	for timer in timers:
		if timer and timer is Timer:
			timer.stop()
			timer.queue_free()

	var nodes: Array = entry.get("nodes", [])
	for node in nodes:
		if node and node is Node and node.is_inside_tree():
			node.queue_free()

	active_node_count = max(0, active_node_count - nodes.size())
	active_affixes.erase(affix_type)


# -----------------------------------------------------------------------------
# GREEN ROUTE
# -----------------------------------------------------------------------------

func _init_jump_pads() -> Dictionary:
	var container := Node2D.new()
	container.name = "Affix_JumpPads"

	var pad_count := 3
	var pads: Array[Area2D] = []

	for i in range(pad_count):
		var pad := Area2D.new()
		pad.name = "JumpPad_%d" % i
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 96.0
		shape.shape = circle
		pad.add_child(shape)

		var visual := ColorRect.new()
		visual.size = Vector2(160, 160)
		visual.position = -visual.size / 2
		visual.color = Color(0.2, 1.0, 0.3, 0.4)
		pad.add_child(visual)

		var callback := Callable(self, "_on_jump_pad_entered").bind(pad)
		pad.set_meta("body_callback", callback)
		pad.body_entered.connect(callback)
		pad.global_position = _get_random_arena_position()
		container.add_child(pad)
		pads.append(pad)

	return {
		"nodes": [container],
		"timers": [],
		"update": Callable(),
		"cleanup": Callable(self, "_cleanup_jump_pads").bind(pads),
		"data": {"pads": pads},
	}


func _cleanup_jump_pads(pads: Array) -> void:
	for pad in pads:
		if pad:
			var cb = pad.get_meta("body_callback", Callable())
			if cb is Callable and pad.is_connected("body_entered", cb):
				pad.body_entered.disconnect(cb)
			pad.set_meta("body_callback", null)


func _on_jump_pad_entered(body: Node, pad: Area2D) -> void:
	if body == null or pad == null:
		return
	if body == player or body.is_in_group("enemies"):
		var direction: Vector2 = (body.global_position - pad.global_position).normalized()
		if direction.length() < 0.1:
			direction = Vector2.RIGHT.rotated(randf() * TAU)
		if body.has_method("apply_impulse"):
			body.apply_impulse(direction, 600.0)
		elif body is CharacterBody2D:
			body.velocity = direction * 600.0
		_play_unique_sound("jump_pad", func():
			AudioManager.play_ability_sound()
		)


func _init_teleport_portals() -> Dictionary:
	var container := Node2D.new()
	container.name = "Affix_TeleportPortals"

	var portal_a := _create_portal(Color(0.3, 0.6, 1.0), "A")
	var portal_b := _create_portal(Color(1.0, 0.6, 0.2), "B")
	portal_a.set_meta("linked_portal", portal_b)
	portal_b.set_meta("linked_portal", portal_a)
	portal_a.global_position = _get_random_arena_position()
	portal_b.global_position = _get_random_arena_position()

	container.add_child(portal_a)
	container.add_child(portal_b)

	return {
		"nodes": [container],
		"timers": [],
		"update": Callable(),
		"cleanup": Callable(self, "_cleanup_portals").bind([portal_a, portal_b]),
	}


func _create_portal(color: Color, suffix: String) -> Area2D:
	var portal := Area2D.new()
	portal.name = "Portal_%s" % suffix

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 72.0
	shape.shape = circle
	portal.add_child(shape)

	var visual := ColorRect.new()
	visual.size = Vector2(140, 140)
	visual.position = -visual.size / 2
	visual.color = Color(color.r, color.g, color.b, 0.45)
	portal.add_child(visual)

	var callback := Callable(self, "_on_portal_entered").bind(portal)
	portal.set_meta("body_callback", callback)
	portal.body_entered.connect(callback)
	return portal


func _cleanup_portals(portals: Array) -> void:
	for portal in portals:
		if portal:
			var cb = portal.get_meta("body_callback", Callable())
			if cb is Callable and portal.is_connected("body_entered", cb):
				portal.body_entered.disconnect(cb)
			portal.set_meta("body_callback", null)


func _on_portal_entered(body: Node, portal: Area2D) -> void:
	if not portal:
		return
	var linked: Area2D = portal.get_meta("linked_portal", null)
	if not linked:
		return
	if body == player or body.is_in_group("enemies"):
		_play_unique_sound("portal", func():
			AudioManager.play_portal_spawn_sound()
		)
		var offset := Vector2(randf_range(-48, 48), randf_range(-48, 48))
		body.global_position = linked.global_position + offset
		if body is CharacterBody2D:
			body.velocity = Vector2.ZERO


# -----------------------------------------------------------------------------
# YELLOW ROUTE
# -----------------------------------------------------------------------------

func _init_swamp_zones() -> Dictionary:
	var container := Node2D.new()
	container.name = "Affix_Swamp"

	var puddles: Array[Area2D] = []
	for i in range(3):
		var puddle := Area2D.new()
		puddle.name = "Swamp_%d" % i

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(220, 160)
		shape.shape = rect
		puddle.add_child(shape)

		var visual := ColorRect.new()
		visual.size = rect.size
		visual.position = -visual.size / 2
		visual.color = Color(0.2, 0.5, 0.2, 0.5)
		puddle.add_child(visual)

		puddle.global_position = _get_random_arena_position()
		container.add_child(puddle)
		puddles.append(puddle)

	return {
		"nodes": [container],
		"timers": [],
		"update": Callable(self, "_update_swamp").bind(puddles),
		"cleanup": Callable(),
	}


func _update_swamp(_delta: float, puddles: Array) -> void:
	for puddle in puddles:
		if not puddle:
			continue
		for body in puddle.get_overlapping_bodies():
			if body == player or body.is_in_group("enemies"):
				if body is CharacterBody2D:
					body.velocity = body.velocity * 0.6


func _init_acid_rain() -> Dictionary:
	var overlay := ColorRect.new()
	overlay.name = "Affix_RainOverlay"
	overlay.color = Color(0.3, 0.4, 0.8, 0.25)
	overlay.size = game_scene.get_viewport_rect().size * 2
	overlay.position = -overlay.size / 4
	overlay.z_index = 50

	var rain_timer := Timer.new()
	rain_timer.wait_time = 0.9
	rain_timer.autostart = true
	rain_timer.timeout.connect(_on_rain_tick)

	_rain_backup = {}
	if player:
		_rain_backup["melee_interval"] = player.melee_interval
		var fire_rates := {}
		for key in player.weapon_fire_rates.keys():
			fire_rates[key] = player.weapon_fire_rates[key]
			player.weapon_fire_rates[key] = player.weapon_fire_rates[key] * 1.3
		_rain_backup["fire_rates"] = fire_rates
		player.melee_interval *= 1.3

	return {
		"nodes": [overlay],
		"timers": [rain_timer],
		"update": Callable(),
		"cleanup": Callable(self, "_cleanup_rain"),
	}


func _on_rain_tick() -> void:
	_play_unique_sound("rain", func():
		AudioManager.play_ability_sound()
	)


func _cleanup_rain() -> void:
	if _rain_backup.is_empty():
		return
	if player:
		if _rain_backup.has("melee_interval"):
			player.melee_interval = _rain_backup["melee_interval"]
		if _rain_backup.has("fire_rates"):
			var rates: Dictionary = _rain_backup["fire_rates"]
			for key in rates.keys():
				player.weapon_fire_rates[key] = rates[key]
	_rain_backup.clear()


# -----------------------------------------------------------------------------
# RED ROUTE
# -----------------------------------------------------------------------------

func _init_emp_storms() -> Dictionary:
	var pulse_timer := Timer.new()
	pulse_timer.wait_time = 10.0
	pulse_timer.autostart = true
	pulse_timer.timeout.connect(_trigger_emp_pulse)

	return {
		"nodes": [],
		"timers": [pulse_timer],
		"update": Callable(),
		"cleanup": Callable(self, "_cleanup_emp"),
		"data": {},
	}


func _trigger_emp_pulse() -> void:
	_play_unique_sound("emp_pulse", func():
		AudioManager.play_ability_cooldown_sound()
	)

	if player:
		player.set_meta("emp_disabled", true)

	var drone_controller = player.get_node_or_null("HackerDroneController") if player else null
	if drone_controller and drone_controller.has_method("toggle_mode"):
		player.set_meta("emp_forced_disable", true)
		drone_controller.is_drone_mode = false

	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(player):
		player.set_meta("emp_disabled", false)
		player.set_meta("emp_forced_disable", false)


func _cleanup_emp() -> void:
	if player:
		player.set_meta("emp_disabled", false)
		player.set_meta("emp_forced_disable", false)


func _init_random_lightning() -> Dictionary:
	var timer := Timer.new()
	timer.wait_time = 4.0
	timer.autostart = true
	timer.timeout.connect(_spawn_lightning_strike)

	return {
		"nodes": [],
		"timers": [timer],
		"update": Callable(),
		"cleanup": Callable(),
	}


func _spawn_lightning_strike() -> void:
	var strike := Area2D.new()
	strike.name = "LightningStrike"

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 120.0
	shape.shape = circle
	strike.add_child(shape)

	var visual := ColorRect.new()
	visual.size = Vector2(220, 220)
	visual.position = -visual.size / 2
	visual.color = Color(0.8, 0.8, 1.0, 0.5)
	strike.add_child(visual)

	strike.global_position = _get_random_arena_position()
	strike.body_entered.connect(_on_lightning_body_entered)
	game_scene.add_child(strike)

	_play_unique_sound("lightning", func():
		AudioManager.play_explosion_sound()
	)

	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(strike):
		strike.queue_free()


func _on_lightning_body_entered(body: Node) -> void:
	if not body:
		return

	if (body == player or body.is_in_group("enemies")) and body.has_method("take_damage"):
		body.take_damage(80)


# Green Route - Missing Functions
func _init_updrafts() -> Dictionary:
	"""Creates wind currents that boost aerial shots and movement"""
	print("AffixManager: Activating UPDRAFTS")
	return {
		"nodes": [],
		"update": _updrafts_update,
		"cleanup": func(): pass,
		"data": {}
	}


func _updrafts_update(delta: float) -> void:
	# Implementation for updrafts effect
	if player and is_instance_valid(player):
		# Boost player movement slightly when moving
		if player.velocity.length() > 0:
			player.velocity *= 1.05


func _init_smoke_clouds() -> Dictionary:
	"""Enemies drop smoke bombs that obscure vision"""
	print("AffixManager: Activating SMOKE_CLOUDS")
	return {
		"nodes": [],
		"update": func(delta): pass,
		"cleanup": func(): pass,
		"data": {}
	}


# Yellow Route - Missing Functions  
func _init_lightning_bolts() -> Dictionary:
	"""Chain lightning effects"""
	print("AffixManager: Activating LIGHTNING_BOLTS")
	return {
		"nodes": [],
		"update": func(delta): pass,
		"cleanup": func(): pass,
		"data": {}
	}


func _init_static_field() -> Dictionary:
	"""Damage zones that persist"""
	print("AffixManager: Activating STATIC_FIELD")
	return {
		"nodes": [],
		"update": func(delta): pass,
		"cleanup": func(): pass,
		"data": {}
	}


# Red Route - Missing Functions
func _init_magnetic_pulse() -> Dictionary:
	"""Magnetic forces pull projectiles off course"""
	print("AffixManager: Activating MAGNETIC_PULSE")
	return {
		"nodes": [],
		"update": func(delta): pass,
		"cleanup": func(): pass,
		"data": {}
	}


func _init_tesla_grid() -> Dictionary:
	"""Tesla coils create persistent damage zones"""
	print("AffixManager: Activating TESLA_GRID")
	return {
		"nodes": [],
		"update": func(delta): pass,
		"cleanup": func(): pass,
		"data": {}
	}


# -----------------------------------------------------------------------------
# UTILITIES
# -----------------------------------------------------------------------------

func _get_random_arena_position() -> Vector2:
	if game_scene:
		var bounds := Rect2(Vector2.ZERO, Vector2(14 * 128, 14 * 128))
		var pos := Vector2(randf_range(bounds.position.x + 128, bounds.end.x - 128), randf_range(bounds.position.y + 128, bounds.end.y - 128))
		return pos
	return Vector2(randf() * 1600, randf() * 1600)


func _play_unique_sound(key: String, fn: Callable) -> void:
	var now := Time.get_ticks_msec()
	var last: int = int(_audio_cooldowns.get(key, 0))
	if now - last < 400:
		return
	_audio_cooldowns[key] = now
	fn.call()
