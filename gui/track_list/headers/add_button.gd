@tool
extends Control


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			custom_minimum_size.x = size.y

func _init() -> void:
	if not resized.is_connected(_on_resied):
		resized.connect(_on_resied)

func _on_resied() -> void:
	custom_minimum_size.x = size.y

