class_name TrackListsPanel
extends MarginContainer


@export var default_player : Player:
	set(value):
		if value != default_player:
			default_player = value
			
			if headers_panel:
				headers_panel.default_player = default_player

@export var default_source : DataSource:
	set(value):
		if value != default_source:
			default_source = value
			
			if headers_panel:
				headers_panel.default_source = default_source

var headers_panel : HeadersPanel


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			headers_panel = %HeadersPanel as HeadersPanel
			headers_panel.default_player = default_player
			headers_panel.default_source = default_source
