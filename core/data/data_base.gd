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
	var track_notification := track.notification as Signal
	
	track_notification.emit(PREDELETE)
	
	for tag_key : int in track.tag_key2type:
		untag_track(_key2tag[tag_key], track)
	
	for connection : Dictionary in track_notification.get_connections():
		track_notification.disconnect(connection.callable)
	
	_key2track.erase(track.key)
	_tracks_array.erase(track)
	track.clear()
	track.removed = true

#func track_get_tags(track : Dictionary) -> Array[Dictionary]:
	#var tags : Array[Dictionary] = []
	#for typed_tags : Array[Dictionary] in track.type2tags:
		#tags.append_array(typed_tags)
	#return tags


func tag_create(names : PackedStringArray, color := Color.GRAY, types : Array[StringName] = []) -> Dictionary:
	return _tag_create(names, color, types)

func tag_track(tag : Dictionary, track : Dictionary, type : StringName = &'', position : int = -1) -> void:
	
	if not type and tag.default_types.size():
		type = tag.default_types[0]
	
	if tag.key in track.tag_key2type:
		var current_tag_type : StringName = track.tag_key2type[tag.key]
		var track_typed_tags : Array[Dictionary] = track.type2tags[current_tag_type]
		if track_typed_tags.size() > 1:
			track_typed_tags.erase(tag)
		else:
			track.type2tags.erase(current_tag_type)
	
	var track_typed_tags : Array[Dictionary] = []
	
	if type in track.type2tags:
		track_typed_tags = track.type2tags[type]
	else:
		track.type2tags[type] = track_typed_tags
	
	if position <= -1:
		position = track_typed_tags.size()
	
	track_typed_tags.insert(clampi(position, 0, track_typed_tags.size()), tag)
	track.tag_key2type[tag.key] = type
	tag.track_key2type[track.key] = type
	
	tag.notification.emit(TAGGED)
	track.notification.emit(TAGGED)

func untag_track(tag, track) -> void:
	assert(tag.key in track.tag_key2type)
	if tag.key in track.tag_key2type:
		var current_tag_type : StringName = track.tag_key2type[tag.key]
		var track_typed_tags : Array[Dictionary] = track.type2tags[current_tag_type]
		if track_typed_tags.size() > 1:
			track_typed_tags.erase(tag)
		else:
			track.type2tags.erase(current_tag_type)
		
		track.tag_key2type.erase(tag.key)
		tag.track_key2type.erase(track.key)
		
		tag.notification.emit(UNTAGGED)
		track.notification.emit(UNTAGGED)

func tag_remove(tag : Dictionary) -> void:
	var tag_notification := tag.notification as Signal
	
	tag_notification.emit(PREDELETE)
	
	for track_key : int in tag.track_key2type:
		untag_track(tag, _key2track[track_key])
	
	for connection : Dictionary in tag_notification.get_connections():
		tag_notification.disconnect(connection.callable)
	
	_key2tag.erase(tag.key)
	_tags_array.erase(tag)
	tag.clear()
	tag.removed = true

func get_tag_or_create(names : PackedStringArray, color := Color.GRAY, types : Array[StringName] = []) -> Dictionary:
	if names:
		if find_tags(names[0]):
			return find_tags(names[0])[0]
		else:
			return tag_create(names, color, types)
	return {}

func get_tags() -> Array[Dictionary]:
	return _tags_array

func find_tags(name : String) -> Array[Dictionary]:
	var tags : Array[Dictionary] = []
	
	for tag in _tags_array:
		if name in tag.names:
			tags.append(tag)
	
	return tags

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
		var track_typed_tags : Array[Dictionary] = track.type2tags[tag_type]
		return track_typed_tags.find(tag)
	return -1

func get_typed_tags_in_track(track : Dictionary, type : StringName) -> Array[Dictionary]:
	if type in track.type2tags:
		return track.type2tags[type]
	return []


func to_bytes() -> PackedByteArray:
	
	## создаем сырые данные треков
	var data_track_key := PackedInt32Array()
	var data_track_file_path := PackedStringArray()
	var data_track_tags_types : Array = []
	var data_track_typed_tags : Array = []
	for arr in [data_track_key, data_track_file_path, data_track_tags_types, data_track_typed_tags]:
		arr.resize(_tracks_array.size())
	
	for track_index in data_track_key.size():
		var track := _tracks_array[track_index]
		
		data_track_key.set(track_index, track.key)
		data_track_file_path.set(track_index, track.file_path)
		
		data_track_tags_types[track_index] = [] as Array[StringName]
		data_track_tags_types[track_index].assign(track.type2tags.keys())
		data_track_typed_tags[track_index] = [] as Array[PackedInt32Array]
		
		for type in data_track_tags_types[track_index]:
			var track_tyepd_tags := track.type2tags[type] as Array[Dictionary]
			var typed_tags := PackedInt32Array()
			typed_tags.resize(track_tyepd_tags.size())
			for tag_index in typed_tags.size():
				typed_tags.set(tag_index, track_tyepd_tags[tag_index].key)
			data_track_typed_tags[track_index].append(typed_tags)
	
	## создаем сырые данные тегов
	var data_tag_key := PackedInt32Array()
	var data_tag_names : Array[PackedStringArray] = []
	var data_tag_color := PackedColorArray()
	var data_tag_default_types : Array = []
	for arr in [data_tag_key, data_tag_names, data_tag_color, data_tag_default_types]:
		arr.resize(_tags_array.size())
	
	for tag_index in data_tag_key.size():
		var tag := _tags_array[tag_index]
		
		data_tag_key.set(tag_index, tag.key)
		data_tag_names[tag_index] = tag.names
		data_tag_color.set(tag_index, tag.color)
		data_tag_default_types[tag_index] = tag.default_types
	
	
	var bytes : PackedByteArray = var_to_bytes([
			data_track_key, data_track_file_path, data_track_tags_types, data_track_typed_tags,
			data_tag_key, data_tag_names, data_tag_color, data_tag_default_types,
	])
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
	
	if not data:
		assert(not bytes)
		return
	
	var data_track_key := data[0] as PackedInt32Array
	var data_track_file_path := data[1] as PackedStringArray
	var data_track_tags_types := data[2] as Array
	var data_track_typed_tags := data[3] as Array
	
	var data_tag_key := data[4] as PackedInt32Array
	var data_tag_names := data[5] as Array
	var data_tag_color := data[6] as PackedColorArray
	var data_tag_default_types := data[7] as Array
	
	for tag_index in data_tag_key.size():
		var default_types : Array[StringName] = []
		default_types.assign(data_tag_default_types[tag_index])
		_tag_create(data_tag_names[tag_index], data_tag_color[tag_index], default_types, data_tag_key[tag_index])
	
	for track_index in data_track_key.size():
		var track := _track_create(data_track_file_path[track_index], data_track_key[track_index])
		var track_tags_types : Array = data_track_tags_types[track_index]
		var track_typed_tags : Array = data_track_typed_tags[track_index]
		for tag_type_index in track_tags_types.size():
			var tag_type := track_tags_types[tag_type_index] as StringName
			var typed_tags : Array[Dictionary] = []
			for tag_key : int in track_typed_tags[tag_type_index]:
				var tag : Dictionary = _key2tag[tag_key]
				typed_tags.append(tag)
				track.tag_key2type[tag_key] = tag_type
				tag.track_key2type[track.key] = tag_type
			track.type2tags[tag_type] = typed_tags
	
	changes_up()
	update()


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
		type2tags = {}, # {type as StringName = [tag, tag] as Array[Dictionary]}
		
		## кешированые данные
		name_string = file_path.get_basename().get_file(),
		find_string = file_path.get_basename().get_file(),
		tag_key2type = {}, # {tag.key = type as StringName}
		notification = Signal(self, signal_name),
	}
	
	## добавляем в базу данных
	_tracks_array.append(track)
	
	## кешируем некоторые данные
	_key2track[key] = track
	
	changes_up()
	
	return track

func _tag_create(names : PackedStringArray, color := Color.GRAY, types : Array[StringName] = [], key : int = 0) -> Dictionary:
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
		names = names,
		color = color,
		default_types = types,
		
		## кешированые данные
		track_key2type = {}, # {track.key = type}
		notification = Signal(self, signal_name),
	}
	
	## добавляем в базу данных
	_tags_array.append(tag)
	
	## кешируем некоторые данные
	_key2tag[key] = tag
	
	changes_up()
	
	return tag

