extends Node

# TileMap Creator for Roboclaust
# Creates TileSet and TileMap from danger tiles

const TILE_SIZE = 256  # Each tile is 256x256
const TILES_DIR = "res://assets/tiles/danger/"
const TILE_COUNT = 64

# Map dimensions (in tiles)
const MAP_WIDTH = 20
const MAP_HEIGHT = 11


func _ready() -> void:
	print("============================================================")
	print("Creating TileMap System")
	print("============================================================")

	# Create TileSet
	var tile_set = create_tileset()

	# Save TileSet resource
	var tileset_path = "res://assets/tiles/danger_tileset.tres"
	ResourceSaver.save(tile_set, tileset_path)
	print("TileSet saved to: ", tileset_path)

	# Create TileMap scene
	create_tilemap_scene(tile_set)

	print("============================================================")
	print("TileMap Creation Complete!")
	print("============================================================")

	await get_tree().create_timer(2.0).timeout
	get_tree().quit()


func create_tileset() -> TileSet:
	"""Create TileSet from danger tiles"""
	print("\n=== Creating TileSet ===")

	var tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create atlas source
	var atlas_source = TileSetAtlasSource.new()

	# Load each tile as a separate texture
	for i in range(TILE_COUNT):
		var tile_path = TILES_DIR + "danger_tile_%02d.png" % i

		if not ResourceLoader.exists(tile_path):
			print("  WARNING: Tile not found: ", tile_path)
			continue

		var texture = load(tile_path)
		if not texture:
			print("  ERROR: Could not load texture: ", tile_path)
			continue

		# Create new source for each tile (simple approach)
		var source = TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

		# Add the tile at position (0, 0) in the atlas
		source.create_tile(Vector2i(0, 0))

		# Add source to tileset
		tile_set.add_source(source, i)

		print("  [", i + 1, "/", TILE_COUNT, "] Added tile: danger_tile_", "%02d" % i)

	print("TileSet created with ", tile_set.get_source_count(), " tiles")
	return tile_set


func create_tilemap_scene(tile_set: TileSet) -> void:
	"""Create TileMap scene with random tile placement"""
	print("\n=== Creating TileMap Scene ===")

	# Create root node
	var root = Node2D.new()
	root.name = "GameMap"

	# Add ParallaxBackground with city background
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
		print("Added parallax city background")
	else:
		print("WARNING: City background not found at ", city_texture_path)

	parallax_layer.add_child(city_sprite)
	city_sprite.owner = root

	# Create TileMapLayer (Godot 4.5)
	var tile_map = TileMapLayer.new()
	tile_map.name = "TileMapLayer"
	tile_map.tile_set = tile_set
	tile_map.z_index = -10
	root.add_child(tile_map)
	tile_map.owner = root

	# Fill map with random tiles
	print("Filling map (", MAP_WIDTH, "x", MAP_HEIGHT, " tiles)...")

	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			# Pick random tile
			var tile_id = randi() % TILE_COUNT

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
