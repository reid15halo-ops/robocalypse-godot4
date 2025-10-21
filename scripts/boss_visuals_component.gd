extends Node2D
class_name BossVisualsComponent

## Boss Visuals Component
## Verwaltet alle visuellen Effekte (Sprites, Animationen, Feedback)
## Kommuniziert mit BossCore via Signals

#region VARIABLES
var boss: Node = null  # BossCore reference

## Sprite references
var sprite: AnimatedSprite2D = null
var damage_flash_timer: float = 0.0
var original_modulate: Color = Color.WHITE

## Phase visual effects
var current_phase_effect: Node2D = null
#endregion

#region INITIALIZATION
func initialize(boss_ref: Node) -> void:
	boss = boss_ref

	# Connect to boss signals
	if boss:
		boss.health_changed.connect(_on_health_changed)
		boss.phase_changed.connect(_on_phase_changed)
		boss.boss_died.connect(_on_boss_died)

	# Setup sprite
	_setup_sprite()

	# Initial visual state
	_update_phase_visuals(1)
#endregion

#region SPRITE_SETUP
func _setup_sprite() -> void:
	# Check if sprite already exists as child
	if has_node("AnimatedSprite2D"):
		sprite = get_node("AnimatedSprite2D")
	elif has_node("Sprite2D"):
		# Convert Sprite2D to AnimatedSprite2D reference
		var simple_sprite: Sprite2D = get_node("Sprite2D")
		# For now, just keep reference to simple sprite
		# In future, could convert to AnimatedSprite2D
	else:
		# Create new AnimatedSprite2D
		sprite = AnimatedSprite2D.new()
		add_child(sprite)
		sprite.name = "AnimatedSprite2D"

	# Setup sprite properties
	if sprite:
		original_modulate = sprite.modulate
		# TODO: Load sprite frames for boss animations

func _load_boss_sprite_frames() -> SpriteFrames:
	# Create sprite frames for boss
	var frames: SpriteFrames = SpriteFrames.new()

	# TODO: Load actual boss sprites
	# For now, return empty frames
	frames.add_animation("idle")
	frames.add_animation("attack")
	frames.add_animation("hurt")
	frames.add_animation("death")

	return frames
#endregion

#region MAIN_UPDATE
func _process(delta: float) -> void:
	# Update damage flash
	if damage_flash_timer > 0.0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0.0:
			_reset_flash()
#endregion

#region DAMAGE_FLASH
func _on_health_changed(current_health: int, max_health: int) -> void:
	# Trigger damage flash
	_trigger_damage_flash()

func _trigger_damage_flash() -> void:
	if sprite == null:
		return

	var stats: Resource = boss.get_stats()

	# Flash red
	sprite.modulate = Color(1.5, 0.5, 0.5, 1.0)
	damage_flash_timer = stats.damage_flash_duration

func _reset_flash() -> void:
	if sprite == null:
		return

	sprite.modulate = original_modulate
#endregion

#region PHASE_VISUALS
func _on_phase_changed(new_phase: int, old_phase: int) -> void:
	_update_phase_visuals(new_phase)

func _update_phase_visuals(phase: int) -> void:
	# Remove old phase effect
	if current_phase_effect and is_instance_valid(current_phase_effect):
		current_phase_effect.queue_free()
		current_phase_effect = null

	# Create new phase effect
	match phase:
		1:
			_create_phase_1_effect()
		2:
			_create_phase_2_effect()
		3:
			_create_phase_3_effect()

	# Change sprite tint based on phase
	if sprite:
		match phase:
			1:
				original_modulate = Color.WHITE
			2:
				original_modulate = Color(1.0, 0.9, 0.7)  # Slight yellow tint
			3:
				original_modulate = Color(1.0, 0.7, 0.7)  # Red tint

		if damage_flash_timer <= 0.0:
			sprite.modulate = original_modulate

func _create_phase_1_effect() -> void:
	# Phase 1: No special effect
	pass

func _create_phase_2_effect() -> void:
	# Phase 2: Energy aura
	current_phase_effect = Node2D.new()
	add_child(current_phase_effect)

	var particles: CPUParticles2D = CPUParticles2D.new()
	current_phase_effect.add_child(particles)

	particles.amount = 20
	particles.lifetime = 1.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 60.0
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 40.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.8, 0.8, 0.3, 0.6)

func _create_phase_3_effect() -> void:
	# Phase 3: Intense energy aura + electric arcs
	current_phase_effect = Node2D.new()
	add_child(current_phase_effect)

	var particles: CPUParticles2D = CPUParticles2D.new()
	current_phase_effect.add_child(particles)

	particles.amount = 40
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 70.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 80.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color(1.0, 0.3, 0.3, 0.8)
#endregion

#region DEATH_ANIMATION
func _on_boss_died() -> void:
	_play_death_animation()

func _play_death_animation() -> void:
	# Create death explosion effect
	var explosion: Node2D = Node2D.new()
	get_parent().add_child(explosion)
	explosion.global_position = global_position

	# Create expanding circle
	var particles: CPUParticles2D = CPUParticles2D.new()
	explosion.add_child(particles)

	particles.amount = 100
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = Color(1.0, 0.5, 0.2, 1.0)

	particles.emitting = true

	# Cleanup after animation
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(explosion):
		explosion.queue_free()

	# Hide boss sprite
	if sprite:
		sprite.visible = false
#endregion

#region ATTACK_ANIMATIONS
## Play animation for specific attack
func play_attack_animation(attack_type: String) -> void:
	if sprite == null:
		return

	match attack_type:
		"basic_laser":
			_play_laser_animation()
		"minion_spawn":
			_play_spawn_animation()
		"gravity_well":
			_play_gravity_well_animation()
		"plasma_walls":
			_play_plasma_walls_animation()

func _play_laser_animation() -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	# TODO: Add muzzle flash effect

func _play_spawn_animation() -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	# TODO: Add summoning circle effect

func _play_gravity_well_animation() -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	# Visual is handled by EffectManager

func _play_plasma_walls_animation() -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	# Visual is handled by EffectManager
#endregion

#region PUBLIC_API
## Set sprite visibility
func set_sprite_visible(visible: bool) -> void:
	if sprite:
		sprite.visible = visible

## Get sprite reference
func get_sprite() -> AnimatedSprite2D:
	return sprite
#endregion
