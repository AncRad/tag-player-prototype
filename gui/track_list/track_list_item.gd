extends Control

signal scroll_progress_changed(progress : float)

@export var source : DataSource:
	set(value):
		if value != source:
			if source:
				source.data_changed.disconnect(_on_source_data_changed)
			if value:
				value.data_changed.connect(_on_source_data_changed)
			
			source = value
			_drawed_line_count = 0
			_drawed_player_track_line = -1
			_drawed_tracks_keys = {}
			_selected_tracks_keys = {}
			
			queue_redraw()

@export var player : Player:
	set(value):
		if value != player:
			if player:
				player.track_changed.disconnect(_on_player_track_changed)
			
			player = value
			
			if player:
				player.track_changed.connect(_on_player_track_changed)
			
			queue_redraw()

#@export_range(0, 100, 1, "or_greater")
var scroll_offset : int = 0: set = set_scroll_offset

var _drawed_line_count : int
var _drawed_player_track_line : int = -1
var _drawed_tracks_keys := {}
var _selected_tracks_keys := {}

## test
@export var _font : Font
@export_range(5, 100, 1)
var _font_size : int = 16
@export_range(-5, 15, 0.1)
var _strings_separation : int = 2
## 


func _draw() -> void:
	if not _font:
		return
	
	if not source: ## BAD
		
		
		return
	
	var debug_time := Time.get_ticks_usec()
	
	var tracks := source.get_tracks()
	
	if scroll_offset > get_max_scroll_offset():
		set_scroll_offset(get_max_scroll_offset())
	
	var begin := mini(tracks.size(), scroll_offset)
	var end := mini(begin + get_max_lines(), tracks.size())
	
	var font_height : int = get_font_height()
	var descent := int(_font.get_descent(_font_size))
	
	var tracks_to_disconnect_keys := _drawed_tracks_keys
	_drawed_line_count = 0
	_drawed_player_track_line = -1
	_drawed_tracks_keys = {}
	#var root := source.get_root()
	
	while _drawed_line_count < end - begin:
		var track := tracks[begin + _drawed_line_count]
		
		_drawed_tracks_keys[track.key] = track
		
		var text : String = track.file_name
		var rect_pos_y := (font_height + _strings_separation) * _drawed_line_count
		var rect := Rect2(Vector2(0, rect_pos_y), Vector2(size.x, font_height))
		var pos := Vector2(0, (font_height + _strings_separation) * _drawed_line_count + font_height - descent)
		var color : Color = Color.WHITE.darkened(0.5)
		
		if track.key in _selected_tracks_keys:
			draw_rect(rect, Color(0.3,0.3,0.6).darkened(0.75), true)
		
		if player and player.current_track == track:
			color = color.lightened(0.5)
			_drawed_player_track_line = _drawed_line_count
		
		draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, size.x, _font_size, color, TextServer.JUSTIFICATION_NONE)
		
		if track.key in tracks_to_disconnect_keys:
			tracks_to_disconnect_keys.erase(track.key)
		else:
			if not track.notification.is_connected(_on_drawed_track_changed):
				track.notification.connect(_on_drawed_track_changed)
			else:
				assert(false)
		
		
		#if root:
			#var rect_size := Vector2(4, rect.size.y - 8)
			#var i := 0
			#for tag in root.track_to_tags(track):
				#draw_rect(Rect2(Vector2(rect.size.x - 2 - (rect_size.x + 2) * i, rect.position.y + 4), rect_size),
						#tag.color.darkened(0.5), true)
				#i += 1
				#
				#var string_width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, size.x, _font_size,
						#TextServer.JUSTIFICATION_NONE).x
				#draw_string(_font, pos, tag.name, HORIZONTAL_ALIGNMENT_RIGHT, size.x, _font_size, tag.color.darkened(0.4),
						#TextServer.JUSTIFICATION_NONE)
		
		_drawed_line_count += 1
		
		## debug
		#draw_line(Vector2(0, pos.y), Vector2(size.x, pos.y), Color.PALE_VIOLET_RED)
	
	for track : Dictionary in tracks_to_disconnect_keys.values():
		if track.notification.is_connected(_on_drawed_track_changed):
			track.notification.disconnect(_on_drawed_track_changed)
		else:
			assert(false)
	
	if OS.is_debug_build():
		debug_time = Time.get_ticks_usec() - debug_time
		set_meta("draws", get_meta("draws", 0) + 1)
		var debug_string := "%4d draws %4d мкс" % [get_meta("draws"), debug_time]
		draw_string(_font, Vector2(size.x - 110, 12), debug_string, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(1,1,1,0.9))
#
#func _gui_input(event : InputEvent) -> void:
	#if not has_focus():
		#grab_focus()
	#
	#if _selection_echo:
		#if event is InputEventMouse:
			#if has_point(event.position):
				#var track := get_track_from_position(event.position.y)
				#if track and not track in _selection_echo_tracks:
					#_selection_echo_tracks[track] = true
					#if not _selected_tracks_keys.erase(track):
						#_selected_tracks_keys[track] = true
					#queue_redraw()
			#
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT:
					#if not event.is_pressed():
						#_selection_echo = false
						#_selection_echo_tracks = {}
	#
	#if event.is_pressed() and not event.is_echo():
		#if event is InputEventMouseButton:
			#
			#if event.double_click:
				### запуск трека из списка мышкой
				#if event.button_index == MOUSE_BUTTON_LEFT:
					#if player and has_point(event.position):
						#var track := get_track_from_position(event.position.y)
						#if track:
							#player.pplay(0, track, source)
			#
			#else:
				### выделение трека из списка мышкой, начало массового выделения
				#if event.button_index == MOUSE_BUTTON_LEFT:
					#if event.get_modifiers_mask() & _selection_action_modifiers_mask:
						#if has_point(event.position):
							#var track := get_track_from_position(event.position.y)
							#if track:
								#if not _selected_tracks_keys.erase(track):
									#_selected_tracks_keys[track] = true
								#queue_redraw()
								#
								### начало массового выделения
								#_selection_echo_tracks = {track : true}
							#_selection_echo = true 
				#
				### скоролл списка
				#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					#scroll_offset += 1
				#elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
					#scroll_offset -= 1
		#
		#elif event.is_action("track_list_current_track_focus"):
			### фокусировка списка на запущенном треке
			#focus_on_current_track(true)
		#
		#elif event.is_action("track_list_select_all"):
			#if source:
				#_selected_tracks_keys.clear()
				#for track in source.get_tracks():
					#_selected_tracks_keys[track] = true

func _on_player_track_changed(_track) -> void:
	if player and source and player.current_source == source:
		var old_track_line := _drawed_player_track_line
		_drawed_player_track_line = source.get_tracks().find(player.current_track) - scroll_offset
		var visible_befor := 0 <= old_track_line and old_track_line <= _drawed_line_count
		var visible_now := 0 <= _drawed_player_track_line and _drawed_player_track_line <= _drawed_line_count
		
		if visible_now or visible_befor:
			queue_redraw()
			
			## Если проигрываемый тек сдвинулся на 1 единицу, то скроллим за ним.
			if _drawed_player_track_line != -1 and old_track_line != -1:
				var track_line_change := _drawed_player_track_line - old_track_line
				if absi(track_line_change) == 1:
					scroll_offset += track_line_change

func _on_source_data_changed() -> void:
	queue_redraw()

func _on_drawed_track_changed(_what : int) -> void:
	queue_redraw()

func focus_on_current_track(on_cursor := false) -> void:
	if player and source and player.current_track:
		var track_index := source.get_tracks().find(player.current_track)
		if track_index >= 0:
			var cursor_line : int = -1
			if on_cursor and has_point(get_local_mouse_position()):
				## ищем номер строки под курсором
				cursor_line = get_line_from_position(get_local_mouse_position().y)
				assert(cursor_line >= 0)
			
			if cursor_line >= 0:
				## центруем под курсор
				scroll_offset = track_index - cursor_line
			else:
				## центруем по центру вертикали
				scroll_offset = track_index - int(get_max_lines() / 2.0)

func select_track(track : Dictionary) -> void:
	if source and track in source.get_tracks():
		if not track.key in _selected_tracks_keys:
			if track.key in _drawed_tracks_keys:
				queue_redraw()
		_selected_tracks_keys[track.key] = track

func select_all() -> void:
	if source:
		for track in source.get_tracks():
			_selected_tracks_keys[track.key] = track
		queue_redraw()

func deselect_track(track : Dictionary) -> bool:
	if _selected_tracks_keys.erase(track.key):
		if track.key in _drawed_tracks_keys:
			queue_redraw()
		return true
	else:
		return false

func deselect_all() -> void:
	if _selected_tracks_keys:
		_selected_tracks_keys = {}
		queue_redraw()


func has_point(point : Vector2) -> bool:
	return Rect2(Vector2(), size).has_point(point)

func get_font_height(font_size := _font_size) -> int:
	return int(_font.get_height(font_size))

func get_max_lines() -> int:
	return get_line_from_position(size.y)

func get_line_from_position(position_y : float) -> int:
	return int((position_y + _strings_separation) / (get_font_height() + _strings_separation))

func get_track_from_position(position_y : float) -> Dictionary:
	var track := {}
	if source and source.size():
		var index := scroll_offset + get_line_from_position(position_y)
		if index >= 0 and index < source.size():
			return source.get_tracks()[index]
	return track

func set_scroll_offset(value : int) -> void:
	value = clampi(value, 0, get_max_scroll_offset())
	if value != scroll_offset:
		scroll_offset = value
		scroll_progress_changed.emit(get_scroll_grogress())
		queue_redraw()

func set_scroll_progress(value : float) -> void:
	value = clampf(value, 0, 1)
	if value != get_scroll_grogress():
		scroll_offset = int(value * float(get_max_scroll_offset()))

func get_scroll_grogress() -> float:
	return clampf(float(scroll_offset) / float(get_max_scroll_offset()), 0, 1)

func get_max_scroll_offset() -> int:
	if source:
		return maxi(0, source.size() - get_max_lines())
	return 0



















