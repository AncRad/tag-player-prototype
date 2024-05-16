class_name TrackList
extends MarginContainer

const TrackListItem = preload('track_list_item.gd')
const FindFilterPanel = preload('find_filter_panel.gd')

@export var source : DataSource:
	set(value):
		if value != source:
			source = value
			
			if _list:
				_list.source = source
				
			if _find_filter_panel:
				if source:
					_find_filter_panel.data_base = source.get_root()
				else:
					_find_filter_panel.data_base = null

@export var playback : Playback:
	set(value):
		if value != playback:
			playback = value
			
			if _list:
				_list.playback = playback

var _list : TrackListItem:
	set(value):
		_list = value
		if _list:
			_list.source = source
			_list.playback = playback

var _find_filter_panel : FindFilterPanel:
	set(value):
		_find_filter_panel = value
		if source:
			_find_filter_panel.data_base = source.get_root()
		else:
			_find_filter_panel.data_base = null

var _find_panel : Control


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_list = %List as TrackListItem
			_find_filter_panel = %FindFilterPanel as FindFilterPanel
			_find_panel = %FindPanel as Control


func _update_find_panel_visibility() -> void:
	if _find_filter_panel.empty() and not _find_filter_panel.is_editing():
		_find_panel.hide()
