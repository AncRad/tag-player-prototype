extends Control

signal player_changed(player : Player)

@export var player : Player: set = set_player

func _ready() -> void:
	player_changed.emit(player)

func set_player(value : Player) -> void:
		player = value
		
		if player:
			set_drag_forwarding(player.get_drag_data, player.can_drop_data, player.drop_data)
		else:
			set_drag_forwarding(Callable(), Callable(), Callable())
		
		player_changed.emit(player)
