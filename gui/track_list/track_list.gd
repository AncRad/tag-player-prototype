class_name TrackList
extends MarginContainer

const TrackListItem = preload('track_list_item.gd')
const FindExpressionEdit = preload('res://gui/find_panel/find_expression_edit.gd')

@export var source : DataSource:
	set(value):
		if value != source:
			source = value
			
			if _list:
				_list.source = source
				
			if _find_expression_edit:
				if source:
					if source.get_not_ordered() is DataSourceFiltered:
						var not_ordered := source.get_not_ordered()
						if not_ordered is DataSourceFiltered:
							_find_expression_edit.expression = not_ordered.expression
							_find_expression_edit.data_base = source.get_root()
							return
				
				_find_expression_edit.data_base = null
				_find_expression_edit.expression = null

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

var _find_expression_edit : FindExpressionEdit:
	set(value):
		_find_expression_edit = value
		if _find_expression_edit:
			if source:
				if source.get_not_ordered() is DataSourceFiltered:
					var not_ordered := source.get_not_ordered()
					if not_ordered is DataSourceFiltered:
						_find_expression_edit.expression = not_ordered.expression
						_find_expression_edit.data_base = source.get_root()
						return
			
			_find_expression_edit.data_base = null
			_find_expression_edit.expression = null

var _find_panel : Control


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_list = %List as TrackListItem
			_find_expression_edit = %FindExpressionEdit as FindExpressionEdit
			_find_panel = %FindPanel as Control

func _on_find_expression_edit_update_visibility() -> void:
	if not _find_expression_edit.in_focus() and _find_expression_edit.is_empty():
		_find_panel.hide()
