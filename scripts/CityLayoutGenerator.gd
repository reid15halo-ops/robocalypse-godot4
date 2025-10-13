extends Node2D

## CityLayoutGenerator - Randomized City Map Generation
## Generates 14x14 grid with 0-3 random houses (4x4 to 8x8 cells)

# ============================================================================
# CONFIGURATION
# ============================================================================

const GRID_WIDTH: int = 14
const GRID_HEIGHT: int = 14
const CELL_SIZE: int = 128

const MIN_HOUSES: int = 0
const MAX_HOUSES: int = 3
const MIN_HOUSE_SIZE: int = 4
const MAX_HOUSE_SIZE: int = 8

# Grid cell types
enum CellType {
	EMPTY,
	STREET,
	BUILDING
}

# Spatial hash for collision detection
const SPATIAL_HASH_CELL_SIZE: int = 2  # Grid cells per hash cell
var spatial_hash: Dictionary = {}

# Grid data
var grid: Array[Array] = []
var generation_seed: int = 0
var spawn_points: Array[Vector2] = []
var occupied_zone_cells: Dictionary = {}

# Visual configuration
const WALL_THICKNESS: int = 24
const WALL_COLOR: Color = Color(0.3, 0.3, 0.35)
const BUILDING_FLOOR_COLOR: Color = Color(0.15, 0.15, 0.18)
const STREET_COLOR: Color = Color(0.25, 0.25, 0.28)
const DOOR_WIDTH: int = 128  # One cell width

# Container nodes
var walls_container: Node2D = null
var floor_container: Node2D = null
var zones_container: Node2D = null
var city_boundary: StaticBody2D = null

# Zone modules (visual placeholders that can be swapped with scenes later)
var zone_definitions := [
	{
		"id": "park",
		"size": Vector2i(2, 2),
		"color": Color(0.1, 0.6, 0.2, 0.8),
		"type": "decor"
	},
	{
		"id": "command",
		"size": Vector2i(3, 3),
		"color": Color(0.2, 0.4, 0.8, 0.85),
		"type": "command"
	},
	{
		"id": "obstacle",
		"size": Vector2i(2, 3),
		"color": Color(0.4, 0.4, 0.4, 0.9),
		"type": "obstacle"
	}
]


# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	"""Initialize generator"""
	walls_container = Node2D.new()
	walls_container.name = "Walls"
	add_child(walls_container)

	floor_container = Node2D.new()
	floor_container.name = "Floor"
	floor_container.z_index = -5
	add_child(floor_container)

	zones_container = Node2D.new()
	zones_container.name = "Zones"
	add_child(zones_container)


# ============================================================================
# MAIN GENERATION
# ============================================================================

func generate_map(seed_value: int = -1) -> void:
	"""Generate randomized city map with seed"""
	if seed_value == -1:
		generation_seed = randi()
	else:
		generation_seed = seed_value

	seed(generation_seed)
	print("=== CityLayoutGenerator: Starting generation (seed: ", generation_seed, ") ===")

	# 1. Initialize grid
	_initialize_grid()

	# 2. Place streets (create grid pattern)
	_place_streets()

	# 3. Generate random houses (0-3 houses)
	var house_count = randi_range(MIN_HOUSES, MAX_HOUSES)
	_generate_random_houses(house_count)

	# 4. Scatter optional zone modules (parks, command centers, obstacles)
	_scatter_zones()

	# 5. Generate visual floor tiles
	_generate_floor_visuals()

	# 6. Generate walls with doors
	_generate_all_walls()

	# 7. Create arena boundary
	_create_arena_boundary()

	# 8. Bake spawn points
	_generate_spawn_points()

	print("=== CityLayoutGenerator: Generation complete (", house_count, " houses) ===")
	_print_grid_debug()


# ============================================================================
# GRID INITIALIZATION
# ============================================================================

func _initialize_grid() -> void:
	"""Create empty grid filled with streets"""
	grid = []
	spatial_hash = {}
	spawn_points = []
	occupied_zone_cells = {}

	for y in range(GRID_HEIGHT):
		var row: Array = []
		for x in range(GRID_WIDTH):
			row.append(CellType.STREET)  # Default to street
		grid.append(row)

	print("Grid initialized: ", GRID_WIDTH, "x", GRID_HEIGHT, " (all streets)")


# ============================================================================
# STREET PLACEMENT
# ============================================================================

func _place_streets() -> void:
	"""Place 2-cell wide streets creating crossroads"""
	# Vertical streets (2 cells wide)
	for street_col in [4, 5, 9, 10]:
		for y in range(GRID_HEIGHT):
			grid[y][street_col] = CellType.STREET

	# Horizontal streets (2 cells wide)
	for street_row in [4, 5, 9, 10]:
		for x in range(GRID_WIDTH):
			grid[street_row][x] = CellType.STREET

	print("Streets placed: Grid pattern for 14x14 map")


# ============================================================================
# RANDOM HOUSE GENERATION
# ============================================================================

func _generate_random_houses(count: int) -> void:
	"""Generate random houses with collision detection"""
	var placed_houses: int = 0
	var max_attempts: int = 50
	var attempts: int = 0

	while placed_houses < count and attempts < max_attempts:
		attempts += 1

		# Random house size
		var house_width = randi_range(MIN_HOUSE_SIZE, MAX_HOUSE_SIZE)
		var house_height = randi_range(MIN_HOUSE_SIZE, MAX_HOUSE_SIZE)

		# Random position (ensure it fits in grid)
		var house_x = randi_range(0, GRID_WIDTH - house_width)
		var house_y = randi_range(0, GRID_HEIGHT - house_height)

		# Check collision with streets and other houses using spatial hash
		if _can_place_house(house_x, house_y, house_width, house_height):
			_place_house(house_x, house_y, house_width, house_height)
			placed_houses += 1
			print("House ", placed_houses, " placed at (", house_x, ",", house_y, ") size ", house_width, "x", house_height)
		else:
			if attempts % 10 == 0:
				print("House placement attempt ", attempts, " failed (collision)")

	if placed_houses < count:
		print("Warning: Only placed ", placed_houses, "/", count, " houses (max attempts reached)")


func _can_place_house(x: int, y: int, width: int, height: int) -> bool:
	"""Check if house can be placed without collisions"""
	# Check if house overlaps with main streets (cols 4,5,9,10 or rows 4,5,9,10)
	for check_y in range(y, y + height):
		for check_x in range(x, x + width):
			if check_x >= GRID_WIDTH or check_y >= GRID_HEIGHT:
				return false

			# Check if overlaps with main street grid
			if check_x in [4, 5, 9, 10] or check_y in [4, 5, 9, 10]:
				return false

	# Check spatial hash for collisions with existing houses
	var hash_min_x = int(x / SPATIAL_HASH_CELL_SIZE)
	var hash_max_x = int((x + width - 1) / SPATIAL_HASH_CELL_SIZE)
	var hash_min_y = int(y / SPATIAL_HASH_CELL_SIZE)
	var hash_max_y = int((y + height - 1) / SPATIAL_HASH_CELL_SIZE)

	for hash_y in range(hash_min_y, hash_max_y + 1):
		for hash_x in range(hash_min_x, hash_max_x + 1):
			var hash_key = str(hash_x) + "," + str(hash_y)
			if spatial_hash.has(hash_key):
				# Check if this house overlaps with any existing house
				for existing_house in spatial_hash[hash_key]:
					if _rectangles_overlap(
						x, y, width, height,
						existing_house.x, existing_house.y, existing_house.width, existing_house.height
					):
						return false

	return true


func _rectangles_overlap(x1: int, y1: int, w1: int, h1: int, x2: int, y2: int, w2: int, h2: int) -> bool:
	"""Check if two rectangles overlap"""
	return not (x1 + w1 <= x2 or x2 + w2 <= x1 or y1 + h1 <= y2 or y2 + h2 <= y1)


func _place_house(x: int, y: int, width: int, height: int) -> void:
	"""Place house in grid and add to spatial hash"""
	# Mark cells as building
	for check_y in range(y, y + height):
		for check_x in range(x, x + width):
			if check_x < GRID_WIDTH and check_y < GRID_HEIGHT:
				grid[check_y][check_x] = CellType.BUILDING

	# Add to spatial hash
	var hash_min_x = int(x / SPATIAL_HASH_CELL_SIZE)
	var hash_max_x = int((x + width - 1) / SPATIAL_HASH_CELL_SIZE)
	var hash_min_y = int(y / SPATIAL_HASH_CELL_SIZE)
	var hash_max_y = int((y + height - 1) / SPATIAL_HASH_CELL_SIZE)

	var house_data = {"x": x, "y": y, "width": width, "height": height}

	for hash_y in range(hash_min_y, hash_max_y + 1):
		for hash_x in range(hash_min_x, hash_max_x + 1):
			var hash_key = str(hash_x) + "," + str(hash_y)
			if not spatial_hash.has(hash_key):
				spatial_hash[hash_key] = []
			spatial_hash[hash_key].append(house_data)


# ============================================================================
# ZONE SCATTERING
# ============================================================================

func _scatter_zones() -> void:
	"""Place decorative or gameplay zones on available street cells"""
	if zone_definitions.is_empty():
		return

	var desired_zone_count = randi_range(2, 4)
	var attempts = 0
	var placed = 0
	var max_attempts = 40

	while placed < desired_zone_count and attempts < max_attempts:
		attempts += 1
		var zone_def = zone_definitions[randi() % zone_definitions.size()]
		var size: Vector2i = zone_def["size"]

		var cell_x = randi_range(0, GRID_WIDTH - size.x)
		var cell_y = randi_range(0, GRID_HEIGHT - size.y)

		if _can_place_zone(cell_x, cell_y, size):
			_mark_zone_cells(cell_x, cell_y, size)
			_create_zone_visual(cell_x, cell_y, size, zone_def)
			placed += 1
		elif attempts % 10 == 0:
			print("Zone placement attempt ", attempts, " failed")


func _can_place_zone(cell_x: int, cell_y: int, size: Vector2i) -> bool:
	for y in range(cell_y, cell_y + size.y):
		for x in range(cell_x, cell_x + size.x):
			if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
				return false

			if grid[y][x] != CellType.STREET:
				return false

			var key = str(x) + "," + str(y)
			if occupied_zone_cells.has(key):
				return false
	return true


func _mark_zone_cells(cell_x: int, cell_y: int, size: Vector2i) -> void:
	for y in range(cell_y, cell_y + size.y):
		for x in range(cell_x, cell_x + size.x):
			var key = str(x) + "," + str(y)
			occupied_zone_cells[key] = true


func _create_zone_visual(cell_x: int, cell_y: int, size: Vector2i, zone_def: Dictionary) -> void:
	var zone_root = Node2D.new()
	zone_root.position = Vector2(cell_x * CELL_SIZE, cell_y * CELL_SIZE)
	var zone_id = zone_def.get("id", "zone")
	zone_root.name = "Zone_" + zone_id + "_" + str(cell_x) + "_" + str(cell_y)
	zones_container.add_child(zone_root)

	var rect = ColorRect.new()
	rect.size = Vector2(size.x * CELL_SIZE, size.y * CELL_SIZE)
	rect.position = Vector2.ZERO
	rect.color = zone_def.get("color", Color(0.5, 0.5, 0.5, 0.7))
	rect.z_index = 0
	zone_root.add_child(rect)

	if zone_def.get("type", "") == "obstacle":
		var obstacle = StaticBody2D.new()
		obstacle.collision_layer = 4
		obstacle.collision_mask = 18  # Stop enemies (2) and projectiles (16)

		var shape = CollisionShape2D.new()
		var o_rect = RectangleShape2D.new()
		o_rect.size = rect.size
		shape.shape = o_rect
		shape.position = rect.size / 2
		obstacle.add_child(shape)

		zone_root.add_child(obstacle)
# ============================================================================
# VISUAL FLOOR GENERATION
# ============================================================================

func _generate_floor_visuals() -> void:
	"""Generate floor tiles for visual feedback"""
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell_type = grid[y][x]
			var floor_tile = ColorRect.new()
			floor_tile.size = Vector2(CELL_SIZE, CELL_SIZE)
			floor_tile.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)

			# Color based on cell type
			match cell_type:
				CellType.STREET:
					floor_tile.color = STREET_COLOR
				CellType.BUILDING:
					floor_tile.color = BUILDING_FLOOR_COLOR
				_:
					floor_tile.color = STREET_COLOR

			floor_container.add_child(floor_tile)


func _generate_spawn_points() -> void:
	"""Collect spawn points only on valid interior street cells"""
	spawn_points.clear()

	var margin_cells = 1
	for y in range(margin_cells, GRID_HEIGHT - margin_cells):
		for x in range(margin_cells, GRID_WIDTH - margin_cells):
			if _is_cell_walkable(x, y):
				var world_pos = Vector2((x + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE)
				spawn_points.append(world_pos)

	if spawn_points.is_empty():
		# Fallback: center of map
		spawn_points.append(get_spawn_position())


func _is_cell_walkable(x: int, y: int) -> bool:
	if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
		return false

	if grid[y][x] != CellType.STREET:
		return false

	var key = str(x) + "," + str(y)
	if occupied_zone_cells.has(key):
		return false

	return true


# ============================================================================
# WALL GENERATION
# ============================================================================

func _generate_all_walls() -> void:
	"""Generate walls for all buildings with doors"""
	var processed: Dictionary = {}

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x] == CellType.BUILDING:
				var key = str(x) + "," + str(y)
				if not processed.has(key):
					# Find contiguous building region
					var region = _find_building_region(x, y, processed)
					# Generate walls for this region
					_create_building_walls(region)


func _find_building_region(start_x: int, start_y: int, processed: Dictionary) -> Dictionary:
	"""Find contiguous building cells using flood fill"""
	var min_x = start_x
	var max_x = start_x
	var min_y = start_y
	var max_y = start_y

	var stack = [[start_x, start_y]]

	while stack.size() > 0:
		var pos = stack.pop_back()
		var x = pos[0]
		var y = pos[1]
		var key = str(x) + "," + str(y)

		if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
			continue
		if processed.has(key):
			continue
		if grid[y][x] != CellType.BUILDING:
			continue

		processed[key] = true

		min_x = min(min_x, x)
		max_x = max(max_x, x)
		min_y = min(min_y, y)
		max_y = max(max_y, y)

		stack.append([x + 1, y])
		stack.append([x - 1, y])
		stack.append([x, y + 1])
		stack.append([x, y - 1])

	return {
		"x": min_x,
		"y": min_y,
		"width": max_x - min_x + 1,
		"height": max_y - min_y + 1
	}


func _create_building_walls(region: Dictionary) -> void:
	"""Create walls around building region with doors on street-facing sides"""
	var grid_x = region.x
	var grid_y = region.y
	var width = region.width
	var height = region.height

	var pos_x = grid_x * CELL_SIZE
	var pos_y = grid_y * CELL_SIZE
	var pixel_width = width * CELL_SIZE
	var pixel_height = height * CELL_SIZE

	print("Creating walls for building at (", grid_x, ",", grid_y, ") size ", width, "x", height)

	# Find which sides face streets
	var street_sides = _get_adjacent_street_sides(region)

	# Top wall
	if "top" in street_sides:
		var door_start = (pixel_width - DOOR_WIDTH) / 2
		_create_wall_segment(pos_x, pos_y, door_start, WALL_THICKNESS)
		_create_wall_segment(pos_x + door_start + DOOR_WIDTH, pos_y, pixel_width - door_start - DOOR_WIDTH, WALL_THICKNESS)
		_create_door_area(pos_x + door_start, pos_y, DOOR_WIDTH, WALL_THICKNESS)
	else:
		_create_wall_segment(pos_x, pos_y, pixel_width, WALL_THICKNESS)

	# Bottom wall
	if "bottom" in street_sides:
		var door_start = (pixel_width - DOOR_WIDTH) / 2
		_create_wall_segment(pos_x, pos_y + pixel_height - WALL_THICKNESS, door_start, WALL_THICKNESS)
		_create_wall_segment(pos_x + door_start + DOOR_WIDTH, pos_y + pixel_height - WALL_THICKNESS, pixel_width - door_start - DOOR_WIDTH, WALL_THICKNESS)
		_create_door_area(pos_x + door_start, pos_y + pixel_height - WALL_THICKNESS, DOOR_WIDTH, WALL_THICKNESS)
	else:
		_create_wall_segment(pos_x, pos_y + pixel_height - WALL_THICKNESS, pixel_width, WALL_THICKNESS)

	# Left wall
	if "left" in street_sides:
		var door_start = (pixel_height - DOOR_WIDTH) / 2
		_create_wall_segment(pos_x, pos_y, WALL_THICKNESS, door_start)
		_create_wall_segment(pos_x, pos_y + door_start + DOOR_WIDTH, WALL_THICKNESS, pixel_height - door_start - DOOR_WIDTH)
		_create_door_area(pos_x, pos_y + door_start, WALL_THICKNESS, DOOR_WIDTH)
	else:
		_create_wall_segment(pos_x, pos_y, WALL_THICKNESS, pixel_height)

	# Right wall
	if "right" in street_sides:
		var door_start = (pixel_height - DOOR_WIDTH) / 2
		_create_wall_segment(pos_x + pixel_width - WALL_THICKNESS, pos_y, WALL_THICKNESS, door_start)
		_create_wall_segment(pos_x + pixel_width - WALL_THICKNESS, pos_y + door_start + DOOR_WIDTH, WALL_THICKNESS, pixel_height - door_start - DOOR_WIDTH)
		_create_door_area(pos_x + pixel_width - WALL_THICKNESS, pos_y + door_start, WALL_THICKNESS, DOOR_WIDTH)
	else:
		_create_wall_segment(pos_x + pixel_width - WALL_THICKNESS, pos_y, WALL_THICKNESS, pixel_height)


func _get_adjacent_street_sides(region: Dictionary) -> Array:
	"""Check which sides of building face streets"""
	var sides = []
	var grid_x = region.x
	var grid_y = region.y
	var width = region.width
	var height = region.height

	# Check top
	if grid_y > 0:
		var is_street = true
		for x in range(grid_x, grid_x + width):
			if x >= 0 and x < GRID_WIDTH and grid[grid_y - 1][x] != CellType.STREET:
				is_street = false
				break
		if is_street:
			sides.append("top")

	# Check bottom
	if grid_y + height < GRID_HEIGHT:
		var is_street = true
		for x in range(grid_x, grid_x + width):
			if x >= 0 and x < GRID_WIDTH and grid[grid_y + height][x] != CellType.STREET:
				is_street = false
				break
		if is_street:
			sides.append("bottom")

	# Check left
	if grid_x > 0:
		var is_street = true
		for y in range(grid_y, grid_y + height):
			if y >= 0 and y < GRID_HEIGHT and grid[y][grid_x - 1] != CellType.STREET:
				is_street = false
				break
		if is_street:
			sides.append("left")

	# Check right
	if grid_x + width < GRID_WIDTH:
		var is_street = true
		for y in range(grid_y, grid_y + height):
			if y >= 0 and y < GRID_HEIGHT and grid[y][grid_x + width] != CellType.STREET:
				is_street = false
				break
		if is_street:
			sides.append("right")

	return sides


func _create_wall_segment(x: float, y: float, width: float, height: float) -> void:
	"""Create a single wall segment with collision"""
	var wall = StaticBody2D.new()
	wall.name = "Wall_" + str(x) + "_" + str(y)

	wall.collision_layer = 4
	wall.collision_mask = 18  # Enemies (2) + Projectiles (16)

	var visual = ColorRect.new()
	visual.size = Vector2(width, height)
	visual.position = Vector2.ZERO
	visual.color = WALL_COLOR
	visual.z_index = 1
	wall.add_child(visual)

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape.shape = rect
	shape.position = Vector2(width / 2, height / 2)
	wall.add_child(shape)

	wall.position = Vector2(x, y)
	walls_container.add_child(wall)


func _create_door_area(x: float, y: float, width: float, height: float) -> void:
	"""Create door area (Area2D) for player/enemy entry detection"""
	var door = Area2D.new()
	door.name = "DoorArea_" + str(x) + "_" + str(y)

	door.collision_layer = 0
	door.collision_mask = 12  # Detect projectiles (8) + walls (4) for entry monitoring

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape.shape = rect
	shape.position = Vector2(width / 2, height / 2)
	door.add_child(shape)

	# Visual indicator (semi-transparent green)
	var visual = ColorRect.new()
	visual.size = Vector2(width, height)
	visual.position = Vector2.ZERO
	visual.color = Color(0.2, 1.0, 0.3, 0.3)
	visual.z_index = 0
	door.add_child(visual)

	door.position = Vector2(x, y)
	walls_container.add_child(door)


func _create_arena_boundary() -> void:
	"""Create solid walls around entire arena perimeter"""
	var arena_width = GRID_WIDTH * CELL_SIZE
	var arena_height = GRID_HEIGHT * CELL_SIZE
	var boundary_thickness = 32

	print("Creating arena boundary walls...")

	if city_boundary and is_instance_valid(city_boundary):
		city_boundary.queue_free()

	city_boundary = StaticBody2D.new()
	city_boundary.name = "CityBoundary"
	city_boundary.collision_layer = 4
	city_boundary.collision_mask = 18  # Stops enemies (2) and projectiles (16)

	walls_container.add_child(city_boundary)

	var segments = [
		{"pos": Vector2(0, -boundary_thickness), "size": Vector2(arena_width, boundary_thickness)},
		{"pos": Vector2(0, arena_height), "size": Vector2(arena_width, boundary_thickness)},
		{"pos": Vector2(-boundary_thickness, 0), "size": Vector2(boundary_thickness, arena_height)},
		{"pos": Vector2(arena_width, 0), "size": Vector2(boundary_thickness, arena_height)}
	]

	for segment in segments:
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = segment["size"]
		shape.shape = rect
		shape.position = segment["pos"] + segment["size"] / 2
		city_boundary.add_child(shape)

		var visual = ColorRect.new()
		visual.size = segment["size"]
		visual.position = segment["pos"]
		visual.color = WALL_COLOR
		visual.z_index = 1
		walls_container.add_child(visual)

	print("Arena boundary created - ", arena_width, "x", arena_height, "px enclosed")


# ============================================================================
# DEBUG UTILITIES
# ============================================================================

func _print_grid_debug() -> void:
	"""Print grid for debugging"""
	print("=== Grid Layout ===")
	var legend = {
		CellType.STREET: "S",
		CellType.BUILDING: "B"
	}

	for y in range(GRID_HEIGHT):
		var row_str = ""
		for x in range(GRID_WIDTH):
			row_str += legend[grid[y][x]] + " "
		print(row_str)
	print("==================")


func get_spawn_position() -> Vector2:
	"""Get center spawn position for player"""
	if spawn_points.is_empty():
		var center_x = (GRID_WIDTH * CELL_SIZE) / 2
		var center_y = (GRID_HEIGHT * CELL_SIZE) / 2
		return Vector2(center_x, center_y)

	return spawn_points[0]


func get_spawn_points() -> Array[Vector2]:
	"""Return all walkable spawn points (streets only)"""
	return spawn_points.duplicate()


func get_arena_bounds() -> Rect2:
	"""Get arena boundaries"""
	return Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)


func clear_map() -> void:
	"""Clear all map elements for regeneration"""
	print("=== CityLayoutGenerator: Clearing map ===")

	if floor_container:
		for child in floor_container.get_children():
			child.queue_free()

	if walls_container:
		for child in walls_container.get_children():
			child.queue_free()

	if zones_container:
		for child in zones_container.get_children():
			child.queue_free()

	if city_boundary and is_instance_valid(city_boundary):
		city_boundary.queue_free()
		city_boundary = null

	grid.clear()
	spatial_hash.clear()
	spawn_points.clear()
	occupied_zone_cells.clear()

	print("Map cleared successfully")


func get_generation_seed() -> int:
	"""Return the seed used for generation"""
	return generation_seed
