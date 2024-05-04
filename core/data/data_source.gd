class_name DataSource
extends Resource
## DataSource

signal data_changed

@export var source : DataSource: set = set_source
var changes : int = 0
var changes_updated : int = 0
var _updated := true
var _ordered := WeakRef.new()
var _children : Array[WeakRef] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func changes_up(up : int = 1) -> void:
	if up >= 0:
		_updated = false
		changes += up
	else:
		assert(up >= 0)

func update() -> void:
	if not _updated or source and not source._updated:
		_update()
	for child in get_children():
		child.update()
	if not _updated:
		_updated = true
		changes_updated = changes
		data_changed.emit()

func _update() -> void:
	pass

func set_source(value : DataSource) -> void:
	if value != source:
		if source:
			source.erase_child(self)
		
		if value:
			value = value.get_not_ordered()
			assert(value)
		
		source = value
		
		if source:
			source.append_child(self)
		
		changes_up()

func size() -> int:
	if source:
		return get_tracks().size()
	return 0

func get_tracks() -> Array[Dictionary]:
	if source:
		return source.get_tracks()
	return []

func has(track : Dictionary) -> bool:
	return track in get_tracks()

func find(track : Dictionary) -> int:
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
		append_child(ordered)
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

func append_child(child : DataSource) -> void:
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

func erase_child(child : DataSource) -> void:
	var i := 0
	while i < _children.size():
		if not _children[i].get_ref() or _children[i].get_ref() == child:
			_children.remove_at(i)
		else:
			i += 1
