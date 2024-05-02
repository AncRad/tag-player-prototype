#class_name Header
extends Button

var list : TrackList:
	set(value):
		if value != list:
			if list:
				list.visible_name_changed.disconnect(set_visible_name)
			if value:
				value.visible_name_changed.connect(set_visible_name)
				set_visible_name(value.get_visible_name())
			
			list = value


func _init(p_list : TrackList) -> void:
	list = p_list
	flat = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR

func _gui_input(event: InputEvent) -> void:
	if not event.is_echo():
		if event is InputEventMouseButton:
			if not event.is_pressed():
				if Rect2(Vector2(), size).has_point(event.position):
					if event.button_index == MOUSE_BUTTON_MIDDLE:
						if list:
							list.queue_free()

func _pressed() -> void:
	list.visible = true

func _get_drag_data(_at_position: Vector2) -> Variant:
	if list:
		return list._get_drag_data(Vector2.INF)
	return

func set_visible_name(value : String) -> void:
	if not value:
		value = 'No name.'
	if value != text:
		text = value
