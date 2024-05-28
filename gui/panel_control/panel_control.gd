@tool
extends BoxContainer

var mode : int:
	set(_value):
		if vertical:
			mode = Vector2.AXIS_Y
		else:
			mode = Vector2.AXIS_X

var modea : int:
	set(_value):
		if vertical:
			modea = Vector2.AXIS_X
		else:
			modea = Vector2.AXIS_Y

var _separator_grabbed : int = -1:
	set(value):
		if value != _separator_grabbed:
			_separator_grabbed = value
			if _separator_grabbed >= 0:
				mouse_default_cursor_shape = Vector2i(Control.CURSOR_HSPLIT, Control.CURSOR_VSPLIT)[mode]
			else:
				mouse_default_cursor_shape = Control.CURSOR_ARROW

var _separator_grabbed_offset : float = 0

var _collapsed := {}

var _input_rect : Control
var _corner : int = -1


func _init() -> void:
	mode = mode
	modea = modea
	_input_rect = ReferenceRect.new()
	_input_rect.top_level = true
	_input_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_input_rect.mouse_force_pass_scroll_events = true
	_input_rect.mouse_default_cursor_shape = Control.CURSOR_CROSS
	_input_rect.editor_only = false
	_input_rect.gui_input.connect(_on_input_rect_gui_input)
	add_child(_input_rect)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PRE_SORT_CHILDREN:
			var controls := get_controls()
			var unresizable_size : float
			var ratio : float
			var new_collapsed := {}
			for control in controls:
				if control in _collapsed:
					new_collapsed[control] = true
				if Vector2i(control.size_flags_horizontal, control.size_flags_vertical)[mode] & SIZE_EXPAND and not control in _collapsed:
					ratio += control.size_flags_stretch_ratio
				else:
					unresizable_size += control.get_combined_minimum_size()[mode]
			_collapsed = new_collapsed
			
			unresizable_size += get_theme_constant('separation') * maxi(controls.size() - 1, 0)
			
			if _separator_grabbed > controls.size() - 1:
				_separator_grabbed = -1
			
			var stretch_ratio_size : float = size[mode] - unresizable_size
			for control in get_controls():
				if Vector2i(control.size_flags_horizontal, control.size_flags_vertical)[mode] & SIZE_EXPAND:
					if control in _collapsed:
						control.size_flags_stretch_ratio = control.get_combined_minimum_size()[mode]
					else:
						control.size_flags_stretch_ratio = control.size_flags_stretch_ratio / ratio * stretch_ratio_size
		
		NOTIFICATION_SORT_CHILDREN:
			fit_child_in_rect(_input_rect, get_global_rect())
		
		NOTIFICATION_EXIT_TREE, NOTIFICATION_PAUSED, NOTIFICATION_DRAG_BEGIN, NOTIFICATION_DISABLED:
			_separator_grabbed = -1
		
		NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_FOCUS_EXIT, NOTIFICATION_THEME_CHANGED:
			_separator_grabbed = -1

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var corner := -1
		if _separator_grabbed < 0:
			if get_global_rect().has_point(event.position):
				var control := get_control_at_point(event.position)
				if control:
					corner = get_rect_corenr_at_point(control.get_global_rect(), event.position)
		_corner = corner
		if _corner >= 0:
			_input_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			_input_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		if _separator_grabbed < 0:
			var at_pos_separator := get_separator_at_point(event.position)
			var as_pos_control_a := get_control_of_separator(at_pos_separator, true)
			var as_pos_control_b := get_control_of_separator(at_pos_separator, false)
			if as_pos_control_a and as_pos_control_b:
				mouse_default_cursor_shape = Vector2i(Control.CURSOR_HSPLIT, Control.CURSOR_VSPLIT)[mode]
			else:
				mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if _separator_grabbed < 0:
					var separator := get_separator_at_point(event.position)
					var control_a := get_control_of_separator(separator, true)
					if control_a and get_control_of_separator(separator, false):
						_separator_grabbed_offset = event.position[mode] - control_a.get_rect().end[mode]
						_separator_grabbed = separator
			
			else:
				_separator_grabbed = -1
	
	elif event is InputEventMouseMotion:
		if _separator_grabbed >= 0 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_separator_grabbed = -1
		if _separator_grabbed >= 0:
			var control_a := get_control_of_separator(_separator_grabbed, true)
			var control_b := get_control_of_separator(_separator_grabbed, false)
			
			if control_a and control_b:
				if event.relative[mode]:
					var delta : float = event.position[mode] - control_a.get_rect().end[mode] - _separator_grabbed_offset
					if delta < 0:
						delta = clamp(delta, control_a.get_combined_minimum_size()[mode] - control_a.size[mode], 0)
						if not delta:
							_collapsed[control_a] = true
					elif delta > 0:
						delta = clamp(delta, 0, control_b.size[mode] - control_b.get_combined_minimum_size()[mode])
						if not delta:
							_collapsed[control_b] = true
					
					if delta:
						control_a.size_flags_stretch_ratio = control_a.size[mode] + delta
						control_b.size_flags_stretch_ratio = control_b.size[mode] - delta
						_collapsed.erase(control_a)
						_collapsed.erase(control_b)
			
			else:
				_separator_grabbed = -1

func _on_input_rect_gui_input(_event: InputEvent) -> void:
	pass


func get_controls() -> Array[Control]:
	var resizable := [] as Array[Control]
	for child in get_children():
		if child is Control:
			if child.is_visible_in_tree() and not child.top_level:
				resizable.append(child)
	return resizable

func get_separator_at_point(point : Vector2) -> int:
	var separation := get_theme_constant('separation')
	var controls := get_controls()
	for i in maxi(controls.size() - 1, 0):
		var control := controls[i]
		if point[mode] >= control.get_rect().end[mode] and point[mode] <= control.get_rect().end[mode] + separation:
			return i
	return -1

func get_control_of_separator(separator : int, begin : bool) -> Control:
	var controls := get_controls()
	var i := separator
	if not begin:
		i += 1
	while i >= 0 and i < controls.size():
		if Vector2i(controls[i].size_flags_horizontal, controls[i].size_flags_vertical)[mode] & SIZE_EXPAND:
			return controls[i]
		i += -1 if begin else 1
	return null

func get_control_at_point(point : Vector2) -> Control:
	for child in get_children():
		if child is Control:
			if child.is_visible_in_tree() and not child.top_level:
				if child.get_global_rect().has_point(point):
					return child
	return

func get_rect_corenr_at_point(rect : Rect2, point : Vector2) -> int:
	var separation := get_theme_constant('separation')
	var rect_size := Vector2(separation, separation * 2)
	
	var rect_top_left := Rect2(rect.position, Vector2(rect_size[mode], rect_size[modea]))
	if rect_top_left.has_point(point):
		return CORNER_TOP_LEFT
	
	var rect_top_right := Transform2D(0, Vector2(rect.size.x - rect_top_left.size.x, 0)) * rect_top_left
	if rect_top_right.has_point(point):
		return CORNER_TOP_RIGHT
	
	var rect_bottom_left := Transform2D(0, Vector2(0, rect.size.y - rect_top_left.size.y)) * rect_top_left
	if rect_bottom_left.has_point(point):
		return CORNER_BOTTOM_LEFT
	
	var rect_bottom_right := Transform2D(0, Vector2(0, rect.size.y - rect_top_right.size.y)) * rect_top_right
	if rect_bottom_right.has_point(point):
		return CORNER_BOTTOM_RIGHT
	
	#var rect_to_corner := {
		#CORNER_TOP_LEFT = rect_top_left,
		#CORNER_TOP_RIGHT = rect_top_right,
		#CORNER_BOTTOM_LEFT = rect_bottom_left,
		#CORNER_BOTTOM_RIGHT = rect_bottom_right,
	#}
	#for corner : int in rect_to_corner:
		#if rect_to_corner[corner].has_point(point):
			#return corner
	return -1
