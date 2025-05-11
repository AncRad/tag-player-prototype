extends Node

@export var playback : Playback

var time : float


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			##TODO: изучить способы использования PackedDataContainer
			var bytes := FileAccess.get_file_as_bytes('%s/window_data' % OS.get_user_data_dir())
			var template := {
				position = TYPE_VECTOR2I,
				size = TYPE_VECTOR2I,
				always_on_top = TYPE_BOOL,
				track_key = TYPE_INT,
				progress = TYPE_FLOAT,
				playing = TYPE_BOOL,
			}
			if G.validate(bytes_to_var(bytes), template):
				var data := bytes_to_var(bytes) as Dictionary
				var w := get_window()
				w.position = data.position
				w.size = data.size
				w.always_on_top = data.always_on_top
				if playback:
					if playback.current_source and playback.current_source.get_root():
						var track := playback.current_source.get_root()._key_to_track.get(data.track_key, null) as DataBase.Track
						if track:
							playback.play(0, track)
							playback.set_progress(data.progress)
							if not data.playing:
								playback.pause()
		
		NOTIFICATION_WM_CLOSE_REQUEST:
			save()

func _process(delta: float) -> void:
	time += delta
	if time > 1:
		time = 0
		save()

func save() -> void:
	##TODO: изучить способы использования PackedDataContainer
	var w := get_window()
	var track_key : int = 0
	var progress : float = 0
	var playing : bool = false
	if playback:
		if playback.current_track and playback.current_track.valid:
			track_key = playback.current_track.key
		progress = playback.get_progress()
		playing = playback.is_playing()
	var data := {
		position = w.position,
		size = w.size,
		always_on_top = w.always_on_top,
		track_key = track_key,
		progress = progress,
		playing = playing,
	}
	var f := FileAccess.open('%s/window_data' % OS.get_user_data_dir(), FileAccess.WRITE_READ)
	f.store_buffer(var_to_bytes(data))
