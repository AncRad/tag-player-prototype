extends Control

signal playback_changed(playback : Playback)

@export var playback : Playback: set = set_playback

func _ready() -> void:
	playback_changed.emit(playback)

func set_playback(value : Playback) -> void:
		playback = value
		
		if playback:
			set_drag_forwarding(playback.get_drag_data, playback.can_drop_data, playback.drop_data)
		else:
			set_drag_forwarding(Callable(), Callable(), Callable())
		
		playback_changed.emit(playback)
