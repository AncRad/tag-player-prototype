extends MarginContainer

const PLAY_STRING = "▷"
const STOP_STRING = "▯▯"

@export var player : Player:
	set(value):
		if value != player:
			if player:
				player.playing_changed.disconnect(set_play_pause_button_playing)
			if value:
				value.playing_changed.connect(set_play_pause_button_playing)
			
			player = value
			
			update_buttons_enable()
			update_drag_callback()
			set_play_pause_button_playing(player and player.playing)

@export var enable := true:
	set(value):
		enable = value
		update_buttons_enable()

var _buttons : Array[BaseButton] = []
var _button_play_pause : BaseButton


## TODO: сделай возмущенный ответ на серию кликов по кнопкам 

func _ready() -> void:
	_button_play_pause = %PlayPause
	_buttons = [%PlayPrev, %Stop, _button_play_pause, %PlayNext]
	
	%HiddenPlayPause1.text = PLAY_STRING
	%HiddenPlayPause2.text = STOP_STRING
	update_buttons_enable()
	update_drag_callback()
	set_play_pause_button_playing(player and player.playing)

func _on_play_prev_pressed() -> void:
	if player:
		player.pplay_prev()

func _on_stop_pressed() -> void:
	if player:
		player.pstop()

func _on_play_pause_pressed() -> void:
	if player:
		player.pplay_pause()

func _on_play_next_pressed() -> void:
	if player:
		player.pplay_next()

func set_play_pause_button_playing(playing : bool) -> void:
	if _button_play_pause:
		if playing:
			_button_play_pause.text = STOP_STRING
		else:
			_button_play_pause.text = PLAY_STRING

func update_drag_callback() -> void:
	if player:
		for button in _buttons:
			button.set_drag_forwarding(player.get_drag_data, player.can_drop_data, player.drop_data)
		self.set_drag_forwarding(player.get_drag_data, player.can_drop_data, player.drop_data)
	else:
		for button in _buttons:
			button.set_drag_forwarding(Callable(), Callable(), Callable())
		self.set_drag_forwarding(Callable(), Callable(), Callable())

func update_buttons_enable() -> void:
	for button in _buttons:
		button.disabled = not enable and not player
