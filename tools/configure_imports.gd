extends Node

# Configure import settings for all PNG sprites
# Sets Filter = Nearest, Mipmaps = Off for pixel art

const SPRITE_DIRS = [
	"res://assets/sprites/enemies",
	"res://assets/sprites/player",
	"res://assets/sprites/boss",
	"res://assets/sprites/effects",
	"res://assets/sprites/projectiles",
	"res://assets/sprites/weapons",
	"res://assets/sprites/items",
	"res://assets/sprites/drugs",
	"res://assets/tiles/danger",
	"res://assets/tiles/factory",
]


func _ready() -> void:
	print("============================================================")
	print("Configuring PNG Import Settings")
	print("============================================================")

	var total_configured = 0

	for dir_path in SPRITE_DIRS:
		var count = configure_directory(dir_path)
		total_configured += count

	print("\n============================================================")
	print("Configuration Complete!")
	print("Total files configured: ", total_configured)
	print("============================================================")
	print("\nRestart Godot to apply import changes.")

	# Quit after completion
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()


func configure_directory(dir_path: String) -> int:
	"""Configure all PNG files in a directory"""
	print("\n=== Configuring: ", dir_path, " ===")

	var dir = DirAccess.open(dir_path)
	if dir == null:
		print("  Directory not found, skipping")
		return 0

	var count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var full_path = dir_path + "/" + file_name
			configure_png_import(full_path)
			count += 1

		file_name = dir.get_next()

	dir.list_dir_end()
	print("  Configured ", count, " files")
	return count


func configure_png_import(png_path: String) -> void:
	"""Create .import file with pixel art settings"""
	var import_path = png_path + ".import"

	var import_content = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://""" + generate_uid() + """"
path="res://.godot/imported/""" + png_path.get_file() + """-""" + generate_hash() + """.ctex"
metadata={
"vram_texture": false
}

[deps]

source_file=\"""" + png_path + """\"
dest_files=["res://.godot/imported/""" + png_path.get_file() + """-""" + generate_hash() + """.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""

	var file = FileAccess.open(import_path, FileAccess.WRITE)
	if file:
		file.store_string(import_content)
		file.close()
		print("  Created: ", import_path)
	else:
		print("  ERROR: Could not write ", import_path)


func generate_uid() -> String:
	"""Generate a random UID for Godot"""
	var chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	var uid = ""
	for i in range(10):
		uid += chars[randi() % chars.length()]
	return uid


func generate_hash() -> String:
	"""Generate a random hash for the import file"""
	var chars = "abcdef0123456789"
	var hash = ""
	for i in range(32):
		hash += chars[randi() % chars.length()]
	return hash
