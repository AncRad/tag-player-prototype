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

var debug_rect : Rect2

## вывести в дочерникй класс
##

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scroll -= 1
				else:
					scroll += 1
			
			elif event.button_index == MOUSE_BUTTON_LEFT:
				debug_rect = Rect2()
				var region := get_region_at_position(event.position)
				if region:
					$'../../../../../Player'.playback.play(0, region.track)
					debug_rect = get_region_at_position(event.position).rect
				queue_redraw()

func _draw() -> void:
	var debug_time := Time.get_ticks_usec()
	
	draw_rect(debug_rect, Color.RED.darkened(0.5), false)
	
	_line_regions.clear()
	
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
	var margin_left : int = 4
	var tag_min_size : float = font.get_string_size('MMM', HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var tag_separator_size : float = font.get_string_size(', ', HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var separator_size : float = font.get_string_size(' - ', HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var creators_max_size : float = (size.x - margin_left) / 3 * 2 - separator_size / 2
	
	var begin : int = clampi(int(scroll), 0, source.size())
	var end : int = clampi(begin + line_max_count, begin, source.size())
	var tracks := source.get_tracks().slice(begin, end) as Array[DataBase.Track]
	
	var draw_region := func(text : String, rect : Rect2, width := -1, color := font_color_default) -> Rect2:
		font.draw_string(get_canvas_item(), rect.position + Vector2(0, font_ascent), text, HORIZONTAL_ALIGNMENT_LEFT,
				width, font_size, color, TextServer.JUSTIFICATION_NONE)
		rect.size.x = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, TextServer.JUSTIFICATION_NONE).x
		return rect
	
	var main_rect := Rect2(0, 0, size.x, size.y)
	#var pos_x : float = main_rect.position.x
	var pos_y : int = int(-wrapf(scroll, 0, 1) * line_distance)
	var root := source.get_root()
	for track in tracks:
		var line_regions : Array[Dictionary] = []
		_line_regions.append(line_regions)
		var rect_left := Rect2(main_rect.position.x + margin_left, pos_y, creators_max_size, line_distance)
		var region_rect := Rect2()
		
		var creators : Array[DataBase.Tag]
		var names : Array[DataBase.Tag]
		if root:
			creators = track.get_typed_tags('creator')
			names = track.get_typed_tags('name')
		
		if creators and names:
			var separeted := false
			for tags : Array[DataBase.Tag] in [creators, names]:
				var first := true
				for tag in tags:
					if first:
						if rect_left.size.x < tag_min_size:
							break
					else:
						if rect_left.size.x < tag_min_size + tag_separator_size:
							break
						
						region_rect = draw_region.call(', ', rect_left, rect_left.size.x)
						line_regions.append({rect = region_rect, track = track, tag = tag})
						rect_left = rect_left.grow_side(SIDE_LEFT, -region_rect.size.x)
					
					region_rect = draw_region.call('%s\n' % tag.names[0], rect_left, rect_left.size.x)
					line_regions.append({rect = region_rect, track = track, tag = tag})
					rect_left = rect_left.grow_side(SIDE_LEFT, -region_rect.size.x)
					
					first = false
				
				if not separeted:
					separeted = true
					rect_left.end.x = main_rect.end.x
					if rect_left.size.x < separator_size:
						break
					
					region_rect = draw_region.call(' - ', rect_left, rect_left.size.x)
					line_regions.append({rect = region_rect, track = track})
					rect_left = rect_left.grow_side(SIDE_LEFT, -region_rect.size.x)
		
		else:
			draw_region.call('%s *\n' % track.order_string, rect_left, rect_left.size.x)
		
		line_regions.append({rect = Rect2(main_rect.position.x, pos_y, main_rect.end.x - main_rect.position.x, line_distance),
				track = track})
		pos_y += line_distance
	
	if OS.is_debug_build():
		debug_time = Time.get_ticks_usec() - debug_time
		set_meta("draw_counter", get_meta("draw_counter", 0) + 1)
		var debug_string := "%4d draws %4d мкс" % [get_meta("draw_counter"), debug_time]
		draw_string(font, Vector2(size.x - 110, 12), debug_string, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(1,1,1,0.9))

##
## вывести в дочерникй класс


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
		return int((p_position.y + separation + wrapf(scroll, 0, 1) * line_distance) / line_distance)
	return -1

func get_line_regions(line : int) -> Array[Dictionary]:
	assert(line >= 0 and line < _line_regions.size())
	if line >= 0 and line < _line_regions.size():
		return _line_regions[line]
	return []

func get_region_at_position(p_position : Vector2) -> Dictionary:
	var line := get_line_at_position(p_position)
	if line >= 0 and line < _line_regions.size():
		var line_regions := get_line_regions(line)
		for region in line_regions:
			if (region.rect as Rect2).has_point(p_position):
				return region
	return {}

func get_scroll_max() -> float:
	if source:
		return maxf(0, source.size() - get_line_max_count())
	return 0

func get_scroll_progress() -> float:
	return clampf(scroll / get_scroll_max(), 0, 1)

func set_scroll_progress(value : float) -> void:
		scroll = get_scroll_max() * clampf(value, 0, 1)
