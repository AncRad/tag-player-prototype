class_name TrackList
extends Control
## TrackList

signal visible_name_changed(visible_name : String)

const TrackListItem = preload("track_list_item.gd")

@export var source : DataSource:
	set(value):
		if value != source:
			if source:
				var not_oredered := source.get_not_ordered()
				if not_oredered is DataSourceFiltered:
					not_oredered.filters_changed.disconnect(_on_source_filters_changed)
			
			source = value
			
			if _list:
				_list.source = source
			
			if source:
				var not_oredered := source.get_not_ordered()
				if not_oredered is DataSourceFiltered:
					not_oredered.filters_changed.connect(_on_source_filters_changed)
					_on_source_filters_changed()

@export var player : Player:
	set(value):
		if value != player:
			player = value
			
			if _list:
				_list.player = player

@export var focus_track_on_ready := false

@export var visible_name : String = "":
	set(value):
		if value != visible_name:
			visible_name = value
			visible_name_changed.emit(visible_name)

var _list : TrackListItem
var _find : LineEdit
var _find_panel : Control

var _sync_filters := false
var _selection_action_modifiers_mask : KeyModifierMask
var _selection_echo : bool = false
var _selection_echo_tracks_keys := {}


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			_selection_action_modifiers_mask = InputMap.action_get_events("track_list_select_modifer")[0].get_modifiers_mask()
			
			_list = %TrackListItem as TrackListItem
			_find = %FindLineEdit as LineEdit
			_find_panel = %FindPanel as Control
			
			_list.player = player
			_list.source = source
			
			if source:
				if source is DataSourceFiltered:
					_on_source_filters_changed()

func _ready() -> void:
	if focus_track_on_ready:
		focus_on_current_track(false)

func _get_drag_data(at_position: Vector2) -> Variant:
	var data := {}
	data.from = self
	
	if source:
		data.source = source
	
	if player:
		data.player = player
	
	if _list:
		var track := _list.get_track_from_position(at_position.y)
		if track:
			data.track = track
	
	return data

func gui_start_find() -> void:
	if source:
		var not_ordered := source.get_not_ordered()
		if not not_ordered is DataSourceFiltered:
			not_ordered = DataSourceFiltered.new(not_ordered)
			source = not_ordered.get_ordered()
		assert(not_ordered is DataSourceFiltered)
		
		_on_source_filters_changed()
		_find_panel.show()
		_find.grab_focus()
		_find.caret_column = _find.text.length()

func _on_track_list_item_gui_input(event : InputEvent) -> void:
	if not _list.has_focus():
		_list.grab_focus()
	
	## начать поиск
	if event.is_action("track_list_start_find", true):
		if not event.is_echo() and event.is_pressed():
			accept_event()
			gui_start_find()
	
	## фокус на текущем треке проигрывателя
	elif event.is_action("track_list_current_track_focus", true):
		if event.is_pressed():
			accept_event()
			focus_on_current_track(true)
	
	## выделить все
	elif event.is_action("track_list_select_all", true):
		if not event.is_echo() and event.is_pressed():
			accept_event()
			if source:
				if _list._selected_tracks_keys.size() == source.size():
					_list.deselect_all()
				else:
					_list.select_all()
	
	elif event is InputEventMouse:
		## продолжение массового выделения
		if _selection_echo:
			if event is InputEventMouseMotion:
				if _list.has_point(event.position):
					accept_event()
					var track := _list.get_track_from_position(event.position.y)
					if track and not track.key in _selection_echo_tracks_keys:
						_selection_echo_tracks_keys[track.key] = true
						if not _list.deselect_track(track):
							_list.select_track(track)
						_list.queue_redraw()
			
			## остановка массового выделения
			elif event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if not event.is_pressed():
						accept_event()
						_selection_echo = false
						_selection_echo_tracks_keys = {}
	
		elif event is InputEventMouseButton:
			if event.is_pressed() and _list.has_point(event.position):
				## запуск трека из списка мышкой
				if event.double_click:
					if event.button_index == MOUSE_BUTTON_LEFT:
						accept_event()
						if player:
							var track := _list.get_track_from_position(event.position.y)
							if track:
								player.pplay(0, track, source)
				
				else:
					## скоролл списка
					if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
						accept_event()
						_list.scroll_offset += 1
					elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
						accept_event()
						_list.scroll_offset -= 1
					
					## выделение трека из списка, начало массового выделения
					elif event.button_index == MOUSE_BUTTON_LEFT:
						if event.get_modifiers_mask() & _selection_action_modifiers_mask:
							accept_event()
							_selection_echo = true ## начало массового выделения
							var track := _list.get_track_from_position(event.position.y)
							if track:
								if not _list.deselect_track(track):
									_list.select_track(track)
								
								_selection_echo_tracks_keys = {track.key : true}

func _on_find_line_edit_text_changed(_new_text: String) -> void:
	if not _sync_filters and _find:
		_sync_filters = true
		
		var not_ordered := source.get_not_ordered()
		assert(not_ordered is DataSourceFiltered)
		if not_ordered is DataSourceFiltered:
			not_ordered.name_filter = '*%s*' % '**'.join(_find.text.split(' ', false))
		
		visible_name = _find.text
		_sync_filters = false

func _on_source_filters_changed() -> void:
	if not _sync_filters and _find:
		_sync_filters = true
		
		var not_ordered := source.get_not_ordered()
		assert(not_ordered is DataSourceFiltered)
		if not_ordered is DataSourceFiltered:
			_find.text = ' '.join(not_ordered.name_filter.split('*', false))
		
		visible_name = _find.text
		_sync_filters = false

func focus_on_current_track(on_cursor := false) -> void:
	if _list.source and _list.player and _list.player.current_track:
		var track_index := source.get_tracks().find(player.current_track)
		if track_index >= 0:
			var cursor_line : int = -1
			if on_cursor and _list.has_point(_list.get_local_mouse_position()):
				## ищем номер строки под курсором
				cursor_line = _list.get_line_from_position(_list.get_local_mouse_position().y)
				assert(cursor_line >= 0)
			
			if cursor_line >= 0:
				## центруем под курсор
				_list.scroll_offset = track_index - cursor_line
			else:
				## центруем по центру вертикали
				_list.scroll_offset = track_index - int(_list.get_max_lines() / 2.0)

