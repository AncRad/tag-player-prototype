extends Container

signal filters_changed
signal filters_cleared

const FilterItem = preload('filter_item.gd')
const FILTER_ITEM = preload('filter_item.tscn')

@export var data_base : DataBase:
	set(value):
		if value != data_base:
			data_base = value

@export var solver : Solver:
	set(value):
		if value != solver:
			solver = value
			update()


var _flow_container : HFlowContainer

var _updating := false
var _items : Array[FilterItem] = []
#var _filters_string := ''


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_flow_container = %HFlowContainer as HFlowContainer
			update()
			if OS.is_debug_build():
				%DebugLabel1.show()
				%DebugLabel2.show()
			else:
				%DebugLabel1.hide()
				%DebugLabel2.hide()

func _on_filter_item_focus_changed(item : FilterItem) -> void:
	if item.has_focus():
		item.text = item.inputed_text
		update()
	
	else:
		_on_filter_item_text_submitted(item)

func _on_filter_item_text_submitted(item : FilterItem) -> void:
	parse_item_text(item)
	item.inputed_text = item.text
	item.text = item.filter_to_string()
	item.caret_column = 10000
	
	update()

func _on_filter_item_text_changed(item : FilterItem) -> void:
	if item.has_focus() and item.type == FilterItem.Type.MatchString:
		item.inputed_text = item.text
		parse()

func parse_item_text(item : FilterItem) -> void:
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

func create_filter_item() -> FilterItem:
	var item = FILTER_ITEM.instantiate() as FilterItem
	_items.append(item)
	connect_filter_item(item)
	_flow_container.add_child(item)
	return item

func connect_filter_item(item : FilterItem, p_connect := true) -> void:
	var signal_to_callable := {
		item.text_changed : _on_filter_item_text_changed.bind(item).unbind(1),
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
	return ' '.join(split)

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
	
	
	if solver:
		parse()
	
	#if filters_to_string() != _filters_string:
		#_filters_string = filters_to_string()
		#filters_changed.emit()
	
	_updating = false
	
	if empty():
		if not get_viewport().gui_get_focus_owner() or not is_ancestor_of(get_viewport().gui_get_focus_owner()):
			filters_cleared.emit()



	#       ______|______
	#       |      _____|_____
	#    ___|___   |    _____|_____
	#  __|__   |   |    |   |   __|__
	#  |   |   |   |    |   |   |   |
	## T & T | T | T & (T | T | T & T)


func parse() -> void:
	var node := ExprNode.new()
	node.type = ExprNode.Type.SubExpression
	
	_parse_items(_items, node.expressions)
	
	%DebugLabel1.text = node.to_text()
	
	_repair(node.expressions)
	
	%DebugLabel2.text = node.to_text()

static func _parse_items(items : Array[FilterItem], expressions : Array[ExprNode] = [], pos : int = 0) -> int:
	
	var return_on_close_bracket := true
	while pos < items.size():
		var item := items[pos]
		
		if item.empty():
			pos += 1
			continue
		
		match item.type:
			
			FilterItem.Type.BracketOpen:
				if pos == 0:
					return_on_close_bracket = false
				
				else:
					var node := ExprNode.new()
					node.type = ExprNode.Type.SubExpression
					pos = _parse_items(items, node.expressions, pos + 1)
					expressions.append(node)
			
			FilterItem.Type.BracketClose:
				if return_on_close_bracket:
					return pos + 1
			
			FilterItem.Type.Not, FilterItem.Type.And, FilterItem.Type.Or:
				var node := ExprNode.new()
				node.type = item.type as ExprNode.Type
				expressions.append(node)
			
			FilterItem.Type.MatchString, FilterItem.Type.Tag:
				var node := ExprNode.new()
				node.type = item.type as ExprNode.Type
				if item.type == FilterItem.Type.Tag:
					node.tag = item.tag
				else:
					node.match_string = item.inputed_text
				expressions.append(node)
		
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
		
		if node.is_operator(): #not, and, or
			if node.is_binary(): # and, or
				if not left or not right or not left.is_operand():
					expressions.remove_at(pos)
					pos -= 1
					continue
			
			else: # not
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
