class_name DataBase
extends DataSource

enum {CHANGED = 1, PREDELETE = 1 << 1, TAGGED = 1 << 2, UNTAGGED = 1 << 3}

const KEY_MIN : int = 1_000_000_000
const KEY_MAX : int = 1_999_999_999
const TRACK_TO_TAG_PRIORTY_MIN : int = -128
const TRACK_TO_TAG_PRIORTY_MAX : int = 127

var changes_cached : int = 0

var _tracks_array : Array[Dictionary] = []
var _tags_array : Array[Dictionary] = []
var _key2track := {}
var _key2tag := {}
var _track_key2tags := {}


func set_source(_value : DataSource) -> void:
	assert(false)

func size() -> int:
	return _tracks_array.size()

# TODO: сделать кеширование массива 'read_only' и возвращать только его.
func get_tracks() -> Array[Dictionary]:
	return _tracks_array


func track_create(file : StringName) -> Dictionary:
	return _track_create(file)

func tracks_create(files : PackedStringArray) -> Array[Dictionary]:
	var tracks : Array[Dictionary] = []
	for file in files:
		tracks.append(_track_create(file))
	return tracks

func remove_track(track : Dictionary) -> void:
	var track_notification := track.notification as Signal
	track_notification.emit(PREDELETE)
	for tag in track_to_tags(track):
		untag_track(track, tag)
	_tracks_array.erase(track)
	_key2track.erase(track.key)
	_track_key2tags.erase(track.key)
	for callable in track_notification.get_connections():
		track_notification.disconnect(callable)
	changes_up()

func key_to_track(key : int) -> Dictionary:
	return _key2track.get(key, {})


func tag_create(name : String, color := Color.GRAY) -> Dictionary:
	return _tag_create(name, color)

func tag_remove(tag : Dictionary) -> void:
	tag.notification.emit(PREDELETE)
	for track_key in tag.track_key2priority:
		untag_track(_key2track[track_key], tag)
	_tags_array.erase(tag)
	_key2tag.erase(tag.key)
	changes_up()

func tag_track(track : Dictionary, tag : Dictionary, priority := 0) -> void:
	tag.track_key2priority[track.key] = priority
	track_to_tags(track).append(tag)
	track.notification.emit(TAGGED)
	tag.notification.emit(TAGGED)
	changes_up()

func untag_track(track : Dictionary, tag : Dictionary) -> void:
	tag.track_key2priority.erase(track.key)
	track_to_tags(track).erase(tag)
	tag.notification.emit(UNTAGGED)
	track.notification.emit(UNTAGGED)
	changes_up()

func get_tags() -> Array[Dictionary]:
	return _tags_array

func name_to_tag(name : String) -> Dictionary:
	for tag in _tags_array:
		if tag.name == name:
			return tag
	return {}

func track_to_tags(track : Dictionary) -> Array[Dictionary]:
	return _track_key2tags.get(track.key, [])


func to_bytes() -> PackedByteArray:
	var tracks_keys := PackedInt32Array()
	var tracks_files := PackedStringArray()
	tracks_keys.resize(size())
	tracks_files.resize(size())
	for i in size():
		tracks_keys.set(i, _tracks_array[i].key)
		tracks_files.set(i, _tracks_array[i].file_path)
	
	var tags_keys := PackedInt32Array()
	var tags_names := PackedStringArray()
	var tags_colors := PackedColorArray()
	var tags_tracks_keys : Array[PackedInt32Array] = []
	var tags_tracks_prioritys : Array[PackedInt32Array] = []
	for array in [tags_keys, tags_names, tags_colors, tags_tracks_keys, tags_tracks_prioritys]:
		array.resize(_tags_array.size())
	for i in _tags_array.size():
		var tag := _tags_array[i]
		tags_keys.set(i, tag.key)
		tags_names.set(i, tag.name)
		tags_colors.set(i, tag.color)
		var tag_tracks_keys := PackedInt32Array()
		var tracks_prioritys := PackedInt32Array()
		tag_tracks_keys.resize(tag.track_key2priority.size())
		tracks_prioritys.resize(tag.track_key2priority.size())
		var j := 0
		for track_key in tag.track_key2priority:
			tag_tracks_keys.set(j, track_key)
			tracks_prioritys.set(j, tag.track_key2priority[track_key])
			j += 1
		tags_tracks_keys[i] = tag_tracks_keys
		tags_tracks_prioritys[i] = tracks_prioritys
	
	var bytes : PackedByteArray = var_to_bytes([tracks_keys, tracks_files, tags_keys, tags_names, tags_colors, tags_tracks_keys, tags_tracks_prioritys])
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return var_to_bytes({hash = ctx.finish(), bytes = bytes})

func from_bytes(bytes : PackedByteArray) -> void:
	var data : Array
	if bytes:
		var variable = bytes_to_var(bytes)
		if variable is Dictionary and variable.has_all(['hash', 'bytes']):
			if variable.hash is PackedByteArray and variable.bytes is PackedByteArray:
				var ctx := HashingContext.new()
				ctx.start(HashingContext.HASH_SHA256)
				ctx.update(variable.bytes)
				if variable.hash == ctx.finish():
					variable = bytes_to_var(variable.bytes)
					if variable and variable is Array:
						data = variable
				else:
					assert(false)
	
	if not data:
		return
	
	var tracks_keys : PackedInt32Array = data[0]
	var tracks_files : PackedStringArray = data[1]
	for i in tracks_keys.size():
		_track_create(tracks_files[i], tracks_keys[i])
	
	var tags_keys : PackedInt32Array = data[2]
	var tags_names : PackedStringArray = data[3]
	var tags_colors : PackedColorArray = data[4]
	var tags_tracks_keys : Array = data[5]
	var tags_tracks_prioritys : Array = data[6]
	for i in tags_keys.size():
		var track_key2priority : Dictionary = {}
		var tag_tracks_keys : PackedInt32Array = tags_tracks_keys[i]
		var tag_tracks_prioritys : PackedInt32Array = tags_tracks_prioritys[i]
		for j in tag_tracks_keys.size():
			track_key2priority[tag_tracks_keys[j]] = tag_tracks_prioritys[j]
		_tag_create(tags_names[i], tags_colors[i], tags_keys[i], track_key2priority)
	
	changes_cached = changes


func _track_create(file_path : StringName, key : int = 0) -> Dictionary:
	assert(not key in _key2track, 'ключ %d уже занят' % key)
	if key < KEY_MIN or key > KEY_MAX:
		assert(not key, 'ключ %d вне диапазона [%d, %d]' % [key, KEY_MIN, KEY_MAX])
		key = randi_range(KEY_MIN, KEY_MAX)
	while key in _key2track:
		key = randi_range(KEY_MIN, KEY_MAX)
	
	var signal_name : StringName = 'track%d' % key
	if has_user_signal(signal_name):
		for data in get_signal_connection_list(signal_name):
			data.signal.disconnect(data.callable)
	else:
		add_user_signal(signal_name)
	var track := {
		key = key,
		file_path = file_path,
		
		file_name = file_path.get_basename().get_file(),
		notification = Signal(self, signal_name)
	}
	_tracks_array.append(track)
	_key2track[key] = track
	var tarck_track_key2tags : Array[Dictionary] = []
	_track_key2tags[key] = tarck_track_key2tags
	changes_up()
	return track

func _tag_create(name : String, color := Color.GRAY, key : int = 0, track_key2priority := {}) -> Dictionary:
	assert(not key in _key2tag, 'ключ %d уже занят' % key)
	if key < KEY_MIN or key > KEY_MAX:
		assert(not key, 'ключ %d вне диапазона [%d, %d]' % [key, KEY_MIN, KEY_MAX])
		key = randi_range(KEY_MIN, KEY_MAX)
	while key in _key2track:
		key = randi_range(KEY_MIN, KEY_MAX)
	
	var signal_name : StringName = 'tag%d' % key
	if has_user_signal(signal_name):
		for data in get_signal_connection_list(signal_name):
			data.signal.disconnect(data.callable)
	else:
		add_user_signal(signal_name)
	var tag := {
		key = key,
		name = name,
		color = color,
		track_key2priority = track_key2priority,
		
		notification = Signal(self, signal_name)
	}
	_tags_array.append(tag)
	_key2tag[key] = tag
	for track_key in track_key2priority:
		_track_key2tags[track_key].append(tag)
	changes_up(1 + track_key2priority.size())
	return tag
