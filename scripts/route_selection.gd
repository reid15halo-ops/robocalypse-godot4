extends Control

@onready var title_label: Label = $Container/TitleLabel
@onready var instruction_label: Label = $Container/InstructionLabel
@onready var up_label: Label = $Container/DirectionLabels/UpLabel
@onready var down_label: Label = $Container/DirectionLabels/DownLabel
@onready var right_label: Label = $Container/DirectionLabels/RightLabel


func show_selection(wave_number: int, direction_labels: Dictionary) -> void:
	title_label.text = "WAVE " + str(wave_number) + ": PFAD AUSWAEHLEN"
	instruction_label.text = "Laufe zu einem farbigen Pfeil (NORD, SUED, OST), um die Route zu aktivieren."

	up_label.text = direction_labels.get("up", "NORD (GRUEN) - SKYWARD RUSH [leicht]")
	down_label.text = direction_labels.get("down", "SUED (GELB) - STORMFRONT [mittel]")
	right_label.text = direction_labels.get("right", "OST (ROT) - EMP OVERLOAD [schwer]")

	modulate.a = 0.0
	visible = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)


func hide_selection() -> void:
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await fade_tween.finished
	visible = false
