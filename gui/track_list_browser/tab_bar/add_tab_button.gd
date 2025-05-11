@tool
extends Control

signal pressed

#func _notification(what: int) -> void:
	#match what:
		#NOTIFICATION_MOUSE_ENTER, NOTIFICATION_MOUSE_EXIT:
			#_update_label_color()
		#NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_ENTER_TREE, NOTIFICATION_EXIT_TREE:
			#if _click_holded:
				#_click_holded = false
		#NOTIFICATION_DRAG_BEGIN, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT:
			#_click_holded = false
#
#func _input(event: InputEvent) -> void:
	#if _click_holded:
		#if event is InputEventMouseButton:
			#if event.button_index == MOUSE_BUTTON_LEFT:
				#if not event.is_pressed():
					#accept_event()
					#_click_holded = false
#
#func _gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if not event.is_echo():
			#if event.is_pressed():
				#if event.button_index == MOUSE_BUTTON_LEFT:
					#_click_holded = true
					#accept_event()
			#
			#else:
				#if _click_holded:
					#if event.button_index == MOUSE_BUTTON_LEFT:
						#_click_holded = false
						#accept_event()
						#if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
							#pressed.emit()

func _ready() -> void:
	%Button.set_drag_forwarding(button_get_grag_data, Callable(), Callable())
	%Button.pressed.connect(pressed.emit)

func button_get_grag_data(_pos = null) -> Variant:
	return true

func _get_minimum_size() -> Vector2:
	var height : float = %Button.get_minimum_size().y
	%Button.custom_minimum_size.x = height
	return Vector2(height, height)
