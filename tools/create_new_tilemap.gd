extends Node

# New TileMap Creator using generated tiles
# Creates TileSet and TileMap from newly generated tile assets

const TILE_SIZE = 64
const TILES_DIR = "res://assets/sprites/"

# Map dimensions (20x11 = 1280x704)
const MAP_WIDTH = 20
const MAP_HEIGHT = 11

# Tile definitions
const TILES = [
	{"file": "tile_scrapyard_64.png", "name": "Scrapyard"},
	{"file": "tile_factory_64.png", "name": "Factory"},
	{"file": "tile_control_center_64.png", "name": "Control Center"},
	{"file": "tile_server_room_64.png", "name": "Server Room"},
]


func _ready() -> void:
	print("============================================================")
	print("Creating New TileMap System")
	print("============================================================")

	# Create TileSet
	var tile_set = create_tileset()

	# Save TileSet resource
	var tileset_path = "res://assets/tiles/roboclaust_tileset.tres"
	ResourceSaver.save(tile_set, tileset_path)
	print("TileSet saved to: ", tileset_path)

	# Create TileMap scene
	create_tilemap_scene(tile_set)

	print("============================================================")
	print("New TileMap Creation Complete!")
	print("============================================================")

	await get_tree().create_timer(2.0).timeout
	get_tree().quit()


func create_tileset() -> TileSet:
	"""Create TileSet from generated tiles"""
	print("\n=== Creating TileSet ===")

	var tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Load each tile
	for i in range(TILES.size()):
		var tile_info = TILES[i]
		var tile_path = TILES_DIR + tile_info["file"]

		if not ResourceLoader.exists(tile_path):
			print("  WARNING: Tile not found: ", tile_path)
			continue

		var texture = load(tile_path)
		if not texture:
			print("  ERROR: Could not load texture: ", tile_path)
			continue

		# Create new source for each tile
		var source = TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

		# Add the tile at position (0, 0) in the atlas
		source.create_tile(Vector2i(0, 0))

		# Add source to tileset
		tile_set.add_source(source, i)

		print("  [", i + 1, "/", TILES.size(), "] Added tile: ", tile_info["name"])

	print("TileSet created with ", tile_set.get_source_count(), " tiles")
	return tile_set


func create_tilemap_scene(tile_set: TileSet) -> void:
	"""Create TileMap scene with varied tile placement"""
	print("\n=== Creating TileMap Scene ===")

	# Create root node
	var root = Node2D.new()
	root.name = "GameMap"

	# Add ParallaxBackground
	var parallax_bg = ParallaxBackground.new()
	parallax_bg.name = "ParallaxBackground"
	root.add_child(parallax_bg)
	parallax_bg.owner = root

	var parallax_layer = ParallaxLayer.new()
	parallax_layer.name = "ParallaxLayer"
	parallax_layer.motion_scale = Vector2(0.2, 0.2)
	parallax_layer.motion_mirroring = Vector2(2048, 2048)
	parallax_bg.add_child(parallax_layer)
	parallax_layer.owner = root

	var city_sprite = Sprite2D.new()
	city_sprite.name = "CitySprite"
	city_sprite.modulate = Color(0.6, 0.6, 0.7, 1)
	city_sprite.z_index = -100
	city_sprite.centered = false
	city_sprite.region_enabled = true
	city_sprite.region_rect = Rect2(0, 0, 4096, 4096)

	var city_texture_path = "res://assets/city-1.jpg"
	if ResourceLoader.exists(city_texture_path):
		city_sprite.texture = load(city_texture_path)

	parallax_layer.add_child(city_sprite)
	city_sprite.owner = root

	# Create TileMapLayer
	var tile_map = TileMapLayer.new()
	tile_map.name = "TileMapLayer"
	tile_map.tile_set = tile_set
	tile_map.z_index = -10
	root.add_child(tile_map)
	tile_map.owner = root

	# Fill map with varied tiles
	print("Filling map (", MAP_WIDTH, "x", MAP_HEIGHT, " tiles)...")

	# Create zones with different tile types
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile_id = 0

			# Zone-based tile selection
			if x < 5:
				# Left edge: Scrapyard
				tile_id = 0
			elif x >= MAP_WIDTH - 5:
				# Right edge: Scrapyard
				tile_id = 0
			elif y < 3:
				# Top: Control Center
				tile_id = 2
			elif y >= MAP_HEIGHT - 3:
				# Bottom: Factory
				tile_id = 1
			else:
				# Center: Server Room
				tile_id = 3

			# Add some randomization
			if randf() < 0.15:
				tile_id = randi() % TILES.size()

			# Set tile
			tile_map.set_cell(Vector2i(x, y), tile_id, Vector2i(0, 0))

	print("Map filled with ", MAP_WIDTH * MAP_HEIGHT, " tiles")

	# Create packed scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)

	# Save scene
	var scene_path = "res://scenes/GameMap.tscn"
	ResourceSaver.save(packed_scene, scene_path)
	print("TileMap scene saved to: ", scene_path)
