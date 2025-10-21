extends Node

# Map System - Manages multiple areas/rooms and level progression
# Player advances through areas after completing waves

# Area data structure
class AreaData:
	var id: String
	var name: String
	var position: Vector2  # Center position
	var size: Vector2  # Area dimensions
	var difficulty_multiplier: float
	var waves_required: int  # Waves needed to unlock next area
	var next_area_id: String

	func _init(p_id: String, p_name: String, p_pos: Vector2, p_size: Vector2, p_diff: float, p_waves: int, p_next: String):
		id = p_id
		name = p_name
		position = p_pos
		size = p_size
		difficulty_multiplier = p_diff
		waves_required = p_waves
		next_area_id = p_next


# Current area tracking
var current_area_id: String = "area_1"
var current_area: AreaData = null
var waves_in_current_area: int = 0

# All areas
var areas: Dictionary = {}

# Portal/Arrow tracking
var active_portal: Node = null
var portal_pending: bool = false

# Signals
signal area_changed(area: AreaData)
signal portal_appeared(position: Vector2)


func _ready() -> void:
    _initialize_areas()
    current_area = areas[current_area_id]


func _initialize_areas() -> void:
	"""Initialize all map areas"""

	# AREA 1 - Starting Zone (Bottom-Left)
	areas["area_1"] = AreaData.new(
		"area_1",
		"Scrapyard Entrance",
		Vector2(400, 500),
		Vector2(600, 400),
		1.0,
		3,  # 3 waves to unlock next
		"area_2"
	)

	# AREA 2 - Factory Floor (Bottom-Right)
	areas["area_2"] = AreaData.new(
		"area_2",
		"Assembly Line",
		Vector2(1100, 500),
		Vector2(600, 400),
		1.3,
		4,  # 4 waves
		"area_3"
	)

	# AREA 3 - Upper Deck (Top-Right)
	areas["area_3"] = AreaData.new(
		"area_3",
		"Control Center",
		Vector2(1100, 200),
		Vector2(600, 300),
		1.6,
		5,  # 5 waves
		"area_4"
	)

	# AREA 4 - Server Room (Top-Left)
	areas["area_4"] = AreaData.new(
		"area_4",
		"Server Farm",
		Vector2(400, 200),
		Vector2(600, 300),
		2.0,
		6,  # 6 waves
		"area_5"
	)

	# AREA 5 - Boss Arena (Center)
	areas["area_5"] = AreaData.new(
		"area_5",
		"Core Processor",
		Vector2(750, 350),
		Vector2(500, 300),
		2.5,
		999,  # Final area
		""
	)


func get_current_area() -> AreaData:
	"""Get current area data"""
	return current_area


func get_difficulty_multiplier() -> float:
	"""Get current area difficulty multiplier"""
	if current_area:
		return current_area.difficulty_multiplier
	return 1.0


func complete_wave() -> void:
    """Called when player completes a wave"""
    if current_area == null:
        return
    waves_in_current_area += 1

    # Check if player can advance to next area
    if waves_in_current_area >= current_area.waves_required and current_area.next_area_id:
        _spawn_portal_to_next_area()


func _spawn_portal_to_next_area() -> void:
    """Spawn portal/arrow to next area"""
    # Avoid duplicate announcements/portals
    if (active_portal and is_instance_valid(active_portal)) or portal_pending:
        return
    var next_area = areas.get(current_area.next_area_id)
    if not next_area:
        return

    # Get direction to next area
    var to_next = next_area.position - current_area.position
    var direction = to_next.length() > 0.0 ? to_next.normalized() : Vector2.RIGHT
    var portal_pos = current_area.position + direction * 250

    portal_appeared.emit(portal_pos)
    portal_pending = true
    print("Portal to ", next_area.name, " has appeared!")


func advance_to_next_area() -> bool:
	"""Advance player to next area"""
	if not current_area.next_area_id:
		return false

	var next_area = areas.get(current_area.next_area_id)
	if not next_area:
		return false

    # Remove old portal
    if active_portal and is_instance_valid(active_portal):
        active_portal.queue_free()
        active_portal = null

	# Switch to new area
    current_area = next_area
    current_area_id = next_area.id
    waves_in_current_area = 0
    portal_pending = false

	area_changed.emit(current_area)
	print("Advanced to: ", current_area.name)
	print("Difficulty multiplier: ", current_area.difficulty_multiplier)

	return true


func create_portal_visual(game_scene: Node, position: Vector2) -> void:
    """Create visual portal/arrow at position"""
    var portal = Area2D.new()
    portal.name = "AreaPortal"
    portal.global_position = position
    portal.collision_layer = 0
    portal.collision_mask = 1  # Detect player

    # Collision shape
    var collision_shape = CollisionShape2D.new()
    var circle = CircleShape2D.new()
    circle.radius = 60.0
    collision_shape.shape = circle
    portal.add_child(collision_shape)

    # Visual - glowing circle using Polygon2D (Node2D-based)
    var visual = Polygon2D.new()
    var circle_points: PackedVector2Array = []
    var segs := 24
    var radius := 60.0
    for i in range(segs):
        var ang = TAU * float(i) / float(segs)
        circle_points.append(Vector2(cos(ang), sin(ang)) * radius)
    visual.polygon = circle_points
    visual.color = Color(0.0, 1.0, 0.5, 0.6)
    visual.z_index = 10
    portal.add_child(visual)

    # Arrow indicator pointing to next area using Polygon2D triangle
    var arrow = Polygon2D.new()
    var tri: PackedVector2Array = [Vector2(40, 0), Vector2(0, 12), Vector2(0, -12)]
    arrow.polygon = tri
    arrow.color = Color(1.0, 1.0, 0.0, 1.0)
    arrow.z_index = 11
    # Orient arrow toward next area if known
    if current_area and current_area.next_area_id and areas.has(current_area.next_area_id):
        var next_area: AreaData = areas[current_area.next_area_id]
        var dir_vec = next_area.position - current_area.position
        var dir = dir_vec.length() > 0.0 ? dir_vec.normalized() : Vector2.RIGHT
        arrow.rotation = dir.angle()
    portal.add_child(arrow)

    # Pulse animation
    var tween = portal.create_tween().set_loops()
    tween.tween_property(visual, "modulate:a", 0.3, 1.0)
    tween.tween_property(visual, "modulate:a", 0.8, 1.0)

    # Connect signal
    portal.body_entered.connect(Callable(self, "_on_portal_entered"))

    game_scene.add_child(portal)
    active_portal = portal


func _on_portal_entered(body: Node2D) -> void:
    """Player entered portal"""
    if body.is_in_group("player") or body == GameManager.player:
        advance_to_next_area()

        # Move player to new area center
        if is_instance_valid(body):
            body.global_position = current_area.position


func reset() -> void:
    """Reset to starting area"""
    if areas.is_empty():
        _initialize_areas()
    current_area_id = "area_1"
    current_area = areas[current_area_id]
    waves_in_current_area = 0
    portal_pending = false

    if active_portal and is_instance_valid(active_portal):
        active_portal.queue_free()
        active_portal = null


# WALL CREATION REMOVED - FREE ROAMING MAP
# No boundaries, player can move freely across entire tilemap
