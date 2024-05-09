class_name DataBase
extends DataSource
## DataBase
##
## 

enum {CHANGED = 1, PREDELETE = 1 << 1, TAGGED = 1 << 2, UNTAGGED = 1 << 3}

const KEY_MIN : int = 1_000_000_000
const KEY_MAX : int = 1_999_999_999

@warning_ignore('unused_private_class_variable')
var _changes_cached : int = 0

var _tracks_array : Array[Dictionary] = []
var _tags_array : Array[Dictionary] = []
var _key2track := {}
var _key2tag := {}


func set_source(_value : DataSource) -> void:
	assert(false)

func size() -> int:
	return _tracks_array.size()

func get_tracks() -> Array[Dictionary]:
	return _tracks_array


func track_create(file : StringName) -> Dictionary:
	return _track_create(file)

func track_remove(track : Dictionary) -> void:
	var notification := track.notification as Signal
	
	notification.emit(PREDELETE)
	
	for tag : Dictionary in track.tag_key2type:
		untag_track(tag, track)
	
	for connection : Dictionary in notification.get_connections():
		notification.disconnect(connection.callable)
	
	_key2track.erase(track.key)
	_tracks_array.erase(track)
	track.clear()
	track.removed = true


func tag_create(names : PackedStringArray, color := Color.GRAY) -> Dictionary:
	return _tag_create(names, color)

func tag_track(tag : Dictionary, track : Dictionary, type : StringName, position : int = -1) -> void:
	
	if tag.key in track.tag_key2type:
		var current_tag_type : StringName = track.tag_key2type[tag.key]
		var track_typed_tags : Array[Dictionary] = track.tags[current_tag_type]
		if track_typed_tags.size() > 1:
			track_typed_tags.erase(tag)
		else:
			track.tags.erase(current_tag_type)
	
	var track_typed_tags : Array[Dictionary] = []
	
	if type in track.tags:
		track_typed_tags = track.tags[type]
	else:
		track.tags[type] = track_typed_tags
	
	if position <= -1:
		position = track_typed_tags.size()
	
	track_typed_tags.insert(clampi(position, 0, track_typed_tags.size()), tag)
	track.tag_key2type[tag.key] = type
	tag.tracks_keys[track.key] = type
	
	tag.notification.emit(TAGGED)
	track.notification.emit(TAGGED)

func untag_track(tag, track) -> void:
	assert(tag.key in track.tag_key2type)
	if tag.key in track.tag_key2type:
		var current_tag_type : StringName = track.tag_key2type[tag.key]
		var track_typed_tags : Array[Dictionary] = track.tags[current_tag_type]
		if track_typed_tags.size() > 1:
			track_typed_tags.erase(tag)
		else:
			track.tags.erase(current_tag_type)
		
		track.tag_key2type.erase(tag.key)
		tag.tracks_keys.erase(track.key)
		
		tag.notification.emit(UNTAGGED)
		track.notification.emit(UNTAGGED)

func tag_remove(tag : Dictionary) -> void:
	var notification := tag.notification as Signal
	
	notification.emit(PREDELETE)
	
	for track_key : int in tag.tracks_keys:
		untag_track(tag, _key2track[track_key])
	
	for connection : Dictionary in notification.get_connections():
		notification.disconnect(connection.callable)
	
	_key2tag.erase(tag.key)
	_tags_array.erase(tag)
	tag.clear()
	tag.removed = true

func track_is_tagged(tag : Dictionary, track : Dictionary) -> bool:
	return tag.key in track.tag_key2type

func get_tag_type_in_track(tag : Dictionary, track : Dictionary) -> StringName:
	assert(tag.key in track.tag_key2type)
	if tag.key in track.tag_key2type:
		return track.tag_key2type[tag.key]
	return &''

func get_tag_position_in_track(tag : Dictionary, track : Dictionary) -> int:
	assert(tag.key in track.tag_key2type)
	if tag.key in track.tag_key2type:
		var tag_type : StringName = track.tag_key2type[tag.key]
		var track_typed_tags : Array[Dictionary] = track.tags[tag_type]
		return track_typed_tags.find(tag)
	return -1



func _track_create(file_path : StringName, key : int = 0) -> Dictionary:
	assert(not key in _key2track, 'ключ %d уже занят' % key)
	
	## ищем ключ
	if key < KEY_MIN or key > KEY_MAX: ## если ключ вне диапазона
		assert(not key, 'ключ %d вне диапазона [%d, %d]' % [key, KEY_MIN, KEY_MAX])
		## генерируем новый
		key = randi_range(KEY_MIN, KEY_MAX)
	while key in _key2track: ## если ключ уже используется, то ищем не используемый ключ
		key = randi_range(KEY_MIN, KEY_MAX)
	
	## создаем сигнал
	var signal_name : StringName = &'track%d' % key
	if has_user_signal(signal_name): ## если уже создан, то очищаем
		for data in get_signal_connection_list(signal_name):
			data.signal.disconnect(data.callable)
	else: ## иначе создаем новый
		add_user_signal(signal_name)
	
	## создаем экземпляр
	var track := {
		## основные данные
		key = key,
		file_path = file_path,
		tags = {}, # {type as StringName = [tag, tag] as Array[Dictionary]}
		
		## кешированые данные
		name_string = file_path.get_basename().get_file(),
		find_string = file_path.get_basename().get_file(),
		tag_key2type = {}, # {tag.key = type as StringName}
		notification = Signal(self, signal_name)
	}
	
	## добавляем в базу данных
	_tracks_array.append(track)
	
	## кешируем некоторые данные
	_key2track[key] = track
	
	changes_up()
	
	return track

func _tag_create(names : PackedStringArray, color := Color.GRAY, key : int = 0) -> Dictionary:
	assert(not key in _key2tag, 'ключ %d уже занят' % key)
	
	## ищем ключ
	if key < KEY_MIN or key > KEY_MAX: ## если ключ вне диапазона
		assert(not key, 'ключ %d вне диапазона [%d, %d]' % [key, KEY_MIN, KEY_MAX])
		## генерируем новый
		key = randi_range(KEY_MIN, KEY_MAX)
	while key in _key2tag: ## если ключ уже используется, то ищем не используемый ключ
		key = randi_range(KEY_MIN, KEY_MAX)
	
	## создаем сигнал
	var signal_name : StringName = &'tag%d' % key
	if has_user_signal(signal_name): ## если уже создан, то очищаем
		for data in get_signal_connection_list(signal_name):
			data.signal.disconnect(data.callable)
	else: ## иначе создаем новый
		add_user_signal(signal_name)
	
	## создаем экземпляр
	var tag := {
		## основные данные
		key = key,
		names = PackedStringArray(),
		color = color,
		default_types = [] as Array[StringName],
		tracks_keys = {}, # {track.key = type}
		
		## кешированые данные
		notification = Signal(self, signal_name)
	}
	
	## добавляем в базу данных
	_tags_array.append(tag)
	
	## кешируем некоторые данные
	_key2tag[key] = tag
	
	changes_up()
	
	return tag
