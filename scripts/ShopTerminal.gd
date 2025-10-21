extends StaticBody2D

# Shop Terminal - Interactive object in the map
# Modernized with AssetManager integration and robust error handling

@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel

var player_in_range: bool = false
var used: bool = false

# Visual fallback node (if texture loading fails)
var visual_fallback: ColorRect = null


func _ready() -> void:
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Hide prompt initially
	if prompt_label:
		prompt_label.hide()

	# Setup visual with AssetManager
	_setup_visual()


func _setup_visual() -> void:
	"""Setup terminal visual with AssetManager fallback system"""
	if not sprite:
		push_warning("[ShopTerminal] Sprite2D node not found in scene")
		return

	# Try to load terminal icon via AssetManager (with fallbacks)
	var terminal_texture: Texture2D = AssetManager.try_load_texture_with_fallback(
		"res://assets/sprites/ui/terminal_icon.png",
		"res://icon.svg"
	)

	# Check if we got placeholder (all textures failed)
	if terminal_texture == AssetManager.get_placeholder():
		# Create ColorRect fallback visual
		_create_fallback_visual()
		sprite.visible = false
	else:
		# Use loaded texture
		sprite.texture = terminal_texture
		sprite.visible = true

		# Remove fallback if it exists
		if visual_fallback:
			visual_fallback.queue_free()
			visual_fallback = null

	# Set terminal color (cyan glow)
	modulate = Color(0.3, 0.8, 1.0)


func _create_fallback_visual() -> void:
	"""Create simple ColorRect when textures unavailable"""
	if visual_fallback:
		return  # Already exists

	visual_fallback = ColorRect.new()
	visual_fallback.size = Vector2(32, 32)
	visual_fallback.position = Vector2(-16, -16)  # Center it
	visual_fallback.color = Color(0.2, 0.6, 0.9)  # Blue terminal color
	add_child(visual_fallback)
	visual_fallback.z_index = -1  # Behind sprite

	print("[ShopTerminal] Using ColorRect fallback visual")


func _process(_delta: float) -> void:
	"""Handle input"""
	if player_in_range and not used:
		if Input.is_action_just_pressed("interact"):  # 'E' key
			_activate_terminal()


func _on_body_entered(body: Node2D) -> void:
	"""Player entered interaction range"""
	if body.is_in_group("player"):
		player_in_range = true
		if not used and prompt_label:
			prompt_label.text = "[E] Open Shop"
			prompt_label.show()


func _on_body_exited(body: Node2D) -> void:
	"""Player left interaction range"""
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.hide()


func _activate_terminal() -> void:
	"""Open the terminal shop"""
	if used:
		return

	# Check if ShopManager exists (safety check)
	if not is_instance_valid(ShopManager):
		push_error("[ShopTerminal] ShopManager autoload not found!")
		return

	used = true

	# Update UI
	if prompt_label:
		prompt_label.text = "EMPTY"

	# Gray out terminal
	modulate = Color(0.5, 0.5, 0.5)

	# Open shop via direct autoload access
	ShopManager.open_shop(ShopManager.ShopType.TERMINAL_SHOP)

	print("[ShopTerminal] Terminal shop activated")
