extends Node

## Error Catcher
## Fängt kritische Fehler automatisch ab und loggt sie

# Aktiviere globales Error-Catching
var error_catching_active: bool = true


func _ready() -> void:
	print("[ErrorCatcher] Error Catcher gestartet")

	# Verbinde mit Godot's error handling
	if DebugLogger:
		DebugLogger.log_info("ErrorCatcher initialisiert")


# Wrapper-Funktionen zum sicheren Aufrufen von Code

func safe_call(object: Object, method: String, args: Array = []) -> Variant:
	"""Ruft eine Methode sicher auf und fängt Fehler ab"""
	if not is_instance_valid(object):
		if DebugLogger:
			DebugLogger.log_error("safe_call: Objekt ist ungültig")
		return null

	if not object.has_method(method):
		if DebugLogger:
			DebugLogger.log_error("safe_call: Methode '%s' existiert nicht auf %s" % [method, object.get_class()])
		return null

	# Versuche Aufruf
	var result = null
	if args.size() == 0:
		result = object.call(method)
	else:
		result = object.callv(method, args)

	return result


func safe_get(object: Object, property: String, default_value: Variant = null) -> Variant:
	"""Holt Property sicher und fängt Fehler ab"""
	if not is_instance_valid(object):
		if DebugLogger:
			DebugLogger.log_warning("safe_get: Objekt ist ungültig")
		return default_value

	if property not in object:
		if DebugLogger:
			DebugLogger.log_warning("safe_get: Property '%s' existiert nicht auf %s" % [property, object.get_class()])
		return default_value

	return object.get(property)


func safe_set(object: Object, property: String, value: Variant) -> bool:
	"""Setzt Property sicher und fängt Fehler ab"""
	if not is_instance_valid(object):
		if DebugLogger:
			DebugLogger.log_error("safe_set: Objekt ist ungültig")
		return false

	if property not in object:
		if DebugLogger:
			DebugLogger.log_error("safe_set: Property '%s' existiert nicht auf %s" % [property, object.get_class()])
		return false

	object.set(property, value)
	return true


func log_null_reference(context: String, object_name: String) -> void:
	"""Loggt Null-Reference-Fehler"""
	if DebugLogger:
		DebugLogger.log_error("NULL REFERENCE: %s - Objekt '%s' ist null" % [context, object_name])


func log_invalid_state(context: String, description: String) -> void:
	"""Loggt ungültige Zustände"""
	if DebugLogger:
		DebugLogger.log_error("INVALID STATE: %s - %s" % [context, description])


func log_crash_prevention(context: String, reason: String) -> void:
	"""Loggt verhinderte Crashes"""
	if DebugLogger:
		DebugLogger.log_critical("CRASH PREVENTED: %s - %s" % [context, reason])
