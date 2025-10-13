extends Area2D

# Projectile properties
var speed: float = 300.0
var damage: int = 40
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 3.0  # Auto-destroy after 3 seconds

func _ready() -> void:
	# Set collision layers
	collision_layer = 8  # Projectile layer
	collision_mask = 4   # Collide with walls; damage handled manually

	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Create visual
	_create_visual()

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func _physics_process(delta: float) -> void:
	# Move in direction
	global_position += direction * speed * delta


func set_direction(dir: Vector2) -> void:
	"""Set projectile direction"""
	direction = dir.normalized()
	rotation = direction.angle()


func _on_body_entered(body: Node) -> void:
	"""Hit a body (player)"""
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Destroy projectile
	queue_free()


func _on_area_entered(area: Node) -> void:
	"""Hit an area (shields, etc.)"""
	# Check if it's a player shield
	if area.is_in_group("player_shield"):
		# Destroy projectile
		queue_free()


func _create_visual() -> void:
	"""Create projectile visual"""
	# Main projectile body
	var body = ColorRect.new()
	body.size = Vector2(16, 8)
	body.position = Vector2(-8, -4)
	body.color = Color(1.0, 0.5, 0.0)  # Orange
	add_child(body)

	# Glow trail
	var trail = ColorRect.new()
	trail.size = Vector2(8, 4)
	trail.position = Vector2(-12, -2)
	trail.color = Color(1.0, 0.8, 0.0, 0.5)  # Yellow glow
	add_child(trail)

	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(16, 8)
	collision_shape.shape = rect_shape
	add_child(collision_shape)
