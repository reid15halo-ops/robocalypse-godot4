extends Control

## Displays active route affixes in the HUD with cycling animation

# Affix Types (same as AffixManager.gd)
enum AffixType {
	# Green Route Affixes (Mobility/Movement)
	JUMPPADS,
	TELEPORT_PORTALS,
	UPDRAFTS,
	SMOKE_CLOUDS,

	# Yellow Route Affixes (Electrical Hazards)
	SWAMP_ZONES,
	ACID_RAIN,
	LIGHTNING_BOLTS,
	STATIC_FIELD,

	# Red Route Affixes (Chaos/Disruption)
	EMP_STORMS,
	RANDOM_LIGHTNING,
	MAGNETIC_PULSE,
	TESLA_GRID
}

@onready var affix_icon: ColorRect = $ContentContainer/IconContainer/AffixIcon
@onready var affix_title: Label = $ContentContainer/LabelsContainer/AffixTitle
@onready var affix_description: Label = $ContentContainer/LabelsContainer/AffixDescription
@onready var border: ColorRect = $Border

var active_affixes: Array = []
var current_index: int = 0
var cycle_timer: float = 0.0
const CYCLE_INTERVAL: float = 3.0  # Seconds between affix changes

func _ready() -> void:
	modulate.a = 0.0  # Start invisible
	visible = false

func _process(delta: float) -> void:
	if active_affixes.size() > 1:
		cycle_timer += delta
		if cycle_timer >= CYCLE_INTERVAL:
			cycle_timer = 0.0
			_cycle_to_next_affix()

func update_affixes(affixes) -> void:
	"""Called when route is selected to display active affixes"""
	if typeof(affixes) == TYPE_DICTIONARY:
		affixes = (affixes as Dictionary).keys()
	active_affixes = affixes

	if affixes.is_empty():
		_hide_indicator()
		return

	current_index = 0
	_display_affix(affixes[0])
	_show_indicator()

func _display_affix(affix: int) -> void:
	"""Display a specific affix with info"""
	var info = _get_affix_info(affix)

	affix_title.text = info.name
	affix_description.text = info.description
	affix_icon.color = info.color
	border.color = info.color

func _cycle_to_next_affix() -> void:
	"""Fade out, switch affix, fade in"""
	if active_affixes.size() <= 1:
		return

	# Fade out
	var tween_out = create_tween()
	tween_out.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween_out.finished

	# Switch to next affix
	current_index = (current_index + 1) % active_affixes.size()
	_display_affix(active_affixes[current_index])

	# Fade in
	var tween_in = create_tween()
	tween_in.tween_property(self, "modulate:a", 1.0, 0.3)

func _show_indicator() -> void:
	"""Fade in the indicator"""
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _hide_indicator() -> void:
	"""Fade out the indicator"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	visible = false

func _get_affix_info(affix: int) -> Dictionary:
	"""Return name, description, and color for each affix type"""
	match affix:
		# Green Route - SKYWARD_RUSH
		AffixType.JUMPPADS:
			return {
				"name": "JUMP PADS",
				"description": "Bounce pads appear across the arena for aerial mobility",
				"color": Color(0.2, 1, 0.3)
			}
		AffixType.TELEPORT_PORTALS:
			return {
				"name": "TELEPORT PORTALS",
				"description": "Portals allow instant travel across the battlefield",
				"color": Color(0.2, 1, 0.3)
			}
		AffixType.UPDRAFTS:
			return {
				"name": "UPDRAFTS",
				"description": "Wind currents boost aerial shots and movement",
				"color": Color(0.2, 1, 0.3)
			}
		AffixType.SMOKE_CLOUDS:
			return {
				"name": "SMOKE CLOUDS",
				"description": "Enemies drop smoke bombs that obscure vision",
				"color": Color(0.2, 1, 0.3)
			}

		# Yellow Route - STORMFRONT
		AffixType.SWAMP_ZONES:
			return {
				"name": "SWAMP ZONES",
				"description": "Muddy areas slow movement but trap enemies",
				"color": Color(1, 0.9, 0)
			}
		AffixType.ACID_RAIN:
			return {
				"name": "ACID RAIN",
				"description": "Periodic acid rain damages all entities",
				"color": Color(1, 0.9, 0)
			}
		AffixType.LIGHTNING_BOLTS:
			return {
				"name": "LIGHTNING BOLTS",
				"description": "Lightning strikes random targets periodically",
				"color": Color(1, 0.9, 0)
			}
		AffixType.STATIC_FIELD:
			return {
				"name": "STATIC FIELD",
				"description": "Electric fields form around combat zones",
				"color": Color(1, 0.9, 0)
			}

		# Red Route - EMP_OVERLOAD
		AffixType.EMP_STORMS:
			return {
				"name": "EMP STORMS",
				"description": "EMP pulses disable abilities temporarily",
				"color": Color(1, 0.2, 0.2)
			}
		AffixType.RANDOM_LIGHTNING:
			return {
				"name": "RANDOM LIGHTNING",
				"description": "Chaotic lightning strikes unpredictably",
				"color": Color(1, 0.2, 0.2)
			}
		AffixType.MAGNETIC_PULSE:
			return {
				"name": "MAGNETIC PULSE",
				"description": "Magnetic forces pull projectiles off course",
				"color": Color(1, 0.2, 0.2)
			}
		AffixType.TESLA_GRID:
			return {
				"name": "TESLA GRID",
				"description": "Tesla coils create persistent damage zones",
				"color": Color(1, 0.2, 0.2)
			}
		_:
			return {
				"name": "UNKNOWN EFFECT",
				"description": "Unknown environmental modifier",
				"color": Color(0.5, 0.5, 0.5)
			}
