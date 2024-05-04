class_name Header
extends Button
## Header

signal close_pressed

var list : TrackList:
	set(value):
		if value != list:
			if list:
				list.visible_name_changed.disconnect(set_title)
			
			list = value
			
			if list:
				list.visible_name_changed.connect(set_title)
				set_title(list.visible_name)
	get:
		if is_instance_valid(list):
			return list
		else:
			return null


func _init() -> void:
	flat = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR

func _gui_input(event: InputEvent) -> void:
	if not event.is_echo():
		if event is InputEventMouseButton:
			if not event.is_pressed():
				if Rect2(Vector2(), size).has_point(event.position):
					if event.button_index == MOUSE_BUTTON_MIDDLE:
						close_pressed.emit()

func set_title(value : String) -> void:
	if not value:
		value = 'No name.'
	if value != text:
		text = value
