extends Label

signal pressed
signal close_pressed

var tab : TrackList:
	set(value):
		if is_instance_valid(tab):
			tab.visibility_changed.disconnect(_update_color)
		
		tab = value
		
		if tab:
			tab.visibility_changed.connect(_update_color)
		_update_color()

@export
var font_color : Color
@export
var font_color_hover : Color
@export
var font_color_enabled : Color

var _click_holded : bool


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER, NOTIFICATION_MOUSE_EXIT:
			_update_color()
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_ENTER_TREE, NOTIFICATION_EXIT_TREE:
			_click_holded = false
			_update_color()
		NOTIFICATION_DRAG_BEGIN, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_click_holded = false

func _input(event: InputEvent) -> void:
	if _click_holded:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not event.is_pressed():
					accept_event()
					_click_holded = false
					if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
						pressed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.is_echo():
			if event.is_pressed():
				if event.button_index == MOUSE_BUTTON_LEFT:
					accept_event()
					_click_holded = true
				elif event.button_index == MOUSE_BUTTON_MIDDLE:
					accept_event()
					_click_holded = false
					close_pressed.emit()
			
			else:
				if _click_holded:
					if event.button_index == MOUSE_BUTTON_LEFT:
						accept_event()
						_click_holded = false
						if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
							pressed.emit()

func _update_color() -> void:
	if not is_inside_tree():
		return
	
	if is_instance_valid(tab) and tab.visible:
		add_theme_color_override('font_color', font_color_enabled)
	else:
		if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
			add_theme_color_override('font_color', font_color_hover)
		else:
			add_theme_color_override('font_color', font_color)
