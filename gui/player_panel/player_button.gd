@tool
class_name PlayerButton
extends Button

enum Mode {Play, Pause, PlayPause, Stop, PlayPrev, PlayNext}

const STRINGS = {
	Mode.Play : "▷",
	Mode.Pause : "▯▯",
	Mode.PlayPause : "▷",
	Mode.Stop : "□",
	Mode.PlayPrev : "◅",
	Mode.PlayNext : "▻",
}

@export var mode : Mode = Mode.PlayPause:
	set(value):
		if value != mode:
			mode = value
			text = STRINGS[mode]
			if player:
				set_play_pause_button_playing(player.playing)

@export var player : Player: set = set_player


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED, NOTIFICATION_THEME_CHANGED:
			var font := get_theme_font('font')
			var font_size := get_theme_font_size('font_size')
			assert(font)
			var rect := Rect2()
			for string : String in STRINGS.values():
				rect = rect.expand(font.get_string_size(string, alignment, -1, font_size))
			custom_minimum_size = Vector2.ONE * rect.size[rect.size.max_axis_index()]

func _pressed() -> void:
	if player:
		match mode:
			Mode.Play:
				player.pplay()
			
			Mode.Pause:
				player.ppause()
			
			Mode.PlayPause:
				player.pplay_pause()
			
			Mode.Stop:
				player.pstop()
			
			Mode.PlayPrev:
				player.pplay_prev()
			
			Mode.PlayNext:
				player.pplay_next()

#func _get_drag_data(_at_position) -> Variant:
	#var data := {}
	#
	#if player:
		#data = player.get_drag_data(_at_position)
	#
	#if data:
		#data.from = self
		#return data
	#return false

func set_player(value : Player) -> void:
	if value != player:
		if player:
			player.playing_changed.disconnect(set_play_pause_button_playing)
			set_drag_forwarding(Callable(), Callable(), Callable())
		
		player = value
		
		if player:
			player.playing_changed.connect(set_play_pause_button_playing)
			set_drag_forwarding(player.get_drag_data, player.can_drop_data, player.drop_data)
			set_play_pause_button_playing(player.playing)

func set_play_pause_button_playing(playing : bool) -> void:
	if mode == Mode.PlayPause:
		if playing:
			text = STRINGS[Mode.Pause]
		else:
			text = STRINGS[Mode.Play]

## TODO: сделай возмущенный ответ на серию кликов по кнопкам 
