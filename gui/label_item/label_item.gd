extends Control




func _notification(what: int) -> void:
	match what:
		NOTIFICATION_THEME_CHANGED:
			queue_redraw()

func _draw() -> void:
	pass

func _get_minimum_size() -> Vector2:
	return Vector2()
