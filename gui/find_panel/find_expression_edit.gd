extends Container

signal unfocused
signal focused

signal empty

const MenuPanel = preload('res://gui/menu_panel/menu_panel.gd')

@export var expression: ExprNode:
	set(value):
		if not value:
			value = ExprNode.new(ExprNode.Type.SubExpression)
		
		if value != expression:
			_focused_expr = null
			if expression:
				expression.changed.disconnect(queue_sort)
			
			expression = value
			
			if expression:
				expression.changed.connect(queue_sort)

@export var data_base : DataBase:
	set(value):
		if value != data_base:
			data_base = value

var _in_focus := false:
	set(value):
		if value != _in_focus:
			_in_focus = value
			if _in_focus:
				focused.emit()
			else:
				unfocused.emit()

var _is_empty := false:
	set(value):
		if value != _is_empty:
			_is_empty = value
			if _is_empty:
				empty.emit()

var _expr_to_item := {}
var _items: Array[Item] = []
var _lines: Array[Array] = []

var _line_edit: LineEdit
var _menu: MenuPanel
var _menu_building := false
var _menu_focus_input : TreeItem
var _menu_builded_from_text : String

var _focused_expr: ExprNode:
	set(value):
		if value != _focused_expr:
			if _focused_expr:
				if not _line_edit.text:
					if expression.has(_focused_expr):
						expression.erase(_focused_expr)
				else:
					var operator := parse_text_to_operator(_line_edit.text.to_lower())
					if operator != ExprNode.Type.Null:
						_focused_expr.type = operator
			
			_focused_expr = value
			
			if _focused_expr:
				assert(expression.has(_focused_expr))
				_line_edit.text = _focused_expr.to_text()
				_line_edit.show()
				_line_edit.grab_focus()
				_menu.hide()
				_menu_clear()
			
			else:
				_line_edit.release_focus()
				_line_edit.hide()
				_menu.hide()
				_menu_clear()
			
			queue_sort()


func _init() -> void:
	expression = null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_line_edit = %LineEdit as LineEdit
			_menu = %MenuPanel as MenuPanel
			
			_menu.hide()
		
		NOTIFICATION_SORT_CHILDREN:
			_resort()
			update_minimum_size()
		
		NOTIFICATION_THEME_CHANGED:
			queue_sort()
		
		NOTIFICATION_TRANSLATION_CHANGED, NOTIFICATION_LAYOUT_DIRECTION_CHANGED:
			queue_sort()
		
		NOTIFICATION_FOCUS_ENTER:
			if not _focused_expr:
				var next : ExprNode
				var pos := expression.expressions.size()
				while pos > 0:
					pos -= 1
					if not expression.expressions[pos].virtual and expression.expressions[pos].is_empty():
						next = expression.expressions[pos]
						break
				
				if next:
					_focused_expr = next
				
				else:
					var index := expression.expressions.size()
					while index > 0:
						if not expression.expressions[index - 1].virtual:
							break
						index -= 1
					
					var expr := ExprNode.new(ExprNode.Type.MatchString)
					expression.insert(index, expr)
					_focused_expr = expr
			queue_redraw()
		
		NOTIFICATION_FOCUS_EXIT:
			queue_redraw()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree():
		if event.is_pressed() and 'position' in event:
			var focus_owner := get_viewport().gui_get_focus_owner()
			if focus_owner:
				if has_focus() or focus_owner.has_focus():
					if not (get_global_rect().has_point(event.position)
							or _menu.is_visible_in_tree() and _menu.get_global_rect().has_point(event.position)):
						focus_owner.release_focus()

func _gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		if event is InputEventMouseButton:
			if not event.is_echo():
				if event.button_index == MOUSE_BUTTON_LEFT:
					if _items:
						for item in _items:
							if item.rect.has_point(event.position):
								_focused_expr = item.expr
								var text_line := TextLine.new()
								text_line.width = item.rect.size.x
								text_line.alignment = HORIZONTAL_ALIGNMENT_CENTER
								text_line.add_string(_line_edit.text, get_font(), get_font_size())
								_line_edit.caret_column = text_line.hit_test(event.position.x - item.rect.position.x)
								return
						_focused_expr = null
					
					else:
						grab_focus()
					
					accept_event()
					return
				
				elif event.button_index == MOUSE_BUTTON_MIDDLE:
					var to_erase := _items.back() as ExprNode
					for item in _items:
						if item.rect.has_point(event.position):
							to_erase = item.expr
							break
					if to_erase:
						if _focused_expr == to_erase:
							_focused_expr = null
						expression.erase(to_erase)
					
					accept_event()
					return
		
		if event.is_action('find_expression_edit_selected_tag_scroll_left'):
			accept_event()
			if _focused_expr:
				grab_focus_neighbour(-1)
		
		elif event.is_action('find_expression_edit_selected_tag_scroll_right'):
			accept_event()
			if _focused_expr:
				grab_focus_neighbour(+1)

func _draw() -> void:
	if not _line_edit.has_focus() and not _menu.in_focus():
		_focused_expr = null
	
	var font: Font = get_font()
	var font_size: int = get_font_size()
	var font_ascent: int = get_line_ascent()
	#var font_color_default := Color.WHITE.darkened(0.5)
	#var font_color_light := Color.WHITE.darkened(0.2)
	#var item_separation: int = 15
	var line_separation: int = get_line_separation()
	#var line_interval: int = get_line_interval()
	#var line_max_size: float = size.x - item_separation
	#var line_max_count: int = get_line_max_count()
	
	for line_i in _lines.size():
		var line := _lines[line_i] as Array[Item]
		for item_i in line.size():
			var item := line[item_i]
			
			var color : Color
			match item.expr.type:
				ExprNode.Type.And, ExprNode.Type.Or, ExprNode.Type.Not, ExprNode.Type.BracketOpen, ExprNode.Type.BracketClose:
					color = Color('66afcc')
				
				ExprNode.Type.Tag, ExprNode.Type.MatchString:
					color = Color.WHITE.darkened(0.1)
				
				ExprNode.Type.Null:
					color = Color.WHITE.darkened(0.1)
			
			if item.expr == _focused_expr:
				if item.expr.type == ExprNode.Type.Null:
					_line_edit.placeholder_text = '•'
				_line_edit.add_theme_color_override('font_color', color)
				_line_edit.add_theme_color_override('font_placeholder_color', Color.WHITE.darkened(0.5))
			
			else:
				var pos := Vector2(item.rect.position.x, item.rect.position.y + font_ascent + line_separation / 2.0)
				font.draw_string(get_canvas_item(), pos, item.expr.to_text(), HORIZONTAL_ALIGNMENT_CENTER, item.rect.size.x, font_size, color)

func _process(_delta = null) -> void:
	if not _line_edit.visible:
		_menu.hide()
		_menu_clear()
		_menu_building = false
	
	if _menu_building:
		_menu_building = false
		
		_menu.show()
		_menu_build(_line_edit.text)
	
	_in_focus = in_focus()
	_is_empty = is_empty()

func _get_minimum_size() -> Vector2:
	return Vector2(get_line_height() * 3, get_line_interval() * maxi(1, _lines.size()) - get_line_separation())

func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		if _focused_expr:
			if event.is_action('ui_text_caret_down'):
				#if _line_edit.caret_column == _line_edit.text.length():
					_line_edit.accept_event()
					if not _menu.visible:
						_menu.show()
						_menu_building = true
					_menu.grab_focus()
			
			elif event.is_action('ui_text_caret_up'):
				#if _line_edit.caret_column == 0:
					_line_edit.accept_event()
					if not _menu.visible:
						_menu.show()
						_menu_building = true
					_menu.grab_focus()
			
			elif event.is_action('ui_text_backspace') or event.is_action('ui_text_caret_left') or event.is_action('ui_text_caret_line_start'):
				if _line_edit.caret_column == 0:
					_line_edit.accept_event()
					grab_focus_neighbour(-1)
			
			elif event.is_action('ui_text_delete') or event.is_action('ui_text_caret_right') or event.is_action('ui_text_caret_line_end'):
				if _line_edit.caret_column == _line_edit.text.length():
					_line_edit.accept_event()
					grab_focus_neighbour(+1)
			
			elif event.is_action('find_expression_edit_selected_tag_scroll_left'):
				grab_focus_neighbour(-1)
				_line_edit.accept_event()
			
			elif event.is_action('find_expression_edit_selected_tag_scroll_right'):
				_line_edit.accept_event()
				grab_focus_neighbour(+1)

func _on_line_edit_text_submitted(_new_text = null) -> void:
	if _menu_builded_from_text != _line_edit.text:
		_menu_build(_line_edit.text)
	if _menu_focus_input is MenuPanel.ItemButton:
		_menu_focus_input.pressed.emit()

func _on_line_edit_text_changed() -> void:
	if _line_edit.has_focus():
		queue_sort()
		if _focused_expr.type == ExprNode.Type.MatchString:
			_focused_expr.match_string = _line_edit.text
		_menu_building = true

func _on_menu_panel_tree_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		if event.is_action('ui_text_caret_left'):
			_menu._tree.accept_event()
			grab_focus_neighbour(-1)
		
		elif event.is_action('ui_text_caret_right'):
			_menu._tree.accept_event()
			grab_focus_neighbour(+1)
		
		elif event.is_action('ui_cancel'):
			_menu._tree.accept_event()
			if _line_edit.is_visible_in_tree():
				_line_edit.grab_focus()

func _on_menu_selected_operator(operator : ExprNode.Type) -> void:
	_menu.hide()
	_focused_expr.type = operator
	_line_edit.grab_focus()
	_line_edit.text = _focused_expr.to_text()
	_line_edit.caret_column = _line_edit.text.length()

func _on_menu_selected_tag(tag : DataBase.Tag) -> void:
	_menu.hide()
	_focused_expr.type = ExprNode.Type.Tag
	_line_edit.grab_focus()
	_focused_expr.tag = tag
	_line_edit.text = _focused_expr.to_text()
	_line_edit.caret_column = _line_edit.text.length()

func _on_menu_selected_matchn() -> void:
	_menu.hide()
	_focused_expr.type = ExprNode.Type.MatchString
	_focused_expr.match_string = _line_edit.text
	_line_edit.grab_focus()
	_line_edit.text = _focused_expr.to_text()
	_line_edit.caret_column = _line_edit.text.length()

func _on_menu_focus_changeed() -> void:
	if is_instance_valid(_menu_focus_input):
		_menu_focus_input.select(0)
		_menu._tree.scroll_to_item(_menu_focus_input, true)


func grab_focus_neighbour(offset : int) -> void:
	assert(offset)
	if _focused_expr and offset:
		var index := expression.expressions.find(_focused_expr)
		if index != -1:
			var right : bool = offset > 0
			var next : ExprNode
			while offset:
				index += signi(offset)
				if index < 0 or index >= expression.expressions.size():
					break
				var expr := expression.expressions[index]
				if not expr.virtual:
					offset -= signi(offset)
					if not offset:
						next = expr
						break
			
			if not next:
				next = ExprNode.new(ExprNode.Type.MatchString)
				expression.insert(clampi(index, 0, expression.expressions.size()), next)
			
			if next:
				_focused_expr = next
				_line_edit.caret_column = 0 if right else _line_edit.text.length()

func in_focus() -> bool:
	if has_focus():
		return true
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner and is_ancestor_of(focus_owner)

func is_empty() -> bool:
	return not expression or expression.is_empty()

func _resort() -> void:
	if not is_visible_in_tree():
		return
	
	if expression._changed:
		expression.update()
	
	if not _line_edit.has_focus() and not _menu.in_focus():
		_focused_expr = null
	
	var font: Font = get_font()
	var font_size: int = get_font_size()
	#var font_ascent: int = get_line_ascent()
	#var font_color_default := Color.WHITE.darkened(0.5)
	#var font_color_light := Color.WHITE.darkened(0.2)
	var item_separation: int = 15
	#var line_separation: int = get_line_separation()
	var line_interval: int = get_line_interval()
	var line_max_size: float = size.x
	#var line_max_count: int = get_line_max_count()
	
	var new_expr_to_item := {}
	var items := [] as Array[Item]
	for expr in expression.expressions:
		if not expr.virtual and expr.type != ExprNode.Type.Null:
			var item: Item
			if expr in _expr_to_item:
				item = _expr_to_item[expr]
			else:
				item = Item.new(expr)
			
			new_expr_to_item[expr] = item
			items.append(item)
	_expr_to_item = new_expr_to_item
	_items = items
	
	if _focused_expr and not _focused_expr in _expr_to_item:
		_focused_expr = null
	
	_lines.clear()
	var line := [] as Array[Item]
	var line_size: float = -item_separation
	var pack := [] as Array[Item]
	var pack_size: float = -item_separation
	for item in items:
		var text := item.expr.to_text()
		if item.expr == _focused_expr:
			text = _line_edit.text
		
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		text_size = maxf(text_size, _line_edit.get_combined_minimum_size().x)
		item.rect = Rect2(maxf(line_size, 0) + maxf(pack_size, 0) + (item_separation if pack or line else 0),
				line_interval * _lines.size(), text_size, line_interval)
		pack.append(item)
		pack_size += item_separation + item.rect.size.x
		if item.expr.is_operand() or item == items[-1] or item.expr.is_bracket_close():
			for pack_item in pack:
				if line_size + item_separation + pack_size > line_max_size:
					_lines.append(line)
					line_size = -item_separation
					line = []
				pack_item.rect.position = Vector2(line_size + item_separation, line_interval * _lines.size())
				line_size += item_separation + pack_item.rect.size.x
				line.append(pack_item)
				pack_size -= item_separation + pack_item.rect.size.x
			pack.clear()
			pack_size = -item_separation
		
	assert(not pack)
	if line or not _lines:
		_lines.append(line)
	
	if _focused_expr:
		var item := _expr_to_item[_focused_expr] as Item
		fit_child_in_rect(_line_edit, item.rect)
		var item_global_rect := get_global_transform() * item.rect
		_menu.set_global_position(Vector2(item_global_rect.position.x, item_global_rect.end.y))
		_menu.size = Vector2(150, 250)
	print(expression.to_text())
	
	queue_redraw()

func _menu_build(text : String) -> void:
	_menu_clear()
	_menu_builded_from_text = text
	if text:
		var operator := parse_text_to_operator(text.to_lower())
		if operator != ExprNode.Type.Null:
			var but_text := ExprNode.Type.find_key(operator) as String
			if not operator in [ExprNode.Type.BracketOpen, ExprNode.Type.BracketClose]:
				but_text = but_text.to_upper()
			var but := _menu.add_button(but_text, Color('66afcc'))
			but.pressed.connect(_on_menu_selected_operator.bind(operator))
			_menu_focus_input = but
		
		var but_matchn := _menu.add_button('matchn', Color('66afcc'))
		but_matchn.pressed.connect(_on_menu_selected_matchn)
		
		if data_base:
			var tags := data_base.find_tags_by_name(text)
			for tag in tags:
				var but := _menu.add_button(tag.get_name())
				but.pressed.connect(_on_menu_selected_tag.bind(tag))
				if not _menu_focus_input:
					_menu_focus_input = but
		
		if not _menu_focus_input:
			_menu_focus_input = but_matchn
	
	else:
		for operator in [ExprNode.Type.And, ExprNode.Type.Or, ExprNode.Type.Not, ExprNode.Type.BracketOpen, ExprNode.Type.BracketClose]:
			var but_text := ExprNode.Type.find_key(operator) as String
			if not operator in [ExprNode.Type.BracketOpen, ExprNode.Type.BracketClose]:
				but_text = but_text.to_upper()
			var but := _menu.add_button(but_text, Color('66afcc'))
			but.pressed.connect(_on_menu_selected_operator.bind(operator))

func _menu_clear() -> void:
	_menu.clear()
	_menu_focus_input = null
	_menu_builded_from_text = ''


func has_point(point: Vector2) -> bool:
	return Rect2(Vector2(), size).grow(0.005).has_point(point)

func get_font() -> Font:
	return get_theme_font('font')

func get_font_size() -> int:
	return 14

func get_line_height() -> int:
	return int(get_font().get_height(get_font_size()))

func get_line_ascent() -> int:
	return int(get_font().get_ascent(get_font_size()))

func get_line_descent() -> int:
	return int(get_font().get_descent(get_font_size()))

func get_line_separation() -> int:
	return 2

func get_line_interval() -> int:
	return get_line_height() + get_line_separation()

func get_line_at_position(p_position: Vector2) -> float:
	if has_point(p_position):
		return p_position.y / get_line_interval()
	return -1

static func parse_text_to_operator(text : String) -> ExprNode.Type:
	match text:
		'and', '&', '&&', '+': return ExprNode.Type.And
		'or', '|', '||', '~': return ExprNode.Type.Or
		'not', '!', '-': return ExprNode.Type.Not
		'(': return ExprNode.Type.BracketOpen
		')': return ExprNode.Type.BracketClose
		_: return ExprNode.Type.Null


class Item:
	var expr: ExprNode
	#var text_line := TextLine.new()
	var rect: Rect2
	#var text: String
	
	func _init(p_expr: ExprNode) -> void:
		expr = p_expr
