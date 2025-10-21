extends Node2D
class_name SpawnBeacon

## Teleporter-style spawn indicator that warns 2.5s (or 5s for bosses) before enemy spawn
## Visual phases: Cyan hexagonal grid → Orange energy column → Red blinking warning

signal spawn_ready

@export var is_boss_beacon: bool = false
@export var base_duration: float = 2.5
@export var boss_duration: float = 5.0

var floor_marker: Polygon2D
var energy_column: ColorRect
var scan_lines: Array[Line2D] = []
var warning_ring: Line2D
var particles: CPUParticles2D
var spawn_timer: Timer

var elapsed_time: float = 0.0
var total_duration: float = 2.5
var current_phase: int = 0
var blink_timer: float = 0.0
var blink_state: bool = true

const PHASE_1_END: float = 0.32  # 32% of duration - Cyan grid
const PHASE_2_END: float = 0.72  # 72% of duration - Orange energy
const PHASE_3_END: float = 1.0   # 100% of duration - Red warning

const COLOR_CYAN: Color = Color(0.0, 0.8, 1.0)
const COLOR_ORANGE: Color = Color(1.0, 0.5, 0.0)
const COLOR_RED: Color = Color(1.0, 0.0, 0.0)

func _ready() -> void:
	total_duration = boss_duration if is_boss_beacon else base_duration
	var beacon_scale: float = 2.0 if is_boss_beacon else 1.0
	scale = Vector2(beacon_scale, beacon_scale)

	_create_visual_components()
	_setup_spawn_timer()

func _create_visual_components() -> void:
	# Hexagonal floor marker
	floor_marker = Polygon2D.new()
	floor_marker.polygon = _create_hexagon(30.0)
	floor_marker.color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.3)
	add_child(floor_marker)

	# Energy column (central pillar)
	energy_column = ColorRect.new()
	energy_column.size = Vector2(8, 0)
	energy_column.position = Vector2(-4, 0)
	energy_column.color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.6)
	add_child(energy_column)

	# Three scan lines
	for i in range(3):
		var scan_line = Line2D.new()
		scan_line.width = 2.0
		scan_line.default_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.8)
		scan_line.add_point(Vector2(-25, 0))
		scan_line.add_point(Vector2(25, 0))
		scan_line.position.y = 0
		add_child(scan_line)
		scan_lines.append(scan_line)

	# Warning ring (outer circle)
	warning_ring = Line2D.new()
	warning_ring.width = 3.0
	warning_ring.default_color = Color(COLOR_RED.r, COLOR_RED.g, COLOR_RED.b, 0.0)
	var circle_points = _create_circle(35.0, 32)
	for point in circle_points:
		warning_ring.add_point(point)
	warning_ring.add_point(circle_points[0])  # Close the circle
	add_child(warning_ring)

	# Particle system (rising energy)
	particles = CPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 25.0
	particles.direction = Vector2(0, -1)
	particles.spread = 15.0
	particles.gravity = Vector2(0, -50)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = COLOR_CYAN
	particles.emitting = true
	add_child(particles)

func _setup_spawn_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = total_duration
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func _process(delta: float) -> void:
	elapsed_time += delta
	var progress: float = elapsed_time / total_duration

	# Phase 1: Cyan hexagonal grid (0-32%)
	if progress < PHASE_1_END:
		_update_phase_1(progress / PHASE_1_END)

	# Phase 2: Orange energy column (32-72%)
	elif progress < PHASE_2_END:
		if current_phase != 2:
			_enter_phase_2()
		var phase_progress = (progress - PHASE_1_END) / (PHASE_2_END - PHASE_1_END)
		_update_phase_2(phase_progress)

	# Phase 3: Red blinking warning (72-100%)
	else:
		if current_phase != 3:
			_enter_phase_3()
		var phase_progress = (progress - PHASE_2_END) / (PHASE_3_END - PHASE_2_END)
		_update_phase_3(phase_progress, delta)

func _update_phase_1(progress: float) -> void:
	current_phase = 1

	# Pulsating floor marker
	var pulse = 0.3 + 0.2 * sin(progress * PI * 8.0)
	floor_marker.color.a = pulse

	# Slowly start particles
	particles.color = COLOR_CYAN
	particles.amount = int(20 * progress)

func _enter_phase_2() -> void:
	current_phase = 2

func _update_phase_2(progress: float) -> void:
	# Grow energy column
	var column_height = progress * 60.0
	energy_column.size.y = column_height
	energy_column.position.y = -column_height

	# Transition color from cyan to orange
	var color = COLOR_CYAN.lerp(COLOR_ORANGE, progress)
	energy_column.color = Color(color.r, color.g, color.b, 0.7)
	floor_marker.color = Color(color.r, color.g, color.b, 0.4)
	particles.color = color

	# Move scan lines upward
	for i in range(scan_lines.size()):
		var offset = i * 0.33
		var scan_progress = fmod(progress + offset, 1.0)
		scan_lines[i].position.y = -scan_progress * 60.0
		scan_lines[i].default_color = Color(color.r, color.g, color.b, 0.8 * (1.0 - scan_progress))

func _enter_phase_3() -> void:
	current_phase = 3
	blink_timer = 0.0
	blink_state = true

func _update_phase_3(progress: float, delta: float) -> void:
	# Blink effect (10 Hz = 0.1s per cycle)
	blink_timer += delta
	if blink_timer >= 0.1:
		blink_timer = 0.0
		blink_state = !blink_state

	var alpha = 0.8 if blink_state else 0.2

	# Red color for all components
	floor_marker.color = Color(COLOR_RED.r, COLOR_RED.g, COLOR_RED.b, alpha * 0.5)
	energy_column.color = Color(COLOR_RED.r, COLOR_RED.g, COLOR_RED.b, alpha)
	particles.color = COLOR_RED

	# Make scan lines red and faster
	for i in range(scan_lines.size()):
		var offset = i * 0.25
		var scan_progress = fmod(progress * 2.0 + offset, 1.0)
		scan_lines[i].position.y = -scan_progress * 60.0
		scan_lines[i].default_color = Color(COLOR_RED.r, COLOR_RED.g, COLOR_RED.b, alpha)

	# Expand warning ring
	var ring_alpha = progress * alpha
	warning_ring.default_color = Color(COLOR_RED.r, COLOR_RED.g, COLOR_RED.b, ring_alpha)
	warning_ring.scale = Vector2(1.0 + progress * 0.5, 1.0 + progress * 0.5)

func _on_spawn_timer_timeout() -> void:
	# Phase 4: White flash and spawn
	_create_spawn_flash()
	spawn_ready.emit()

	# Cleanup after short delay
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _create_spawn_flash() -> void:
	var flash = ColorRect.new()
	flash.size = Vector2(80, 80)
	flash.position = Vector2(-40, -40)
	flash.color = Color(1.0, 1.0, 1.0, 0.8)
	add_child(flash)

	# Fade out flash
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)

# Helper function: Create hexagon polygon
func _create_hexagon(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i in range(6):
		var angle = deg_to_rad(i * 60.0)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

# Helper function: Create circle points
func _create_circle(radius: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i in range(segments):
		var angle = (i / float(segments)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
