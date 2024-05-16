class_name DataBase
extends DataSource
## DataBase
##
## DataBase

const KEY_MIN : int = 1_000_000_000
const KEY_MAX : int = 1_999_999_999

@warning_ignore('unused_private_class_variable')
var _changes_cached : int = 0

var _items_array : Array[Item] = []
var _tracks_array : Array[Track] = []
var _tags_array : Array[Tag] = []
var _key_to_item := {}
var _key_to_track := {}
var _key_to_tag := {}


func set_source(_value : DataSource) -> void:
	assert(false)

func size() -> int:
	return _tracks_array.size()

func get_tracks() -> Array[Track]:
	return _tracks_array


func track_create(file : StringName) -> Track:
	return _track_create(file)

func track_remove(track : Track) -> void:
	
	track.predelete.emit()
	
	for tag in track.get_tags():
		tag.untag(track)
	
	_key_to_item.erase(track.key)
	_items_array.erase(track.key)
	_key_to_track.erase(track.key)
	_tracks_array.erase(track)
	track.clear()


func tag_create(names : Array[StringName], types : Array[StringName] = [], color := Color.WHITE) -> Tag:
	return _tag_create(names, color, types)

func tag_remove(tag : Tag) -> void:
	
	tag.predelete.emit()
	
	for track_key : int in tag.track_key_to_type.duplicate():
		tag.untag(_key_to_track[track_key])
	
	_key_to_item.erase(tag.key)
	_items_array.erase(tag)
	_key_to_tag.erase(tag.key)
	_tags_array.erase(tag)
	tag.clear()

func get_tags() -> Array[Tag]:
	return _tags_array

func find_tags_by_name(name : StringName, p_match := true, no_register := true, sort := true) -> Array[Tag]:
	var tags : Array[Tag] = []
	
	if no_register:
		name = name.to_lower()
	
	var filter := ''
	if p_match:
		var split := name.split(' ', false)
		if split:
			filter = '*%s*' % '*'.join(split)
	
	if not name or p_match and not filter:
		return []
	
	for tag in _tags_array:
		for tag_name in tag.names:
			var condition := false
			if p_match:
				if no_register:
					condition = tag_name.matchn(filter)
				else:
					condition = tag_name.match(filter)
			
			else:
				if no_register:
					condition = tag_name.to_lower().begins_with(name)
				else:
					condition = tag_name.begins_with(name)
			
			if condition:
				tags.append(tag)
				break
	
	if sort:
		## кэш таблица 'тег - схожесть имени тега с искомым именем'
		var cache := {}
		for tag in tags:
			## ищем лучшую схожесть имени тега с искомым именем
			var max_similarity := -INF
			for tag_name in tag.names:
				var similarity := tag_name.similarity(name)
				if similarity > max_similarity:
					max_similarity = similarity
			cache[tag] = max_similarity
		
		## сортируем теги по величине схожести имени тега с искомым именем
		tags.sort_custom(func (a, b): return cache[a] > cache[b])
	
	return tags

func get_tag_or_create(names : Array[StringName], types : Array[StringName] = [], color := Color.WHITE) -> Tag:
	if names:
		var tags := find_tags_by_name(names[0])
		if tags:
			return tags[0]
		else:
			return tag_create([names[0]], types, color)
	return null


func to_bytes() -> PackedByteArray:
	
	## создаем сырые данные треков
	#var data_track_key := PackedInt32Array()
	#var data_track_file_path := PackedStringArray()
	#var data_track_tags_types : Array = []
	#var data_track_typed_tags : Array = []
	#for arr in [data_track_key, data_track_file_path, data_track_tags_types, data_track_typed_tags]:
		#arr.resize(_tracks_array.size())
	#
	#for track_index in data_track_key.size():
		#var track := _tracks_array[track_index]
		#
		#data_track_key.set(track_index, track.key)
		#data_track_file_path.set(track_index, track.file_path)
		#
		#data_track_tags_types[track_index] = [] as Array[StringName]
		#data_track_tags_types[track_index].assign(track.type_to_tags.keys())
		#data_track_typed_tags[track_index] = [] as Array[PackedInt32Array]
		#
		#for type in data_track_tags_types[track_index]:
			#var track_tyepd_tags := track.type_to_tags[type] as Array[Tag]
			#var typed_tags := PackedInt32Array()
			#typed_tags.resize(track_tyepd_tags.size())
			#for tag_index in typed_tags.size():
				#typed_tags.set(tag_index, track_tyepd_tags[tag_index].key)
			#data_track_typed_tags[track_index].append(typed_tags)
	#
	### создаем сырые данные тегов
	#var data_tag_key := PackedInt32Array()
	#var data_tag_names : Array[PackedStringArray] = []
	#var data_tag_color := PackedColorArray()
	#var data_tag_default_types : Array = []
	#for arr in [data_tag_key, data_tag_names, data_tag_color, data_tag_default_types]:
		#arr.resize(_tags_array.size())
	#
	#for tag_index in data_tag_key.size():
		#var tag := _tags_array[tag_index]
		#
		#data_tag_key.set(tag_index, tag.key)
		#data_tag_names[tag_index] = tag.names
		#data_tag_color.set(tag_index, tag.color)
		#data_tag_default_types[tag_index] = tag.default_types
	#
	#
	#var bytes : PackedByteArray = var_to_bytes([
			#data_track_key, data_track_file_path, data_track_tags_types, data_track_typed_tags,
			#data_tag_key, data_tag_names, data_tag_color, data_tag_default_types,
	#])
	
	var tags_bytes : Array[PackedByteArray] = []
	for tag in get_tags():
		tags_bytes.append(tag.to_bytes())
	
	var tracks_bytes : Array[PackedByteArray] = []
	for track in get_tracks():
		tracks_bytes.append(track.to_bytes())
	
	var bytes := var_to_bytes([tags_bytes, tracks_bytes])
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
	
	#var data_track_key := data[0] as PackedInt32Array
	#var data_track_file_path := data[1] as PackedStringArray
	#var data_track_tags_types := data[2] as Array
	#var data_track_typed_tags := data[3] as Array
	#
	#var data_tag_key := data[4] as PackedInt32Array
	#var data_tag_names := data[5] as Array
	#var data_tag_color := data[6] as PackedColorArray
	#var data_tag_default_types := data[7] as Array
	#
	#for tag_index in data_tag_key.size():
		#var default_types : Array[StringName] = []
		#default_types.assign(data_tag_default_types[tag_index])
		#_tag_create(data_tag_names[tag_index], data_tag_color[tag_index], default_types, data_tag_key[tag_index])
	#
	#for track_index in data_track_key.size():
		#var track := _track_create(data_track_file_path[track_index], data_track_key[track_index])
		#var track_tags_types : Array = data_track_tags_types[track_index]
		#var track_typed_tags : Array = data_track_typed_tags[track_index]
		#for tag_type_index in track_tags_types.size():
			#var tag_type := track_tags_types[tag_type_index] as StringName
			#var typed_tags : Array[Tag] = []
			#for tag_key : int in track_typed_tags[tag_type_index]:
				#var tag : Dictionary = _key_to_tag[tag_key]
				#typed_tags.append(tag)
				#track.tag_key_to_type[tag_key] = tag_type
				#tag.track_key_to_type[track.key] = tag_type
			#track.type_to_tags[tag_type] = typed_tags
	
	
	var tags_bytes := data[0] as Array
	var tracks_bytes := data[1] as Array
	
	for tag_bytes : PackedByteArray in tags_bytes:
		var tag := Tag.from_bytes(tag_bytes)
		_items_array.append(tag)
		_key_to_item[tag.key] = tag
		_tags_array.append(tag)
		_key_to_tag[tag.key] = tag
		tag.data_base = weakref(self)
	
	for track_bytes : PackedByteArray in tracks_bytes:
		var track := Track.from_bytes(track_bytes, _key_to_tag)
		_items_array.append(track)
		_key_to_item[track.key] = track
		_tracks_array.append(track)
		_key_to_track[track.key] = track
		track.data_base = weakref(self)
	
	changes_up()
	update()


func _track_create(file_path : StringName, key : int = 0) -> Track:
	assert(not key in _key_to_item, 'ключ %d уже занят' % key)
	
	## ищем ключ
	if key < KEY_MIN or key > KEY_MAX: ## если ключ вне диапазона
		assert(not key, 'ключ %d вне диапазона [%d, %d]' % [key, KEY_MIN, KEY_MAX])
		## генерируем новый
		key = randi_range(KEY_MIN, KEY_MAX)
	while key in _key_to_item: ## если ключ уже используется, то ищем не используемый ключ
		key = randi_range(KEY_MIN, KEY_MAX)
	
	## создаем экземпляр
	var track := Track.new(key, file_path)
	track.data_base = weakref(self)
	
	## добавляем в базу данных
	_items_array.append(track)
	_tracks_array.append(track)
	
	## кешируем некоторые данные
	_key_to_item[key] = track
	_key_to_track[key] = track
	
	changes_up()
	
	return track

func _tag_create(names : Array[StringName], color := Color.WHITE,
		types : Array[StringName] = ['default'], key : int = 0) -> Tag:
	assert(not key in _key_to_item, 'ключ %d уже занят' % key)
	
	## ищем ключ
	if key < KEY_MIN or key > KEY_MAX: ## если ключ вне диапазона
		assert(not key, 'ключ %d вне диапазона [%d, %d]' % [key, KEY_MIN, KEY_MAX])
		## генерируем новый
		key = randi_range(KEY_MIN, KEY_MAX)
	while key in _key_to_item: ## если ключ уже используется, то ищем не используемый ключ
		key = randi_range(KEY_MIN, KEY_MAX)
	
	## создаем экземпляр
	var tag := Tag.new(key, names, types, color)
	tag.data_base = weakref(self)
	
	## добавляем в базу данных
	_items_array.append(tag)
	_tags_array.append(tag)
	
	## кешируем некоторые данные
	_key_to_item[key] = tag
	_key_to_tag[key] = tag
	
	changes_up()
	
	return tag


class Item:
	signal changed
	signal predelete
	
	### основные данные
	var valid : bool = true
	var data_base : WeakRef
	var key : int
	
	
	func changes_up() -> void:
		if data_base.get_ref():
			var db := data_base.get_ref() as DataBase
			db.changes_up()
	
	func clear() -> void:
		valid = false
		data_base = null
		key = 0
		
		for signal_data in get_signal_list():
			for connection : Dictionary in get_signal_connection_list(signal_data.name):
				connection.signal.disconnect(connection.callable)
	
	func to_bytes() -> PackedByteArray:
		return PackedByteArray()
	
	static func from_bytes(_bytes : PackedByteArray) -> Item:
		return

class Track extends Item:
	signal tagged
	signal untagged
	
	### основные данные
	var file_path : StringName
	var name : StringName
	var type_to_tags := {}
	### кешированые данные
	var order_string : String
	var find_string : String
	var tag_to_type := {}
	
	
	func _init(p_key : int, p_file_path : StringName) -> void:
		key = p_key
		file_path = p_file_path
		name = file_path.get_basename().get_file()
		order_string = name
		find_string = name
	
	func clear() -> void:
		super()
		file_path = ''
		type_to_tags.clear()
		order_string = ''
		find_string = ''
		tag_to_type.clear()
	
	func to_bytes() -> PackedByteArray:
		var type_to_key_tags : Dictionary = {}
		for type in type_to_tags:
			var tags : Array[Tag] = type_to_tags[type]
			var tags_keys := PackedInt32Array()
			tags_keys.resize(tags.size())
			for i in tags_keys.size():
				tags_keys.set(i, tags[i].key)
			type_to_key_tags[type] = tags_keys
		return var_to_bytes([key, file_path, name, type_to_key_tags])
	
	static func from_bytes(bytes : PackedByteArray, _key_to_tag : Dictionary = {}) -> Track:
		var data := bytes_to_var(bytes) as Array
		
		var track := Track.new(data[0], data[1])
		track.name = data[2]
		
		var type_to_key_tags := data[3] as Dictionary
		for type : StringName in type_to_key_tags:
			var tags_keys := type_to_key_tags[type] as PackedInt32Array
			var typed_tags := [] as Array[Tag]
			for tag_key in tags_keys:
				var tag := _key_to_tag[tag_key] as Tag
				typed_tags.append(tag)
				tag.track_key_to_type[track.key] = type
				track.tag_to_type[tag] = type
			track.type_to_tags[type] = typed_tags
		return track
	
	func get_tags() -> Array[Tag]:
		var tags : Array[Tag] = []
		tags.assign(tag_to_type.keys())
		return tags
	
	func is_tagged(tag : Tag) -> bool:
		return tag in tag_to_type
	
	func get_typed_tags(type : StringName) -> Array[Tag]:
		if type in type_to_tags:
			return type_to_tags[type]
		return []

class Tag extends Item:
	signal tagged
	signal untagged
	
	### основные данные
	var names : Array[StringName] = []
	var types : Array[StringName] = []
	var color : Color = Color.WHITE
	### кешированые данные
	var track_key_to_type := {}
	
	
	func _init(p_key : int, p_names : Array[StringName], p_types : Array[StringName] = ['default'],
			p_color : Color = Color.WHITE) -> void:
		key = p_key
		names = p_names
		types = p_types
		color = p_color
	
	func tag(track : Track, type : StringName = &'', position : int = -1) -> void:
		if not type and types.size():
			type = types[0]
		
		if self in track.tag_to_type:
			var current_tag_type : StringName = track.tag_to_type[self]
			var track_typed_tags : Array[Tag] = track.type_to_tags[current_tag_type]
			if track_typed_tags.size() > 1:
				track_typed_tags.erase(self)
			else:
				track.type_to_tags.erase(current_tag_type)
		
		var track_typed_tags : Array[Tag] = []
		
		if type in track.type_to_tags:
			track_typed_tags = track.type_to_tags[type]
		else:
			track.type_to_tags[type] = track_typed_tags
		
		if position <= -1:
			position = track_typed_tags.size()
		
		track_typed_tags.insert(clampi(position, 0, track_typed_tags.size()), self)
		track.tag_to_type[self] = type
		track_key_to_type[track.key] = type
		
		changes_up()
		
		tagged.emit()
		track.tagged.emit()
	
	func untag(track : Track) -> void:
		assert(self in track.tag_to_type)
		if self in track.tag_to_type:
			var current_tag_type : StringName = track.tag_to_type[self]
			var track_typed_tags : Array[Dictionary] = track.type_to_tags[current_tag_type]
			if track_typed_tags.size() > 1:
				track_typed_tags.erase(self)
			else:
				track.type_to_tags.erase(current_tag_type)
			
			track.tag_to_type.erase(self)
			track_key_to_type.erase(track.key)
			
			changes_up()
			
			tagged.emit()
			track.tagged.emit()
	
	func clear() -> void:
		super()
		names.clear()
		types.clear()
		color = Color()
		track_key_to_type.clear()
	
	func get_name() -> StringName:
		if names:
			return names[0]
		return ''
	
	func to_bytes() -> PackedByteArray:
		return var_to_bytes([key, names, types, color])
	
	static func from_bytes(bytes : PackedByteArray) -> Tag:
		var data := bytes_to_var(bytes) as Array
		@warning_ignore('shadowed_variable')
		var names := [] as Array[StringName]
		names.assign(data[1])
		@warning_ignore('shadowed_variable')
		var types := [] as Array[StringName]
		types.assign(data[2])
		return Tag.new(data[0], names, types, data[3])

#func find_tags(name : String) -> Array[Tag]:
	#var tags : Array[Tag] = []
	#
	#for tag in _tags_array:
		#if name in tag.names:
			#tags.append(tag)
	#
	#return tags
#
#func track_is_tagged(tag : Tag, track : Track) -> bool:
	#return tag.key in track.tag_key_to_type
#
#func get_tag_type_in_track(tag : Tag, track : Track) -> StringName:
	#assert(tag.key in track.tag_key_to_type)
	#if tag.key in track.tag_key_to_type:
		#return track.tag_key_to_type[tag.key]
	#return &''
#
#func get_tag_position_in_track(tag : Tag, track : Track) -> int:
	#assert(tag.key in track.tag_key_to_type)
	#if tag.key in track.tag_key_to_type:
		#var tag_type : StringName = track.tag_key_to_type[tag.key]
		#var track_typed_tags : Array[Tag] = track.type_to_tags[tag_type]
		#return track_typed_tags.find(tag)
	#return -1
