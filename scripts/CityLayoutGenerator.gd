@tool
class_name CityLayoutGenerator
extends Node2D

## CityLayoutGenerator - V2 (Ares-Revision)
## Erzeugt ein prozedurales Stadtlayout und gibt ein optimiertes MapData-Objekt zurück.

# ============================================================================
# NEUE MapData-KLASSE: KAPSELT ALLE LEVEL-INFORMATIONEN
# ============================================================================
class MapData extends RefCounted:
	var grid: Array[Array]
	var grid_size: Vector2i
	var cell_size: int
	var generation_seed: int
	var arena_bounds: Rect2
	
	# Optimierte, vorab berechnete Spawn-Punkte
	var spawn_points_all: Array[Vector2] = []
	var spawn_points_ambush: Array[Vector2] = []
	var spawn_points_perimeter: Array[Vector2] = []
	var spawn_points_open_area: Array[Vector2] = []
	
	func _init(gen_seed: int, _grid: Array, _grid_size: Vector2i, _cell_size: int):
		self.generation_seed = gen_seed
		self.grid = _grid
		self.grid_size = _grid_size
		self.cell_size = _cell_size
		self.arena_bounds = Rect2(Vector2.ZERO, grid_size * cell_size)

	# Effiziente öffentliche API für den Zugriff auf Spawn-Punkte
	func get_strategic_spawn_position(spawn_type: String) -> Vector2:
		match spawn_type.to_lower():
			"ambush":
				if not spawn_points_ambush.is_empty():
					return spawn_points_ambush.pick_random()
			"perimeter":
				if not spawn_points_perimeter.is_empty():
					return spawn_points_perimeter.pick_random()
			"open_area":
				if not spawn_points_open_area.is_empty():
					return spawn_points_open_area.pick_random()
		
		# Fallback auf einen beliebigen Spawn-Punkt
		if not spawn_points_all.is_empty():
			return spawn_points_all.pick_random()
			
		# Absoluter Notfall-Fallback
		return arena_bounds.get_center()

# ============================================================================
# KONFIGURATION
# ============================================================================

const GRID_WIDTH: int = 20  # Vergrößert von 14 auf 20 für mehr Kampfraum
const GRID_HEIGHT: int = 20  # Vergrößert von 14 auf 20 für mehr Kampfraum
const CELL_SIZE: int = 64 # Skaliert von 128 auf 64 für ein feineres Grid

const MIN_HOUSES: int = 1  # Mindestens 1 Gebäude für taktische Deckung
const MAX_HOUSES: int = 4  # Mehr Gebäude für Abwechslung (war 3)
const MIN_HOUSE_SIZE: int = 3  # Kleinere Min-Größe für bessere Verteilung (war 4)
const MAX_HOUSE_SIZE: int = 6  # Kleinere Max-Größe für mehr offenen Raum (war 8)

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
var occupied_zone_cells: Dictionary = {}

# Visual configuration
const WALL_THICKNESS: int = 24
const WALL_COLOR: Color = Color(0.3, 0.3, 0.35)
const BUILDING_FLOOR_COLOR: Color = Color(0.15, 0.15, 0.18)
const STREET_COLOR: Color = Color(0.25, 0.25, 0.28)
const DOOR_WIDTH: int = 128  # One cell width

# Prozedurale Straßenkonfiguration
const NUM_VERTICAL_STREETS: int = 2
const NUM_HORIZONTAL_STREETS: int = 2
const STREET_WIDTH_CELLS: int = 2

# Container nodes
var walls_container: Node2D = null
@onready var tile_map: TileMap = $TileMap # NEU: Referenz zur TileMap
var zones_container: Node2D = null
var city_boundary: StaticBody2D = null

# Zone modules (gameplay-focused placeholders)
var zone_definitions := [
	{
		"id": "cover_rocks",
		"size": Vector2i(1, 1),
		"color": Color(0.4, 0.3, 0.2, 0.9),
		"type": "cover"  # Kleine Deckungsobjekte
	},
	{
		"id": "small_barrier",
		"size": Vector2i(2, 1),
		"color": Color(0.3, 0.3, 0.3, 0.9),
		"type": "cover"  # Längliche Barrieren
	},
	{
		"id": "plaza",
		"size": Vector2i(3, 3),
		"color": Color(0.25, 0.25, 0.35, 0.6),
		"type": "open_area"  # Große offene Kampfbereiche
	},
	{
		"id": "scrap_pile",
		"size": Vector2i(2, 2),
		"color": Color(0.5, 0.4, 0.1, 0.8),
		"type": "resource"  # Ressourcen-Bereiche
	}
]


# ============================================================================
# INITIALISIERUNG
# ============================================================================

func _ready() -> void:
	"""Initialize generator"""
	walls_container = Node2D.new()
	walls_container.name = "Walls"
	add_child(walls_container)

	# floor_container wird nicht mehr benötigt, da TileMap verwendet wird
	# floor_container = Node2D.new()
	# floor_container.name = "Floor"
	# floor_container.z_index = -5
	# add_child(floor_container)

	zones_container = Node2D.new()
	zones_container.name = "Zones"
	add_child(zones_container)


# ============================================================================
# GENERATION
# ============================================================================

func generate_map(seed_value: int = -1) -> MapData:
	"""Generiert eine prozedurale Stadtkarte und gibt ein MapData-Objekt zurück."""
	if seed_value == -1:
		generation_seed = randi()
	else:
		generation_seed = seed_value

	seed(generation_seed)
	clear_map()
	print("=== Ares-Generator: Starte Generierung (Seed: ", generation_seed, ") ===")

	# 1. Grid initialisieren
	_initialize_grid()

	# 2. Straßen prozedural platzieren
	_place_streets_procedural()

	# 3. Zufällige Häuser generieren
	var house_count = randi_range(MIN_HOUSES, MAX_HOUSES)
	_generate_random_houses(house_count)

	# 4. Taktische Zonen verteilen
	_scatter_zones()

	# 5. Visuelle Bodenelemente via TileMap erzeugen
	_generate_tilemap_visuals()

	# 6. Wände mit Türen generieren
	_generate_all_walls()

	# 7. Arenabegrenzung erstellen
	_create_arena_boundary()

	# 8. MapData-Objekt erstellen und mit strategischen Daten füllen
	var map_data = _create_and_populate_map_data()

	print("=== Ares-Generator: Generierung abgeschlossen. MapData-Objekt bereit. ===")
	_print_grid_debug()
	
	return map_data


# ============================================================================
# GRID INITIALISIERUNG
# ============================================================================

func _initialize_grid() -> void:
	"""Create empty grid filled with a base floor type"""
	grid = []
	spatial_hash = {}
	occupied_zone_cells = {}

	for y in range(GRID_HEIGHT):
		var row: Array = []
		for x in range(GRID_WIDTH):
			row.append(CellType.EMPTY)  # Default to empty, streets will be carved out
		grid.append(row)


# ============================================================================
# STRASSENPLATZIERUNG (NEU & PROZEDURAL)
# ============================================================================

func _place_streets_procedural() -> void:
	"""Platziert Straßen dynamisch basierend auf Grid-Größe und Konfiguration."""
	var section_width = GRID_WIDTH / (NUM_VERTICAL_STREETS + 1)
	for i in range(NUM_VERTICAL_STREETS):
		var center_col = section_width * (i + 1)
		var start_col = center_col - (STREET_WIDTH_CELLS / 2)
		for col_offset in range(STREET_WIDTH_CELLS):
			var current_col = start_col + col_offset
			if current_col >= 0 and current_col < GRID_WIDTH:
				for y in range(GRID_HEIGHT):
					grid[y][current_col] = CellType.STREET

	var section_height = GRID_HEIGHT / (NUM_HORIZONTAL_STREETS + 1)
	for i in range(NUM_HORIZONTAL_STREETS):
		var center_row = section_height * (i + 1)
		var start_row = center_row - (STREET_WIDTH_CELLS / 2)
		for row_offset in range(STREET_WIDTH_CELLS):
			var current_row = start_row + row_offset
			if current_row >= 0 and current_row < GRID_HEIGHT:
				for x in range(GRID_WIDTH):
					grid[current_row][x] = CellType.STREET
	
	print("Straßen prozedural platziert für ", GRID_WIDTH, "x", GRID_HEIGHT, " Grid.")


# ============================================================================
# NAVIGATION MESH GENERATION (NEU)
# ============================================================================

func bake_navigation_mesh(nav_region: NavigationRegion2D) -> void:
	if not nav_region:
		push_warning("CityLayoutGenerator: NavigationRegion2D ist nicht zugewiesen.")
		return

	var nav_poly = NavigationPolygon.new()
	
	# 1. Erstelle ein großes Polygon für die gesamte Arena
	var map_width_pixels = GRID_WIDTH * CELL_SIZE
	var map_height_pixels = GRID_HEIGHT * CELL_SIZE
	var arena_outline = PackedVector2Array([
		Vector2(0, 0),
		Vector2(map_width_pixels, 0),
		Vector2(map_width_pixels, map_height_pixels),
		Vector2(0, map_height_pixels)
	])
	nav_poly.add_outline(arena_outline)

	# 2. Füge Gebäude als Löcher hinzu
	for cell in occupied_zone_cells:
		if occupied_zone_cells[cell] == CellType.BUILDING:
			var building_rect = Rect2(
				cell.x * CELL_SIZE,
				cell.y * CELL_SIZE,
				CELL_SIZE,
				CELL_SIZE
			)
			var building_outline = PackedVector2Array([
				building_rect.position,
				Vector2(building_rect.position.x + building_rect.size.x, building_rect.position.y),
				building_rect.position + building_rect.size,
				Vector2(building_rect.position.x, building_rect.position.y + building_rect.size.y)
			])
			nav_poly.add_outline(building_outline)

	# 3. Bake das Mesh und weise es der Region zu
	nav_region.navigation_polygon = nav_poly
	print("Navigation Mesh gebacken.")


# ============================================================================
# ZUFÄLLIGE HAUSGENERIERUNG
# ============================================================================

func _generate_random_houses(count: int) -> void:
	var attempts = 0
	var placed = 0
	var max_attempts = 100

	while placed < count and attempts < max_attempts:
		attempts += 1
		var width = randi_range(MIN_HOUSE_SIZE, MAX_HOUSE_SIZE)
		var height = randi_range(MIN_HOUSE_SIZE, MAX_HOUSE_SIZE)
		var x = randi_range(0, GRID_WIDTH - width)
		var y = randi_range(0, GRID_HEIGHT - height)

		if _can_place_house(x, y, width, height):
			_place_house(x, y, width, height)
			placed += 1


func _can_place_house(x: int, y: int, width: int, height: int) -> bool:
	# Check grid bounds
	if x + width > GRID_WIDTH or y + height > GRID_HEIGHT:
		return false

	# Check if the area is empty (not a street)
	for check_y in range(y, y + height):
		for check_x in range(x, x + width):
			if check_x >= GRID_WIDTH or check_y >= GRID_HEIGHT:
				return false

			# Verhindert, dass Häuser direkt auf Straßen gebaut werden
			if grid[check_y][check_x] == CellType.STREET:
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
				for house in spatial_hash[hash_key]:
					if _rectangles_overlap(x, y, width, height, house.x, house.y, house.width, house.height):
						return false
	return true


func _rectangles_overlap(x1: int, y1: int, w1: int, h1: int, x2: int, y2: int, w2: int, h2: int) -> bool:
	return (x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2)


func _place_house(x: int, y: int, width: int, height: int) -> void:
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
	"""Place tactical gameplay zones on available street cells"""
	if zone_definitions.is_empty():
		return

	# Mehr taktische Objekte für besseres Gameplay
	var desired_zone_count = randi_range(4, 8)  # Erhöht von 2-4 auf 4-8
	var attempts = 0
	var placed = 0
	var max_attempts = 80  # Mehr Versuche für bessere Platzierung
	
	# Prioritäts-basierte Platzierung: Kleine Cover-Objekte zuerst
	var cover_zones = zone_definitions.filter(func(z): return z["type"] == "cover")
	var other_zones = zone_definitions.filter(func(z): return z["type"] != "cover")
	
	# Phase 1: Platziere kleine Cover-Objekte
	var cover_target = randi_range(3, 5)
	while placed < cover_target and attempts < max_attempts / 2:
		attempts += 1
		if cover_zones.is_empty():
			break
			
		var zone_def = cover_zones[randi() % cover_zones.size()]
		var size: Vector2i = zone_def["size"]

		var cell_x = randi_range(1, GRID_WIDTH - size.x - 1)
		var cell_y = randi_range(1, GRID_HEIGHT - size.y - 1)

		if _can_place_zone(cell_x, cell_y, size):
			_mark_zone_cells(cell_x, cell_y, size)
			_create_zone_visual(cell_x, cell_y, size, zone_def)
			placed += 1
	
	# Phase 2: Platziere größere taktische Bereiche
	while placed < desired_zone_count and attempts < max_attempts:
		attempts += 1
		var zone_def = other_zones[randi() % other_zones.size()] if not other_zones.is_empty() else zone_definitions[randi() % zone_definitions.size()]
		var size: Vector2i = zone_def["size"]

		var cell_x = randi_range(1, GRID_WIDTH - size.x - 1)
		var cell_y = randi_range(1, GRID_HEIGHT - size.y - 1)

		if _can_place_zone(cell_x, cell_y, size):
			_mark_zone_cells(cell_x, cell_y, size)
			_create_zone_visual(cell_x, cell_y, size, zone_def)
			placed += 1
		elif attempts % 15 == 0:
			print("Zone placement attempt ", attempts, " failed - trying different approach")

	print("Placed ", placed, " tactical zones for enhanced gameplay")


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
	var zone_rect = ColorRect.new()
	zone_rect.size = Vector2(size.x * CELL_SIZE, size.y * CELL_SIZE)
	zone_rect.position = Vector2(cell_x * CELL_SIZE, cell_y * CELL_SIZE)
	zone_rect.color = zone_def["color"]
	zones_container.add_child(zone_rect)


# ============================================================================
# VISUELLE BODENGENERIERUNG
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
					floor_tile.color = BUILDING_FLOOR_COLOR # Default to building floor

			floor_container.add_child(floor_tile)


func _create_and_populate_map_data() -> MapData:
	"""Erstellt das MapData-Objekt und führt die einmalige Berechnung aller strategischen Punkte durch."""
	var map_data = MapData.new(generation_seed, grid, Vector2i(GRID_WIDTH, GRID_HEIGHT), CELL_SIZE)
	
	var all_walkable_points: Array[Vector2] = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if _is_cell_walkable(x, y):
				all_walkable_points.append(Vector2((x + 0.5) * CELL_SIZE, (y + 0.5) * CELL_SIZE))
	
	map_data.spawn_points_all = all_walkable_points.duplicate()

	# Einmalige Kategorisierung
	var edge_threshold = 3 * CELL_SIZE
	var open_area_radius_cells = 3

	for point in all_walkable_points:
		var grid_pos = Vector2i(int(point.x / CELL_SIZE), int(point.y / CELL_SIZE))
		
		# 1. Perimeter-Check
		if (point.x < edge_threshold or point.x > (GRID_WIDTH * CELL_SIZE - edge_threshold) or \
			point.y < edge_threshold or point.y > (GRID_HEIGHT * CELL_SIZE - edge_threshold)):
			map_data.spawn_points_perimeter.append(point)

		# 2. Ambush-Check (Nähe zu Gebäuden)
		if _is_near_building(grid_pos, 2):
			map_data.spawn_points_ambush.append(point)
		
		# 3. Open-Area-Check (keine Gebäude in der Nähe)
		elif not _is_near_building(grid_pos, open_area_radius_cells):
			map_data.spawn_points_open_area.append(point)
			
	print("MapData erstellt: ", map_data.spawn_points_all.size(), " Gesamtpunkte, ", \
		map_data.spawn_points_ambush.size(), " Ambush, ", \
		map_data.spawn_points_perimeter.size(), " Perimeter, ", \
		map_data.spawn_points_open_area.size(), " OpenArea.")
		
	return map_data


func _is_near_building(grid_pos: Vector2i, radius: int) -> bool:
	"""Prüft, ob sich ein Gebäude innerhalb eines bestimmten Radius (in Zellen) befindet."""
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var check_pos = grid_pos + Vector2i(dx, dy)
			if check_pos.x >= 0 and check_pos.x < GRID_WIDTH and \
			   check_pos.y >= 0 and check_pos.y < GRID_HEIGHT:
				if grid[check_pos.y][check_pos.x] == CellType.BUILDING:
					return true
	return false


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
# WANDGENERIERUNG
# ============================================================================

func _generate_all_walls() -> void:
	"""Generate walls for all buildings with doors"""
	var processed: Dictionary = {}

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x] == CellType.BUILDING:
				var key = str(x) + "," + str(y)
				if not processed.has(key):
					var region = _flood_fill_region(x, y, processed)
					_create_building_walls(region)


func _flood_fill_region(start_x: int, start_y: int, processed: Dictionary) -> Dictionary:
	"""Find all connected building cells"""
	var stack: Array = [[start_x, start_y]]
	var min_x = start_x
	var max_x = start_x
	var min_y = start_y
	var max_y = start_y

	while not stack.is_empty():
		var cell = stack.pop_back()
		var x = cell[0]
		var y = cell[1]

		if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
			continue

		var key = str(x) + "," + str(y)
		if processed.has(key) or grid[y][x] != CellType.BUILDING:
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


func _get_adjacent_street_sides(region: Dictionary) -> Array[String]:
	"""Check which sides of a building region are adjacent to streets"""
	var sides: Array[String] = []
	var x = region.x
	var y = region.y
	var width = region.width
	var height = region.height

	# Top
	if y > 0 and grid[y - 1][x] == CellType.STREET:
		sides.append("top")
	# Bottom
	if y + height < GRID_HEIGHT and grid[y + height][x] == CellType.STREET:
		sides.append("bottom")
	# Left
	if x > 0 and grid[y][x - 1] == CellType.STREET:
		sides.append("left")
	# Right
	if x + width < GRID_WIDTH and grid[y][x + width] == CellType.STREET:
		sides.append("right")

	return sides


func _create_wall_segment(x: float, y: float, width: float, height: float) -> void:
	"""Create a single wall segment"""
	var wall = StaticBody2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, height)
	var collision = CollisionShape2D.new()
	collision.shape = shape
	wall.add_child(collision)
	wall.position = Vector2(x, y)
	walls_container.add_child(wall)

	var visual = ColorRect.new()
	visual.size = shape.size
	visual.color = WALL_COLOR
	wall.add_child(visual)


func _create_door_area(x: float, y: float, width: float, height: float) -> void:
	"""Create a non-colliding area for a door"""
	var door_visual = ColorRect.new()
	door_visual.size = Vector2(width, height)
	door_visual.position = Vector2(x, y)
	door_visual.color = STREET_COLOR.lightened(0.1)
	walls_container.add_child(door_visual)


# ============================================================================
# ARENA-BEGRANZUNG
# ============================================================================

func _create_arena_boundary() -> void:
	"""Create a boundary around the entire map"""
	city_boundary = StaticBody2D.new()
	city_boundary.name = "CityBoundary"
	add_child(city_boundary)

	var map_width = GRID_WIDTH * CELL_SIZE
	var map_height = GRID_HEIGHT * CELL_SIZE
	var thickness = 100.0

	var shapes = [
		[Vector2(map_width / 2, -thickness / 2), Vector2(map_width + thickness * 2, thickness)],  # Top
		[Vector2(map_width / 2, map_height + thickness / 2), Vector2(map_width + thickness * 2, thickness)],  # Bottom
		[Vector2(-thickness / 2, map_height / 2), Vector2(thickness, map_height)],  # Left
		[Vector2(map_width + thickness / 2, map_height / 2), Vector2(thickness, map_height)]  # Right
	]

	for shape_data in shapes:
		var collision_shape = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = shape_data[1]
		collision_shape.shape = rect_shape
		collision_shape.position = shape_data[0]
		city_boundary.add_child(collision_shape)


# ============================================================================
# DEBUG-TOOLS
# ============================================================================

func _print_grid_debug() -> void:
	"""Print grid for debugging"""
	var output = ""
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			match grid[y][x]:
				CellType.EMPTY:
					output += "."
				CellType.STREET:
					output += "#"
				CellType.BUILDING:
					output += "B"
		output += "\n"
	print(output)


# ============================================================================
# ÖFFENTLICHE API (BEREINIGT)
# ============================================================================

func get_arena_bounds() -> Rect2:
	"""Get arena boundaries"""
	return Rect2(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)


func clear_map() -> void:
	"""Clear all map elements for regeneration"""
	print("=== CityLayoutGenerator: Clearing map ===")

	var floor_container = get_node_or_null("Floor")
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
	occupied_zone_cells.clear()

	print("Karte erfolgreich bereinigt.")


func get_generation_seed() -> int:
	"""Return the seed used for generation"""
	return generation_seed
