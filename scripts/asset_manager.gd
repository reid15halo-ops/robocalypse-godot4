extends Node

## AssetManager - Centralized Asset Loading with Fallbacks
## Provides robust texture/resource loading with automatic fallback to placeholders

# ============================================================================
# ASSET CACHE
# ============================================================================

var texture_cache: Dictionary = {}  # path -> Texture2D
var placeholder_texture: ImageTexture = null


# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	"""Initialize asset manager"""
	_create_placeholder_texture()
	print("[AssetManager] Initialized with fallback system")


func _create_placeholder_texture() -> void:
	"""Create a simple placeholder texture for missing assets"""
	var size: int = 64
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Create checkerboard pattern (magenta/black - obvious missing asset)
	for y in range(size):
		for x in range(size):
			var checker: bool = ((x / 8) + (y / 8)) % 2 == 0
			var color: Color = Color.MAGENTA if checker else Color.BLACK
			img.set_pixel(x, y, color)

	placeholder_texture = ImageTexture.create_from_image(img)


# ============================================================================
# TEXTURE LOADING
# ============================================================================

func load_texture(path: String, use_cache: bool = true) -> Texture2D:
	"""
	Load a texture with automatic fallback to placeholder

	Args:
		path: Resource path to texture (e.g., "res://assets/sprites/player.png")
		use_cache: Whether to use cached textures (default: true)

	Returns:
		Loaded texture or placeholder if failed
	"""
	# Check cache first
	if use_cache and texture_cache.has(path):
		return texture_cache[path]

	# Attempt to load
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path) as Texture2D
		if texture != null:
			if use_cache:
				texture_cache[path] = texture
			return texture
		else:
			push_warning("[AssetManager] Failed to load texture at '%s' - file exists but load failed" % path)
	else:
		push_warning("[AssetManager] Texture not found: '%s'" % path)

	# Return placeholder
	return placeholder_texture


func try_load_texture_with_fallback(primary_path: String, fallback_path: String = "") -> Texture2D:
	"""
	Try to load primary texture, fall back to secondary, then placeholder

	Args:
		primary_path: Primary texture path
		fallback_path: Optional fallback path

	Returns:
		First successfully loaded texture or placeholder
	"""
	# Try primary
	if ResourceLoader.exists(primary_path):
		var texture: Texture2D = load(primary_path) as Texture2D
		if texture != null:
			texture_cache[primary_path] = texture
			return texture

	# Try fallback
	if fallback_path != "" and ResourceLoader.exists(fallback_path):
		var texture: Texture2D = load(fallback_path) as Texture2D
		if texture != null:
			texture_cache[fallback_path] = texture
			push_warning("[AssetManager] Using fallback texture: '%s' (primary failed: '%s')" % [fallback_path, primary_path])
			return texture

	# Return placeholder
	push_warning("[AssetManager] All paths failed, using placeholder. Primary: '%s', Fallback: '%s'" % [primary_path, fallback_path])
	return placeholder_texture


func preload_textures(paths: Array[String]) -> void:
	"""Preload multiple textures into cache"""
	for path in paths:
		load_texture(path, true)


# ============================================================================
# CACHE MANAGEMENT
# ============================================================================

func clear_cache() -> void:
	"""Clear texture cache to free memory"""
	texture_cache.clear()
	print("[AssetManager] Cache cleared")


func get_cache_size() -> int:
	"""Get number of cached textures"""
	return texture_cache.size()


func get_placeholder() -> Texture2D:
	"""Get the placeholder texture directly"""
	return placeholder_texture
