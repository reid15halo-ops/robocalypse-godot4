extends Control

## AdminTool - Lightweight in-game cheat interface (toggle with F1)

const PANEL_WIDTH := 320

var game_scene: Node = null
var player: Node = null

var status_label: Label = null
var item_dropdown: OptionButton = null
var item_ids: Array[String] = []
var invulnerability_enabled: bool = false
var invulnerability_button: Button = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	visible = false

	game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene:
		player = game_scene.get_node_or_null("Player")

	_build_ui()
	_populate_item_dropdown()
	set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_toggle_visibility()
		get_viewport().set_input_as_handled()


func _toggle_visibility() -> void:
	visible = not visible
	if visible and status_label:
		status_label.text = "Admin panel active"


func _process(_delta: float) -> void:
	if invulnerability_enabled:
		if (not player or not is_instance_valid(player)) and game_scene:
			player = game_scene.get_node_or_null("Player")
		if player and is_instance_valid(player):
			player.invulnerable = true
			player.invulnerability_timer = max(player.invulnerability_timer, player.invulnerability_time)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "AdminPanel"
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(20, 80)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "Content"
	vbox.custom_minimum_size = Vector2(PANEL_WIDTH - 24, 0)
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "Admin Tools (F1 to toggle)"
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)

	var scrap_box := HBoxContainer.new()
	scrap_box.add_theme_constant_override("separation", 6)
	vbox.add_child(scrap_box)

	var scrap100 := Button.new()
	scrap100.text = "+100 Scrap"
	scrap100.pressed.connect(func(): _grant_scrap(100))
	scrap_box.add_child(scrap100)

	var scrap1k := Button.new()
	scrap1k.text = "+1000 Scrap"
	scrap1k.pressed.connect(func(): _grant_scrap(1000))
	scrap_box.add_child(scrap1k)

	var heal_button := Button.new()
	heal_button.text = "Full Heal"
	heal_button.pressed.connect(_heal_player)
	vbox.add_child(heal_button)

	invulnerability_button = Button.new()
	invulnerability_button.text = "Enable Invulnerability"
	invulnerability_button.pressed.connect(_toggle_invulnerability)
	vbox.add_child(invulnerability_button)

	var random_item_btn := Button.new()
	random_item_btn.text = "Random Item"
	random_item_btn.pressed.connect(_grant_random_item)
	vbox.add_child(random_item_btn)

	item_dropdown = OptionButton.new()
	item_dropdown.name = "ItemDropdown"
	item_dropdown.focus_mode = Control.FOCUS_ALL
	item_dropdown.custom_minimum_size = Vector2(PANEL_WIDTH - 24, 0)
	vbox.add_child(item_dropdown)

	var give_item_btn := Button.new()
	give_item_btn.text = "Give Selected Item"
	give_item_btn.pressed.connect(_grant_selected_item)
	vbox.add_child(give_item_btn)

	var ability_btn := Button.new()
	ability_btn.text = "Unlock Abilities"
	ability_btn.pressed.connect(_unlock_all_abilities)
	vbox.add_child(ability_btn)

	var drone_btn := Button.new()
	drone_btn.text = "Spawn Hacker Drone"
	drone_btn.pressed.connect(_spawn_hacker_drone)
	vbox.add_child(drone_btn)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.text = "Admin panel ready"
	vbox.add_child(status_label)


func _populate_item_dropdown() -> void:
	if not item_dropdown:
		return

	item_dropdown.clear()
	item_ids.clear()

	if not ItemDatabase:
		return

	var all_items = ItemDatabase.items
	for item in all_items:
		item_dropdown.add_item("%s (%s)" % [item.name, item.id])
		item_dropdown.set_item_metadata(item_dropdown.item_count - 1, item.id)
		item_ids.append(item.id)

	if item_dropdown.item_count > 0:
		item_dropdown.select(0)


func _grant_scrap(amount: int) -> void:
	if not game_scene:
		_update_status("No game scene available")
		return

	game_scene.add_scrap(amount)
	_update_status("Added %d scrap" % amount)


func _heal_player() -> void:
	if not player:
		player = game_scene.get_node_or_null("Player") if game_scene else null

	if player and player.has_method("heal"):
		var to_full = player.max_health - player.current_health
		player.heal(player.max_health)
		_update_status("Player healed (%d HP)" % to_full)
	else:
		_update_status("Player not found or no heal method")


func _grant_random_item() -> void:
	if not game_scene:
		_update_status("No game scene available")
		return

	var picks = ItemDatabase.get_random_items(1)
	if picks.is_empty():
		_update_status("No items available")
		return

	var item = picks[0]
	if game_scene.admin_grant_item(item.id):
		_update_status("Granted random item: %s" % item.name)
	else:
		_update_status("Failed to grant item %s" % item.id)


func _grant_selected_item() -> void:
	if not game_scene or not item_dropdown or item_dropdown.selected < 0:
		_update_status("Select an item first")
		return

	var item_id = item_dropdown.get_item_metadata(item_dropdown.selected)
	if not item_id:
		_update_status("Invalid item selection")
		return

	if game_scene.admin_grant_item(item_id):
		_update_status("Granted item: %s" % item_id)
	else:
		_update_status("Item '%s' not found" % item_id)


func _unlock_all_abilities() -> void:
	if not AbilitySystem:
		_update_status("AbilitySystem unavailable")
		return

	for ability in AbilitySystem.abilities_database:
		AbilitySystem.equip_ability(ability.id, ability.keybind)

	AbilitySystem.mana_changed.emit(AbilitySystem.current_mana, AbilitySystem.max_mana)
	_update_status("All abilities equipped")


func _spawn_hacker_drone() -> void:
	if not game_scene:
		_update_status("No game scene available")
		return

	if game_scene.has_method("_spawn_hacker_drone"):
		game_scene._spawn_hacker_drone()
		_update_status("Spawned Hacker drone")
	else:
		_update_status("Drone spawn not available")


func _toggle_invulnerability() -> void:
	if (not player or not is_instance_valid(player)) and game_scene:
		player = game_scene.get_node_or_null("Player")

	if not player or not is_instance_valid(player):
		_update_status("Player not found")
		return

	invulnerability_enabled = not invulnerability_enabled

	if invulnerability_enabled:
		player.invulnerable = true
		player.invulnerability_timer = max(player.invulnerability_timer, player.invulnerability_time)
		player.set_meta("admin_invulnerability", true)
		if invulnerability_button:
			invulnerability_button.text = "Disable Invulnerability"
		_update_status("Invulnerability enabled")
	else:
		player.set_meta("admin_invulnerability", false)
		player.invulnerable = false
		player.invulnerability_timer = 0.0
		if invulnerability_button:
			invulnerability_button.text = "Enable Invulnerability"
		if is_instance_valid(player):
			player.modulate = Color.WHITE
		_update_status("Invulnerability disabled")


func _update_status(text: String) -> void:
	if status_label:
		status_label.text = text
