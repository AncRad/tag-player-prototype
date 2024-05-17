class_name DataSource
extends Resource
## DataSource
##
## .

## Испускается в самом конце обновления, если обновление было выполнено. Смотри [member update()].
signal data_changed
enum UpdateMode {
	## Обновление может быть выполнено, если у этого узла нет родительского узла, иначе зависи от родительского узла
	## обновление может быть выполнено у родительского узла.
	Inherit,
	## Обновление может быть выполнено.
	Always,
	## Обновление не может быть выполнено.
	Disabled
}
## Родительский узел.
@export var source : DataSource: set = set_source
## Свойство используется для управления режимом выполнения обновления. Смотри [member UpdateMode] и [member can_update()].
@export var update_mode := UpdateMode.Inherit

## Счетчик внесенных изменений в этот [DataSource].
var _changes : int = 0
## Счетчик учетнных изменений в этом [DataSource].
var _changes_updated : int = 0
## Счетчик учтенных изменений родительского узла [member source] учтенных в этом [DataSource].
var _source_changes_updated_cached : int = -1
## Слабая ссылка на дочерний [DataSourceOrdered].
var _ordered := WeakRef.new()
## Массив слабых ссылок на все дочерние [DataSource].
var _children : Array[WeakRef] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

## Поднять счетчик изменений [member _changes] на указанное число [param up].
## Число [param up] должно быть больше 0.
func changes_up(up : int = 1) -> void:
	assert(up > 0)
	if up > 0:
		_changes += up

## Устанавливает родительский узел [DataSource].
func set_source(value : DataSource) -> void:
	if value != source:
		var parent := self
		while parent:
			if value == parent:
				assert(false, 'Предотвращена попытка создания циклической зависимости DataSource')
				break
			parent = parent.source
		
		assert(not value is DataSourceOrdered)
		
		if source:
			source._erase_child(self)
		
		source = value
		
		if source:
			source._append_child(self)

## Выполняет действия в следующем порядке:[br]
## вызывает метод [member _update()] если есть необходимость совершить обновление [member need_update()]
## и может быть совершено обновление [member can_update()];[br]
## вызывает [member update()] у всех дочерних [DataSource];[br]
## если было совершено обновление, то выравнивает [member _changes_updated] с [member _changes],
## устанавливает значение [member _source_changes_updated_cached] = -1, если нет родительского узла [member source], иначе
## выравнивает [member _source_changes_updated_cached] со значением [member _changes_updated] родительского узла [member source],
## испускает сигнал [signal data_changed].
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


## Метод должен быть переопределен дочерним классом. Это подходящее место для реализации основной функции дочернего класса.[br]
## Если результат выполнения функции подразумевает, что были внесены изменения в список треков, то следует вызвать [member changes_up()]
## для того, чтобы дочерние узлы получили оповещение об зменениях внесенных в этот узел.
func _update() -> void:
	changes_up()

## Возвращает массив треков родительского узла, если его нет, то возвращает пустой массив.[br]
## Этот метод должен быть переопределен дочерним классом.
func get_tracks() -> Array[DataBase.Track]:
	if source:
		return source.get_tracks()
	return []

## Возвращает размер массива списка треков [member get_tracks()].
func size() -> int:
	return get_tracks().size()

## Проверка, есть ли [param track] в списке треков [member get_tracks()].
func has(track : DataBase.Track) -> bool:
	return track in get_tracks()


## Возвращает [param true] или [param false] в зависимости от значения [member update_mode].
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

## Возвращает [param true], если есть необходимость совершить обновления списка треков.[br]
## Необходимость определяется в зависимости от одного следующих условий в этом порядке:[br]
## [member _changes] != [member _changes_updated] or[br]
## [member source] and [member _source_changes_updated_cached] != [member source].[member _changes_updated] or[br]
## [member _source_changes_updated_cached] != -1
func need_update() -> bool:
	if _changes != _changes_updated:
		return true
	
	elif source:
		return _source_changes_updated_cached != source._changes_updated
	
	else:
		return _source_changes_updated_cached != -1

## Поиск [param track] в списке треков [member get_tracks()].
func find(track : DataBase.Track) -> int:
	return get_tracks().find(track)

## Ищет и возвщарает родительский [DataBase], если не находит, то возвращает null.
func get_root() -> DataBase:
	var ret : DataSource = self as DataSource
	while ret:
		if ret is DataBase:
			return ret
		ret = ret.source
	return null

## Возвращает дочерний [DataSourceOrdered]. Если такого нет, то создает.
func get_ordered() -> DataSourceOrdered:
	if self is DataSourceOrdered:
		return self
	
	if not _ordered.get_ref():
		var ordered := DataSourceOrdered.new(self)
		_append_child(ordered)
		_ordered = weakref(ordered)
		return ordered
	
	return _ordered.get_ref()

## Возвщарает [DataSource], не являющийся классом или наследником [DataSourceOrdered].[br]
## Если этот экземпляр не наследник [DataSourceOrdered], то возвращает [param self], иначе ищет среди родительских,
## если не находит, то возвращает [param null].
func get_not_ordered() -> DataSource:
	var ret : DataSource = self as DataSource
	while ret:
		if not ret is DataSourceOrdered:
			return ret
		ret = ret.source
	return null

## Возвращает массив дочерних [DataSource].
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
