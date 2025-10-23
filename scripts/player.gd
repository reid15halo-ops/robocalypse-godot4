extends CharacterBody2D

# Signals
signal health_changed(new_health: int)
signal shield_changed(new_shield: int)
signal died

# Movement
@export var speed: float = 200.0

# Health
@export var max_health: int = 100
var current_health: int = 100

# Damage
var invulnerable: bool = false
var invulnerability_time: float = 1.0
var invulnerability_timer: float = 0.0

# Melee Attack
@export var melee_damage: int = 20
@export var melee_range: float = 90.0
@export var melee_interval: float = 0.5
var melee_timer: float = 0.0
var attack_side: String = "right"  # Alternating left/right punches

# Regeneration and Defense
var hp_regen_rate: float = 0.0  # HP per second
var damage_reduction: float = 0.0  # Percentage (0.0 to 1.0)
var _shield_hp_internal: int = 0
var shield_hp: int:
	get:
		return _shield_hp_internal
	set(value):
		var clamped: int = int(max(value, 0))
		if clamped == _shield_hp_internal:
			return
		_shield_hp_internal = clamped
		shield_changed.emit(_shield_hp_internal)  # Shield absorbs damage before health

# Slow/Hold Effects (Support Drone)
var base_speed: float = 200.0  # Original speed
var slow_stacks: int = 0  # Number of active slow effects

# Ranged Weapons
var equipped_weapons: Array[String] = []  # Array of weapon types
var weapon_cooldowns: Dictionary = {}  # weapon_type -> cooldown_timer
const WEAPON_FIRE_RATES := {
	"laser": 0.3,
	"rocket": 1.5,
	"shotgun": 0.8
}
var weapon_range: float = 800.0
var external_velocity: Vector2 = Vector2.ZERO

# Laser Upgrades
var laser_upgrades: Dictionary = {
	"laser_damage_mult": 1.0,
	"laser_firerate_mult": 1.0,
	"laser_width_mult": 1.0,
	"laser_penetration_bonus": 0,
	"infinite_pierce": false,
	"laser_chain_count": 0,
	"laser_chain_range": 150.0,
	"chain_damage_mult": 0.5,
	"laser_split_count": 0,
	"laser_split_angle": 45.0,
	"split_homing": 0.0,
	"overcharge_interval": 0,
	"overcharge_damage_mult": 1.0,
	"overcharge_aoe": 0.0,
	"overcharge_stun": 0.0
}
var laser_shot_counter: int = 0  # For overcharge tracking

@onready var weapon_anchor: Node2D = get_node_or_null("WeaponAnchor")
@onready var weapon_sprite: Sprite2D = get_node_or_null("WeaponAnchor/WeaponSprite")
var weapon_base_offset: Vector2 = Vector2(26, -10)
var weapon_target_offset: Vector2 = Vector2(26, -10)
var weapon_swing_time: float = 0.0
var weapon_swing_duration: float = 0.18
var current_weapon_texture_path: String = ""
var facing_direction: int = 1

# Preload projectile scenes
var laser_scene: PackedScene = preload("res://scenes/LaserBullet.tscn")
var rocket_scene: PackedScene = preload("res://scenes/Rocket.tscn")
var shotgun_pellet_scene: PackedScene = preload("res://scenes/ShotgunPellet.tscn")

# Visual nodes
var sprite: AnimatedSprite2D = null
var visual_node: Node2D = null
var use_sprites: bool = true  # Sprites are now available!

# Animation State Machine (Phase 1)
enum AnimState {IDLE, WALK, ATTACK, DAMAGED, DEATH}
var current_anim_state: AnimState = AnimState.IDLE
var previous_anim_state: AnimState = AnimState.IDLE

# ============================================================================
# ITEM UPGRADE TRACKING SYSTEM
# ============================================================================
var owned_items: Dictionary = {}  # item_id -> current_level (1, 2, or 3)

# ============================================================================
# DRONE SHOP ABILITY (HACKER-SPECIFIC)
# ============================================================================
var drone_shops_available: int = 0  # Number of drone shops available to use


func has_item(item_id: String) -> bool:
	"""Check if player owns an item"""
	return owned_items.has(item_id)


func get_item_level(item_id: String) -> int:
	"""Get current level of owned item (0 if not owned)"""
	return owned_items.get(item_id, 0)


func upgrade_item(item_id: String, item_data) -> int:
	"""
	Upgrade item or add it at level 1
	Returns the new level
	"""
	var current_level: int = get_item_level(item_id)

	if current_level == 0:
		# New item - add at level 1
		owned_items[item_id] = 1
		print("New item acquired: ", item_data.name, " [Level 1]")
		return 1
	elif current_level < item_data.max_level:
		# Upgrade existing item
		owned_items[item_id] = current_level + 1
		print("Item upgraded: ", item_data.name, " [Level ", current_level, " -> ", owned_items[item_id], "]")
		return owned_items[item_id]
	else:
		# Already max level
		print("Item already max level: ", item_data.name, " [Level ", current_level, "]")
		return current_level


func can_upgrade_item(item_id: String, max_level: int) -> bool:
	"""Check if item can be upgraded further"""
	var current_level: int = get_item_level(item_id)
	return current_level < max_level


func _ready() -> void:
	# Set collision layer and mask
	collision_layer = 1  # Layer 1 (Player)
	collision_mask = 28  # Interact with Boundary (4) + Walls (8) + Projectiles (16)

	if weapon_anchor == null:
		weapon_anchor = Node2D.new()
		weapon_anchor.name = "WeaponAnchor"
		add_child(weapon_anchor)
	if weapon_sprite == null:
		weapon_sprite = Sprite2D.new()
		weapon_sprite.name = "WeaponSprite"
		weapon_anchor.add_child(weapon_sprite)
		weapon_sprite.centered = true
		weapon_sprite.position = Vector2.ZERO
		weapon_sprite.z_index = 2

	if weapon_anchor:
		weapon_anchor.position = weapon_base_offset
		weapon_target_offset = weapon_base_offset
	if weapon_sprite:
		weapon_sprite.position = Vector2.ZERO
		weapon_sprite.visible = false

	# Initialize health
	current_health = max_health
	health_changed.emit(int(current_health))
	shield_changed.emit(shield_hp)

	# Initialize speed tracking
	base_speed = speed
	slow_stacks = 0

	# Register with GameManager
	GameManager.set_player(self)

	# Setup visual (sprite or ColorRect fallback)
	_setup_visual()

	# Starting weapon will be added by CharacterSystem
	# (applied in game.gd _ready after character stats are set)

	# Abilities are NOT equipped by default - must be unlocked through gameplay


func _physics_process(delta: float) -> void:
	# Handle invulnerability timer
	if invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			invulnerable = false
			modulate = Color.WHITE  # Reset color

	# Handle HP regeneration
	if hp_regen_rate > 0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)
		health_changed.emit(int(current_health))

	# Handle melee attack timer
	melee_timer += delta

	# Handle weapon cooldowns
	for weapon_type in weapon_cooldowns:
		weapon_cooldowns[weapon_type] = weapon_cooldowns.get(weapon_type, 0.0) + delta

	# Get input direction
	var input_direction: Vector2 = Vector2.ZERO

	# Only handle input if not AI controlled
	if not has_meta("ai_controlled") or not get_meta("ai_controlled"):
		input_direction.x = Input.get_axis("move_left", "move_right")
		input_direction.y = Input.get_axis("move_up", "move_down")

		# Check for inverted controls (drug side effect)
		if has_meta("controls_inverted") and get_meta("controls_inverted"):
			input_direction.x = -input_direction.x
			input_direction.y = -input_direction.y

		# Normalize diagonal movement
		if input_direction.length() > 0:
			input_direction = input_direction.normalized()

	# Apply movement (velocity will be set by AI in controller if ai_controlled)
	if not has_meta("ai_controlled") or not get_meta("ai_controlled"):
		velocity = input_direction * speed

	velocity += external_velocity

	# Move and slide
	move_and_slide()
	external_velocity = external_velocity.move_toward(Vector2.ZERO, 800.0 * delta)

	if velocity.x < -10.0:
		facing_direction = -1
	elif velocity.x > 10.0:
		facing_direction = 1

	# Update sprite animation
	_update_sprite_animation()
	_update_weapon_anchor(delta)

	# Automatic melee attack
	if melee_timer >= melee_interval:
		perform_melee_attack()
		melee_timer = 0.0

	# Fire equipped weapons
	_fire_weapons()

	# Handle ability inputs (only if not AI controlled)
	if not has_meta("ai_controlled") or not get_meta("ai_controlled"):
		if Input.is_action_just_pressed("ability_q"):
			AbilitySystem.use_ability("Q", self)
		# W-key removed - used for movement only
		if Input.is_action_just_pressed("ability_e"):
			AbilitySystem.use_ability("E", self)
		if Input.is_action_just_pressed("ability_r"):
			AbilitySystem.use_ability("R", self)

		# Drone Shop ability (T key) - Hacker-specific
		if Input.is_action_just_pressed("drone_shop"):
			_try_open_drone_shop()

# Check for enemy overlaps
	_check_enemy_overlap()


func perform_melee_attack() -> void:
	"""Perform automatic melee attack in alternating directions"""
	# Trigger attack animation (Phase 1)
	trigger_attack_animation()
	
	# Get current weapon data for special effects
	var weapon_data: Dictionary = get_meta("current_weapon", {})
	var has_aoe: bool = weapon_data.get("has_aoe", false)
	var aoe_radius: float = weapon_data.get("aoe_radius", 0.0)

	_trigger_weapon_swing()

	# Create attack area based on which side
	var attack_rect: Rect2 = Rect2()
	var offset_x: float = melee_range if attack_side == "right" else -melee_range

	attack_rect.position = global_position + Vector2(offset_x - melee_range/2, -melee_range/2)
	attack_rect.size = Vector2(melee_range, melee_range)

	# Visual feedback - flash white briefly
	var original_modulate: Color = modulate
	modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.05).timeout

	# Safety check - player could die during await
	if not is_instance_valid(self):
		return

	modulate = original_modulate

	# Check for enemies in attack range
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(melee_range, melee_range)
	query.shape = shape
	query.transform = Transform2D(0, global_position + Vector2(offset_x, 0))
	query.collision_mask = 2  # Enemy layer

	var results: Array[Dictionary] = space_state.intersect_shape(query)

	# Damage enemies
	for result in results:
		var collider: Node = result["collider"]
		if collider.is_in_group("enemies") and collider.has_method("take_damage"):
			collider.take_damage(melee_damage)

			# AoE damage for advanced weapons
			if has_aoe and aoe_radius > 0:
				var aoe_damage: int = int(round(melee_damage / 2.0))
				_apply_aoe_damage(collider.global_position, aoe_radius, aoe_damage)

			if not has_aoe:
				break  # Only hit first enemy if no AoE

	# Alternate attack side
	attack_side = "left" if attack_side == "right" else "right"


func _apply_aoe_damage(center: Vector2, radius: float, damage: int) -> void:
	"""Apply AoE damage around a point"""
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist: float = center.distance_to(enemy.global_position)
		if dist <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(damage)


func update_weapon_visual(weapon: Dictionary) -> void:
	"""Update weapon sprite to match currently equipped melee weapon"""
	if not weapon_sprite:
		return

	var texture_path: String = weapon.get("texture", "")
	if texture_path == "":
		weapon_sprite.visible = false
		current_weapon_texture_path = ""
		return

	if texture_path != current_weapon_texture_path or weapon_sprite.texture == null:
		# Load texture via AssetManager with automatic fallback
		var texture: Texture2D = AssetManager.load_texture(texture_path)

		# If placeholder (asset missing), hide weapon sprite
		if texture == AssetManager.get_placeholder():
			weapon_sprite.visible = false
			current_weapon_texture_path = ""
			return

		weapon_sprite.texture = texture
		current_weapon_texture_path = texture_path

		var tex_size: Vector2 = texture.get_size()
		var max_dimension: float = float(max(tex_size.x, tex_size.y))
		var desired_size: float = 96.0
		var denominator: float = float(max(1.0, max_dimension))
		var scale_factor: float = desired_size / denominator
		weapon_sprite.scale = Vector2(scale_factor, scale_factor)
		weapon_sprite.offset = Vector2.ZERO
		weapon_sprite.rotation = 0.0

	if weapon_anchor:
		var base_offset: Vector2 = _get_base_weapon_offset()
		weapon_anchor.position = base_offset
		weapon_target_offset = base_offset

	weapon_sprite.visible = weapon_sprite.texture != null


func _trigger_weapon_swing() -> void:
	"""Kick off a short swing animation on the weapon anchor"""
	if weapon_swing_duration <= 0.0:
		weapon_swing_duration = 0.18
	weapon_swing_time = weapon_swing_duration


func _get_base_weapon_offset() -> Vector2:
	return Vector2(weapon_base_offset.x * facing_direction, weapon_base_offset.y)


func _update_weapon_anchor(delta: float) -> void:
	if not weapon_anchor:
		return

	var base_offset: Vector2 = _get_base_weapon_offset()
	var desired_offset: Vector2 = base_offset
	var swing_strength: float = 0.0

	if weapon_swing_time > 0.0 and weapon_swing_duration > 0.0:
		weapon_swing_time = max(weapon_swing_time - delta, 0.0)
		var progress: float = 1.0 - (weapon_swing_time / weapon_swing_duration)
		swing_strength = sin(progress * PI)
		var swing_offset: Vector2 = Vector2(20.0 * facing_direction, -8.0) * swing_strength
		desired_offset += swing_offset
	else:
		weapon_swing_time = 0.0

	weapon_target_offset = weapon_target_offset.lerp(desired_offset, clamp(delta * 14.0, 0.0, 1.0))
	weapon_anchor.position = weapon_target_offset

	if weapon_sprite:
		weapon_sprite.flip_h = facing_direction == -1
		var target_rotation: float = -facing_direction * deg_to_rad(20.0) * swing_strength
		weapon_sprite.rotation = lerp(weapon_sprite.rotation, target_rotation, clamp(delta * 18.0, 0.0, 1.0))
		if not weapon_sprite.visible:
			weapon_sprite.rotation = 0.0


func take_damage(damage: int) -> void:
	"""Apply damage to player"""
	if invulnerable or GameManager.is_game_over:
		return

	# Apply damage reduction
	var final_damage: float = damage * (1.0 - damage_reduction)

	# Shield absorbs damage first
	if shield_hp > 0:
		if shield_hp >= final_damage:
			shield_hp -= int(final_damage)
			final_damage = 0
		else:
			final_damage -= shield_hp
			shield_hp = 0

	# Apply remaining damage to health
	if final_damage > 0:
		current_health -= int(final_damage)
		current_health = max(0, current_health)
		health_changed.emit(int(current_health))
		
		# Trigger damage animation (Phase 1)
		trigger_damage_animation()

		# Play damage sound
		if final_damage >= 50:
			AudioManager.play_big_damage_sound()  # Screaming Goat for big damage
		else:
			AudioManager.play_damage_sound()

		# Start invulnerability period
		invulnerable = true
		invulnerability_timer = invulnerability_time
		modulate = Color(1, 0.5, 0.5)  # Red tint

	# Check for death
	if current_health <= 0:
		die()


func die() -> void:
	"""Handle player death"""
	# Trigger death animation (Phase 1)
	trigger_death_animation()
	
	# Play death sound
	AudioManager.play_death_sound()

	died.emit()
	GameManager.trigger_game_over()
	# Optionally hide or disable player
	# queue_free()


func heal(amount: int) -> void:
	"""Heal the player"""
	current_health = min(current_health + amount, max_health)
	health_changed.emit(int(current_health))


func add_shield(amount: int) -> void:
	shield_hp = shield_hp + amount


func apply_impulse(direction: Vector2, strength: float) -> void:
	if direction.length() == 0.0:
		return
	external_velocity += direction.normalized() * strength


func add_weapon(weapon_type: String) -> void:
	"""Add a weapon to the player's arsenal"""
	if weapon_type in equipped_weapons:
		return
	equipped_weapons.append(weapon_type)
	weapon_cooldowns[weapon_type] = 0.0
	print("Equipped weapon: ", weapon_type)


func _fire_weapons() -> void:
	"""Fire all equipped weapons that are off cooldown"""
	if GameManager.is_game_over or GameManager.is_paused:
		return

	# Find nearest enemy
	var target: Node2D = _find_nearest_enemy()
	if not target:
		return

	# Check if in range
	if global_position.distance_to(target.global_position) > weapon_range:
		return

	# Fire each weapon
	for weapon_type in equipped_weapons:
		var fire_rate: float = WEAPON_FIRE_RATES.get(weapon_type, 1.0)

		# Apply laser fire rate multiplier
		if weapon_type == "laser":
			fire_rate = fire_rate / laser_upgrades.get("laser_firerate_mult", 1.0)

		var cooldown: float = weapon_cooldowns.get(weapon_type, 0.0)

		if cooldown >= fire_rate:
			_fire_weapon(weapon_type, target)
			weapon_cooldowns[weapon_type] = 0.0


func _fire_weapon(weapon_type: String, target: Node2D) -> void:
	"""Fire a specific weapon at target"""
	var direction: Vector2 = (target.global_position - global_position).normalized()

	match weapon_type:
		"laser":
			_fire_laser(direction)
		"rocket":
			# TEMPORARILY DISABLED
			print("Rocket launcher disabled for stability")
			# _spawn_projectile(rocket_scene, direction)
		"shotgun":
			# TEMPORARILY DISABLED
			print("Shotgun disabled for stability")
			# _fire_shotgun(direction)


func _spawn_projectile(projectile_scene: PackedScene, direction: Vector2) -> void:
	"""Spawn a projectile"""
	var projectile: Node2D = projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.set_direction(direction)
	get_parent().add_child(projectile)


func _fire_laser(direction: Vector2) -> void:
	"""Fire laser with upgrades"""
	laser_shot_counter += 1

	# Check for overcharge
	var is_overcharged = false
	var overcharge_interval = laser_upgrades.get("overcharge_interval", 0)
	if overcharge_interval > 0 and laser_shot_counter >= overcharge_interval:
		is_overcharged = true
		laser_shot_counter = 0

	# Create laser projectile
	var laser = laser_scene.instantiate()
	laser.global_position = global_position

	# Apply upgrades
	var upgrades = laser_upgrades.duplicate()
	upgrades["is_overcharged"] = is_overcharged
	if is_overcharged:
		upgrades["overcharge_aoe"] = laser_upgrades.get("overcharge_aoe", 0.0)

	if laser.has_method("set_laser_upgrades"):
		laser.set_laser_upgrades(upgrades)

	laser.set_direction(direction)
	get_parent().add_child(laser)


func _fire_shotgun(direction: Vector2) -> void:
	"""Fire shotgun with spread pattern"""
	var pellet_count: int = 5
	var spread_angle: float = deg_to_rad(30.0)

	for i in range(pellet_count):
		# Calculate spread
		var angle_offset: float = (i - pellet_count / 2.0) * (spread_angle / pellet_count)
		var spread_direction: Vector2 = direction.rotated(angle_offset)

		_spawn_projectile(shotgun_pellet_scene, spread_direction)


func _find_nearest_enemy() -> Node2D:
	"""Find the nearest enemy"""
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var enemy_node: Node2D = enemy as Node2D
		if enemy_node == null:
			continue

		var dist: float = global_position.distance_to(enemy_node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy_node

	return nearest


func _setup_visual() -> void:
	"""Setup player visual (sprite or ColorRect fallback)"""
	# Get the Sprite node from scene (already configured in Player.tscn)
	sprite = get_node_or_null("Sprite")

	if sprite == null:
		print("Warning: Player Sprite node not found in scene!")
		use_sprites = false
		return

	# Check if sprite_frames are loaded and have walk animation
	if sprite.sprite_frames == null:
		print("Warning: No SpriteFrames assigned to player sprite!")
		use_sprites = false
		return

	if not sprite.sprite_frames.has_animation("walk"):
		print("Warning: No 'walk' animation found in player SpriteFrames!")
		use_sprites = false
		return

	# Sprite is already configured in scene, just set scale
	sprite.scale = Vector2(1.3, 1.3)
	sprite.play("idle")


func _update_sprite_animation() -> void:
	"""Update sprite animation based on movement - enhanced with state machine"""
	if not use_sprites or not sprite:
		return

	# Determine target animation state
	var target_state: AnimState = AnimState.IDLE
	
	if velocity.length() > 12.0:
		target_state = AnimState.WALK
	else:
		target_state = AnimState.IDLE
	
	# Transition to new state if different
	if target_state != current_anim_state:
		_set_animation_state(target_state)
	
	# Always update facing direction
	sprite.flip_h = facing_direction == -1


func _set_animation_state(new_state: AnimState) -> void:
	"""Change animation state with proper transitions"""
	if not sprite or not sprite.sprite_frames:
		return
	
	previous_anim_state = current_anim_state
	current_anim_state = new_state
	
	match current_anim_state:
		AnimState.IDLE:
			if sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
		AnimState.WALK:
			if sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
		AnimState.ATTACK:
			if sprite.sprite_frames.has_animation("attack"):
				sprite.play("attack")
			else:
				# Fallback if attack animation not yet created
				if sprite.sprite_frames.has_animation("walk"):
					sprite.play("walk")
		AnimState.DAMAGED:
			if sprite.sprite_frames.has_animation("damaged"):
				sprite.play("damaged")
			# Auto-return to previous state after damage animation
			if sprite.sprite_frames.has_animation("damaged"):
				sprite.animation_finished.connect(_on_damage_animation_finished, CONNECT_ONE_SHOT)
		AnimState.DEATH:
			if sprite.sprite_frames.has_animation("death"):
				sprite.play("death")
			elif sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")
				sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)  # Fade out


func _on_damage_animation_finished() -> void:
	"""Return to previous state after damage animation completes"""
	if current_anim_state == AnimState.DAMAGED:
		_set_animation_state(previous_anim_state)


func trigger_attack_animation() -> void:
	"""Trigger attack animation (called by melee attack)"""
	if use_sprites and sprite:
		_set_animation_state(AnimState.ATTACK)
		# Auto-return after attack animation
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
			sprite.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)


func _on_attack_animation_finished() -> void:
	"""Return to idle/walk after attack animation completes"""
	if current_anim_state == AnimState.ATTACK:
		if velocity.length() > 12.0:
			_set_animation_state(AnimState.WALK)
		else:
			_set_animation_state(AnimState.IDLE)


func trigger_damage_animation() -> void:
	"""Trigger damage/hit animation (called when taking damage)"""
	if use_sprites and sprite:
		_set_animation_state(AnimState.DAMAGED)


func trigger_death_animation() -> void:
	"""Trigger death animation (called on death)"""
	if use_sprites and sprite:
		_set_animation_state(AnimState.DEATH)


func apply_slow(slow_amount: float) -> void:
	"""Apply slow effect from Support Drone (stacks)"""
	slow_stacks += 1

	# Only apply slow on first stack
	if slow_stacks == 1:
		speed = base_speed * slow_amount
		print("Player slowed to ", speed, " (", slow_amount * 100, "%)")


func remove_slow() -> void:
	"""Remove slow effect from Support Drone"""
	slow_stacks = max(slow_stacks - 1, 0)

	# Restore speed when no more slow stacks
	if slow_stacks == 0:
		speed = base_speed
		print("Player speed restored to ", speed)


func _check_enemy_overlap() -> void:
	if invulnerable:
		return

	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if not shape_node:
		return

	var shape: Shape2D = shape_node.shape
	if not shape:
		return

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = shape_node.global_transform
	query.collision_mask = 2  # Enemy layer
	query.exclude = [get_rid()]

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var results: Array[Dictionary] = space_state.intersect_shape(query, 1)
	for result in results:
		var collider: Node = result.get("collider") as Node
		if collider and collider.is_in_group("enemies"):
			take_damage(10)
			break


func _try_open_drone_shop() -> void:
	"""Try to open drone shop (Hacker-specific ability)"""
	if drone_shops_available <= 0:
		print("No drone shops available. Gain one every 3 waves!")
		return

	# Consume one drone shop charge
	drone_shops_available -= 1
	print("Opening Drone Shop! (", drone_shops_available, " remaining)")

	# Open the shop
	ShopManager.open_shop(ShopManager.ShopType.DRONE_SHOP)


func grant_drone_shop() -> void:
	"""Grant a drone shop charge (called by game.gd every 3 waves)"""
	drone_shops_available += 1
	print("Drone Shop available! Press [T] to open. (", drone_shops_available, " total)")
