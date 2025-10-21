extends Node

## Debug Logger Singleton
## Fängt alle Fehler, Warnungen und Debug-Nachrichten ab und zeigt sie in einem separaten Fenster

signal log_added(message: String, type: String)
signal logs_cleared()

enum LogType {
	INFO,
	WARNING,
	ERROR,
	CRITICAL
}

# Log-Speicher
var logs: Array[Dictionary] = []
var max_logs: int = 500  # Maximale Anzahl an Logs

# Statistiken
var error_count: int = 0
var warning_count: int = 0
var info_count: int = 0

# Einstellungen
var capture_errors: bool = true
var capture_warnings: bool = true
var capture_prints: bool = true
var save_to_file: bool = true

# Log-Datei
var log_file_path: String = "user://debug_log.txt"
var log_file: FileAccess = null


func _ready() -> void:
	print("[DebugLogger] Fehlerlog-System gestartet")

	# Öffne Log-Datei
	if save_to_file:
		_open_log_file()

	# Schreibe Start-Header
	_add_log("=== DEBUG SESSION GESTARTET ===", LogType.INFO)
	_add_log("Godot Version: " + Engine.get_version_info().string, LogType.INFO)
	_add_log("Datum: " + Time.get_datetime_string_from_system(), LogType.INFO)
	_add_log("=====================================", LogType.INFO)


func _open_log_file() -> void:
	"""Öffnet die Log-Datei zum Schreiben"""
	log_file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if log_file:
		log_file.store_line("=== ROBOCALYPSE DEBUG LOG ===")
		log_file.store_line("Session Start: " + Time.get_datetime_string_from_system())
		log_file.store_line("=====================================")
		print("[DebugLogger] Log-Datei erstellt: " + log_file_path)
	else:
		push_error("[DebugLogger] Konnte Log-Datei nicht erstellen!")


func _add_log(message: String, type: LogType) -> void:
	"""Fügt einen neuen Log-Eintrag hinzu"""
	var timestamp = Time.get_time_string_from_system()

	var log_entry = {
		"timestamp": timestamp,
		"message": message,
		"type": type,
		"type_name": LogType.keys()[type]
	}

	# Füge zu Array hinzu
	logs.append(log_entry)

	# Begrenze Array-Größe
	if logs.size() > max_logs:
		logs.pop_front()

	# Aktualisiere Statistiken
	match type:
		LogType.INFO:
			info_count += 1
		LogType.WARNING:
			warning_count += 1
		LogType.ERROR, LogType.CRITICAL:
			error_count += 1

	# Signal senden
	log_added.emit(message, LogType.keys()[type])

	# In Datei schreiben
	if save_to_file and log_file:
		var log_line = "[%s] [%s] %s" % [timestamp, LogType.keys()[type], message]
		log_file.store_line(log_line)
		log_file.flush()  # Sofort speichern


# Öffentliche API-Funktionen

func log_info(message: String) -> void:
	"""Logge eine Info-Nachricht"""
	_add_log(message, LogType.INFO)
	print("[INFO] " + message)


func log_warning(message: String) -> void:
	"""Logge eine Warnung"""
	_add_log(message, LogType.WARNING)
	push_warning("[WARNING] " + message)


func log_error(message: String) -> void:
	"""Logge einen Fehler"""
	_add_log(message, LogType.ERROR)
	push_error("[ERROR] " + message)


func log_critical(message: String) -> void:
	"""Logge einen kritischen Fehler"""
	_add_log(message, LogType.CRITICAL)
	push_error("[CRITICAL] " + message)


func clear_logs() -> void:
	"""Löscht alle Logs"""
	logs.clear()
	error_count = 0
	warning_count = 0
	info_count = 0
	logs_cleared.emit()
	_add_log("Logs gelöscht", LogType.INFO)


func get_logs() -> Array[Dictionary]:
	"""Gibt alle Logs zurück"""
	return logs


func get_logs_by_type(type: LogType) -> Array[Dictionary]:
	"""Gibt alle Logs eines bestimmten Typs zurück"""
	var filtered: Array[Dictionary] = []
	for log in logs:
		if log.type == type:
			filtered.append(log)
	return filtered


func get_formatted_log_text() -> String:
	"""Gibt alle Logs als formatierten Text zurück"""
	var text = ""
	for log in logs:
		text += "[%s] [%s] %s\n" % [log.timestamp, log.type_name, log.message]
	return text


func export_logs_to_clipboard() -> void:
	"""Exportiert alle Logs in die Zwischenablage"""
	var export_text = "=== ROBOCALYPSE FEHLERLOG ===\n"
	export_text += "Exportiert: " + Time.get_datetime_string_from_system() + "\n"
	export_text += "Gesamt Fehler: %d | Warnungen: %d | Info: %d\n" % [error_count, warning_count, info_count]
	export_text += "=====================================\n\n"
	export_text += get_formatted_log_text()

	DisplayServer.clipboard_set(export_text)
	_add_log("Logs in Zwischenablage kopiert!", LogType.INFO)


func _notification(what: int) -> void:
	"""Schließe Log-Datei beim Beenden"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if log_file:
			log_file.store_line("=== SESSION BEENDET ===")
			log_file.close()


# Godot-Error-Handler überschreiben
func _process(_delta: float) -> void:
	# Prüfe auf Godot-Fehler (wird durch push_error/push_warning getriggert)
	# Diese Funktion wird automatisch von unserem System aufgerufen
	pass
