extends Control

# Ability HUD - Shows Q, W, E, R abilities with cooldown timers and mana

# Ability display containers
var ability_displays: Dictionary = {}

# Colors
var COLOR_READY = Color(0.2, 0.8, 0.2, 0.9)
var COLOR_COOLDOWN = Color(0.2, 0.2, 0.2, 0.9)
var COLOR_LOCKED = Color(0.1, 0.1, 0.1, 0.9)
var COLOR_NO_MANA = Color(0.8, 0.2, 0.2, 0.9)

# Mana bar
var mana_bar: ProgressBar
var mana_label: Label


func _ready() -> void:
	# Position at bottom center
	position = Vector2(470, 620)
	size = Vector2(340, 100)

	# Create abilities display
	_create_ability_displays()

	# Create mana bar
	_create_mana_bar()

	# Connect to AbilitySystem signals
	AbilitySystem.ability_used.connect(_on_ability_used)
	AbilitySystem.mana_changed.connect(_on_mana_changed)


func _create_ability_displays() -> void:
	"""Create visual displays for Q, E, R (W removed)"""
	var slots = ["Q", "E", "R"]
	var x_offset = 0

	for slot in slots:
		var container = PanelContainer.new()
		container.position = Vector2(x_offset, 0)
		container.custom_minimum_size = Vector2(75, 75)
		add_child(container)

		# Background panel style
		var style = StyleBoxFlat.new()
		style.bg_color = COLOR_LOCKED
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.5, 0.5)
		container.add_theme_stylebox_override("panel", style)

		# VBox for content
		var vbox = VBoxContainer.new()
		container.add_child(vbox)

		# Hotkey label (Q, W, E, R)
		var key_label = Label.new()
		key_label.text = slot
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 24)
		key_label.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(key_label)

		# Ability name label
		var name_label = Label.new()
		name_label.text = "LOCKED"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color.GRAY)
		vbox.add_child(name_label)

		# Cooldown label
		var cd_label = Label.new()
		cd_label.text = ""
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_label.add_theme_font_size_override("font_size", 16)
		cd_label.add_theme_color_override("font_color", Color.YELLOW)
		vbox.add_child(cd_label)

		# Store references
		ability_displays[slot] = {
			"container": container,
			"style": style,
			"key_label": key_label,
			"name_label": name_label,
			"cd_label": cd_label
		}

		x_offset += 85


func _create_mana_bar() -> void:
	"""Create mana bar display"""
	var mana_container = VBoxContainer.new()
	mana_container.position = Vector2(0, 80)
	mana_container.size = Vector2(340, 20)
	add_child(mana_container)

	# Mana label
	mana_label = Label.new()
	mana_label.text = "MANA: 100 / 100"
	mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mana_label.add_theme_font_size_override("font_size", 12)
	mana_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	mana_container.add_child(mana_label)

	# Mana progress bar
	mana_bar = ProgressBar.new()
	mana_bar.custom_minimum_size = Vector2(340, 12)
	mana_bar.max_value = 100
	mana_bar.value = 100
	mana_bar.show_percentage = false
	mana_container.add_child(mana_bar)

	# Style mana bar
	var mana_style = StyleBoxFlat.new()
	mana_style.bg_color = Color(0.1, 0.3, 0.6)
	mana_bar.add_theme_stylebox_override("fill", mana_style)


func _process(_delta: float) -> void:
	"""Update ability displays"""
	_update_ability_displays()


func _update_ability_displays() -> void:
	"""Update all ability displays with current state"""
	for slot in ["Q", "E", "R"]:
		var display = ability_displays[slot]
		var ability = AbilitySystem.ability_slots.get(slot)

		if not ability:
			# Ability not unlocked
			display.style.bg_color = COLOR_LOCKED
			display.name_label.text = "LOCKED"
			display.cd_label.text = ""
			continue

		# Ability is unlocked - show name
		display.name_label.text = ability.name.substr(0, 8)  # Truncate long names

		# Check cooldown
		var cd_remaining = AbilitySystem.get_cooldown_remaining(slot)

		if cd_remaining > 0:
			# On cooldown
			display.style.bg_color = COLOR_COOLDOWN
			display.cd_label.text = str(ceil(cd_remaining))
		else:
			# Check mana
			if AbilitySystem.current_mana >= ability.mana_cost:
				# Ready to use
				display.style.bg_color = COLOR_READY
				display.cd_label.text = "READY"
			else:
				# Not enough mana
				display.style.bg_color = COLOR_NO_MANA
				display.cd_label.text = "NO MANA"


func _on_ability_used(slot: String) -> void:
	"""Visual feedback when ability is used"""
	if not ability_displays.has(slot):
		return

	var display = ability_displays[slot]

	# Flash effect
	display.style.bg_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(display.container):
		display.style.bg_color = COLOR_COOLDOWN


func _on_mana_changed(current: int, max_val: int) -> void:
	"""Update mana bar"""
	if mana_bar:
		mana_bar.max_value = max_val
		mana_bar.value = current

	if mana_label:
		mana_label.text = "MANA: " + str(current) + " / " + str(max_val)
