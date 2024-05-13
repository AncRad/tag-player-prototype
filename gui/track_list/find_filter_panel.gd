extends Container

signal filters_changed
signal filters_cleared

const FilterItem = preload('filter_item.gd')
const FILTER_ITEM = preload('filter_item.tscn')

@export var data_base : DataBase:
	set(value):
		if value != data_base:
			data_base = value

var _flow_container : HFlowContainer

var _updating := false
var _items : Array[FilterItem] = []
var _filters_string := ''


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_flow_container = %HFlowContainer as HFlowContainer
			update()

func _on_filter_item_focus_changed(item : FilterItem) -> void:
	if item.has_focus():
		item.text = item.inputed_text
		update()
	
	else:
		_on_filter_item_text_submitted(item)

func _on_filter_item_text_submitted(item : FilterItem) -> void:
	parse(item)
	item.inputed_text = item.text
	item.text = item.filter_to_string()
	item.caret_column = 10000
	
	update()

func parse(item : FilterItem) -> void:
	var finded := false
	
	if not finded:
		if '*' in item.text or '?' in item.text:
			item.type = FilterItem.Type.MatchString
			finded = true
	
	if not finded:
		var type_to_name_variations := {
			FilterItem.Type.And : PackedStringArray(['and', '&', '&&']),
			FilterItem.Type.Or : PackedStringArray(['or', '|', '||']),
			FilterItem.Type.Not : PackedStringArray(['not', '!']),
		}
		var text := item.text.to_lower().replace(' ', '')
		for type : FilterItem.Type in type_to_name_variations:
			if text in type_to_name_variations[type]:
				item.type = type
				finded = true
				break
	
	if not finded:
		if data_base:
			var tags := data_base.find_tags_by_name(item.text)
			if tags:
				item.tag = tags[0]
				item.type = FilterItem.Type.Tag
				finded = true
	
	if not finded:
		item.type = FilterItem.Type.MatchString
		finded = true

func create_filter_item() -> FilterItem:
	var item = FILTER_ITEM.instantiate() as FilterItem
	_items.append(item)
	connect_filter_item(item)
	_flow_container.add_child(item)
	return item

func connect_filter_item(item : FilterItem, p_connect := true) -> void:
	var signal_to_callable := {
		item.text_changed : update.unbind(1),
		item.focus_entered : _on_filter_item_focus_changed.bind(item),
		item.focus_exited : _on_filter_item_focus_changed.bind(item),
		item.visibility_changed : update,
		item.text_submitted : _on_filter_item_text_submitted.bind(item).unbind(1),
	}
	
	if p_connect:
		for _signal : Signal in signal_to_callable:
			if not _signal.is_connected(signal_to_callable[_signal]):
				_signal.connect(signal_to_callable[_signal])
	
	else:
		for _signal : Signal in signal_to_callable:
			if _signal.is_connected(signal_to_callable[_signal]):
				_signal.disconnect(signal_to_callable[_signal])

func empty() -> bool:
	return filters_to_string() == ''

func filters_to_string() -> String:
	var split := PackedStringArray()
	for item in _items:
		if not item.empty():
			split.append(item.filter_to_string())
	return ', '.join(split)

func get_tags() -> Array[DataBase.Tag]:
	var tags := [] as Array[DataBase.Tag]
	
	for item in _items:
		if item.type == FilterItem.Type.Tag and item.tag and item.tag.valid:
			tags.append(item.tag)
	
	return tags

func filter_item_grab_focus() -> void:
	if not _items:
		create_filter_item()
	_items[-1].grab_focus()

func update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _update() -> void:
	
	var to_remove := _items.duplicate() as Array[FilterItem]
	
	var items := [] as Array[FilterItem]
	for node in _flow_container.get_children():
		if node is FilterItem:
			if node.visible:
				items.append(node)
				to_remove.erase(node)
			
			elif not node in to_remove:
				to_remove.append(node)
	
	var last_item : FilterItem
	if items:
		last_item = items[-1]
	
	if not last_item or not last_item.empty():
		last_item = create_filter_item()
		items.append(last_item)
	
	for item in items.duplicate():
		if not item.empty() or item.has_focus() or item == last_item:
			if not item in _items:
				connect_filter_item(item)
		
		else:
			items.erase(item)
			to_remove.append(item)
	
	for item in to_remove:
		if is_instance_valid(item):
			connect_filter_item(item, false)
			
			if item.get_parent() == _flow_container:
				_flow_container.remove_child(item)
				item.queue_free()
		
		items.erase(item)
	
	for i in items.size():
		var item := items[i]
		if i == 0:
			item.focus_neighbor_left = ^''
			item.focus_previous = ^''
		else:
			item.focus_neighbor_left = item.get_path_to(items[i - 1])
			item.focus_previous = item.focus_neighbor_left
		
		if i < items.size() - 1:
			item.focus_neighbor_right = item.get_path_to(items[i + 1])
			item.focus_next = item.focus_neighbor_right
		else:
			item.focus_neighbor_right = ^''
			item.focus_next = ^''
	
	
	if _items != items:
		_items = items
	
	
	if filters_to_string() != _filters_string:
		_filters_string = filters_to_string()
		filters_changed.emit()
	
	_updating = false
	
	if empty():
		if not get_viewport().gui_get_focus_owner() or not is_ancestor_of(get_viewport().gui_get_focus_owner()):
			filters_cleared.emit()

