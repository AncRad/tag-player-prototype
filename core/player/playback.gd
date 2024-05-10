class_name Playback
extends Resource

signal track_changed(current_track: Dictionary)
signal playing_changed(playing: bool)
signal progress_changed(progress: float)

var player : Player:
	set(value):
		if value:
			assert(not player and is_instance_valid(value))
			if not player and is_instance_valid(value):
					player = value
					player.finished.connect(play_next)

@export var current_source: DataSource = preload('res://core/data_base_ordered.tres')
var current_track: Dictionary
var progress_on_pause: float = 0


func play(offset := 0, track := current_track, source := current_source) -> void:
	var finded_track := find_track(source, track, offset)
	if finded_track:
		var new_stream := load_stream(finded_track.file_path)
		
		current_source = source
		current_track = finded_track
		if new_stream and new_stream.get_length():
			player.stream = new_stream
			player.play()
			player.get_window().title = current_track.name_string
		else:
			player.stream = null
			current_track = {}
			player.get_window().title = ProjectSettings.get_setting('application/config/name', 'TagPlayer') as String
			## TODO: добавить обработку ощибки загрузки
		track_changed.emit(current_track)
		playing_changed.emit(player.playing)

func pause() -> void:
	if player.playing:
		progress_on_pause = get_progress()
		player.stream_paused = true
		playing_changed.emit(player.playing)

func unpause() -> void:
	if player.stream_paused:
		if progress_on_pause == 1:
			play_next()
		else:
			player.stream_paused = false
			set_progress(progress_on_pause)
			playing_changed.emit(player.playing)

func play_pause() -> void:
	if player.playing:
		pause()
	elif player.stream_paused:
		unpause()
	else:
		play()
	playing_changed.emit(player.playing)

func stop() -> void:
	if player.playing or player.stream_paused:
		player.stop()
		progress_on_pause = 0
	playing_changed.emit(player.playing)

func play_next() -> void:
	if current_source:
		play(+1)

func play_prev() -> void:
	if current_source:
		play(-1)


func is_playing() -> bool:
	if player:
		return player.playing
	return false

func get_length() -> float:
	if player.stream:
		return player.stream.get_length()
	return 0

func get_progress() -> float:
	if player.stream_paused:
		return progress_on_pause
	else:
		return clampf(player.get_playback_position() / get_length(), 0, 1)

func set_progress(value: float) -> void:
	value = clampf(value, 0, 1)
	if player.stream:
		if player.stream_paused:
			progress_on_pause = value
		else:
			if value == 1:
				play_next()
			else:
				player.seek(get_length() * value)


func get_drag_data(_at_position: Vector2) -> Variant:
	var data := {}
	data.from = self
	data.playback = self
	
	if current_source:
		data.source = current_source
	
	if current_track:
		data.track = current_track
	
	return data

func can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary:
		if 'from' in data and data.from == self:
			return false
		
		if 'source' in data and data.source is DataSource:
			return true
		
		if 'player' in data and data.player is Player and data.player != self and data.player.current_source:
			return true
		
		if 'track' in data and data.track is Dictionary:
			if find_track(current_source, data.track):
				return true
		
		if 'player' in data and data.player is Player and data.player != self:
			if find_track(current_source, data.player.current_track) != {}:
				return true
	return false

func drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		if 'from' in data and data.from == self:
			return
		
		if 'source' in data and data.source is DataSource:
			current_source = data.source
		
		elif 'player' in data and data.player is Player and data.player.current_source and data.player != self:
			current_source = data.player.current_source
		
		if 'track' in data and data.track is Dictionary:
			play(0, data.track)
		
		elif 'player' in data and data.player is Player and data.player.current_track and data.player != self:
			play(0, data.player.current_track)


static func find_track(source: DataSource, track: Dictionary, offset := 0) -> Dictionary:
	if source.size():
		var tracks := source.get_tracks()
		var index := tracks.find(track) if track else 0
		if index >= 0:
			return tracks[wrapi(index + offset, 0, tracks.size())]
		elif tracks.size():
			return tracks[0]
	return {}

static func load_stream(file_path: String) -> AudioStream:
	if FileAccess.file_exists(file_path):
		var bytes := FileAccess.get_file_as_bytes(file_path)
		var err := FileAccess.get_open_error()
		if err == OK and bytes:
			@warning_ignore("shadowed_variable_base_class")
			var stream := AudioStreamMP3.new()
			stream.data = bytes
			if stream.get_length():
				return stream
	
	assert(false) # добавить обработчик ошибок
	return null
