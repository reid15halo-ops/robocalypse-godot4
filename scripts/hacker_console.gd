extends Area2D

signal console_hacked(console: Node, mod_type: ModType, mod_scene_path: String)

var is_hacked: bool = false
var is_player_nearby: bool = false
var available_mods: Array[ModType] = []
var prompt_label: Label = null
var selection_layer: CanvasLayer = null

enum ModType {
	TURRET,
	BARRIER,
	HEALTH_STATION,
	DAMAGE_ZONE,
	SPEED_PAD
}

var mod_data: Dictionary = {
	ModType.TURRET: {
		"name": "Auto-Turret",
		"description": "Automatic defense turret",
		"scene": "res://scenes/map_mods/Turret.tscn",
		"color": Color(1, 0.3, 0)
	},
	ModType.BARRIER: {
		"name": "Energy Barrier",
		"description": "Blocks enemies",
		"scene": "res://scenes/map_mods/Barrier.tscn",
		"color": Color(0, 0.5, 1)
	},
	ModType.HEALTH_STATION: {
		"name": "Health Station",
		"description": "Heal 10 HP/s",
		"scene": "res://scenes/map_mods/HealthStation.tscn",
		"color": Color(0, 1, 0.3)
	},
	ModType.DAMAGE_ZONE: {
		"name": "Damage Field",
		"description": "15 DPS to enemies",
		"scene": "res://scenes/map_mods/DamageZone.tscn",
		"color": Color(1, 0, 0.3)
	},
	ModType.SPEED_PAD: {
		"name": "Speed Boost",
		"description": "+50% movement speed",
		"scene": "res://scenes/map_mods/SpeedPad.tscn",
		"color": Color(1, 1, 0)
	}
}


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_generate_mod_options()
	modulate = Color(0, 1, 1, 0.8)
	prompt_label = get_node_or_null("InteractionPrompt")
	if prompt_label:
		prompt_label.text = "[F] Hack Console"
		prompt_label.visible = false


func _generate_mod_options() -> void:
	var all_mods: Array[ModType] = [ModType.TURRET, ModType.BARRIER, ModType.HEALTH_STATION, ModType.DAMAGE_ZONE, ModType.SPEED_PAD]
	all_mods.shuffle()
	available_mods = all_mods.slice(0, 3)


func _process(_delta: float) -> void:
	if is_player_nearby and not is_hacked and Input.is_action_just_pressed("interact"):
		_show_mod_selection()


func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.get_player() or body.is_in_group("player"):
		is_player_nearby = true
		if not is_hacked:
			_show_interaction_prompt(true)


func _on_body_exited(body: Node2D) -> void:
	if body == GameManager.get_player() or body.is_in_group("player"):
		is_player_nearby = false
		_show_interaction_prompt(false)
		if selection_layer:
			_hide_selection_ui()


func _show_interaction_prompt(display: bool) -> void:
	if prompt_label:
		prompt_label.visible = display


func _show_mod_selection() -> void:
	if is_hacked or available_mods.is_empty():
		return
	if selection_layer:
		return

	_show_interaction_prompt(false)
	selection_layer = CanvasLayer.new()
	selection_layer.name = "HackerConsoleSelection"
	selection_layer.layer = 30

	var panel := PanelContainer.new()
	panel.name = "SelectionPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -160
	panel.offset_bottom = 160

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Hack Console"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 28)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose one system to deploy"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(subtitle)

	for mod_type in available_mods:
		var mod_info: Dictionary = mod_data.get(mod_type, {})
		if mod_info == null:
			continue
		var button := Button.new()
		button.text = "%s\n%s" % [mod_info.name, mod_info.description]
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override("font_color", mod_info.color)
		button.tooltip_text = mod_info.description
		button.pressed.connect(_on_mod_selected.bind(mod_type))
		vbox.add_child(button)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.focus_mode = Control.FOCUS_ALL
	cancel_button.pressed.connect(_on_selection_cancelled)
	vbox.add_child(cancel_button)

	selection_layer.add_child(panel)
	get_tree().root.add_child(selection_layer)

	# Focus the first option for keyboard/gamepad navigation
	for child in vbox.get_children():
		if child is Button:
			child.grab_focus()
			break


func apply_modification(mod_type: ModType) -> void:
	if is_hacked:
		return
	is_hacked = true
	modulate = Color(0.3, 0.3, 0.3)

	var mod_info: Dictionary = mod_data.get(mod_type, {})
	if mod_info.is_empty():
		return

	var mod_scene: PackedScene = load(mod_info.scene)
	if mod_scene:
		var modification := mod_scene.instantiate()
		if modification == null:
			push_warning("Failed to instantiate mod scene: %s" % mod_info.scene)
		elif modification is Node2D:
			var mod_node: Node2D = modification
			mod_node.global_position = global_position
			var parent: Node = get_parent()
			if parent:
				parent.call_deferred("add_child", mod_node)
		else:
			var parent: Node = get_parent()
			if parent:
				parent.call_deferred("add_child", modification)

	_show_interaction_prompt(false)
	is_player_nearby = false
	print("Console hacked! Spawned: ", mod_info.name)
	console_hacked.emit(self, mod_type, mod_info.scene)
	queue_free()


func _on_mod_selected(mod_type: ModType) -> void:
	_hide_selection_ui()
	apply_modification(mod_type)


func _on_selection_cancelled() -> void:
	_hide_selection_ui()
	if not is_hacked and is_instance_valid(self) and is_player_nearby:
		_show_interaction_prompt(true)


func _hide_selection_ui() -> void:
	if selection_layer and is_instance_valid(selection_layer):
		selection_layer.queue_free()
	selection_layer = null
