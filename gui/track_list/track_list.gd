class_name TrackList
extends Control

signal visible_name_changed(visible_name : String)

const TrackListItem = preload("track_list_item.gd")

@export var source : DataSource:
	set(value):
		if value != source:
			source = value
			
			if _list:
				_list.source = source

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

var _selection_action_modifiers_mask : KeyModifierMask
var _selection_echo : bool = false
var _selection_echo_tracks_keys := {}

@onready var _list := %List as TrackListItem


func _ready() -> void:
	_selection_action_modifiers_mask = InputMap.action_get_events("track_list_select_modifer")[0].get_modifiers_mask()
	
	if _list:
		_list.player = player
		_list.source = source
	
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

func _on_list_gui_input(event : InputEvent) -> void:
	if not _list.has_focus():
		_list.grab_focus()
	
	if event.is_action("track_list_current_track_focus"):
		## фокусировка списка на запущенном треке
		focus_on_current_track(true)
	
	elif event.is_action("track_list_select_all"):
		if source:
			_list.select_all()
	
	elif _selection_echo:
		if event is InputEventMouse:
			if _list.has_point(event.position):
				var track := _list.get_track_from_position(event.position.y)
				if track and not track.key in _selection_echo_tracks_keys:
					_selection_echo_tracks_keys[track.key] = true
					if not _list.deselect_track(track):
						_list.select_track(track)
					_list.queue_redraw()
			
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if not event.is_pressed():
						_selection_echo = false
						_selection_echo_tracks_keys = {}
	
	elif event.is_pressed() and not event.is_echo():
		if event is InputEventMouseButton:
			
			if event.double_click:
				## запуск трека из списка мышкой
				if event.button_index == MOUSE_BUTTON_LEFT:
					if player and _list.has_point(event.position):
						var track := _list.get_track_from_position(event.position.y)
						if track:
							player.pplay(0, track, source)
			
			else:
				## выделение трека из списка мышкой, начало массового выделения
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.get_modifiers_mask() & _selection_action_modifiers_mask:
						if _list.has_point(event.position):
							var track := _list.get_track_from_position(event.position.y)
							if track:
								if not _list.deselect_track(track):
									_list.select_track(track)
								
								## начало массового выделения
								_selection_echo_tracks_keys = {track.key : true}
							_selection_echo = true 
				
				## скоролл списка
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_list.scroll_offset += 1
				elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
					_list.scroll_offset -= 1

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

