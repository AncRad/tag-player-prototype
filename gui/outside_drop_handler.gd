extends Node

var _data : Variant


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			if get_window().has_focus() and get_window().gui_is_dragging():
				_data = get_window().gui_get_drag_data()
				#var from := G.validate(_data.get('control'), Control) as Control
				#if from:
					#var label := Label.new()
					#label.text = 'btesttesttesttesttesttesttesttest'
					#from.set_drag_preview(label)
		
		NOTIFICATION_DRAG_END:
			if get_window().has_focus() and not get_window().gui_is_drag_successful():
				if _data is Dictionary:
					var pos := get_tree().root.get_mouse_position() + Vector2(get_tree().root.position)
					if position_is_outside(pos):
						if G.validate(_data.get('source'), DataSource) and G.validate(_data.get('playback'), Playback):
							var window := load('res://gui/sub_window/sub_window.tscn').instantiate() as SubWindow
							#window.default_source = default_source
							#window.default_playback = default_playback
							if window.get_node_or_null('%SubWindowGUI/%TrackListsPanel/%HeadersPanel'):
								if window.get_node('%SubWindowGUI/%TrackListsPanel/%HeadersPanel').drop_data(Vector2(),
										_data):
									window.position = pos
									add_child(window)
							else:
								window.queue_free()
							pass
			
			_data = null

func _input(event: InputEvent) -> void:
	if 'position' in event:
		if get_window().has_focus() and get_window().gui_is_dragging():
			if _data is Dictionary:
				var pos := get_tree().root.get_mouse_position() + Vector2(get_tree().root.position)
				if position_is_outside(pos):
					if G.validate(_data.get('source'), DataSource) and G.validate(_data.get('playback'), Playback):
						Input.set_default_cursor_shape(Input.CURSOR_CAN_DROP)

func position_is_outside(pos : Vector2) -> bool:
	for window in DisplayServer.get_window_list():
		if Rect2(DisplayServer.window_get_position(window), DisplayServer.window_get_size(window)).has_point(pos):
			return false
	return true
