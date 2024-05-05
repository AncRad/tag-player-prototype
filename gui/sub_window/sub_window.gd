class_name SubWindow
extends Window

@export var accept_close := true

@export var default_player : Player:
	set(value):
		if value != default_player:
			default_player = value
			
			if player_panel:
				player_panel.player = default_player
			if track_list_panel:
				track_list_panel.default_player = default_player

@export var default_source : DataSource:
	set(value):
		if value != default_source:
			default_source = value
			
			if track_list_panel:
				track_list_panel.default_source = default_source

var player_panel : PlayerPanel
var track_list_panel : TrackListsPanel


func _init() -> void:
	close_requested.connect(_on_close_requested)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			player_panel = $SubWindowGUI/VBoxContainer/PlayerPanel as PlayerPanel
			track_list_panel = $SubWindowGUI/VBoxContainer/TrackListsPanel as TrackListsPanel
			
			player_panel.player = default_player
			track_list_panel.default_player = default_player
			track_list_panel.default_source = default_source

func _on_close_requested() -> void:
	if accept_close:
		queue_free()
