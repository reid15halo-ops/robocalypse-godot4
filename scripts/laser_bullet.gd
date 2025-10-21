extends "res://scripts/projectile.gd"

# Laser projectile - fast and penetrating

# Laser-specific upgrades
var base_damage: int = 15
var laser_damage_mult: float = 1.0
var laser_width_mult: float = 1.0

# Chain lightning
var chain_count: int = 0
var chain_range: float = 150.0
var chain_damage_mult: float = 0.5
var chained_enemies: Array = []

# Split beam
var split_count: int = 0
var split_angle: float = 45.0
var split_homing: float = 0.0
var is_split_projectile: bool = false

# Overcharge
var is_overcharged: bool = false
var overcharge_aoe: float = 0.0

# Visual effects
var trail_particles: CPUParticles2D = null
var glow_sprite: Sprite2D = null

# Hit enemies for chain lightning
var hit_enemies: Array = []


func _ready() -> void:
	# Laser base properties
	speed = 600.0
	damage = base_damage
	max_distance = 1200.0
	lifetime = 3.0

	# Penetration
	can_penetrate = true
	max_penetrations = 3

	# No explosion (unless overcharged)
	has_explosion = false

	# Apply damage multiplier
	damage = int(base_damage * laser_damage_mult)

	# Setup visual effects
	_setup_visual_effects()

	# Play laser fire sound (if available)
	_play_laser_sound()

	# Call parent ready
	super._ready()


func _play_laser_sound() -> void:
	"""Play laser fire sound"""
	# Check if laser sound exists
	var sound_path = "res://sounds/laser_fire.ogg"
	if not FileAccess.file_exists(sound_path):
		return

	var audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = load(sound_path)
	audio_player.volume_db = -10.0 if not is_overcharged else -5.0
	audio_player.pitch_scale = 1.0 + randf_range(-0.1, 0.1)  # Random pitch variation
	audio_player.play()

	# Auto-destroy after playing
	audio_player.finished.connect(func():
		if is_instance_valid(audio_player):
			audio_player.queue_free()
	)


func _setup_visual_effects() -> void:
	"""Setup trail and glow effects"""
	# Create trail particles
	trail_particles = CPUParticles2D.new()
	add_child(trail_particles)
	trail_particles.emitting = true
	trail_particles.amount = 20
	trail_particles.lifetime = 0.3
	trail_particles.local_coords = false

	# Trail properties
	trail_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail_particles.emission_sphere_radius = 2.0
	trail_particles.direction = Vector2(-1, 0)
	trail_particles.spread = 15.0
	trail_particles.gravity = Vector2.ZERO
	trail_particles.initial_velocity_min = 20.0
	trail_particles.initial_velocity_max = 40.0
	trail_particles.scale_amount_min = 2.0 * laser_width_mult
	trail_particles.scale_amount_max = 4.0 * laser_width_mult

	# Color based on overcharge
	if is_overcharged:
		trail_particles.color = Color(1.0, 0.5, 0.0, 0.8)
	else:
		trail_particles.color = Color(0.2, 0.8, 1.0, 0.6)

	# Add glow effect
	var sprite_node = get_node_or_null("Sprite2D")
	if sprite_node:
		sprite_node.modulate = Color(0.2, 0.9, 1.0) if not is_overcharged else Color(1.0, 0.5, 0.0)
		sprite_node.scale = Vector2(1.0 * laser_width_mult, 1.0 * laser_width_mult)


func set_laser_upgrades(upgrades: Dictionary) -> void:
	"""Apply laser upgrades from player"""
	laser_damage_mult = upgrades.get("laser_damage_mult", 1.0)
	laser_width_mult = upgrades.get("laser_width_mult", 1.0)

	# Penetration
	var penetration_bonus = upgrades.get("laser_penetration_bonus", 0)
	max_penetrations += penetration_bonus
	if upgrades.get("infinite_pierce", false):
		max_penetrations = 999

	# Chain lightning
	chain_count = upgrades.get("laser_chain_count", 0)
	chain_range = upgrades.get("laser_chain_range", 150.0)
	chain_damage_mult = upgrades.get("chain_damage_mult", 0.5)

	# Split beam
	split_count = upgrades.get("laser_split_count", 0)
	split_angle = upgrades.get("laser_split_angle", 45.0)
	split_homing = upgrades.get("split_homing", 0.0)

	# Overcharge
	is_overcharged = upgrades.get("is_overcharged", false)
	overcharge_aoe = upgrades.get("overcharge_aoe", 0.0)

	# Apply damage multiplier
	damage = int(base_damage * laser_damage_mult)

	# If overcharged, enable explosion
	if is_overcharged and overcharge_aoe > 0:
		has_explosion = true
		explosion_radius = overcharge_aoe


func _hit_enemy(enemy: Node2D) -> void:
	"""Override to add chain lightning and split beam"""
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		hit_enemies.append(enemy)

	# Chain lightning
	if chain_count > 0 and not is_split_projectile:
		_trigger_chain_lightning(enemy)

	# Split beam on first hit
	if split_count > 0 and not is_split_projectile and hit_enemies.size() == 1:
		_trigger_split_beam(enemy.global_position)

	# Check penetration
	if can_penetrate and penetration_count < max_penetrations:
		penetration_count += 1
	else:
		# Destroy projectile
		_on_impact(enemy.global_position)


func _trigger_chain_lightning(origin_enemy: Node2D) -> void:
	"""Chain to nearby enemies"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var chained = 0
	var last_position = origin_enemy.global_position
	var already_hit = [origin_enemy]

	for i in range(chain_count):
		if chained >= chain_count:
			break

		# Find nearest enemy not yet hit
		var nearest: Node2D = null
		var nearest_dist = INF

		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy in already_hit:
				continue

			var dist = last_position.distance_to(enemy.global_position)
			if dist <= chain_range and dist < nearest_dist:
				nearest = enemy
				nearest_dist = dist

		if nearest:
			# Apply chain damage
			var chain_damage = int(damage * chain_damage_mult)
			if nearest.has_method("take_damage"):
				nearest.take_damage(chain_damage)

			# Visual effect - lightning arc
			_create_chain_visual(last_position, nearest.global_position)

			# Play chain sound
			_play_chain_sound()

			already_hit.append(nearest)
			last_position = nearest.global_position
			chained += 1


func _play_chain_sound() -> void:
	"""Play chain lightning sound effect"""
	var sound_path = "res://sounds/laser_chain.ogg"
	if not FileAccess.file_exists(sound_path):
		return

	var audio_player = AudioStreamPlayer2D.new()
	audio_player.global_position = global_position
	get_tree().root.add_child(audio_player)
	audio_player.stream = load(sound_path)
	audio_player.volume_db = -15.0
	audio_player.pitch_scale = 1.2 + randf_range(-0.1, 0.1)
	audio_player.play()

	audio_player.finished.connect(func():
		if is_instance_valid(audio_player):
			audio_player.queue_free()
	)


func _trigger_split_beam(hit_position: Vector2) -> void:
	"""Split into multiple beams"""
	var laser_scene = load("res://scenes/LaserBullet.tscn")

	for i in range(split_count):
		# Calculate split angle
		var angle_offset = (i - split_count / 2.0) * deg_to_rad(split_angle / split_count)
		var split_direction = direction.rotated(angle_offset)

		# Create split projectile
		var split_laser = laser_scene.instantiate()
		split_laser.global_position = hit_position
		split_laser.direction = split_direction
		split_laser.is_split_projectile = true
		split_laser.damage = int(damage * 0.5)  # Split beams deal 50% damage
		split_laser.laser_width_mult = laser_width_mult * 0.7

		# Add to scene
		get_parent().add_child(split_laser)


func _create_chain_visual(from: Vector2, to: Vector2) -> void:
	"""Create lightning arc visual between two points"""
	var line = Line2D.new()
	line.width = 3.0 * laser_width_mult
	line.default_color = Color(1.0, 1.0, 0.0, 0.8)
	line.add_point(from)
	line.add_point(to)

	# Add to scene
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene:
		game_scene.add_child(line)
	else:
		get_tree().root.add_child(line)

	# Fade out
	var tween = get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		if is_instance_valid(line):
			line.queue_free()
	)
