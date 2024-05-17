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
var _expression_root : ExprNode


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
	update()
	_building = true

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
	return not _expression_root or _expression_root.expressions.is_empty()

func is_editing() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner and is_ancestor_of(focus_owner):
		return true
	return false

func _update() -> void:
	#var empty_befor := empty()
	
	if _building:
		#_build()
		pass
	
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
	var pos := 0
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
	
	## выполняем парсинг
	if solver:
		_parse()
	
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
	
	## обновляем массив
	_items = items
	
	
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

func _parse() -> void:
	if not _expression_root:
		_expression_root = ExprNode.new()
		_expression_root.type = ExprNode.Type.SubExpression
	
	_expression_root.expressions.clear()
	
	_parse_items(_items, _expression_root.expressions)
	
	_repair(_expression_root.expressions)
	
	if solver:
		var next := Solver.new()
		next.all = false
		next.invert = false
		next.items.clear()
		_compile(_expression_root.expressions, next)
		%DebugLabel1.text = _expression_root.to_text()
		#_expression_root.expressions.clear()
		#_expression_root.expressions = _decompile(next)
		#%DebugLabel2.text = _expression_root.to_text()
		solver.all = next.all
		solver.invert = next.invert
		solver.items.clear()
		solver.items.assign(next.items)
		solver.emit_changed()

static func _parse_items(items : Array[FilterItem], expressions : Array[ExprNode] = [], pos : int = -1) -> int:
	
	
	var return_on_close_bracket := pos != -1
	
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
			var node := ExprNode.new()
			node.type = ExprNode.Type.SubExpression
			while not_openned > 0:
				not_openned -= 1
				pos = _parse_items(items, node.expressions, pos)
				
				var next := ExprNode.new()
				next.type = ExprNode.Type.SubExpression
				next.expressions.append(node)
				node = next
			expressions.append(node.expressions[0])
	
	while pos < items.size():
		var item := items[pos]
		
		if item.empty():
			pos += 1
			continue
		
		match item.type:
			
			FilterItem.Type.BracketOpen:
				var node := ExprNode.new()
				expressions.append(node)
				node.type = ExprNode.Type.SubExpression
				pos = _parse_items(items, node.expressions, pos + 1)
			
			FilterItem.Type.BracketClose:
				assert(return_on_close_bracket)
				if return_on_close_bracket:
					return pos + 1
			
			FilterItem.Type.Not, FilterItem.Type.And, FilterItem.Type.Or:
				var node := ExprNode.new()
				expressions.append(node)
				node.type = item.type as ExprNode.Type
			
			FilterItem.Type.MatchString, FilterItem.Type.Tag:
				var node := ExprNode.new()
				expressions.append(node)
				node.type = item.type as ExprNode.Type
				if item.type == FilterItem.Type.Tag:
					node.tag = item.tag
				else:
					node.match_string = item.get_match_string()
		
		pos += 1
	
	
	
	return pos

static func _repair(expressions : Array[ExprNode]) -> void:
	
	var pos : int = 0
	while pos < expressions.size():
		var node := expressions[pos]
		if node.type == ExprNode.Type.SubExpression:
			_repair(node.expressions)
			if not node.expressions:
				expressions.remove_at(pos)
				pos -= 1
		pos += 1
	
	pos = 0
	while maxi(0, pos) < expressions.size():
		if pos < 0:
			pos = 0
		
		var node := expressions[pos]
		var left : ExprNode
		var right : ExprNode
		if pos > 0:
			left = expressions[pos - 1]
		if pos < expressions.size() - 1:
			right = expressions[pos + 1]
		
		if node.is_operator():
			if node.is_binary():
				if not left or not right or not left.is_operand():
					expressions.remove_at(pos)
					pos -= 1
					continue
			
			else:
				if not right:
					expressions.remove_at(pos)
					pos -= 1
					continue
				
				if right.is_operator():
					if right.is_binary():
						expressions.remove_at(pos)
						pos -= 1
						continue
				
				if right.type == ExprNode.Type.Not:
					expressions.remove_at(pos)
					expressions.remove_at(pos)
					pos -= 1
					continue
		
		elif node.is_operand():
			if right and right.is_operand():
				right = ExprNode.new()
				right.type = ExprNode.Type.And
				expressions.insert(pos + 1, right)
				pos += 2
				continue
		
		else:
			assert(false)
		
		pos += 1

@warning_ignore('shadowed_variable')
static func _compile(expressions : Array[ExprNode], solver : Solver, begin := 0) -> int:
	var pos := begin
	
	var invert := false
	var stack_up := false
	while pos < expressions.size():
		var node := expressions[pos]
		
		match node.type:
			ExprNode.Type.Not:
				invert = true
			
			ExprNode.Type.And, FilterItem.Type.Or:
				if solver.items.size() >= 2:
					stack_up = solver.all != (node.type == ExprNode.Type.And)
					if stack_up and begin != 0:
						return pos
				
				else:
					solver.all = node.type == ExprNode.Type.And
			
			ExprNode.Type.MatchString, ExprNode.Type.Tag, ExprNode.Type.SubExpression:
				var right
				if node.type == ExprNode.Type.SubExpression:
					right = Solver.new()
					right.invert = invert
					_compile(node.expressions, right)
				
				elif invert:
					right = Solver.new()
					right.invert = invert
					right.items.append(node.get_value())
				
				else:
					right = node.get_value()
				
				if stack_up:
					stack_up = false
					var next := Solver.new()
					
					if solver.all:
						next.all = solver.all
						next.invert = solver.invert
						next.items = solver.items
						
						solver.all = not solver.all
						solver.invert = false
						solver.items = [next, right]
					else:
						next.all = not solver.all
						next.invert = invert
						next.items = [solver.items[-1]]
						solver.items[-1] = next
						pos = _compile(expressions, next, pos)
				
				else:
					solver.items.append(right)
				
				invert = false
		
		pos += 1
	
	return pos

@warning_ignore('shadowed_variable')
static func _decompile(solver : Solver) -> Array[ExprNode]:
	var root := [] as Array[ExprNode]
	var expressions := root
	
	if solver.invert:
		var node := ExprNode.new()
		expressions.append(node)
		node.type = ExprNode.Type.Not
		if solver.items.size() != 1:
			node = ExprNode.new()
			expressions.append(node)
			node.type = ExprNode.Type.SubExpression
			expressions = node.expressions
	
	for i in solver.items.size():
		var item = solver.items[i]
		if item is Solver:
			assert(solver.items)
			
			if not item.all and solver.all and not (item.invert and item.items.size() == 1):
				var node := ExprNode.new()
				expressions.append(node)
				node.type = ExprNode.Type.SubExpression
				node.expressions = _decompile(item)
			else:
				expressions.append_array(_decompile(item))
		
		elif item is DataBase.Tag:
			var node := ExprNode.new()
			expressions.append(node)
			node.type = ExprNode.Type.Tag
			node.tag = item
		
		elif item is String:
			var node := ExprNode.new()
			expressions.append(node)
			node.type = ExprNode.Type.MatchString
			node.match_string = item
		
		else:
			assert(false)
		
		if i < solver.items.size() - 1:
			var node := ExprNode.new()
			expressions.append(node)
			if solver.all:
				node.type = ExprNode.Type.And
			else:
				node.type = ExprNode.Type.Or
	
	return root

static func _build() -> void:
	pass


class ExprNode:
	enum Type {
		Not = FilterItem.Type.Not,
		And = FilterItem.Type.And,
		Or = FilterItem.Type.Or,
		Tag = FilterItem.Type.Tag,
		MatchString = FilterItem.Type.MatchString,
		BracketOpen = FilterItem.Type.BracketOpen,
		BracketClose = FilterItem.Type.BracketClose,
		SubExpression,
	}
	var type : Type
	var virtual := false
	var disabled := false
	
	## Tag
	var tag : DataBase.Tag
	## MatchString
	var match_string : String
	
	## SubExpression
	var expressions : Array[ExprNode] = []
	
	## Tag, MatchString
	func get_value() -> Variant:
		if type == Type.Tag:
			return tag
		if type == Type.MatchString:
			return match_string
		return
	
	
	func is_operator() -> bool:
		match type:
			Type.Not, Type.And, Type.Or:
				return true
		return false
	
	func is_binary() -> bool:
		match type:
			Type.And, Type.Or:
				return true
			
			Type.Not:
				return false
		return false
	
	func is_operand() -> bool:
		match type:
			Type.MatchString, Type.Tag, Type.SubExpression:
				return true
		return false
	
	func to_text() -> String:
		match type:
			Type.Not:
				return 'NOT'
			
			Type.And:
				return 'AND'
			
			Type.Or:
				return 'OR'
			
			Type.Tag:
				return '[tag:%d]' % tag.key
			
			Type.MatchString:
				return '[%s]' % match_string
			
			Type.BracketOpen:
				return '('
			
			Type.BracketClose:
				return ')'
			
			Type.SubExpression:
				var texts : Array[String] = []
				for node in expressions:
					texts.append(node.to_text())
				return '(%s)' % ' '.join(texts)
			
			_:
				return '<err expr>'
