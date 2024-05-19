extends Container

#signal filters_changed
signal updated

const FilterItem = preload('filter_item.gd')
const FILTER_ITEM = preload('filter_item.tscn')

@export var data_base : DataBase:
	set(value):
		if value != data_base:
			data_base = value
			build()

@export var solver : Solver:
	set(value):
		if value != solver:
			if solver:
				solver.changed.disconnect(build)
			
			solver = value
			
			if solver:
				solver.changed.connect(build)
			
			build()


var _flow_container : HFlowContainer

var _updating := false
var _building := false
var _items : Array[FilterItem] = []
@export var _expression : ExprNode:
	set(value):
		if value != _expression:
			if _expression:
				_expression.changed.disconnect(build)
			
			_expression = value
			
			if _expression:
				_expression.changed.connect(build)
			
			build()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_flow_container = %HFlowContainer as HFlowContainer
			update()
			if OS.is_debug_build():
				%DebugLabel1.show()
				%DebugLabel2.show()
				pass
			else:
				%DebugLabel1.hide()
				%DebugLabel2.hide()

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

func _on_filter_item_gui_input(event: InputEvent, item: FilterItem) -> void:
	if item.has_focus() and event.is_pressed():
		if (event.is_action('ui_text_caret_left') or event.is_action('ui_text_caret_line_start')
				or event.is_action('ui_text_backspace')):
			if item.caret_column == 0:
				var item_index := _items.find(item)
				
				if item_index == 0:
					var left := FILTER_ITEM.instantiate() as FilterItem
					left.type = FilterItem.Type.MatchString
					_items.insert(0, left)
					_flow_container.add_child(left)
					_flow_container.move_child(left, 0)
					connect_filter_item(left)
					item_index += 1
					update()
				
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
			update()
			
			accept_event()
			return

func _on_filter_item_focus_changed(item : FilterItem) -> void:
	if item.has_focus():
		if item.is_seprarator():
			item.type = FilterItem.Type.MatchString
		item.text = item.inputed_text
		update()
	
	else:
		_on_filter_item_text_submitted(item)

func _on_filter_item_text_submitted(item : FilterItem) -> void:
	_parse_item_text(item)
	#item.inputed_text = item.text
	item.text = item.filter_to_string()
	item.inputed_text = item.text
	item.caret_column = 10000
	
	update()

func _on_filter_item_text_changed(item : FilterItem) -> void:
	if item.has_focus():
		if item.type == FilterItem.Type.MatchString:
			item.inputed_text = item.text
			update()
		
		if not item.text:
			item.type = FilterItem.Type.MatchString
			item.inputed_text = ''
			update()

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
		connect_filter_item(item)
		_flow_container.add_child(item)
	_items[-1].grab_focus()

func update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func build() -> void:
	if not _building:
		_building = true
		update()

func get_tags() -> Array[DataBase.Tag]:
	var tags := [] as Array[DataBase.Tag]
	
	for item in _items:
		if item.type == FilterItem.Type.Tag and item.tag and item.tag.valid:
			tags.append(item.tag)
	
	return tags

func filters_to_string() -> String:
	var split := PackedStringArray()
	for item in _items:
		if not item.empty():
			split.append(item.filter_to_string())
	return ' '.join(split)

func empty() -> bool:
	return not _expression or _expression.expressions.is_empty()

func is_editing() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner and is_ancestor_of(focus_owner):
		return true
	return false

func _update() -> void:
	#var empty_befor := empty()
	
	var pos := 0
	var focused_item : FilterItem
	var items := [] as Array[FilterItem]
	
	## ищем focused_item и составляем массив видимых FilterItem
	for node in _flow_container.get_children():
		if node is Control:
			if node is FilterItem:
				if node.visible:
					items.append(node)
				if node.has_focus():
					focused_item = node
			
			else:
				assert(false)
				_flow_container.remove_child(node)
				node.queue_free()
	
	## удаляем пустые FilterItem кроме focused_item
	while pos < items.size():
		var item := items[pos]
		
		var left : FilterItem
		if pos > 0:
			left = items[pos - 1]
		
		if item != focused_item and item.empty():
			if pos != items.size() - 1 or left and left.empty():
				_flow_container.remove_child(item)
				item.queue_free()
				items.remove_at(pos)
				continue
		
		pos += 1
	
	if _building:
		for item in items:
			connect_filter_item(item, false)
			_flow_container.remove_child(item)
			item.queue_free()
		items.clear()
		_items.clear()
		
		if _expression:
			pos = 0
			while pos < _expression.expressions.size():
				var node := _expression.expressions[pos]
				
				if not node.virtual:
					var item := FILTER_ITEM.instantiate() as FilterItem
					items.append(item)
					item.expr_node = node
					item.type = node.type as FilterItem.Type
					if node.is_operand():
						if item.type == FilterItem.Type.MatchString:
							item.text = node.match_string
							item.inputed_text = item.text
						else:
							item.tag = node.tag
							item.text = item.tag.names[0]
							item.inputed_text = item.text
					item.text = item.filter_to_string()
					item.inputed_text = item.text
					_flow_container.add_child(item)
					connect_filter_item(item)
				
				pos += 1
		
		%DebugLabel1.text = _expression.to_text()
	
	## если в конце нет пустого, то добавляем
	if not items or not items[-1].empty():
		var end := FILTER_ITEM.instantiate() as FilterItem
		end.type = FilterItem.Type.MatchString
		items.append(end)
		_flow_container.add_child(end)
		connect_filter_item(end)
	
	
	## удаляем все крайние разделители, разделители соседствующие с разделителями и пустыми FilterItem
	## создаем разделители между всеми не пустыми FilterItem, не имеющими между собой разделителей
	pos = 0
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
				separator.type = FilterItem.Type.Separator
				items.insert(pos + 1, separator)
				item.add_sibling(separator)
				connect_filter_item(separator)
				pos += 2
				continue
		
		pos += 1
	
	## удаляем все не нужные FilterItem
	for item in _items:
		if is_instance_valid(item) and not item in items:
			connect_filter_item(item, false)
			
			if item.get_parent() == _flow_container:
				_flow_container.remove_child(item)
				item.queue_free()
	
	## обновляем массив
	_items = items
	
	## выполняем парсинг
	if not _building:
		_building = true
		
		if not _expression:
			_expression = ExprNode.new()
			_expression.type = ExprNode.Type.SubExpression
		
		_expression.clear()
		
		_parse_items(items, _expression)
		
		_repair(_expression)
		
		_expression.emit_changed()
		
		if solver:
			var next := Solver.new()
			next.all = false
			next.invert = false
			next.items.clear()
			_expression.compile(next)
			%DebugLabel1.text = _expression.to_text()
			#_expression.expressions.clear()
			#_expression.expressions = _decompile(next)
			#%DebugLabel2.text = _expression.to_text()
			solver.all = next.all
			solver.invert = next.invert
			solver.items.clear()
			solver.items.assign(next.items)
			solver.emit_changed()
	
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
	
	
	#if filters_to_string() != _filters_string:
		#_filters_string = filters_to_string()
		#filters_changed.emit()
	
	#if empty() and not empty_befor:
	
	
	updated.emit()
	_updating = false
	_building = false



	#       ______|______
	#       |      _____|_____
	#    ___|___   |    _____|_____
	#  __|__   |   |    |   |   __|__
	#  |   |   |   |    |   |   |   |
	## T & T | T | T & (T | T | T & T)


func _parse_item_text(item : FilterItem) -> void:
	var finded := false
	
	if not finded:
		if '*' in item.text or '?' in item.text:
			item.type = FilterItem.Type.MatchString
			finded = true
	
	if not finded:
		var type_to_name_variations := {
			FilterItem.Type.And : PackedStringArray(['and', '&', '&&', '+']),
			FilterItem.Type.Or : PackedStringArray(['or', '|', '||', '~']),
			FilterItem.Type.Not : PackedStringArray(['not', '!', '-']),
			FilterItem.Type.BracketOpen : PackedStringArray(['(']),
			FilterItem.Type.BracketClose : PackedStringArray([')']),
		}
		var text := ' '.join(item.text.to_lower().split(' ', false))
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

static func _parse_items(items : Array[FilterItem], node : ExprNode, pos : int = -1) -> int:
	if pos == -1:
		pos = 0
		
		var brackets := 0
		var not_openned := 0
		for item in items:
			if item.type == FilterItem.Type.BracketOpen:
				brackets += 1
			elif item.type == FilterItem.Type.BracketClose:
				if brackets == 0:
					not_openned += 1
				else:
					brackets -= 1
		
		if not_openned:
			for i in not_openned:
				var bracket := ExprNode.new(ExprNode.Type.BracketOpen)
				bracket.virtual = true
				node.append(bracket)
		#if not_openned:
			#var node1 := ExprNode.new()
			#node1.type = ExprNode.Type.SubExpression
			#while not_openned > 0:
				#not_openned -= 1
				#pos = _parse_items(items, node1, pos)
				#
				#var next := ExprNode.new()
				#next.type = ExprNode.Type.SubExpression
				#next.append(node1)
				#node1 = next
			#node.append(node1.expressions[0])
	
	while pos < items.size():
		var item := items[pos]
		
		if item.empty():
			pos += 1
			continue
		
		match item.type:
			
			FilterItem.Type.BracketOpen:
				node.append(ExprNode.new(ExprNode.Type.BracketOpen))
			
			FilterItem.Type.BracketClose:
				node.append(ExprNode.new(ExprNode.Type.BracketClose))
			
			FilterItem.Type.Not, FilterItem.Type.And, FilterItem.Type.Or:
				var new := ExprNode.new(item.type as ExprNode.Type)
				node.append(new)
				item.expr_node = new
			
			FilterItem.Type.MatchString, FilterItem.Type.Tag:
				var node1 := ExprNode.new()
				if item.type == FilterItem.Type.Tag:
					node1.type = ExprNode.Type.Tag
					node1.tag = item.tag
				else:
					node1.type = ExprNode.Type.MatchString
					node1.match_string = item.inputed_text
				node.append(node1)
				item.expr_node = node1
		
		pos += 1
	
	_repair(node)
	
	return pos

static func _repair(node : ExprNode) -> void:
	
	var pos : int = 0
	#while pos < node.expressions.size():
		#var node2 := node.expressions[pos]
		#if node2.type == ExprNode.Type.SubExpression:
			#_repair(node2)
			#if not node2.expressions:
				#node.remove_at(pos)
				#pos -= 1
		#pos += 1
	
	pos = 0
	while maxi(0, pos) < node.expressions.size():
		if pos < 0:
			pos = 0
		
		var this := node.expressions[pos]
		if not this.enabled:
			pos += 1
			continue
		
		var left : ExprNode
		var right : ExprNode
		var p := pos
		while p > 0:
			p -= 1
			var n := node.expressions[p]
			if n.enabled:
				if n.is_operator() or n.is_operand():
					left = n
					break
		p = pos
		while p < node.expressions.size() - 1:
			p += 1
			var n := node.expressions[p]
			if n.enabled:
				if n.is_operator() or n.is_operand():
					right = n
					break
		
		if this.is_operator():
			if this.is_binary():
				if not left or not right or not left.is_operand():
					this.enabled = false
					pos -= 1
					continue
			
			else:
				if not right:
					this.enabled = false
					pos -= 1
					continue
				
				if right.is_operator():
					if right.is_binary():
						this.enabled = false
						pos -= 1
						continue
				
				if right.type == ExprNode.Type.Not:
					this.enabled = false
					right.enabled = false
					pos -= 1
					continue
		
		elif this.is_operand():
			if right:
				if right.is_operand() or not right.is_binary():
					right = ExprNode.new(ExprNode.Type.And)
					right.virtual = true
					node.insert(pos + 1, right)
					pos += 2
					continue
		
		pos += 1
