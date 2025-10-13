extends Area2D

@export var route: GameManager.RouteModifier = GameManager.RouteModifier.SKYWARD_RUSH

var game: Node = null


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var player = GameManager.get_player()
	if player and body == player and game and game.has_method("handle_route_portal_selection"):
		game.handle_route_portal_selection(route)
