extends Node

#@export var default_playback : Playback:
	#set(value):
		#if value != default_playback:
			#default_playback = value
#
#@export var default_source : DataSource:
	#set(value):
		#if value != default_source:
			#default_source = value

var _drag_data : Variant


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			_drag_data = get_tree().root.gui_get_drag_data()
		
		NOTIFICATION_DRAG_END:
			if not get_viewport().gui_is_drag_successful():
				if G.validate(_drag_data.get('source'), DataSource) and G.validate(_drag_data.get('playback'), Playback):
					var pos := get_tree().root.get_mouse_position() + Vector2(get_tree().root.position)
					var stop := false
					for window in DisplayServer.get_window_list():
						if Rect2(DisplayServer.window_get_position(window), DisplayServer.window_get_size(window)).has_point(pos):
							stop = true
							break
					
					if not stop:
						var window := load('res://gui/sub_window/sub_window.tscn').instantiate() as SubWindow
						#window.default_source = default_source
						#window.default_playback = default_playback
						if window.get_node_or_null('%SubWindowGUI/%TrackListsPanel/%HeadersPanel'):
							if window.get_node('%SubWindowGUI/%TrackListsPanel/%HeadersPanel').drop_data(Vector2(), _drag_data):
								window.position = pos
								add_child(window)
						else:
							window.queue_free()
						pass
			
			_drag_data = null
