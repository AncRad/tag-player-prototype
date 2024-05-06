@tool
class_name PlaybackButton
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
			
			if Engine.is_editor_hint(): return
			
			if playback:
				set_play_pause_button_playing(playback.is_playing())

@export var playback : Playback: set = set_playback


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
	if playback:
		match mode:
			Mode.Play:
				playback.play()
			
			Mode.Pause:
				playback.pause()
			
			Mode.PlayPause:
				playback.play_pause()
			
			Mode.Stop:
				playback.stop()
			
			Mode.PlayPrev:
				playback.play_prev()
			
			Mode.PlayNext:
				playback.play_next()

#func _get_drag_data(_at_position) -> Variant:
	#var data := {}
	#
	#if playback:
		#data = playback.get_drag_data(_at_position)
	#
	#if data:
		#data.from = self
		#return data
	#return false

func set_playback(value : Playback) -> void:
	if value != playback:
		if playback and not Engine.is_editor_hint():
			playback.playing_changed.disconnect(set_play_pause_button_playing)
			set_drag_forwarding(Callable(), Callable(), Callable())
		
		playback = value
		
		if playback and not Engine.is_editor_hint():
			playback.playing_changed.connect(set_play_pause_button_playing)
			set_drag_forwarding(playback.get_drag_data, playback.can_drop_data, playback.drop_data)
			set_play_pause_button_playing(playback.is_playing())

func set_play_pause_button_playing(playing : bool) -> void:
	if mode == Mode.PlayPause:
		if playing:
			text = STRINGS[Mode.Pause]
		else:
			text = STRINGS[Mode.Play]

## TODO: сделай реакцию на длинную серию кликов по кнопкам 
