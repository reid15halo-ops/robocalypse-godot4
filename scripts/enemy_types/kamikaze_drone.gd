extends CharacterBody2D

@export var current_speed: float = 180.0
@export var max_health: int = 50
var current_health: int = 50
@export var hp_regen_rate: float = 0.0
var player: CharacterBody2D = null
@export var score_value: int = 15
@export var scrap_reward: int = 15
var explosion_damage: int = 80
var explosion_radius: float = 150.0
var is_exploding: bool = false

var is_stunned: bool = false
var stun_timer: float = 0.0
var _pre_stun_speed: float = 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 14
	add_to_group("enemies")
	current_health = max_health
	player = GameManager.get_player()
	
	# Setup animated sprite
	_setup_sprite()
	
	# Distinct visual: Bright red, pulsing (dangerous!)
	modulate = Color(2.0, 0.2, 0.2)  # Very bright red
	scale = Vector2(0.9, 0.9)  # Slightly smaller but dangerous
	_start_pulsing()  # Add pulsing effect


func _setup_sprite() -> void:
	"""Setup AnimatedSprite2D for kamikaze drone"""
	var sprite = AnimatedSprite2D.new()
	sprite.z_index = 1
	sprite.centered = true
	sprite.name = "Sprite"
	add_child(sprite)
	
	var sprite_path = "res://assets/anim/drone_kamikaze.tres"
	if ResourceLoader.exists(sprite_path):
		sprite.sprite_frames = load(sprite_path)
		if sprite.sprite_frames.has_animation("hover"):
			sprite.play("hover")
		elif sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
	else:
		push_warning("Kamikaze drone sprite not found: " + sprite_path)


func _start_pulsing() -> void:
	"""Pulsing visual effect for danger indication"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate", Color(2.5, 0.5, 0.5), 0.3)
	tween.tween_property(self, "modulate", Color(2.0, 0.2, 0.2), 0.3)


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if is_exploding:
		return

	if is_stunned:
		stun_timer -= delta
		velocity = Vector2.ZERO
		if stun_timer <= 0.0:
			is_stunned = false
			current_speed = max(_pre_stun_speed, 40.0)
		else:
			return

	if hp_regen_rate > 0.0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)

	if not player or not is_instance_valid(player):
		player = GameManager.get_player()

	if player and is_instance_valid(player) and not GameManager.is_game_over:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * current_speed
		move_and_slide()

		# Check proximity
		if global_position.distance_to(player.global_position) <= 80.0:
			explode()


func take_damage(damage: int) -> void:
	current_health -= damage
	modulate = Color(2.0, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if not is_queued_for_deletion():
		modulate = Color(1.5, 0.2, 0.2)

	if current_health <= 0:
		explode()


func explode() -> void:
	"""Trigger explosion"""
	if is_exploding:
		return
	is_exploding = true

	# Play explosion sound
	AudioManager.play_explosion_sound()

	# Visual flash
	modulate = Color(3.0, 3.0, 0.0)
	await get_tree().create_timer(0.1).timeout

	# Damage in radius
	_damage_in_radius()

	# Visual explosion (using projectile explosion system)
	var explosion = ColorRect.new()
	explosion.color = Color(1.0, 0.5, 0.0, 0.8)
	explosion.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	explosion.position = global_position - explosion.size / 2

	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene:
		game_scene.add_child(explosion)

	var tween = get_tree().create_tween()
	tween.tween_property(explosion, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): if is_instance_valid(explosion): explosion.queue_free())

	# Award score
	GameManager.add_score(score_value)

	var drop_scene = get_tree().get_first_node_in_group("game_scene")
	if drop_scene:
		if drop_scene.has_method("register_kill"):
			drop_scene.register_kill()
		if scrap_reward > 0 and drop_scene.has_method("spawn_scrap_pickups"):
			drop_scene.spawn_scrap_pickups(global_position, scrap_reward)

	queue_free()


func apply_stun(duration: float) -> void:
	if duration <= 0.0 or is_exploding:
		return
	is_stunned = true
	stun_timer = max(stun_timer, duration)
	_pre_stun_speed = current_speed
	current_speed = 0.0
	velocity = Vector2.ZERO


func _damage_in_radius() -> void:
	"""Damage all entities in explosion radius"""
	# Damage player
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= explosion_radius:
			if player.has_method("take_damage"):
				player.take_damage(explosion_damage)

	# Damage other enemies (50% damage)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist <= explosion_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage / 2)
