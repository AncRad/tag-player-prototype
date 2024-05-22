extends Container

signal updated

const FilterItem = preload('filter_item.gd')
const FILTER_ITEM = preload('filter_item.tscn')

@export var data_base : DataBase:
	set(value):
		if value != data_base:
			data_base = value

@export var expression : ExprNode:
	set(value):
		if not value:
			value = ExprNode.new(ExprNode.Type.SubExpression)
		
		if value != expression:
			if expression:
				expression.changed.disconnect(update)
			
			expression = value
			
			if expression:
				expression.changed.connect(update)
			
			update()

var _flow_container : HFlowContainer

var _updating := false
var _building := false
var _items : Array[FilterItem] = []


func _init() -> void:
	expression = null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_flow_container = %HFlowContainer as HFlowContainer
			update()
			if OS.is_debug_build():
				%DebugLabel1.show()
				pass
			else:
				%DebugLabel1.hide()

func _input(event: InputEvent) -> void:
	if event.is_pressed():
		if 'position' in event:
			var focus_owner := get_viewport().gui_get_focus_owner()
			if focus_owner is FilterItem:
				if is_ancestor_of(focus_owner):
					var pos := event.position as Vector2
					var rect := focus_owner.get_global_transform() * Rect2(Vector2(), focus_owner.size)
					if not rect.has_point(pos):
						focus_owner.release_focus()

func _process(_delta = null) -> void:
	if _updating and is_visible_in_tree():
		print('_updating')
		var items := [] as Array[FilterItem]
		
		## составляем массив видимых FilterItem
		for node in _flow_container.get_children():
			if node is Control:
				if node is FilterItem:
					if node.visible:
						items.append(node)
				
				else:
					assert(false)
					_flow_container.remove_child(node)
					node.queue_free()
		
		## удаляем пустые FilterItem кроме has_focus или последнего
		for item in items.duplicate():
			if item.empty() and not item.has_focus() and not item != items.back():
				_flow_container.remove_child(item)
				item.queue_free()
				items.erase(item)
		
		if not _building:
			for item in items:
				connect_filter_item(item, false)
				_flow_container.remove_child(item)
				item.queue_free()
			items.clear()
			_items.clear()
			
			for node in expression.expressions:
				if not node.virtual:
					var item := FILTER_ITEM.instantiate() as FilterItem
					items.append(item)
					item.expression = node
					_flow_container.add_child(item)
					connect_filter_item(item)
		
		## если в конце нет пустого, то добавляем
		if not items or not items[-1].empty():
			var end := FILTER_ITEM.instantiate() as FilterItem
			end.expression.type = ExprNode.Type.MatchString
			items.append(end)
			_flow_container.add_child(end)
			connect_filter_item(end)
		
		## удаляем все крайние разделители, разделители соседствующие с разделителями и пустыми FilterItem
		## создаем разделители между всеми не пустыми FilterItem, не имеющими между собой разделителей
		var pos := 0
		while pos < items.size():
			var item := items[pos]
			
			var left : FilterItem
			if pos > 0:
				left = items[pos - 1]
			
			var right : FilterItem
			if pos + 1 < items.size():
				right = items[pos + 1]
			
			if item.is_seprarator():
				if (pos == 0 or pos == items.size() - 1
							or right and (right.is_seprarator() or right.empty())
							or left and (left.is_seprarator() or left.empty())):
					_flow_container.remove_child(item)
					item.queue_free()
					items.remove_at(pos)
					continue
			
			else:
				if right and not right.is_seprarator() and not right.empty() and not item.empty():
					var separator := FILTER_ITEM.instantiate() as FilterItem
					separator.expression.type = ExprNode.Type.Null
					items.insert(pos + 1, separator)
					item.add_sibling(separator)
					connect_filter_item(separator)
					pos += 2
					continue
			
			pos += 1
		
		## удаляем все не нужные FilterItem и обновляем массив
		for item in _items:
			if is_instance_valid(item) and not item in items:
				connect_filter_item(item, false)
				
				if item.get_parent() == _flow_container:
					_flow_container.remove_child(item)
					item.queue_free()
		_items = items
		
		## выполняем парсинг
		if _building:
			expression.clear()
			for item in items:
				item.expression.enabled = true
				expression.append(item.expression)
			expression.update()
			expression.emit_changed()
		
		## настраиваем пути направления фокуса FilterItem
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
		
		%DebugLabel1.text = expression.to_text()
		updated.emit()
	
	_updating = false
	_building = false

func _on_filter_item_gui_input(event: InputEvent, item: FilterItem) -> void:
	if item.has_focus() and event.is_pressed():
		if (event.is_action('ui_text_caret_left') or event.is_action('ui_text_caret_line_start')
				or event.is_action('ui_text_backspace')):
			if item.caret_column == 0:
				var item_index := _items.find(item)
				
				if item_index == 0:
					var left := FILTER_ITEM.instantiate() as FilterItem
					left.expression.type = ExprNode.Type.MatchString
					_items.insert(0, left)
					_flow_container.add_child(left)
					_flow_container.move_child(left, 0)
					connect_filter_item(left)
					build()
					item_index = _items.find(item)
				
				if item_index - 1 >= 0:
					var left_item := _items[item_index - 1]
					left_item.grab_focus()
					left_item.caret_column = 10000
				
				accept_event()
				return
		
		elif (event.is_action('ui_text_caret_right') or event.is_action('ui_text_caret_line_end')
				or event.is_action('ui_text_delete')):
			if item.caret_column == item.text.length():
				var item_index := _items.find(item)
				if item_index != -1 and item_index + 1 < _items.size():
					var right_item := _items[item_index + 1]
					right_item.grab_focus()
					right_item.caret_column = 0
				
				accept_event()
				return
		
		elif event.is_action('ui_text_caret_down'):
			if item.caret_column == item.text.length():
				print('смахнуть вниз')
				
				accept_event()
				return
		
		elif event.is_action('ui_text_caret_up'):
			if item.caret_column == 0:
				print('смахнуть вверх')
				
				accept_event()
				return
		
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			item.hide()
			_items.erase(item)
			item.queue_free()
			build()
			
			accept_event()
			return

func _on_filter_item_focus_changed(item : FilterItem) -> void:
	if item.has_focus():
		if item.is_seprarator():
			item.expression.type = ExprNode.Type.MatchString
			update()
	
	else:
		_on_filter_item_text_submitted(item)
		if item.empty():
			item.expression.type = ExprNode.Type.Null
			update()

func _on_filter_item_text_submitted(item : FilterItem) -> void:
	_parse_item_text(item)
	item.caret_column = 10000

func _on_filter_item_text_changed(item : FilterItem) -> void:
	if item.has_focus():
		if item.expression.type == ExprNode.Type.MatchString:
			item.expression.match_string = item.text
		
		if not item.text:
			item.expression.type = ExprNode.Type.MatchString
			item.expression.match_string = ''

func connect_filter_item(item : FilterItem, p_connect := true) -> void:
	var signal_to_callable := {
		item.gui_input : _on_filter_item_gui_input.bind(item),
		item.text_changed : _on_filter_item_text_changed.bind(item).unbind(1),
		item.focus_entered : _on_filter_item_focus_changed.bind(item),
		item.focus_exited : _on_filter_item_focus_changed.bind(item),
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

func filter_item_grab_focus() -> void:
	if not _items:
		var item = FILTER_ITEM.instantiate() as FilterItem
		_items.append(item)
		_flow_container.add_child(item)
		connect_filter_item(item)
	_items[-1].grab_focus()
	build()

func update() -> void:
	print('update()')
	if not _updating:
		_updating = true

func build() -> void:
	if not _building:
		_building = true
		update()

func filters_to_string() -> String:
	var split := PackedStringArray()
	for item in _items:
		if not item.is_seprarator() and item.expression.enabled:
			if not item.empty() or item.has_focus():
				split.append(item.filter_to_string())
	return ' '.join(split)

func empty() -> bool:
	return not expression or expression.expressions.is_empty()

func is_editing() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner and is_ancestor_of(focus_owner):
		return true
	return false

func _parse_item_text(item : FilterItem) -> void:
	var finded := false
	
	if not finded:
		if '*' in item.text or '?' in item.text:
			var text := item.text
			item.expression.type = ExprNode.Type.MatchString
			item.expression.match_string = text
			finded = true
	
	if not finded:
		var type_to_name_variations := {
			ExprNode.Type.And : PackedStringArray(['and', '&', '&&', '+']),
			ExprNode.Type.Or : PackedStringArray(['or', '|', '||', '~']),
			ExprNode.Type.Not : PackedStringArray(['not', '!', '-']),
			ExprNode.Type.BracketOpen : PackedStringArray(['(']),
			ExprNode.Type.BracketClose : PackedStringArray([')']),
		}
		var text := ' '.join(item.text.to_lower().split(' ', false))
		for type : ExprNode.Type in type_to_name_variations:
			if text in type_to_name_variations[type]:
				item.expression.type = type
				finded = true
				break
	
	if not finded:
		if data_base:
			var tags := data_base.find_tags_by_name(item.text)
			if tags:
				item.expression.type = ExprNode.Type.Tag
				item.expression.tag = tags[0]
				finded = true
	
	if not finded:
		var text := item.text
		item.expression.type = ExprNode.Type.MatchString
		item.expression.match_string = text
		finded = true
