extends Node2D

## MapGenerator - Procedural Arena Generation
## Generates 18x18 grid with 2-cell streets and 3x3+ buildings with solid walls

# ============================================================================
# GRID CONFIGURATION
# ============================================================================

const GRID_WIDTH: int = 14
const GRID_HEIGHT: int = 14
const CELL_SIZE: int = 128  # pixels per grid cell
const MIN_STREET_WIDTH: int = 5  # Minimum width for primary avenues

const STREET_TILES: Array[Texture2D] = [
	# Gemini-generierte Tiles (Hauptboden)
	preload("res://assets/tiles/floor/gemini/misc_image.png"),
	preload("res://assets/tiles/floor/gemini/misc_image_01.png"),
	preload("res://assets/tiles/floor/gemini/misc_image_02.png"),
	preload("res://assets/tiles/floor/gemini/misc_image_03.png"),
	preload("res://assets/tiles/floor/gemini/misc_image1.png"),
	preload("res://assets/tiles/floor/gemini/misc_image1_01.png"),
	preload("res://assets/tiles/floor/gemini/misc_image1_02.png")
]
const AVENUE_TILES: Array[Texture2D] = [
	# High-Tech Tiles für Hauptstraßen
	preload("res://assets/tiles/floor/gemini/control_center_clean_brushed_metal_with_led_strip_accents_bluecya_02.png"),
	preload("res://assets/tiles/floor/gemini/misc_image2.png"),
	preload("res://assets/tiles/floor/gemini/misc_image2_01.png"),
	preload("res://assets/tiles/floor/gemini/misc_image2_02.png")
]
const BUILDING_TILES: Array[Texture2D] = [
	preload("res://assets/tiles/floor/gemini/misc_image3.png"),
	preload("res://assets/tiles/floor/gemini/misc_image3_01.png"),
	preload("res://assets/tiles/floor/gemini/misc_image3_02.png"),
	preload("res://assets/tiles/floor/gemini/misc_image3_03.png")
]
const DIAGONAL_TILES: Array[Texture2D] = [
	preload("res://assets/tiles/floor/gemini/misc_image1_03.png"),
	preload("res://assets/tiles/floor/gemini/misc_image2_03.png"),
	preload("res://assets/tiles/floor/gemini/misc_image3_02.png")
]
const ALLEY_TILES: Array[Texture2D] = [
	preload("res://assets/tiles/floor/gemini/misc_image_02.png"),
	preload("res://assets/tiles/floor/gemini/misc_image_03.png")
]
const DEFAULT_TILE: Texture2D = preload("res://assets/tiles/floor/gemini/misc_image.png")
const WARNING_TILE_HORIZONTAL: Texture2D = preload("res://assets/tiles/floor/tile_wall_warning_h_64.png")
const WARNING_TILE_VERTICAL: Texture2D = preload("res://assets/tiles/floor/tile_wall_warning_v_64.png")

# Grid cell types
enum CellType {
	EMPTY,
	STREET,
	BUILDING,
	AVENUE,
	DIAGONAL,
	ALLEY
}

# Grid data structure
var grid: Array[Array] = []
var spawn_points: Array[Vector2] = []
var tile_texture_map: Dictionary = {}  # Vector2i -> Texture2D (tracks which texture is at each grid position)

# Wall configuration
const WALL_THICKNESS: int = 24
const WALL_COLOR: Color = Color(0.3, 0.3, 0.35)  # Dark gray
const BUILDING_FLOOR_COLOR: Color = Color(0.15, 0.15, 0.18)  # Darker floor
const BASE_STREET_COLOR: Color = Color(0.22, 0.22, 0.24)  # Base pavement tone
const AVENUE_COLOR: Color = Color(0.4, 0.4, 0.46)  # Primary avenues
const DIAGONAL_COLOR: Color = Color(0.32, 0.28, 0.45)
const ALLEY_COLOR: Color = Color(0.28, 0.24, 0.2)

# Container nodes
var walls_container: Node2D = null
var floor_container: Node2D = null


# ============================================================================
# MAIN GENERATION
# ============================================================================

func _ready() -> void:
	"""Initialize generator (call generate_map() from game.gd)"""
	walls_container = Node2D.new()
	walls_container.name = "Walls"
	add_child(walls_container)

	floor_container = Node2D.new()
	floor_container.name = "Floor"
	floor_container.z_index = -5
	add_child(floor_container)


func generate_map() -> void:
	"""Generate complete procedural map"""
	print("=== MapGenerator: Starting generation ===")
	randomize()

	# 1. Initialize grid
	_initialize_grid()

	# 2. Generate dynamic avenue network (fully walkable)
	_place_streets()

	# 3. Generate visual floor tiles (fully walkable)
	_generate_floor_visuals()

	# 4. Create arena perimeter boundary
	_create_arena_boundary()

	# 5. Collect spawn points
	_collect_spawn_points()

	# 6. Spawn shop terminals
	_spawn_shop_terminals()

	print("=== MapGenerator: Generation complete ===")
	_print_grid_debug()


# ============================================================================
# GRID INITIALIZATION
# ============================================================================

func _initialize_grid() -> void:
	"""Create empty 7x7 grid"""
	grid = []
	spawn_points = []
	for y in range(GRID_HEIGHT):
		var row: Array = []
		for x in range(GRID_WIDTH):
			row.append(CellType.EMPTY)
		grid.append(row)

	print("Grid initialized: ", GRID_WIDTH, "x", GRID_HEIGHT)


# ============================================================================
# STREET PLACEMENT
# ============================================================================

func _place_streets() -> void:
	"""Generate a dynamic avenue network while keeping the arena fully walkable"""
	# Start fully walkable
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			grid[y][x] = CellType.STREET

	var vertical_avenues: Array[int] = _generate_avenue_centers(GRID_WIDTH)
	for center_x in vertical_avenues:
		_mark_vertical_avenue(center_x, _random_avenue_width())

	var horizontal_avenues: Array[int] = _generate_avenue_centers(GRID_HEIGHT)
	for center_y in horizontal_avenues:
		_mark_horizontal_avenue(center_y, _random_avenue_width())

	var diagonal_specs: Array[Dictionary] = _generate_diagonal_specs()
	for spec in diagonal_specs:
		_mark_diagonal(spec)

	_generate_side_alleys()

	print("Avenues generated - vertical: ", vertical_avenues, " horizontal: ", horizontal_avenues, " diagonals: ", diagonal_specs.size())


func _random_avenue_width() -> int:
	return MIN_STREET_WIDTH + randi_range(0, 2)  # 5-7 cells wide


func _generate_avenue_centers(grid_size: int) -> Array[int]:
	"""Pick random avenue centers ensuring spacing"""
	var min_avenues: int = 2
	var max_avenues: int = 4
	var avenue_count: int = randi_range(min_avenues, max_avenues)
	var padding: int = MIN_STREET_WIDTH

	var candidates: Array[int] = []
	for i in range(padding, grid_size - padding):
		candidates.append(i)

	var centers: Array[int] = []
	while avenue_count > 0 and candidates.size() > 0:
		var index: int = randi() % candidates.size()
		var center: int = candidates[index]
		centers.append(center)
		avenue_count -= 1

		# Remove neighbouring indices to enforce spacing
		var remove_start: int = max(0, center - MIN_STREET_WIDTH)
		var remove_end: int = min(grid_size - 1, center + MIN_STREET_WIDTH)
		var filtered: Array[int] = []
		for value in candidates:
			if value < remove_start or value > remove_end:
				filtered.append(value)
		candidates = filtered

	# Ensure we always have at least one center in case spacing removed all
	if centers.is_empty():
		centers.append(int(grid_size * 0.5))

	return centers


func _mark_vertical_avenue(center_x: int, width: int) -> void:
	var half_width: int = int(width * 0.5)
	var start_x: int = max(0, center_x - half_width)
	var end_x: int = min(GRID_WIDTH - 1, center_x + half_width)
	for x in range(start_x, end_x + 1):
		for y in range(GRID_HEIGHT):
			grid[y][x] = CellType.AVENUE


func _mark_horizontal_avenue(center_y: int, width: int) -> void:
	var half_width: int = int(width * 0.5)
	var start_y: int = max(0, center_y - half_width)
	var end_y: int = min(GRID_HEIGHT - 1, center_y + half_width)
	for y in range(start_y, end_y + 1):
		for x in range(GRID_WIDTH):
			grid[y][x] = CellType.AVENUE


func _generate_diagonal_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var half_grid: int = int(GRID_WIDTH * 0.5)
	var diag_count: int = randi_range(1, 2)
	for i in range(diag_count):
		var direction: int = 1
		if randf() < 0.5:
			direction = -1
		var width: int = clamp(_random_avenue_width() - 2, 3, MIN_STREET_WIDTH + 2)
		var offset: int = 0
		if direction == 1:
			offset = randi_range(-half_grid, half_grid)
		else:
			offset = randi_range(half_grid, GRID_WIDTH + GRID_HEIGHT - half_grid)
		specs.append({
			"direction": direction,
			"offset": offset,
			"width": width
		})
	return specs


func _mark_diagonal(spec: Dictionary) -> void:
	var direction: int = spec.get("direction", 1)
	var offset: float = spec.get("offset", 0.0)
	var width: int = spec.get("width", MIN_STREET_WIDTH)
	var half_width: float = float(width) / 2.0

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if direction == 1:
				var value: float = float(y - x)
				if abs(value - offset) <= half_width and grid[y][x] != CellType.AVENUE:
					grid[y][x] = CellType.DIAGONAL
			else:
				var value: float = float(x + y)
				if abs(value - offset) <= half_width and grid[y][x] != CellType.AVENUE:
					grid[y][x] = CellType.DIAGONAL


func _generate_side_alleys() -> void:
	var alley_count: int = randi_range(3, 6)
	var attempts: int = alley_count * 6
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while alley_count > 0 and attempts > 0:
		attempts -= 1
		var start: Vector2i = Vector2i(randi_range(0, GRID_WIDTH - 1), randi_range(0, GRID_HEIGHT - 1))
		if grid[start.y][start.x] != CellType.AVENUE:
			continue

		var dir: Vector2i = directions[randi() % directions.size()]
		var length: int = randi_range(3, 6)
		var alley_width: int = randi_range(1, 2)
		var success: bool = false

		for step in range(1, length + 1):
			var pos: Vector2i = start + dir * step
			if pos.x < 0 or pos.x >= GRID_WIDTH or pos.y < 0 or pos.y >= GRID_HEIGHT:
				break
			if grid[pos.y][pos.x] == CellType.AVENUE:
				break
			if grid[pos.y][pos.x] == CellType.DIAGONAL:
				continue
			if grid[pos.y][pos.x] == CellType.ALLEY:
				success = true
				continue

			grid[pos.y][pos.x] = CellType.ALLEY
			var perp: Vector2i = Vector2i(-dir.y, dir.x)
			for offset in range(1, alley_width + 1):
				for direction_sign in [-1, 1]:
					var side: Vector2i = pos + perp * offset * direction_sign
					if side.x < 0 or side.x >= GRID_WIDTH or side.y < 0 or side.y >= GRID_HEIGHT:
						continue
					if grid[side.y][side.x] == CellType.AVENUE or grid[side.y][side.x] == CellType.DIAGONAL:
						continue
					grid[side.y][side.x] = CellType.ALLEY
			success = true

		if success:
			alley_count -= 1


# ============================================================================
# BUILDING ZONE IDENTIFICATION
# ============================================================================

func _identify_building_zones() -> Array[Dictionary]:
	"""Identify 3x3+ zones for buildings in 14x14 grid"""
	var zones: Array[Dictionary] = []

	# Create 9 building zones (3x3 grid pattern)
	# Zone row 1 (y: 0-3)
	zones.append({"x": 0, "y": 0, "width": 4, "height": 4})    # Top-left
	zones.append({"x": 6, "y": 0, "width": 3, "height": 4})    # Top-center
	zones.append({"x": 11, "y": 0, "width": 3, "height": 4})   # Top-right

	# Zone row 2 (y: 6-8)
	zones.append({"x": 0, "y": 6, "width": 4, "height": 3})    # Mid-left
	zones.append({"x": 6, "y": 6, "width": 3, "height": 3})    # Center
	zones.append({"x": 11, "y": 6, "width": 3, "height": 3})   # Mid-right

	# Zone row 3 (y: 11-13)
	zones.append({"x": 0, "y": 11, "width": 4, "height": 3})   # Bottom-left
	zones.append({"x": 6, "y": 11, "width": 3, "height": 3})   # Bottom-center
	zones.append({"x": 11, "y": 11, "width": 3, "height": 3})  # Bottom-right

	print("Building zones identified: ", zones.size())
	return zones


# ============================================================================
# BUILDING PLACEMENT
# ============================================================================

func _place_building(zone: Dictionary) -> void:
	"""Mark building cells in grid"""
	var start_x: int = zone.x
	var start_y: int = zone.y
	var width: int = zone.width
	var height: int = zone.height

	for y in range(start_y, start_y + height):
		for x in range(start_x, start_x + width):
			if y < GRID_HEIGHT and x < GRID_WIDTH:
				grid[y][x] = CellType.BUILDING

	print("Building placed at (", start_x, ",", start_y, ") size ", width, "x", height)


# ============================================================================
# VISUAL FLOOR GENERATION
# ============================================================================

func _generate_floor_visuals() -> void:
	"""Generate floor visuals using tile textures"""
	if not floor_container:
		return

	tile_texture_map.clear()  # Reset texture map

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var tile_texture: Texture2D = _get_tile_texture_for(grid[y][x], x, y)

			# Track which texture is used at this position
			if tile_texture:
				tile_texture_map[Vector2i(x, y)] = tile_texture

			if tile_texture:
				var tile_sprite: Sprite2D = Sprite2D.new()
				tile_sprite.texture = tile_texture
				tile_sprite.centered = false
				var texture_size: Vector2 = tile_texture.get_size()
				if texture_size.x == 0 or texture_size.y == 0:
					continue
				var tile_scale: Vector2 = Vector2(CELL_SIZE / texture_size.x, CELL_SIZE / texture_size.y)
				tile_sprite.scale = tile_scale
				tile_sprite.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
				tile_sprite.z_index = -10
				_apply_tile_variation(tile_sprite, x, y)
				floor_container.add_child(tile_sprite)
			else:
				var fallback: ColorRect = ColorRect.new()
				fallback.size = Vector2(CELL_SIZE, CELL_SIZE)
				fallback.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
				fallback.color = BASE_STREET_COLOR
				floor_container.add_child(fallback)

			_add_boundary_overlays(x, y, grid[y][x])


func _get_tile_texture_for(cell_type: CellType, grid_x: int, grid_y: int) -> Texture2D:
	var tiles: Array[Texture2D] = STREET_TILES
	match cell_type:
		CellType.AVENUE:
			tiles = AVENUE_TILES
		CellType.DIAGONAL:
			tiles = DIAGONAL_TILES
		CellType.ALLEY:
			tiles = ALLEY_TILES
		CellType.BUILDING:
			tiles = BUILDING_TILES
		CellType.STREET:
			tiles = STREET_TILES
		_:
			tiles = STREET_TILES

	return _select_texture_variant(tiles, grid_x, grid_y)


func _select_texture_variant(tile_list: Array[Texture2D], grid_x: int, grid_y: int) -> Texture2D:
	if tile_list.is_empty():
		return DEFAULT_TILE

	var tile_seed: int = abs(_grid_hash(grid_x, grid_y))
	var index: int = tile_seed % tile_list.size()
	var texture: Texture2D = tile_list[index]
	if texture == null:
		return DEFAULT_TILE
	return texture


func _apply_tile_variation(sprite: Sprite2D, grid_x: int, grid_y: int) -> void:
	var tile_seed: int = abs(_grid_hash(grid_x, grid_y))
	sprite.flip_h = (tile_seed & 1) == 1
	sprite.flip_v = ((tile_seed >> 1) & 1) == 1


func _add_boundary_overlays(grid_x: int, grid_y: int, cell_type: CellType) -> void:
	if not floor_container:
		return
	if cell_type == CellType.BUILDING:
		return

	if grid_y == 0 and WARNING_TILE_HORIZONTAL:
		_add_boundary_tile(WARNING_TILE_HORIZONTAL, grid_x, grid_y, false, false)
	if grid_y == GRID_HEIGHT - 1 and WARNING_TILE_HORIZONTAL:
		_add_boundary_tile(WARNING_TILE_HORIZONTAL, grid_x, grid_y, false, true)
	if grid_x == 0 and WARNING_TILE_VERTICAL:
		_add_boundary_tile(WARNING_TILE_VERTICAL, grid_x, grid_y, false, false)
	if grid_x == GRID_WIDTH - 1 and WARNING_TILE_VERTICAL:
		_add_boundary_tile(WARNING_TILE_VERTICAL, grid_x, grid_y, true, false)


func _add_boundary_tile(texture: Texture2D, grid_x: int, grid_y: int, flip_h: bool, flip_v: bool) -> void:
	if texture == null:
		return

	var boundary_sprite: Sprite2D = Sprite2D.new()
	boundary_sprite.texture = texture
	boundary_sprite.centered = false
	var boundary_texture_size: Vector2 = texture.get_size()
	if boundary_texture_size.x == 0 or boundary_texture_size.y == 0:
		return

	var boundary_scale: Vector2 = Vector2(CELL_SIZE / boundary_texture_size.x, CELL_SIZE / boundary_texture_size.y)
	boundary_sprite.scale = boundary_scale
	boundary_sprite.position = Vector2(grid_x * CELL_SIZE, grid_y * CELL_SIZE)
	boundary_sprite.z_index = -9
	boundary_sprite.flip_h = flip_h
	boundary_sprite.flip_v = flip_v
	floor_container.add_child(boundary_sprite)


func _grid_hash(x: int, y: int) -> int:
	return ((x * 73856093) ^ (y * 19349663)) & 0x7fffffff

# ============================================================================
# WALL GENERATION
# ============================================================================

func _generate_all_walls() -> void:
	"""Generate walls for all buildings"""
	# Find all building blocks and create perimeter walls
	var processed: Dictionary = {}  # Track processed cells

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x] == CellType.BUILDING:
				var key: String = str(x) + "," + str(y)
				if not processed.has(key):
					# Find contiguous building region
					var region: Dictionary = _find_building_region(x, y, processed)
					# Generate walls for this region
					_create_building_walls(region)


func _find_building_region(start_x: int, start_y: int, processed: Dictionary) -> Dictionary:
	"""Find contiguous building cells using flood fill"""
	var min_x: int = start_x
	var max_x: int = start_x
	var min_y: int = start_y
	var max_y: int = start_y

	var stack: Array = [[start_x, start_y]]

	while stack.size() > 0:
		var pos: Array = stack.pop_back()
		var x: int = pos[0]
		var y: int = pos[1]
		var key: String = str(x) + "," + str(y)

		# Skip if out of bounds or already processed
		if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
			continue
		if processed.has(key):
			continue
		if grid[y][x] != CellType.BUILDING:
			continue

		# Mark as processed
		processed[key] = true

		# Update bounds
		min_x = min(min_x, x)
		max_x = max(max_x, x)
		min_y = min(min_y, y)
		max_y = max(max_y, y)

		# Add neighbors to stack
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
	"""Create walls around a building region with door openings to streets"""
	var grid_x: int = region.x
	var grid_y: int = region.y
	var width: int = region.width
	var height: int = region.height

	# Convert to pixel coordinates
	var pos_x: float = float(grid_x * CELL_SIZE)
	var pos_y: float = float(grid_y * CELL_SIZE)
	var pixel_width: float = float(width * CELL_SIZE)
	var pixel_height: float = float(height * CELL_SIZE)

	print("Creating walls for building at (", grid_x, ",", grid_y, ") size ", width, "x", height)

	# Find which sides have adjacent streets
	var street_sides: Array = _get_adjacent_street_sides(region)

	const DOOR_WIDTH = CELL_SIZE  # 128px door opening

	# Top wall
	if "top" in street_sides:
		# Create wall with door opening in center
		var door_start: float = (pixel_width - DOOR_WIDTH) / 2.0
		_create_wall_segment(pos_x, pos_y, door_start, WALL_THICKNESS)  # Left of door
		_create_wall_segment(pos_x + door_start + DOOR_WIDTH, pos_y, pixel_width - door_start - DOOR_WIDTH, WALL_THICKNESS)  # Right of door
	else:
		_create_wall_segment(pos_x, pos_y, pixel_width, WALL_THICKNESS)  # Solid wall

	# Bottom wall
	if "bottom" in street_sides:
		var door_start: float = (pixel_width - DOOR_WIDTH) / 2.0
		_create_wall_segment(pos_x, pos_y + pixel_height - WALL_THICKNESS, door_start, WALL_THICKNESS)
		_create_wall_segment(pos_x + door_start + DOOR_WIDTH, pos_y + pixel_height - WALL_THICKNESS, pixel_width - door_start - DOOR_WIDTH, WALL_THICKNESS)
	else:
		_create_wall_segment(pos_x, pos_y + pixel_height - WALL_THICKNESS, pixel_width, WALL_THICKNESS)

	# Left wall
	if "left" in street_sides:
		var door_start: float = (pixel_height - DOOR_WIDTH) / 2.0
		_create_wall_segment(pos_x, pos_y, WALL_THICKNESS, door_start)
		_create_wall_segment(pos_x, pos_y + door_start + DOOR_WIDTH, WALL_THICKNESS, pixel_height - door_start - DOOR_WIDTH)
	else:
		_create_wall_segment(pos_x, pos_y, WALL_THICKNESS, pixel_height)

	# Right wall
	if "right" in street_sides:
		var door_start: float = (pixel_height - DOOR_WIDTH) / 2.0
		_create_wall_segment(pos_x + pixel_width - WALL_THICKNESS, pos_y, WALL_THICKNESS, door_start)
		_create_wall_segment(pos_x + pixel_width - WALL_THICKNESS, pos_y + door_start + DOOR_WIDTH, WALL_THICKNESS, pixel_height - door_start - DOOR_WIDTH)
	else:
		_create_wall_segment(pos_x + pixel_width - WALL_THICKNESS, pos_y, WALL_THICKNESS, pixel_height)


func _get_adjacent_street_sides(region: Dictionary) -> Array[String]:
	"""Check which sides of a building have adjacent streets"""
	var sides: Array[String] = []
	var grid_x: int = region.x
	var grid_y: int = region.y
	var width: int = region.width
	var height: int = region.height

	# Check top side (y - 1)
	if grid_y > 0:
		var is_street: bool = true
		for x in range(grid_x, grid_x + width):
			if x >= 0 and x < GRID_WIDTH and grid[grid_y - 1][x] != CellType.STREET:
				is_street = false
				break
		if is_street:
			sides.append("top")

	# Check bottom side (y + height)
	if grid_y + height < GRID_HEIGHT:
		var is_street: bool = true
		for x in range(grid_x, grid_x + width):
			if x >= 0 and x < GRID_WIDTH and grid[grid_y + height][x] != CellType.STREET:
				is_street = false
				break
		if is_street:
			sides.append("bottom")

	# Check left side (x - 1)
	if grid_x > 0:
		var is_street: bool = true
		for y in range(grid_y, grid_y + height):
			if y >= 0 and y < GRID_HEIGHT and grid[y][grid_x - 1] != CellType.STREET:
				is_street = false
				break
		if is_street:
			sides.append("left")

	# Check right side (x + width)
	if grid_x + width < GRID_WIDTH:
		var is_street: bool = true
		for y in range(grid_y, grid_y + height):
			if y >= 0 and y < GRID_HEIGHT and grid[y][grid_x + width] != CellType.STREET:
				is_street = false
				break
		if is_street:
			sides.append("right")

	return sides


func _create_wall_segment(x: float, y: float, width: float, height: float) -> void:
	"""Create a single wall segment with collision"""
	var wall: StaticBody2D = StaticBody2D.new()
	wall.name = "Wall_" + str(x) + "_" + str(y)

	# Collision layer setup
	wall.collision_layer = 4  # Walls layer (bit 3)
	wall.collision_mask = 18  # Interact with Enemies (2) + Projectiles (16)

	# Visual representation
	var visual: ColorRect = ColorRect.new()
	visual.size = Vector2(width, height)
	visual.position = Vector2.ZERO
	visual.color = WALL_COLOR
	visual.z_index = 1
	wall.add_child(visual)

	# Collision shape
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape.shape = rect
	shape.position = Vector2(width / 2, height / 2)
	wall.add_child(shape)

	# Position the wall
	wall.position = Vector2(x, y)

	walls_container.add_child(wall)


func _create_arena_boundary() -> void:
	"""Create solid walls around entire arena perimeter"""
	var arena_width: float = float(GRID_WIDTH * CELL_SIZE)  # 1792px (14*128)
	var arena_height: float = float(GRID_HEIGHT * CELL_SIZE)  # 1792px (14*128)
	var boundary_thickness: float = 32.0  # Thicker than building walls

	print("Creating arena boundary walls...")

	# Top boundary wall
	_create_wall_segment(0, -boundary_thickness, arena_width, boundary_thickness)

	# Bottom boundary wall
	_create_wall_segment(0, arena_height, arena_width, boundary_thickness)

	# Left boundary wall
	_create_wall_segment(-boundary_thickness, 0, boundary_thickness, arena_height)

	# Right boundary wall
	_create_wall_segment(arena_width, 0, boundary_thickness, arena_height)

	print("Arena boundary created - ", arena_width, "x", arena_height, "px enclosed")


# ============================================================================
# DEBUG UTILITIES
# ============================================================================

func _print_grid_debug() -> void:
	"""Print grid for debugging"""
	print("=== Grid Layout ===")
	var legend: Dictionary = {
		CellType.EMPTY: ".",
		CellType.STREET: "S",
		CellType.BUILDING: "B",
		CellType.AVENUE: "A",
		CellType.DIAGONAL: "D",
		CellType.ALLEY: "L"
	}

	for y in range(GRID_HEIGHT):
		var row_str: String = ""
		for x in range(GRID_WIDTH):
			row_str += legend[grid[y][x]] + " "
		print(row_str)
	print("==================")


func get_spawn_position() -> Vector2:
	"""Get center spawn position for player"""
	# Center of grid in pixels
	var center: Vector2 = Vector2((GRID_WIDTH * CELL_SIZE) * 0.5, (GRID_HEIGHT * CELL_SIZE) * 0.5)
	return center


func get_arena_bounds() -> Rect2:
	"""Get arena boundaries"""
	return Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)


func clear_map() -> void:
	"""Clear all map elements for regeneration"""
	print("=== MapGenerator: Clearing map ===")

	# Clear all floor tiles
	if floor_container:
		for child in floor_container.get_children():
			child.queue_free()

	# Clear all walls
	if walls_container:
		for child in walls_container.get_children():
			child.queue_free()

	# Clear grid data
	grid.clear()
	spawn_points.clear()

	print("Map cleared successfully")


func get_spawn_points() -> Array[Vector2]:
	return (spawn_points.duplicate()) as Array[Vector2]


func _collect_spawn_points() -> void:
	spawn_points.clear()
	var avenue_points: Array[Vector2] = []
	var diagonal_points: Array[Vector2] = []
	var fallback_points: Array[Vector2] = []

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var world_pos: Vector2 = Vector2((x + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE)
			match grid[y][x]:
				CellType.AVENUE:
					if ((x + y) % 2) == 0:
						avenue_points.append(world_pos)
				CellType.DIAGONAL:
					if ((x + y) % 3) == 0:
						diagonal_points.append(world_pos)
				CellType.ALLEY:
					if ((x + y) % 4) == 1:
						fallback_points.append(world_pos)
				CellType.STREET:
					if ((x + y) % 4) == 0:
						fallback_points.append(world_pos)

	if avenue_points.is_empty():
		avenue_points = diagonal_points

	if avenue_points.is_empty():
		avenue_points = fallback_points

	if avenue_points.is_empty():
		avenue_points.append(get_spawn_position())

	spawn_points = avenue_points


func get_control_center_positions() -> Array[Vector2]:
	"""Get all world positions where control_center tiles are located"""
	var control_center_tile: Texture2D = preload("res://assets/tiles/floor/tile_control_center_64.png")
	var positions: Array[Vector2] = []

	for grid_pos in tile_texture_map.keys():
		var texture: Texture2D = tile_texture_map[grid_pos]
		if texture == control_center_tile:
			# Convert grid position to world position (center of tile)
			var world_pos: Vector2 = Vector2((grid_pos.x + 0.5) * CELL_SIZE, (grid_pos.y + 0.5) * CELL_SIZE)
			positions.append(world_pos)

	print("Found ", positions.size(), " control_center tiles for console spawning")
	return positions


# ============================================================================
# SHOP TERMINAL SPAWNING
# ============================================================================

const SHOP_TERMINAL_SCENE = preload("res://scenes/ShopTerminal.tscn")

func _spawn_shop_terminals() -> void:
	"""Spawn 1-3 shop terminals at valid positions"""
	var terminal_count = randi_range(1, 3)
	var spawned = 0
	var max_attempts = 50

	print("Attempting to spawn ", terminal_count, " shop terminals...")

	for i in range(terminal_count):
		var attempts = 0
		while attempts < max_attempts:
			attempts += 1

			# Get random position from spawn points
			if spawn_points.is_empty():
				print("No spawn points available for terminals")
				break

			var spawn_pos = spawn_points[randi() % spawn_points.size()]

			# Check if position is valid (not too close to other terminals)
			if _is_valid_terminal_position(spawn_pos):
				var terminal = SHOP_TERMINAL_SCENE.instantiate()
				terminal.position = spawn_pos
				add_child(terminal)
				spawned += 1
				print("Shop terminal ", spawned, " spawned at ", spawn_pos)
				break

		if attempts >= max_attempts:
			print("Failed to find valid position for terminal ", i + 1)

	print("Successfully spawned ", spawned, " shop terminals")


func _is_valid_terminal_position(pos: Vector2) -> bool:
	"""Check if position is valid for a terminal"""
	# Check minimum distance from other terminals
	var min_distance = CELL_SIZE * 4  # At least 4 cells apart

	for child in get_children():
		if child.is_in_group("shop_terminal"):
			if child.position.distance_to(pos) < min_distance:
				return false

	# Check if position is not too close to edges
	var arena_size = Vector2(GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
	if pos.x < CELL_SIZE * 2 or pos.x > arena_size.x - CELL_SIZE * 2:
		return false
	if pos.y < CELL_SIZE * 2 or pos.y > arena_size.y - CELL_SIZE * 2:
		return false

	return true
