extends MarginContainer

signal default_playback_changed(default_playback : Playback)
signal default_source_changed(default_source : Playback)

@export var default_playback : Playback: set = set_default_playback

@export var default_source : DataSource: set = set_default_source


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			default_playback_changed.emit(default_playback)
			default_source_changed.emit(default_source)

func _ready() -> void:
	_notification(NOTIFICATION_SCENE_INSTANTIATED)

func set_default_playback(value : Playback) -> void:
	default_playback = value
	default_playback_changed.emit(default_playback)

func set_default_source(value : DataSource):
	default_source = value
	default_source_changed.emit(default_source)
