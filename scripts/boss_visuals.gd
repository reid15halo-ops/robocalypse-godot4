extends Node

# Constants
const SPRITE_Z_INDEX: int = 1
const SPRITE_SCALE: float = 0.15

const COLOR_RECT_SIZE: float = 128.0
const COLOR_RECT_BODY_COLOR_R: float = 0.8
const COLOR_RECT_BODY_COLOR_G: float = 0.1
const COLOR_RECT_BODY_COLOR_B: float = 0.1
const COLOR_RECT_BODY_COLOR_A: float = 1.0
const COLOR_RECT_ARMOR_COLOR_R: float = 0.1
const COLOR_RECT_ARMOR_COLOR_G: float = 0.1
const COLOR_RECT_ARMOR_COLOR_B: float = 0.1
const COLOR_RECT_ARMOR_COLOR_A: float = 0.9
const COLOR_RECT_ARMOR_TOP_SIZE_Y: int = 16
const COLOR_RECT_ARMOR_TOP_POS_X_MULTIPLIER: float = 0.45
const COLOR_RECT_ARMOR_BOTTOM_POS_Y_MULTIPLIER: float = 0.35
const COLOR_RECT_ARMOR_LEFT_SIZE_X: int = 16
const COLOR_RECT_ARM_LENGTH: float = 60.0
const COLOR_RECT_ARM_THICKNESS: float = 12.0
const COLOR_RECT_ARM_POS_Y_MULTIPLIER: float = 0.5
const COLOR_RECT_ARM_COLOR_R: float = 0.2
const COLOR_RECT_ARM_COLOR_G: float = 0.2
const COLOR_RECT_ARM_COLOR_B: float = 0.2
const COLOR_RECT_EYE_SIZE: int = 20
const COLOR_RECT_EYE_LEFT_POS_X: int = -30
const COLOR_RECT_EYE_LEFT_POS_Y: int = -20
const COLOR_RECT_EYE_RIGHT_POS_X: int = 10
const COLOR_RECT_EYE_RIGHT_POS_Y: int = -20
const COLOR_RECT_EYE_COLOR_R: float = 1.0
const COLOR_RECT_EYE_COLOR_G: float = 0.0
const COLOR_RECT_EYE_COLOR_B: float = 0.0
const COLOR_RECT_EYE_COLOR_A: float = 1.0
const COLOR_RECT_EYE_TWEEN_MODULATE_A_1: float = 0.5
const COLOR_RECT_EYE_TWEEN_DURATION_1: float = 0.8
const COLOR_RECT_EYE_TWEEN_MODULATE_A_2: float = 1.0
const COLOR_RECT_EYE_TWEEN_DURATION_2: float = 0.8
const COLOR_RECT_CORE_SIZE: int = 32
const COLOR_RECT_CORE_COLOR_R: float = 1.0
const COLOR_RECT_CORE_COLOR_G: float = 0.3
const COLOR_RECT_CORE_COLOR_B: float = 0.0
const COLOR_RECT_CORE_COLOR_A: float = 0.8
const COLOR_RECT_CORE_TWEEN_SCALE_1: float = 1.2
const COLOR_RECT_CORE_TWEEN_DURATION_1: float = 0.5
const COLOR_RECT_CORE_TWEEN_SCALE_2: float = 0.8
const COLOR_RECT_CORE_TWEEN_DURATION_2: float = 0.5

const PHASE_2_MODULATE_R: float = 1.2
const PHASE_2_MODULATE_G: float = 0.55
const PHASE_2_MODULATE_B: float = 0.55
const PHASE_3_MODULATE_R: float = 1.6
const PHASE_3_MODULATE_G: float = 0.35
const PHASE_3_MODULATE_B: float = 0.35
const PHASE_4_MODULATE_R: float = 2.0
const PHASE_4_MODULATE_G: float = 0.25
const PHASE_4_MODULATE_B: float = 0.25

const FLASH_DAMAGE_MODULATE_R: float = 1.6
const FLASH_DAMAGE_MODULATE_G: float = 0.6
const FLASH_DAMAGE_MODULATE_B: float = 0.6
const FLASH_DAMAGE_TIMER: float = 0.1

const FLASH_SHIELD_HIT_MODULATE_R_1: float = 0.8
const FLASH_SHIELD_HIT_MODULATE_G_1: float = 1.4
const FLASH_SHIELD_HIT_MODULATE_B_1: float = 1.6
const FLASH_SHIELD_HIT_MODULATE_A_1: float = 0.7
const FLASH_SHIELD_HIT_TWEEN_DURATION_1: float = 0.1
const FLASH_SHIELD_HIT_MODULATE_R_2: float = 0.2
const FLASH_SHIELD_HIT_MODULATE_G_2: float = 1.0
const FLASH_SHIELD_HIT_MODULATE_B_2: float = 1.5
const FLASH_SHIELD_HIT_MODULATE_A_2: float = 0.45
const FLASH_SHIELD_HIT_TWEEN_DURATION_2: float = 0.2

const CIRCLE_POINTS_SEGMENTS: int = 24

var boss: CharacterBody2D

func _init(boss_node: CharacterBody2D):
	boss = boss_node

func _create_boss_visual() -> void:
	"""Create impressive boss visual with multi-layered design"""
	if boss.use_sprites:
		_create_sprite_visual()
	else:
		_create_colorrect_visual()

func _create_sprite_visual() -> void:
	"""Create sprite visual for boss"""
	var sprite_path: String = "res://assets/sprites/boss/boss_mech.tres"

	if not ResourceLoader.exists(sprite_path):
		# Fallback to ColorRect
		boss.use_sprites = false
		_create_colorrect_visual()
		return

	boss.sprite = AnimatedSprite2D.new()
	boss.sprite.z_index = SPRITE_Z_INDEX
	boss.sprite.centered = true
	boss.sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	boss.add_child(boss.sprite)

	boss.sprite.sprite_frames = load(sprite_path)
	boss.sprite.play("idle")

func _create_colorrect_visual() -> void:
	"""Create ColorRect fallback visual"""
	var visual: Node2D = Node2D.new()
	visual.name = "Visual"
	boss.visual_node = visual
	boss.add_child(visual)

	var size: float = COLOR_RECT_SIZE

	# Main body - massive red rectangle
	var body: ColorRect = ColorRect.new()
	body.size = Vector2(size, size)
	body.position = -body.size / 2
	body.color = Color(COLOR_RECT_BODY_COLOR_R, COLOR_RECT_BODY_COLOR_G, COLOR_RECT_BODY_COLOR_B, COLOR_RECT_BODY_COLOR_A)
	visual.add_child(body)

	# Black armor plates overlay
	var armor_color: Color = Color(COLOR_RECT_ARMOR_COLOR_R, COLOR_RECT_ARMOR_COLOR_G, COLOR_RECT_ARMOR_COLOR_B, COLOR_RECT_ARMOR_COLOR_A)

	# Top armor plate
	var armor_top: ColorRect = ColorRect.new()
	armor_top.size = Vector2(size * COLOR_RECT_ARMOR_COLOR_A, COLOR_RECT_ARMOR_TOP_SIZE_Y)
	armor_top.position = Vector2(-size * COLOR_RECT_ARMOR_TOP_POS_X_MULTIPLIER, -size * COLOR_RECT_ARMOR_TOP_POS_X_MULTIPLIER)
	armor_top.color = armor_color
	visual.add_child(armor_top)

	# Bottom armor plate
	var armor_bottom: ColorRect = ColorRect.new()
	armor_bottom.size = Vector2(size * COLOR_RECT_ARMOR_COLOR_A, COLOR_RECT_ARMOR_TOP_SIZE_Y)
	armor_bottom.position = Vector2(-size * COLOR_RECT_ARMOR_TOP_POS_X_MULTIPLIER, size * COLOR_RECT_ARMOR_BOTTOM_POS_Y_MULTIPLIER)
	armor_bottom.color = armor_color
	visual.add_child(armor_bottom)

	# Left armor plate
	var armor_left: ColorRect = ColorRect.new()
	armor_left.size = Vector2(COLOR_RECT_ARMOR_LEFT_SIZE_X, size * COLOR_RECT_ARMOR_COLOR_A)
	armor_left.position = Vector2(-size * COLOR_RECT_ARMOR_TOP_POS_X_MULTIPLIER, -size * COLOR_RECT_ARMOR_TOP_POS_X_MULTIPLIER)
	armor_left.color = armor_color
	visual.add_child(armor_left)

	# Right armor plate
	var armor_right: ColorRect = ColorRect.new()
	armor_right.size = Vector2(COLOR_RECT_ARMOR_LEFT_SIZE_X, size * COLOR_RECT_ARMOR_COLOR_A)
	armor_right.position = Vector2(size * COLOR_RECT_ARMOR_BOTTOM_POS_Y_MULTIPLIER, -size * COLOR_RECT_ARMOR_TOP_POS_X_MULTIPLIER)
	armor_right.color = armor_color
	visual.add_child(armor_right)

	# 4 weapon arms (extending outward)
	var arm_length: float = COLOR_RECT_ARM_LENGTH
	var arm_thickness: float = COLOR_RECT_ARM_THICKNESS

	# Top arm
	var arm_top_arm: ColorRect = ColorRect.new()
	arm_top_arm.size = Vector2(arm_thickness, arm_length)
	arm_top_arm.position = Vector2(-arm_thickness / 2, -size * COLOR_RECT_ARM_POS_Y_MULTIPLIER - arm_length)
	arm_top_arm.color = Color(COLOR_RECT_ARM_COLOR_R, COLOR_RECT_ARM_COLOR_G, COLOR_RECT_ARM_COLOR_B)
	visual.add_child(arm_top_arm)

	# Bottom arm
	var arm_bottom_arm: ColorRect = ColorRect.new()
	arm_bottom_arm.size = Vector2(arm_thickness, arm_length)
	arm_bottom_arm.position = Vector2(-arm_thickness / 2, size * COLOR_RECT_ARM_POS_Y_MULTIPLIER)
	arm_bottom_arm.color = Color(COLOR_RECT_ARM_COLOR_R, COLOR_RECT_ARM_COLOR_G, COLOR_RECT_ARM_COLOR_B)
	visual.add_child(arm_bottom_arm)

	# Left arm
	var arm_left_arm: ColorRect = ColorRect.new()
	arm_left_arm.size = Vector2(arm_length, arm_thickness)
	arm_left_arm.position = Vector2(-size * COLOR_RECT_ARM_POS_Y_MULTIPLIER - arm_length, -arm_thickness / 2)
	arm_left_arm.color = Color(COLOR_RECT_ARM_COLOR_R, COLOR_RECT_ARM_COLOR_G, COLOR_RECT_ARM_COLOR_B)
	visual.add_child(arm_left_arm)

	# Right arm
	var arm_right_arm: ColorRect = ColorRect.new()
	arm_right_arm.size = Vector2(arm_length, arm_thickness)
	arm_right_arm.position = Vector2(size * COLOR_RECT_ARM_POS_Y_MULTIPLIER, -arm_thickness / 2)
	arm_right_arm.color = Color(COLOR_RECT_ARM_COLOR_R, COLOR_RECT_ARM_COLOR_G, COLOR_RECT_ARM_COLOR_B)
	visual.add_child(arm_right_arm)

	# Glowing red eyes
	var eye_left: ColorRect = ColorRect.new()
	eye_left.size = Vector2(COLOR_RECT_EYE_SIZE, COLOR_RECT_EYE_SIZE)
	eye_left.position = Vector2(COLOR_RECT_EYE_LEFT_POS_X, COLOR_RECT_EYE_LEFT_POS_Y)
	eye_left.color = Color(COLOR_RECT_EYE_COLOR_R, COLOR_RECT_EYE_COLOR_G, COLOR_RECT_EYE_COLOR_B, COLOR_RECT_EYE_COLOR_A)
	eye_left.name = "EyeLeft"
	visual.add_child(eye_left)

	var eye_right: ColorRect = ColorRect.new()
	eye_right.size = Vector2(COLOR_RECT_EYE_SIZE, COLOR_RECT_EYE_SIZE)
	eye_right.position = Vector2(COLOR_RECT_EYE_RIGHT_POS_X, COLOR_RECT_EYE_RIGHT_POS_Y)
	eye_right.color = Color(COLOR_RECT_EYE_COLOR_R, COLOR_RECT_EYE_COLOR_G, COLOR_RECT_EYE_COLOR_B, COLOR_RECT_EYE_COLOR_A)
	eye_right.name = "EyeRight"
	visual.add_child(eye_right)

	# Pulsing glow effect on eyes
	var tween: Tween = boss.create_tween().set_loops()
	tween.set_parallel(true)
	tween.tween_property(eye_left, "modulate:a", COLOR_RECT_EYE_TWEEN_MODULATE_A_1, COLOR_RECT_EYE_TWEEN_DURATION_1)
	tween.tween_property(eye_right, "modulate:a", COLOR_RECT_EYE_TWEEN_MODULATE_A_1, COLOR_RECT_EYE_TWEEN_DURATION_1)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(eye_left, "modulate:a", COLOR_RECT_EYE_TWEEN_MODULATE_A_2, COLOR_RECT_EYE_TWEEN_DURATION_2)
	tween.tween_property(eye_right, "modulate:a", COLOR_RECT_EYE_TWEEN_MODULATE_A_2, COLOR_RECT_EYE_TWEEN_DURATION_2)

	# Core reactor (center glow)
	var core: ColorRect = ColorRect.new()
	core.size = Vector2(COLOR_RECT_CORE_SIZE, COLOR_RECT_CORE_SIZE)
	core.position = -core.size / 2
	core.color = Color(COLOR_RECT_CORE_COLOR_R, COLOR_RECT_CORE_COLOR_G, COLOR_RECT_CORE_COLOR_B, COLOR_RECT_CORE_COLOR_A)
	core.name = "Core"
	visual.add_child(core)

	# Pulsing core
	var core_tween: Tween = boss.create_tween().set_loops()
	core_tween.tween_property(core, "scale", Vector2(COLOR_RECT_CORE_TWEEN_SCALE_1, COLOR_RECT_CORE_TWEEN_SCALE_1), COLOR_RECT_CORE_TWEEN_DURATION_1)
	core_tween.tween_property(core, "scale", Vector2(COLOR_RECT_CORE_TWEEN_SCALE_2, COLOR_RECT_CORE_TWEEN_SCALE_2), COLOR_RECT_CORE_TWEEN_DURATION_2)

func _apply_phase_color() -> void:
	match boss.state_machine.phase:
		1:
			boss.modulate = Color(1.0, 1.0, 1.0)
		2:
			boss.modulate = Color(PHASE_2_MODULATE_R, PHASE_2_MODULATE_G, PHASE_2_MODULATE_B)
		3:
			boss.modulate = Color(PHASE_3_MODULATE_R, PHASE_3_MODULATE_G, PHASE_3_MODULATE_B)
		4:
			boss.modulate = Color(PHASE_4_MODULATE_R, PHASE_4_MODULATE_G, PHASE_4_MODULATE_B)

func _flash_damage() -> void:
	boss.modulate = Color(FLASH_DAMAGE_MODULATE_R, FLASH_DAMAGE_MODULATE_G, FLASH_DAMAGE_MODULATE_B)
	await boss.get_tree().create_timer(FLASH_DAMAGE_TIMER).timeout
	if boss.is_queued_for_deletion():
		return
	_apply_phase_color()

func _flash_shield_hit() -> void:
	if boss.shield_visual and boss.is_instance_valid(boss.shield_visual):
		var ring: Polygon2D = boss.shield_visual.get_child(0) as Polygon2D
		if ring and ring is CanvasItem:
			var tween: Tween = boss.get_tree().create_tween()
			tween.tween_property(ring, "modulate", Color(FLASH_SHIELD_HIT_MODULATE_R_1, FLASH_SHIELD_HIT_MODULATE_G_1, FLASH_SHIELD_HIT_MODULATE_B_1, FLASH_SHIELD_HIT_MODULATE_A_1), FLASH_SHIELD_HIT_TWEEN_DURATION_1)
			tween.tween_property(ring, "modulate", Color(FLASH_SHIELD_HIT_MODULATE_R_2, FLASH_SHIELD_HIT_MODULATE_G_2, FLASH_SHIELD_HIT_MODULATE_B_2, FLASH_SHIELD_HIT_MODULATE_A_2), FLASH_SHIELD_HIT_TWEEN_DURATION_2)

func _circle_points(radius: float, segments: int = CIRCLE_POINTS_SEGMENTS) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts