class_name PlayerProgressBar
extends ProgressBar

@export var player : Player: set = set_player

@export var size_y_master : Control:
	set(val):
		if val != size_y_master:
			if size_y_master:
				size_y_master.resized.disconnect(_on_size_y_master_resized)
			
			size_y_master = val
			
			if size_y_master:
				size_y_master.resized.connect(_on_size_y_master_resized)

var _grabbed : bool


func _notification(what : int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			set_progress(0)
			_on_size_y_master_resized()
		
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_grabbed = false

func _ready() -> void:
	_notification(NOTIFICATION_SCENE_INSTANTIATED)

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.is_echo():
			if event.button_index == MOUSE_BUTTON_LEFT:
				if _grabbed:
					if not event.is_pressed():
						_grabbed = false
						value = clampf(event.position.x / size.x, 0, 1)
						player.set_progress(value)
				
				else:
					if event.is_pressed():
						_grabbed = true
			
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if _grabbed and event.is_pressed():
					_grabbed = false
	
	elif event is InputEventMouseMotion:
		if _grabbed:
			value = clampf(event.position.x / size.x, 0, 1)

func _on_size_y_master_resized() -> void:
	if size_y_master:
		if custom_minimum_size.y != size_y_master.size.y:
			custom_minimum_size.y = size_y_master.size.y

func set_player(p_value : Player) -> void:
	if p_value != player:
		if player:
			player.progress_changed.disconnect(set_progress)
			set_drag_forwarding(Callable(), Callable(), Callable())
		
		player = p_value
		
		if player:
			p_value.progress_changed.connect(set_progress)
			set_drag_forwarding(Callable(), player.can_drop_data, player.drop_data)

func set_progress(progress : float) -> void:
	if not _grabbed:
		value = progress
