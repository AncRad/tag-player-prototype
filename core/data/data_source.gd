class_name DataSource
extends Resource
## DataSource
##
## 

signal data_changed

enum UpdateMode {Inherit, Always, Disabled}

@export var source : DataSource: set = set_source

@export var update_mode := UpdateMode.Inherit

var _changes : int = 0
var _changes_updated : int = 0
var _source_changes_updated_cached : int = -1

var _ordered := WeakRef.new()
var _children : Array[WeakRef] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func changes_up(up : int = 1) -> void:
	assert(up >= 0)
	if up >= 0:
		_changes += up

func update() -> void:
	var do_update := can_update() and need_update()
	
	if do_update:
		_update()
	
	for child in get_children():
		child.update()
	
	if do_update:
		_changes_updated = _changes
		_source_changes_updated_cached = source._changes_updated if source else -1
		data_changed.emit()

func can_update() -> bool:
	match update_mode:
		UpdateMode.Always:
			return true
		
		UpdateMode.Disabled:
			return false
		
		UpdateMode.Inherit:
			if source:
				return source.can_update()
			else:
				return true
		
		_:
			assert(false)
			return false

func need_update() -> bool:
	if _changes != _changes_updated:
		return true
	
	elif source:
		return _source_changes_updated_cached != source._changes_updated
	
	else:
		return _source_changes_updated_cached != -1

func set_source(value : DataSource) -> void:
	if value != source:
		if source:
			source._erase_child(self)
		
		assert(not value is DataSourceOrdered)
		#if value:
			#value = value.get_not_ordered()
			#assert(value)
		
		source = value
		
		if source:
			source._append_child(self)

func get_tracks() -> Array[DataBase.Track]:
	if source:
		return source.get_tracks()
	return []

func size() -> int:
	return get_tracks().size()

func has(track : DataBase.Track) -> bool:
	return track in get_tracks()

func find(track : DataBase.Track) -> int:
	return get_tracks().find(track)

func get_root() -> DataBase:
	var ret : DataSource = self as DataSource
	while ret:
		if ret is DataBase:
			return ret
		ret = ret.source
	return null

func get_ordered() -> DataSourceOrdered:
	if self is DataSourceOrdered:
		return self
	
	if not _ordered.get_ref():
		var ordered := DataSourceOrdered.new(self)
		_append_child(ordered)
		_ordered = weakref(ordered)
		return ordered
	
	return _ordered.get_ref()

func get_not_ordered() -> DataSource:
	var ret : DataSource = self as DataSource
	while ret:
		if not ret is DataSourceOrdered:
			return ret
		ret = ret.source
	return null

func get_children() -> Array[DataSource]:
	var children : Array[DataSource] = []
	var i := 0
	while i < _children.size():
		if _children[i].get_ref():
			children.append(_children[i].get_ref())
			i += 1
		else:
			_children.remove_at(i)
	return children


func _append_child(child : DataSource) -> void:
	var finded := false
	var i := 0
	while i < _children.size():
		if _children[i].get_ref():
			if not finded and _children[i].get_ref() == child:
				finded = true
			i += 1
		else:
			_children.remove_at(i)
	
	if not finded:
		_children.append(weakref(child))

func _erase_child(child : DataSource) -> void:
	var i := 0
	while i < _children.size():
		if not _children[i].get_ref() or _children[i].get_ref() == child:
			_children.remove_at(i)
		else:
			i += 1

func _update() -> void:
	changes_up()
