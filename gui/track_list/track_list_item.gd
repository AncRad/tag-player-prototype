#class_name TrackListItem
extends Control

signal scroll_progress_changed(progress : float)
signal selection_changed
signal highlighting_changed

@export var source : DataSource:
	set(value):
		if value != source:
			if source:
				source.data_changed.disconnect(_on_source_data_changed)
			if value:
				value.data_changed.connect(_on_source_data_changed)
			
			for item : Dictionary in _drawed_items.values():
				if item.notification.is_connected(_on_drawed_item_changed):
					item.notification.disconnect(_on_drawed_item_changed)
				else:
					assert(false)
			
			source = value
			
			_drawed_items = {}
			_selected_items = {}
			
			queue_redraw()

#@export_range(0, 100, 1, "or_greater")
var scroll_offset : int = 0: set = set_scroll_offset

var _drawed_items := {}
var _selected_items := {}
var _highlighting_items := {}

## test
@export var _font : Font
@export_range(5, 100, 1)
var _font_size : int = 16
@export_range(-5, 15, 0.1)
var _strings_separation : int = 2
## 


func _draw() -> void:
	if not _font: ## TODO: отобразить ошибку
		return
	
	if not source: ## TODO: реализовать пустоту
		return
	
	var debug_time := Time.get_ticks_usec()
	
	var items := source.get_tracks()
	
	if scroll_offset > get_scroll_max_offset():
		set_scroll_offset(get_scroll_max_offset())
	
	var begin := mini(items.size(), scroll_offset)
	var end := mini(begin + get_max_lines(), items.size())
	
	var font_height : int = get_font_height()
	var descent := int(_font.get_descent(_font_size))
	
	var items_to_disconnect := _drawed_items
	var line_count : int = 0
	_drawed_items = {}
	#var root := source.get_root()
	
	while line_count < end - begin:
		var item := items[begin + line_count]
		
		_drawed_items[item.key] = item
		
		var text : String = item.file_name
		
		
		#var root := source.get_root()
		#if root:
			##var compare = func (a : Dictionary, b : Dictionary):
					##return a.track_key2priority[item.key] > b.track_key2priority[item.key]
			#var tags : Array[Dictionary] = root.item_to_tags(item)
			#var first_tags : Array[Dictionary] = []
			#var second_tags : Array[Dictionary] = []
			#var third_tags : Array[Dictionary] = []
			#for tag in tags:
				#if tag.track_key2priority[item.key] < 10:
					#first_tags.append(tag)
				#elif tag.track_key2priority[item.key] < 35:
					#second_tags.append(tag)
				#elif tag.track_key2priority[item.key] < 60:
					#third_tags.append(tag)
		
		
		var rect_pos_y := (font_height + _strings_separation) * line_count
		var rect := Rect2(Vector2(0, rect_pos_y), Vector2(size.x, font_height))
		var text_rect := rect.grow_individual(-2, 0, -2, 0)
		var text_pos := Vector2(text_rect.position.x, (font_height + _strings_separation) * line_count + font_height - descent)
		var color : Color = Color.WHITE.darkened(0.5)
		
		if item.key in _selected_items:
			draw_rect(rect, Color.WHITE.darkened(0.7), true)
			color = Color.WHITE.darkened(0.4).darkened(1)
		
		if item.key in _highlighting_items:
			color = Color.WHITE.darkened(0.2)
		
		draw_string(_font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, text_rect.size.x, _font_size, color,
				TextServer.JUSTIFICATION_NONE)
		
		if item.key in items_to_disconnect:
			items_to_disconnect.erase(item.key)
		else:
			if not item.notification.is_connected(_on_drawed_item_changed):
				item.notification.connect(_on_drawed_item_changed)
			else:
				assert(false)
		
		
		#if root:
			#var rect_size := Vector2(4, rect.size.y - 8)
			#var i := 0
			#for tag in root.item_to_tags(item):
				#draw_rect(Rect2(Vector2(rect.size.x - 2 - (rect_size.x + 2) * i, rect.position.y + 4), rect_size),
						#tag.color.darkened(0.5), true)
				#i += 1
				#
				#var string_width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, size.x, _font_size,
						#TextServer.JUSTIFICATION_NONE).x
				#draw_string(_font, pos, tag.name, HORIZONTAL_ALIGNMENT_RIGHT, size.x, _font_size, tag.color.darkened(0.4),
						#TextServer.JUSTIFICATION_NONE)
		
		line_count += 1
		
		## debug
		#draw_line(Vector2(0, pos.y), Vector2(size.x, pos.y), Color.PALE_VIOLET_RED)
	
	for item : Dictionary in items_to_disconnect.values():
		if item.notification.is_connected(_on_drawed_item_changed):
			item.notification.disconnect(_on_drawed_item_changed)
		else:
			assert(false)
	
	if OS.is_debug_build():
		debug_time = Time.get_ticks_usec() - debug_time
		set_meta("draws", get_meta("draws", 0) + 1)
		var debug_string := "%4d draws %4d мкс" % [get_meta("draws"), debug_time]
		draw_string(_font, Vector2(size.x - 110, 12), debug_string, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(1,1,1,0.9))
#
#func _on_playback_item_changed(_item) -> void:
	#if playback and source:
		#var begin := scroll_offset
		#var end := begin + get_max_lines()
		#
		#var old_item_line := _drawed_playback_item_index
		#var new_item_line := source.get_tracks().find(playback.current_item)
		#var visible_befor := old_item_line >= begin and old_item_line < end
		#var visible_now := new_item_line >= begin and new_item_line < end
		#
		#if visible_befor or visible_now:
			#queue_redraw()
		#
		#if visible_befor:
			### Если проигрываемый тек сдвинулся на 1 единицу, то скроллим за ним.
			#var item_line_change := new_item_line - old_item_line
			#if absi(item_line_change) == 1:
				#scroll_offset += item_line_change

func _on_source_data_changed() -> void:
	queue_redraw()
	var remaining := {}
	for item in source.get_tracks():
		if item.key in _selected_items:
			remaining[item.key] = item
	if remaining.size() != _selected_items.size():
		_selected_items = remaining
		selection_changed.emit()
	
	remaining = {}
	for item in source.get_tracks():
		if item.key in _highlighting_items:
			remaining[item.key] = item
	if remaining.size() != _highlighting_items.size():
		_highlighting_items = remaining
		highlighting_changed.emit()

func _on_drawed_item_changed(_what : int) -> void:
	queue_redraw()


func select_item(item : Dictionary) -> void:
	if source and item in source.get_tracks():
		if not item.key in _selected_items:
			_selected_items[item.key] = item
			if item.key in _drawed_items:
				queue_redraw()
			selection_changed.emit()

func deselect_item(item : Dictionary) -> bool:
	if _selected_items.erase(item.key):
		if item.key in _drawed_items:
			queue_redraw()
		selection_changed.emit()
		return true
	else:
		return false

func select_all() -> void:
	if source:
		_selected_items.clear()
		for item in source.get_tracks():
			_selected_items[item.key] = item
		queue_redraw()
		selection_changed.emit()

func deselect_all() -> void:
	if _selected_items:
		_selected_items = {}
		queue_redraw()
		selection_changed.emit()

func get_selection() -> Dictionary:
	return _selected_items

func get_selection_array() -> Array[Dictionary]:
	var selection : Array[Dictionary] = []
	selection.assign(_selected_items.values())
	return selection


func highlight_item(item : Dictionary) -> void:
	if source and item in source.get_tracks():
		if not item.key in _highlighting_items:
			_highlighting_items[item.key] = item
			if item.key in _drawed_items:
				queue_redraw()
			highlighting_changed.emit()

func dehighlight_item(item : Dictionary) -> bool:
	if _highlighting_items.erase(item.key):
		if item.key in _drawed_items:
			queue_redraw()
		highlighting_changed.emit()
		return true
	else:
		return false

func highlight_all() -> void:
	if source:
		_highlighting_items.clear()
		for item in source.get_tracks():
			_highlighting_items[item.key] = item
		queue_redraw()
		highlighting_changed.emit()

func dehighlight_all() -> void:
	if _highlighting_items:
		for item_key in _highlighting_items:
			if item_key in _drawed_items:
				queue_redraw()
				break
		_highlighting_items = {}
		highlighting_changed.emit()

func get_highlighting() -> Dictionary:
	return _highlighting_items

func get_highlighting_array() -> Array[Dictionary]:
	var highlighting : Array[Dictionary] = []
	highlighting.assign(_highlighting_items.values())
	return highlighting


func has_point(point : Vector2) -> bool:
	return Rect2(Vector2(), size).has_point(point)

func get_font_height(font_size := _font_size) -> int:
	return int(_font.get_height(font_size))

func get_max_lines() -> int:
	return get_line_from_position(size.y)

func get_line_from_position(position_y : float) -> int:
	return int((position_y + _strings_separation) / (get_font_height() + _strings_separation))

func get_item_from_position(position_y : float) -> Dictionary:
	var item := {}
	if source and source.size():
		var index := scroll_offset + get_line_from_position(position_y)
		if index >= 0 and index < source.size():
			return source.get_tracks()[index]
	return item

func set_scroll_offset(value : int) -> void:
	value = clampi(value, 0, get_scroll_max_offset())
	if value != scroll_offset:
		scroll_offset = value
		scroll_progress_changed.emit(get_scroll_grogress())
		queue_redraw()

func set_scroll_progress(value : float) -> void:
	value = clampf(value, 0, 1)
	if value != get_scroll_grogress():
		scroll_offset = int(value * float(get_scroll_max_offset()))

func get_scroll_grogress() -> float:
	return clampf(float(scroll_offset) / float(get_scroll_max_offset()), 0, 1)

func get_scroll_max_offset() -> int:
	if source:
		return maxi(0, source.size() - get_max_lines())
	return 0
