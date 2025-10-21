extends CanvasLayer

## Debug Log Window
## Zeigt alle Debug-Logs in einem separaten Fenster an

@onready var window_panel: Panel = $WindowPanel
@onready var log_text: RichTextLabel = $WindowPanel/VBoxContainer/LogText
@onready var error_count_label: Label = $WindowPanel/VBoxContainer/TopBar/ErrorCount
@onready var warning_count_label: Label = $WindowPanel/VBoxContainer/TopBar/WarningCount
@onready var info_count_label: Label = $WindowPanel/VBoxContainer/TopBar/InfoCount
@onready var clear_button: Button = $WindowPanel/VBoxContainer/BottomBar/ClearButton
@onready var copy_button: Button = $WindowPanel/VBoxContainer/BottomBar/CopyButton
@onready var close_button: Button = $WindowPanel/VBoxContainer/BottomBar/CloseButton
@onready var auto_scroll_check: CheckBox = $WindowPanel/VBoxContainer/BottomBar/AutoScrollCheck

# Einstellungen
var auto_scroll: bool = true
var window_visible: bool = true

# Farben für Log-Typen
var color_info: Color = Color(0.7, 0.7, 0.7)
var color_warning: Color = Color(1.0, 0.8, 0.0)
var color_error: Color = Color(1.0, 0.3, 0.3)
var color_critical: Color = Color(1.0, 0.0, 0.0)


func _ready() -> void:
	# Verbinde mit DebugLogger-Signalen
	if DebugLogger:
		DebugLogger.log_added.connect(_on_log_added)
		DebugLogger.logs_cleared.connect(_on_logs_cleared)

	# Verbinde UI-Buttons
	clear_button.pressed.connect(_on_clear_pressed)
	copy_button.pressed.connect(_on_copy_pressed)
	close_button.pressed.connect(_on_close_pressed)
	auto_scroll_check.toggled.connect(_on_auto_scroll_toggled)

	# Initialisierung
	auto_scroll_check.button_pressed = auto_scroll
	_update_statistics()

	# Lade existierende Logs
	_load_existing_logs()

	print("[DebugLogWindow] Fehlerlog-Fenster initialisiert")


func _load_existing_logs() -> void:
	"""Lade alle existierenden Logs aus dem DebugLogger"""
	if not DebugLogger:
		return

	var logs = DebugLogger.get_logs()
	for log in logs:
		_add_log_to_display(log.timestamp, log.message, log.type_name)


func _on_log_added(message: String, type_name: String) -> void:
	"""Wird aufgerufen wenn ein neuer Log hinzugefügt wird"""
	var timestamp = Time.get_time_string_from_system()
	_add_log_to_display(timestamp, message, type_name)
	_update_statistics()


func _add_log_to_display(timestamp: String, message: String, type_name: String) -> void:
	"""Fügt einen Log-Eintrag zum Display hinzu"""
	var color: Color

	match type_name:
		"INFO":
			color = color_info
		"WARNING":
			color = color_warning
		"ERROR":
			color = color_error
		"CRITICAL":
			color = color_critical
		_:
			color = color_info

	# Formatiere Log-Eintrag
	log_text.append_text("[color=#%s][%s] [%s] %s[/color]\n" % [
		color.to_html(false),
		timestamp,
		type_name,
		message
	])

	# Auto-Scroll
	if auto_scroll:
		await get_tree().process_frame
		log_text.scroll_to_line(log_text.get_line_count())


func _update_statistics() -> void:
	"""Aktualisiert die Statistik-Labels"""
	if not DebugLogger:
		return

	error_count_label.text = "Fehler: %d" % DebugLogger.error_count
	warning_count_label.text = "Warnungen: %d" % DebugLogger.warning_count
	info_count_label.text = "Info: %d" % DebugLogger.info_count

	# Färbe Error-Count rot wenn Fehler vorhanden
	if DebugLogger.error_count > 0:
		error_count_label.add_theme_color_override("font_color", Color.RED)
	else:
		error_count_label.add_theme_color_override("font_color", Color.WHITE)


func _on_logs_cleared() -> void:
	"""Wird aufgerufen wenn Logs gelöscht werden"""
	log_text.clear()
	_update_statistics()


func _on_clear_pressed() -> void:
	"""Clear-Button gedrückt"""
	if DebugLogger:
		DebugLogger.clear_logs()


func _on_copy_pressed() -> void:
	"""Copy-Button gedrückt - Kopiert Logs in Zwischenablage"""
	if DebugLogger:
		DebugLogger.export_logs_to_clipboard()
		_show_notification("Logs in Zwischenablage kopiert!")


func _on_close_pressed() -> void:
	"""Close-Button gedrückt - Versteckt Fenster"""
	window_visible = false
	window_panel.visible = false


func _on_auto_scroll_toggled(button_pressed: bool) -> void:
	"""Auto-Scroll CheckBox geändert"""
	auto_scroll = button_pressed


func _show_notification(text: String) -> void:
	"""Zeigt eine kurze Benachrichtigung"""
	var notification = Label.new()
	notification.text = text
	notification.position = Vector2(window_panel.position.x + 10, window_panel.position.y - 30)
	notification.add_theme_color_override("font_color", Color.GREEN)
	add_child(notification)

	# Fade out
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notification.queue_free)


func _input(event: InputEvent) -> void:
	"""Toggle-Fenster mit F3"""
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		window_visible = not window_visible
		window_panel.visible = window_visible


func toggle_window() -> void:
	"""Öffentliche Funktion zum Togglen des Fensters"""
	window_visible = not window_visible
	window_panel.visible = window_visible
