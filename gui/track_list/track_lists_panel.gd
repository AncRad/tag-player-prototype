extends MarginContainer

signal default_player_changed(default_player : Player)
signal default_source_changed(default_source : Player)

@export var default_player : Player: set = set_default_player

@export var default_source : DataSource: set = set_default_source


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			default_player_changed.emit(default_player)
			default_source_changed.emit(default_source)

func _ready() -> void:
	_notification(NOTIFICATION_SCENE_INSTANTIATED)

func set_default_player(value : Player) -> void:
	default_player = value
	default_player_changed.emit(default_player)

func set_default_source(value : DataSource):
	default_source = value
	default_source_changed.emit(default_source)
