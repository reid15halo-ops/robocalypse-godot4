extends Area2D

@export var amount: int = 5
@export var magnet_radius: float = 220.0
@export var pickup_radius: float = 26.0
@export var max_speed: float = 500.0
@export var acceleration: float = 900.0

var game: Node = null
var player: CharacterBody2D = null
var velocity: Vector2 = Vector2.ZERO
var bob_phase: float = randf() * TAU
var bob_speed: float = 2.5
var bob_height: float = 6.0

@onready var visual: Node2D = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D
var pickup_radius_squared: float = 0.0
var magnet_radius_squared: float = 0.0


func _ready() -> void:
	monitoring = true
	collision_layer = 8  # Items
	collision_mask = 1   # Player

	player = GameManager.get_player()
	pickup_radius_squared = pickup_radius * pickup_radius
	magnet_radius_squared = magnet_radius * magnet_radius

	if collision and collision.shape is CircleShape2D:
		collision.shape.radius = pickup_radius

	body_entered.connect(_on_body_entered)
	_scale_pop_in()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = GameManager.get_player()
		if not player:
			return

	var to_player := player.global_position - global_position
	var distance_squared := to_player.length_squared()

	if distance_squared <= magnet_radius_squared:
		var distance := sqrt(distance_squared)
		var direction := Vector2.ZERO
		if distance > 0.0:
			direction = to_player / distance
		var target_velocity := direction * max_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		global_position += velocity * delta
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * 0.5 * delta)

	_apply_bobbing(delta)

	if distance_squared <= pickup_radius_squared:
		_collect()


func _on_body_entered(body: Node) -> void:
	if body == GameManager.get_player():
		_collect()


func _collect() -> void:
	if game and game.has_method("on_scrap_collected"):
		game.on_scrap_collected(amount)
	elif game and game.has_method("add_scrap"):
		game.add_scrap(amount)
	queue_free()


func _apply_bobbing(delta: float) -> void:
	bob_phase = fmod(bob_phase + bob_speed * delta, TAU)
	if visual:
		visual.position.y = sin(bob_phase) * bob_height
		visual.rotation += delta * 1.0


func _scale_pop_in() -> void:
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
