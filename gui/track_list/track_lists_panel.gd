extends MarginContainer


@export var default_source : DataSource:
	set(value):
		if value != default_source:
			default_source = value
			
			if headers_panel:
				headers_panel.default_source = default_source

@export var default_player : Player:
	set(value):
		if value != default_player:
			default_player = value
			
			if headers_panel:
				headers_panel.default_player = default_player

var headers_panel : HeadersPanel
#var track_list_switcher : TrackListSwitcher


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			headers_panel = %HeadersPanel as HeadersPanel
			headers_panel.default_player = default_player
			headers_panel.default_source = default_source
