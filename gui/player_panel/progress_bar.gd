class_name PlaybackProgressBar
extends ProgressBar

@export var playback : Playback: set = set_playback

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
						playback.set_progress(value)
				
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

func set_playback(p_value : Playback) -> void:
	if p_value != playback:
		if playback:
			playback.progress_changed.disconnect(set_progress)
			set_drag_forwarding(Callable(), Callable(), Callable())
		
		playback = p_value
		
		if playback:
			p_value.progress_changed.connect(set_progress)
			set_drag_forwarding(Callable(), playback.can_drop_data, playback.drop_data)

func set_progress(progress : float) -> void:
	if not _grabbed:
		value = progress
