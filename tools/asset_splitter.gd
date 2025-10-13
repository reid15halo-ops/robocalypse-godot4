extends Node

# Asset Splitter for Roboclaust
# Splits JPEG sprite sheets into individual PNG files

const DIRS = {
	"enemies": "res://assets/sprites/enemies",
	"player": "res://assets/sprites/player",
	"boss": "res://assets/sprites/boss",
	"effects": "res://assets/sprites/effects",
	"projectiles": "res://assets/sprites/projectiles",
	"weapons": "res://assets/sprites/weapons",
	"items": "res://assets/sprites/items",
	"drugs": "res://assets/sprites/drugs",
	"tiles_factory": "res://assets/tiles/factory",
	"tiles_danger": "res://assets/tiles/danger",
}


func _ready() -> void:
	print("============================================================")
	print("Roboclaust Asset Splitter")
	print("============================================================")

	# Create all directories
	create_directories()

	# Process all sprite sheets
	process_player()
	process_drones()
	process_boss()
	process_effects()
	process_projectiles()
	process_weapons()
	process_materials()
	process_drugs()
	process_map_tiles()

	print("============================================================")
	print("Asset splitting complete!")
	print("============================================================")
	print("\nAll PNG files have been created.")
	print("Godot will automatically reimport them.")

	# Quit after completion
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()


func create_directories() -> void:
	"""Create all output directories"""
	for dir_path in DIRS.values():
		DirAccess.make_dir_recursive_absolute(dir_path)
		print("Created directory: ", dir_path)


func split_sprite_sheet(input_path: String, output_dir: String, grid_cols: int, grid_rows: int, names: Array) -> void:
	"""Split sprite sheet into individual images"""
	print("\n=== Processing: ", input_path, " ===")
	print("Grid: ", grid_cols, "x", grid_rows)

	var img = Image.load_from_file(input_path)
	if img == null:
		print("ERROR: Could not load ", input_path)
		return

	var width = img.get_width()
	var height = img.get_height()
	var cell_width = width / grid_cols
	var cell_height = height / grid_rows

	print("Image size: ", width, "x", height)
	print("Cell size: ", cell_width, "x", cell_height)

	var count = 0
	for row in range(grid_rows):
		for col in range(grid_cols):
			var index = row * grid_cols + col
			if index >= names.size():
				break

			var name = names[index]
			if name == "skip":  # Skip empty cells
				continue

			var left = col * cell_width
			var top = row * cell_height
			var right = (col + 1) * cell_width
			var bottom = (row + 1) * cell_height

			# Create sub-image
			var cell = img.get_region(Rect2(left, top, cell_width, cell_height))

			# Save as PNG
			var output_path = output_dir + "/" + name + ".png"
			var err = cell.save_png(output_path)
			if err == OK:
				count += 1
				print("  [", count, "] Saved: ", name, ".png")
			else:
				print("  ERROR saving: ", name, ".png")

	print("Completed: ", count, " images extracted\n")


func process_drones() -> void:
	"""Process dronen-1.jpg - Enemy drones"""
	split_sprite_sheet(
		"res://assets/dronen-1.jpg",
		DIRS["enemies"],
		2, 3,
		[
			"standard_drone",
			"fast_drone",
			"heavy_drone",
			"explosion_smoke",
			"kamikaze_drone",
			"sniper_drone"
		]
	)


func process_player() -> void:
	"""Process hacker-1.jpg - Player character"""
	print("\n=== Processing: hacker-1.jpg ===")
	var img = Image.load_from_file("res://assets/hacker-1.jpg")
	if img:
		var output_path = DIRS["player"] + "/player.png"
		img.save_png(output_path)
		print("Saved: player.png\n")


func process_boss() -> void:
	"""Process boss-gegner1.jpg - Boss enemy"""
	print("\n=== Processing: boss-gegner1.jpg ===")
	var img = Image.load_from_file("res://assets/boss-gegner1.jpg")
	if img:
		var output_path = DIRS["boss"] + "/boss_mech.png"
		img.save_png(output_path)
		print("Saved: boss_mech.png\n")


func process_effects() -> void:
	"""Process effects-1.jpg - VFX effects"""
	split_sprite_sheet(
		"res://assets/effects-1.jpg",
		DIRS["effects"],
		2, 3,
		[
			"laser_beam",
			"explosion_burst",
			"energy_blast",
			"portal_ring",
			"skip",
			"lightning_wave"
		]
	)


func process_projectiles() -> void:
	"""Process geschosse-1.jpg - Projectiles"""
	split_sprite_sheet(
		"res://assets/geschosse-1.jpg",
		DIRS["projectiles"],
		2, 3,
		[
			"energy_bullet",
			"energy_beam",
			"energy_laser",
			"rocket",
			"grenade",
			"energy_orb"
		]
	)


func process_weapons() -> void:
	"""Process weapons-1.jpg - Weapons"""
	split_sprite_sheet(
		"res://assets/weapons-1.jpg",
		DIRS["weapons"],
		3, 3,
		[
			"pistol_energy",
			"pistol_gray",
			"skip",
			"rifle_blue",
			"rifle_gray",
			"skip",
			"sword_energy",
			"gun_heavy",
			"skip"
		]
	)


func process_materials() -> void:
	"""Process materialien-1.jpg - Items"""
	split_sprite_sheet(
		"res://assets/materialien-1.jpg",
		DIRS["items"],
		6, 6,
		[
			# Row 1
			"metal_rusty", "crystal_cyan", "crystal_pink",
			"tech_panel", "shard_cyan", "orb_blue",
			# Row 2
			"cube_empty", "cube_filled", "tile_cracked_1",
			"cube_glass", "tile_cracked_2", "orb_tech_blue",
			# Row 3
			"orb_purple", "orb_glow_blue", "tile_cracked_3",
			"crystal_blue", "crystal_purple", "orb_green",
			# Row 4
			"crystal_green", "gem_blue", "gem_pink",
			"gem_purple", "gem_rainbow", "star_purple",
			# Row 5
			"crystal_white", "tile_metal", "gem_holo_purple",
			"ring_tech_black", "crystal_rainbow", "crystal_green_2",
			# Row 6
			"tile_dark_1", "tile_dark_2", "tile_dark_3",
			"tile_dark_4", "tile_dark_5", "tile_dark_6"
		]
	)


func process_drugs() -> void:
	"""Copy specific items as drug icons"""
	print("\n=== Creating Drug Icons ===")

	var drug_mapping = {
		"crystal_pink.png": "stim_pack.png",
		"crystal_purple.png": "nano_boost.png",
		"gem_rainbow.png": "combat_drug.png",
		"orb_glow_blue.png": "focus_serum.png",
		"gem_holo_purple.png": "rage_pill.png",
		"crystal_cyan.png": "speed_injector.png",
	}

	for source in drug_mapping.keys():
		var dest = drug_mapping[source]
		var source_path = DIRS["items"] + "/" + source
		var dest_path = DIRS["drugs"] + "/" + dest

		var img = Image.load_from_file(source_path)
		if img:
			img.save_png(dest_path)
			print("Created drug icon: ", dest)

	print()


func process_map_tiles() -> void:
	"""Process map-2.jpg - Danger zone tiles"""
	var names = []
	for i in range(64):
		names.append("danger_tile_%02d" % i)

	split_sprite_sheet(
		"res://assets/map-2.jpg",
		DIRS["tiles_danger"],
		8, 8,
		names
	)
