extends MarginContainer

const PlayerButtons = preload('player_buttons.gd')

@export var player : Player:
	set(value):
		if value != player:
			if player:
				player.progress_changed.disconnect(set_progress)
			if value:
				value.progress_changed.connect(set_progress)
			
			player = value
			
			update_drag_callback()
			if _player_buttons:
				_player_buttons.player = player

var _grabbed : bool

@onready var _progress_bar := %ProgressBar as ProgressBar
@onready var _player_buttons := %PlayerButtons as PlayerButtons


func _notification(what : int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_grabbed = false

func _ready() -> void:
	_player_buttons.player = player
	update_drag_callback()

func _enter_tree() -> void:
	set_progress(0)

func _on_progress_bar_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.is_echo():
			if event.button_index == MOUSE_BUTTON_LEFT:
				if _grabbed:
					if not event.is_pressed():
						_grabbed = false
						_progress_bar.value = clampf(event.position.x / size.x, 0, 1)
						player.set_progress(_progress_bar.value)
				
				else:
					if event.is_pressed():
						_grabbed = true
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if _grabbed and event.is_pressed():
					_grabbed = false
	
	elif event is InputEventMouseMotion:
		if _grabbed:
			_progress_bar.value = clampf(event.position.x / size.x, 0, 1)

func _on_progress_bar_resized() -> void:
	if _progress_bar:
		if _progress_bar.custom_minimum_size.y != _progress_bar.size.y:
			_progress_bar.custom_minimum_size.y = _progress_bar.size.y

func set_progress(progress : float) -> void:
	if _progress_bar:
		if not _grabbed:
			_progress_bar.value = progress

func update_drag_callback() -> void:
	if _progress_bar:
		if player:
			_progress_bar.set_drag_forwarding(Callable(), player.can_drop_data, player.drop_data)
		else:
			_progress_bar.set_drag_forwarding(Callable(), Callable(), Callable())


