extends Node

@export var player : Player
@export var saving_current_track := true

var _last_save_time : int = 0


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			print('NOTIFICATION_WM_CLOSE_REQUEST')
			#var w := get_window()
			if saving_current_track:
				save_current_track()
		
		NOTIFICATION_CRASH:
			print('NOTIFICATION_CRASH')
			assert(false)


func _ready() -> void:
	if saving_current_track:
		load_current_track.call_deferred()

func _process(_delta: float) -> void:
	if saving_current_track and Time.get_ticks_msec() - _last_save_time > 1000 * 5:
		_last_save_time = Time.get_ticks_msec()
		save_current_track()

func save_current_track() -> void:
	var file := FileAccess.open('%s/current_track' % OS.get_user_data_dir(), FileAccess.WRITE)
	if file:
		if player:
			if player.current_track:
				file.store_string(var_to_str({current_track = [player.current_track.key, player.get_progress()]}))
	file.flush()

func load_current_track() -> void:
	if player and player.current_source:
		var st := FileAccess.get_file_as_string('%s/current_track' % OS.get_user_data_dir())
		if st and str_to_var(st) is Dictionary:
			var dict := str_to_var(st) as Dictionary
			if 'current_track' in dict and dict.current_track is Array:
				var ar := dict.current_track as Array
				if ar.size() == 2 and ar[0] is int and ar[1] is float:
					var track := player.current_source.get_root().key_to_track(ar[0])
					if track:
						player.pplay(0, track)
						player.set_progress(ar[1])
