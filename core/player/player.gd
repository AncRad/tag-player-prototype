class_name Player
extends AudioStreamPlayer
## Player

signal track_changed(current_track: Dictionary)
signal playing_changed(playing: bool)
signal progress_changed(progress: float)

@export var current_source: DataSource
var current_track: Dictionary
var progress_on_pause: float = 0


func _init():
	finished.connect(_on_finished)

func _process(_delta) -> void:
	progress_changed.emit(get_progress())

func pplay(offset := 0, track := current_track, source := current_source) -> void:
	var finded_track := find_track(source, track, offset)
	if finded_track:
		var new_stream := load_stream(finded_track.file_path)
		
		current_source = source
		current_track = finded_track
		if new_stream and new_stream.get_length():
			stream = new_stream
			play()
			get_window().title = current_track.file_name
		else:
			stream = null
			current_track = {}
			get_window().title = ProjectSettings.get_setting('application/config/name', 'TagPlayer') as String
			## TODO: добавить обработку ощибки загрузки
		track_changed.emit(current_track)
		playing_changed.emit(playing)

func ppause() -> void:
	if playing:
		progress_on_pause = get_progress()
		stream_paused = true
		playing_changed.emit(playing)

func punpause() -> void:
	if stream_paused:
		if progress_on_pause == 1:
			pplay_next()
		else:
			stream_paused = false
			set_progress(progress_on_pause)
			playing_changed.emit(playing)

func pplay_pause() -> void:
	if playing:
		ppause()
	elif stream_paused:
		punpause()
	else:
		pplay()
	playing_changed.emit(playing)

func pstop() -> void:
	if playing or stream_paused:
		stop()
		progress_on_pause = 0
	playing_changed.emit(playing)

func pplay_next() -> void:
	if current_source:
		pplay(+1)

func pplay_prev() -> void:
	if current_source:
		pplay(-1)


func get_length() -> float:
	if stream:
		return stream.get_length()
	return 0

func get_progress() -> float:
	if stream_paused:
		return progress_on_pause
	else:
		return clampf(get_playback_position() / get_length(), 0, 1)

func set_progress(value: float) -> void:
	value = clampf(value, 0, 1)
	if stream:
		if stream_paused:
			progress_on_pause = value
		else:
			if value == 1:
				pplay_next()
			else:
				seek(get_length() * value)


func get_drag_data(_at_position: Vector2) -> Variant:
	var data := {}
	data.from = self
	data.player = self
	
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
			pplay(0, data.track)
		
		elif 'player' in data and data.player is Player and data.player.current_track and data.player != self:
			pplay(0, data.player.current_track)


func _on_finished() -> void:
	pplay_next()


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
