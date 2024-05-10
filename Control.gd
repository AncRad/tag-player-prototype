extends Control

signal scroll_changed(scroll : float)
signal scroll_progress_changed(scroll_progress : float)

@export var source : DataSource:
	set(value):
		if value != source:
			if source:
				source.data_changed.disconnect(queue_redraw)
			
			source = value
			
			if source:
				source.data_changed.connect(queue_redraw)

var scroll : float = 0.0:
	set(value):
		value = clampf(value, 0, get_scroll_max())
		if value != scroll:
			scroll = value
			queue_redraw()
			scroll_changed.emit(scroll)
			scroll_progress_changed.emit(scroll_progress)

var scroll_progress : float = 0.0: set = set_scroll_progress, get = get_scroll_progress

var _line_regions : Array[Array] = []


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scroll -= 1
				else:
					scroll += 1

func _draw() -> void:
	var debug_time := Time.get_ticks_usec()
	
	if scroll > get_scroll_max():
		scroll = get_scroll_max()
	
	var font : Font = get_font() #font.set_cache_capacity(1000, 10)
	var font_size : int = get_font_size()
	var font_height : int = get_line_height()
	var font_ascent : int = get_line_ascent()
	var font_color_default := Color.WHITE.darkened(0.5)
	#var font_color_light := Color.WHITE.darkened(0.8)
	var line_separation : int = get_line_separation()
	var line_distance : int = font_height + line_separation
	var line_max_count : int = get_line_max_count()
	
	var begin : int = clampi(int(scroll), 0, source.size())
	var end : int = clampi(begin + line_max_count, begin, source.size())
	var tracks := source.get_tracks().slice(begin, end) as Array[Dictionary]
	
	var draw_item := func(text : String, pos : Vector2, width := -1, color := font_color_default) -> float:
		pos.y += font_ascent
		font.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size,
				color, TextServer.JUSTIFICATION_NONE)
		var length := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, TextServer.JUSTIFICATION_NONE).x
		return length
	
	var pos_x : float = 0
	var pos_y : int = int(-wrapf(scroll, 0, 1) * line_distance)
	var root := source.get_root()
	for track in tracks:
		if root:
			var creators := root.get_typed_tags_in_track(track, 'creator')
			var names := root.get_typed_tags_in_track(track, 'name')
			if creators and names:
				var first := true
				for creator in creators:
					if not first:
						pos_x += draw_item.call(', ', Vector2(pos_x, pos_y))
					pos_x += draw_item.call('%s\n' % creator.names[0], Vector2(pos_x, pos_y))
					first = false
				
				pos_x += draw_item.call(' - ', Vector2(pos_x, pos_y))
				
				first = true
				for track_name in names:
					if not first:
						pos_x += draw_item.call(', ', Vector2(pos_x, pos_y))
					pos_x += draw_item.call('%s\n' % track_name.names[0], Vector2(pos_x, pos_y))
					first = false
				
				pos_x = 0
				pos_y += font_height + line_separation
				continue
		
		draw_item.call('%s *\n' % track.name_string, Vector2(pos_x, pos_y))
		
		pos_x = 0
		pos_y += font_height + line_separation
	
	if OS.is_debug_build():
		debug_time = Time.get_ticks_usec() - debug_time
		set_meta("draw_counter", get_meta("draw_counter", 0) + 1)
		var debug_string := "%4d draws %4d мкс" % [get_meta("draw_counter"), debug_time]
		draw_string(font, Vector2(size.x - 110, 12), debug_string, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(1,1,1,0.9))

#func draw_l(text : String, pos : Vector2, color : Color, font : Font, font_size : int, width := -1) -> float:
	#font.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color, TextServer.JUSTIFICATION_NONE)
	#return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, TextServer.JUSTIFICATION_NONE).x

func has_point(point : Vector2) -> bool:
	return Rect2(Vector2(), size).has_point(point)

func get_font() -> Font:
	return get_theme_font('font')

func get_font_size() -> int:
	return 14

func get_line_height() -> int:
	return int(get_font().get_height(get_font_size()))

func get_line_ascent() -> int:
	return int(get_font().get_ascent(get_font_size()))

func get_line_separation() -> int:
	return 2

func get_line_max_count() -> int:
	var separation : int = get_line_separation()
	var line_distance := get_line_height() + separation
	return int(ceil((size.y + separation + wrapf(scroll, 0, 1) * line_distance) / line_distance))

func get_line_at_position(p_position : Vector2) -> int:
	if has_point(p_position):
		var separation : int = get_line_separation()
		var line_distance := get_line_height() + separation
		return int(ceil((p_position.y + separation + wrapf(scroll, 0, 1) * line_distance) / line_distance))
	return -1

func get_line_regions(line : int) -> Array[Dictionary]:
	assert(0 >= line and line < _line_regions.size())
	if 0 >= line and line < _line_regions.size():
		return _line_regions[line]
	return []

func get_scroll_max() -> float:
	if source:
		return maxf(0, source.size() - get_line_max_count())
	return 0

func get_scroll_progress() -> float:
	return clampf(scroll / get_scroll_max(), 0, 1)

func set_scroll_progress(value : float) -> void:
		scroll = get_scroll_max() * clampf(value, 0, 1)
