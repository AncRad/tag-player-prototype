extends Container

#class_name TrackList
#extends Control
#
#signal visible_name_changed(visible_name : String)
#
#const TrackListItem = preload("track_list_item.gd")
#
#@export var source : DataSource:
	#set(value):
		#if value != source:
			#source = value
			#
			#if _list:
				#_list.source = source
#
#@export var player : Player:
	#set(value):
		#if value != player:
			#player = value
			#
			#if _list:
				#_list.player = player
#
#var _selection_action_modifiers_mask : KeyModifierMask
#var _selection_echo : bool = false
#var _selection_echo_tracks_keys := {}
#
#@onready var _list := %List as TrackListItem
#
#
#func _ready() -> void:
	#_selection_action_modifiers_mask = InputMap.action_get_events("track_list_select_modifer")[0].get_modifiers_mask()
	#
	#if _list:
		#_list.player = player
		#_list.source = source
#
#func _get_drag_data(at_position: Vector2) -> Variant:
	#var data := {}
	#data.from = self
	#
	#if source:
		#data.source = source
	#
	#if player:
		#data.player = player
	#
	#if _list:
		#var track := _list.get_track_from_position(at_position.y)
		#if track:
			#data.track = track
	#
	#return data
#
#func _on_list_gui_input(event : InputEvent) -> void:
	#if not has_focus():
		#_list.grab_focus()
	#
	#if _selection_echo:
		#if event is InputEventMouse:
			#if _list.has_point(event.position):
				#var track := _list.get_track_from_position(event.position.y)
				#if track and not track.key in _selection_echo_tracks_keys:
					#_selection_echo_tracks_keys[track.key] = true
					#
					### DEPRECATED
					#if not _list._selected_tracks_keys.erase(track.key):
						#_list._selected_tracks_keys[track.key] = true
					#
					#_list.queue_redraw()
			#
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT:
					#if not event.is_pressed():
						#_selection_echo = false
						#_selection_echo_tracks_keys = {}
	#
	#if event.is_pressed() and not event.is_echo():
		#if event is InputEventMouseButton:
			#
			#if event.double_click:
				### запуск трека из списка мышкой
				#if event.button_index == MOUSE_BUTTON_LEFT:
					#if player and _list.has_point(event.position):
						#var track := _list.get_track_from_position(event.position.y)
						#if track:
							#player.pplay(0, track, source)
			#
			#else:
				### выделение трека из списка мышкой, начало массового выделения
				#if event.button_index == MOUSE_BUTTON_LEFT:
					#if event.get_modifiers_mask() & _selection_action_modifiers_mask:
						#if _list.has_point(event.position):
							#var track := _list.get_track_from_position(event.position.y)
							#if track:
								#if not _list.deselect_track(track):
									#_list.select_track(track)
								#
								### начало массового выделения
								#_selection_echo_tracks_keys = {track.key : true}
							#_selection_echo = true 
				#
				### скоролл списка
				#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					#_list.scroll_offset += 1
				#elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
					#_list.scroll_offset -= 1
		#
		#elif event.is_action("track_list_current_track_focus"):
			### фокусировка списка на запущенном треке
			#_list.focus_on_current_track(true)
		#
		#elif event.is_action("track_list_select_all"):
			#if source:
				#_list._selected_tracks_keys.clear()
				#for track in source.get_tracks():
					#_list.select_track(track)
#
#func get_visible_name() -> String:
	#return ""
