extends List

const FindExpressionEdit = preload('res://gui/find_panel/find_expression_edit.gd')

@export var source : DataSource:
	set(value):
		if value != source:
			if source:
				source.data_changed.disconnect(queue_redraw)
			
			source = value
			
			if source:
				source.data_changed.connect(queue_redraw)
			
			queue_redraw()

@export var playback : Playback:
	set(value):
		if value != playback:
			if playback:
				playback.track_changed.disconnect(set_highlighted_track)
			
			playback = value
			
			if playback:
				playback.track_changed.connect(set_highlighted_track)
			
			queue_redraw()

var highlighted_track : DataBase.Track: set = set_highlighted_track

var _find_panel : Control:
	set(value):
		if value != _find_panel:
			_find_panel = value
			if _find_panel:
				_find_panel.hide()

var _find_expression_edit : FindExpressionEdit:
	set(value):
		if value != _find_expression_edit:
			_find_expression_edit = value

var _deferred_scroll_to_track : DataBase.Track


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_find_panel = %FindPanel as Control
			_find_expression_edit = %FindExpressionEdit as FindExpressionEdit

func get_scroll_max() -> float:
	if source:
		return maxf(0, source.size() - int((size.y + get_line_descent()) / get_line_interval()))
	return 0

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and has_focus():
		if event.is_action('track_list_current_track_focus', true):
			accept_event()
			var pos := get_global_mouse_position() * get_global_transform()
			if has_point(pos):
				scroll_to_track(pos.y, highlighted_track)
			else:
				scroll_to_track(-0.5, highlighted_track, true)
		
		elif event.is_action('track_list_start_find', true):
			accept_event()
			_find_panel.show()
			_find_expression_edit.grab_focus()

func _gui_input(event: InputEvent) -> void:
	if event.is_pressed() and 'position' in event:
		grab_focus()
	
	if event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scroll -= 1
				else:
					scroll += 1
			
			elif event.button_index == MOUSE_BUTTON_LEFT:
				var region := get_region_at_position(event.position)
				#if OS.is_debug_build():
					#set_meta('highlight_region', region.get('rect', Rect2()))
				if region and playback:
					if source:
						playback.play(0, region.track, source)
					else:
						playback.play(0, region.track)

#func _get_tooltip(at_position: Vector2) -> String:
	#var region := get_region_at_position(at_position)
	#if OS.is_debug_build():
		#set_meta('highlight_region', region.get('rect', Rect2()))
		#queue_redraw()
	#return ''

func _draw() -> void:
	var debug_time := Time.get_ticks_usec()
	
	_line_regions.clear()
	
	var font : Font = get_font()
	font.set_cache_capacity(1000, 1000)
	var font_size : int = get_font_size()
	var font_ascent : int = get_line_ascent()
	var font_color_default := Color.WHITE.darkened(0.5)
	var font_color_light := Color.WHITE.darkened(0.2)
	var line_separation : int = get_line_separation()
	var line_interval : int = get_line_interval()
	var line_max_count : int = get_line_max_count()
	var margin_left : int = 4
	var tag_min_size : float = font.get_string_size('MMM', HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var tag_separator_size : float = font.get_string_size(', ', HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var separator_size : float = font.get_string_size(' - ', HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var creators_max_size : float = (size.x - margin_left) / 3 * 2 - separator_size / 2
	
	if scroll > get_scroll_max():
		scroll = get_scroll_max()
	
	if playback:
		highlighted_track = playback.current_track
	
	if _deferred_scroll_to_track:
		if source:
			scroll_to_track(size.y / 2.0, _deferred_scroll_to_track, false)
		_deferred_scroll_to_track = null
	
	var begin : int = clampi(int(scroll), 0, source.size())
	var end : int = clampi(begin + line_max_count, begin, source.size())
	var tracks := source.get_tracks().slice(begin, end) as Array[DataBase.Track]
	
	var draw_region := func draw_region(text : String, rect : Rect2, width := -1, color := font_color_default) -> Rect2:
		font.draw_string(get_canvas_item(), rect.position + Vector2(0, font_ascent + line_separation / 2.0),
				text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color, TextServer.JUSTIFICATION_NONE)
		rect.size.x = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, TextServer.JUSTIFICATION_NONE).x
		return rect
	
	var main_rect := Rect2(0, 0, size.x, size.y)
	var pos_y : int = int(-wrapf(scroll, 0, 1) * line_interval)
	var root := source.get_root()
	for track : DataBase.Track in tracks:
		var color := font_color_default
		if track == highlighted_track:
			color = font_color_light
		
		var line_regions : Array[Dictionary] = []
		_line_regions.append(line_regions)
		var line_rect := Rect2(main_rect.position.x, pos_y, main_rect.end.x - main_rect.position.x, line_interval)
		var rect_left := Rect2(main_rect.position.x + margin_left, pos_y, creators_max_size, line_interval)
		var region_rect := Rect2()
		
		var creators : Array[DataBase.Tag]
		if root:
			creators = track.get_typed_tags('creator')
		
		if track.valid and creators and track.name:
			var first := true
			for creator in creators:
				if first:
					if rect_left.size.x < tag_min_size:
						break
				else:
					if rect_left.size.x < tag_min_size + tag_separator_size:
						break
					
					region_rect = draw_region.call(', ', rect_left, rect_left.size.x, color)
					line_regions.append({rect = region_rect, track = track, tag = creator})
					rect_left = rect_left.grow_side(SIDE_LEFT, -region_rect.size.x)
				
				region_rect = draw_region.call('%s\n' % creator.names[0], rect_left, rect_left.size.x, color)
				line_regions.append({rect = region_rect, track = track, tag = creator})
				rect_left = rect_left.grow_side(SIDE_LEFT, -region_rect.size.x)
				
				first = false
			
			rect_left.end.x = main_rect.end.x
			
			if rect_left.size.x >= separator_size:
				region_rect = draw_region.call(' - ', rect_left, rect_left.size.x, color)
				line_regions.append({rect = region_rect, track = track})
				rect_left = rect_left.grow_side(SIDE_LEFT, -region_rect.size.x)
				
				if rect_left.size.x >= separator_size:
					region_rect = draw_region.call(track.name, rect_left, rect_left.size.x, color)
					line_regions.append({rect = region_rect, track = track})
					rect_left = rect_left.grow_side(SIDE_LEFT, -region_rect.size.x)
		
		else:
			var text : String = '[Deleted]'
			if track.valid:
				text = track.name
				if not text:
					text = track.order_string
				
				if not text:
					text = track.find_string
				
				if not text:
					if track.file_path:
						text = '[Unnamed <%s:%s>]' % [track.key, track.file_path]
					else:
						text = '[Unnamed <%s>]' % track.key
			
			rect_left.end.x = main_rect.end.x
			draw_region.call('%s *' % text, rect_left, rect_left.size.x, color)
		
		line_regions.append({rect = line_rect, track = track})
		pos_y += line_interval
	
	if OS.is_debug_build():
		draw_rect(get_meta('highlight_region', Rect2()), Color(1,0,0,0.5), false)
		debug_time = Time.get_ticks_usec() - debug_time
		set_meta("draw_counter", get_meta("draw_counter", 0) + 1)
		var debug_string := "%4d draws %4d мкс" % [get_meta("draw_counter"), debug_time]
		draw_string(font, Vector2(size.x - 110, 12), debug_string, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(1,1,1,0.9))

func set_highlighted_track(value : DataBase.Track) -> void:
	if value != highlighted_track:
		var old_track_line : int = -1
		if highlighted_track and source:
			old_track_line = source.get_tracks().find(highlighted_track)
		
		var new_track_line : int = -1
		if value:
			new_track_line = source.get_tracks().find(value)
		
		highlighted_track = value
		
		var begin := int(scroll)
		var end := begin + get_line_max_count()
		var visible_befor := old_track_line >= begin and old_track_line < end
		var visible_now := new_track_line >= begin and new_track_line < end
		
		if visible_befor or visible_now:
			queue_redraw()
		
		if old_track_line >= 0 or new_track_line >= 0:
			
			if visible_befor:
				### Если проигрываемый тек сдвинулся на 1 единицу, то скроллим за ним.
				var track_line_change := new_track_line - old_track_line
				if absi(track_line_change) == 1:
					scroll += track_line_change

func scroll_to_track(offset : float = -0.5, track := highlighted_track, deferred := false) -> void:
	if deferred:
		_deferred_scroll_to_track = track
		if track:
			queue_redraw()
	else:
		if source:
			var index := source.get_tracks().find(track)
			if index >= 0:
				if offset >= 0:
					scroll = index - (offset + get_line_separation() / 2.0) / get_line_interval() + 0.5
				else:
					scroll = index + offset / size.y * get_line_interval() + 0.5
