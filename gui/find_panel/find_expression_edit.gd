extends Container
#•

@export var expression : ExprNode:
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

var _line_edit : LineEdit
var _tree : Tree
var _expr_to_item := {}
var _items : Array[Item] = []
var _lines : Array[Array] = []

var _focused_expr : ExprNode:
	set(value):
		if value != _focused_expr:
			if not _line_edit.text:
				if expression.has(_focused_expr):
					expression.erase(_focused_expr)
			
			_focused_expr = value
			
			if _focused_expr:
				assert(expression.has(_focused_expr))
				_line_edit.text = _focused_expr.to_text()
				_line_edit.show()
				_line_edit.grab_focus()
			
			else:
				_line_edit.release_focus()
				_line_edit.hide()
			
			queue_sort()


func _init() -> void:
	expression = null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_line_edit = %LineEdit as LineEdit
			_tree = %Tree as Tree
		
		NOTIFICATION_SORT_CHILDREN:
			_resort()
			update_minimum_size()
		
		NOTIFICATION_THEME_CHANGED:
			queue_sort()
		
		NOTIFICATION_TRANSLATION_CHANGED, NOTIFICATION_LAYOUT_DIRECTION_CHANGED:
			queue_sort()
		
		#NOTIFICATION_FOCUS_EXIT:

func _gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		if not event.is_echo():
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					accept_event()
					if _items:
						for item in _items:
							if item.rect.has_point(event.position):
								_focused_expr = item.expr
								_line_edit.grab_focus()
								var text_line := TextLine.new()
								text_line.add_string(_line_edit.text, get_font(), get_font_size())
								_line_edit.caret_column = text_line.hit_test(event.position.x - item.rect.position.x)
								return
						_focused_expr = null
					
					else:
						var expr := ExprNode.new(ExprNode.Type.MatchString)
						expression.append(expr)
						_focused_expr = expr
				
				elif event.button_index == MOUSE_BUTTON_MIDDLE:
					accept_event()
					var to_erase := _items.back() as ExprNode
					for item in _items:
						if item.rect.has_point(event.position):
							to_erase = item.expr
							break
					if to_erase:
						if _focused_expr == to_erase:
							_focused_expr = null
						expression.erase(to_erase)

func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		if _focused_expr in _expr_to_item:
			if event.is_action('ui_text_backspace') or event.is_action('ui_text_caret_left'):
				if _line_edit.caret_column == 0:
					_line_edit.accept_event()
					if _focused_expr and _focused_expr in _expr_to_item:
						var item := _expr_to_item[_focused_expr] as Item
						var index := _items.find(item)
						if _items.size() > 1 and index > 0:
							_focused_expr = _items[index - 1].expr
							_line_edit.caret_column = _line_edit.text.length()
						
						else:
							var expr := ExprNode.new(ExprNode.Type.MatchString)
							index = expression.expressions.find(item.expr)
							if index != -1 or not expression.expressions:
								expression.insert(maxi(0, index), expr)
								_focused_expr = expr
			
			elif event.is_action('ui_text_delete') or event.is_action('ui_text_caret_right'):
				if _line_edit.caret_column == _line_edit.text.length():
					_line_edit.accept_event()
					if _focused_expr and _focused_expr in _expr_to_item:
						var item := _expr_to_item[_focused_expr] as Item
						var index := _items.find(item)
						if _items.size() > 1 and index < _items.size() - 1:
							_focused_expr = _items[index + 1].expr
							_line_edit.caret_column = 0
						
						else:
							var expr := ExprNode.new(ExprNode.Type.MatchString)
							index = expression.expressions.find(item.expr)
							if index != -1 or not expression.expressions:
								expression.insert(maxi(0, index + 1), expr)
								_focused_expr = expr

func _draw() -> void:
	print('%6d # ' % Engine.get_frames_drawn(), '_draw')
	
	if not _line_edit.has_focus():
		_focused_expr = null
	
	var font : Font = get_font()
	var font_size : int = get_font_size()
	var font_ascent : int = get_line_ascent()
	#var font_color_default := Color.WHITE.darkened(0.5)
	#var font_color_light := Color.WHITE.darkened(0.2)
	#var item_separation : int = 15
	var line_separation : int = get_line_separation()
	#var line_interval : int = get_line_interval()
	#var line_max_size : float = size.x - item_separation
	#var line_max_count : int = get_line_max_count()
	
	for line_i in _lines.size():
		var line := _lines[line_i] as Array[Item]
		for item_i in line.size():
			var item := line[item_i]
			
			if item.expr == _focused_expr:
				#_focused_expr_exists = true
				pass
			
			else:
				var pos := Vector2(item.rect.position.x, item.rect.position.y + font_ascent + line_separation / 2.0)
				font.draw_string(get_canvas_item(), pos, item.expr.to_text(), HORIZONTAL_ALIGNMENT_LEFT, item.rect.size.x, font_size)

func _get_minimum_size() -> Vector2:
	print('%6d # ' % Engine.get_frames_drawn(), '_get_minimum_size')
	return Vector2(get_line_height() * 3, get_line_interval() * maxi(1, _lines.size()) - get_line_separation())

func _on_line_edit_text_changed() -> void:
	if _focused_expr and _focused_expr in _expr_to_item:
		queue_sort()
		if _focused_expr.type == ExprNode.Type.MatchString:
			_focused_expr.match_string = _line_edit.text

func _resort() -> void:
	if not is_visible_in_tree():
		return
	
	if expression._changed:
		expression.update()
	
	var t := Time.get_ticks_usec()
	
	if not _line_edit.has_focus():
		_focused_expr = null
	
	var font : Font = get_font()
	var font_size : int = get_font_size()
	#var font_ascent : int = get_line_ascent()
	#var font_color_default := Color.WHITE.darkened(0.5)
	#var font_color_light := Color.WHITE.darkened(0.2)
	var item_separation : int = 15
	#var line_separation : int = get_line_separation()
	var line_interval : int = get_line_interval()
	var line_max_size : float = size.x - item_separation
	#var line_max_count : int = get_line_max_count()
	
	var new_expr_to_item := {}
	var items := [] as Array[Item]
	for expr in expression.expressions:
		if not expr.virtual and expr.type != ExprNode.Type.Null:
			var item : Item
			if expr in _expr_to_item:
				item = _expr_to_item[expr]
			else:
				item = Item.new(expr)
			
			new_expr_to_item[expr] = item
			items.append(item)
	_expr_to_item = new_expr_to_item
	_items = items
	
	if _focused_expr:
		if not _focused_expr in _expr_to_item:
			_focused_expr = null
	
	_lines.clear()
	var line := [] as Array[Item]
	var line_size : float
	#var pack := [] as Array[Item]
	#var pack_size : float
	for item in items:
		var text := item.expr.to_text()
		if item.expr == _focused_expr:
			text = _line_edit.text
		
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var fit := line_size + text_size < line_max_size
		if not fit and line:
			_lines.append(line)
			line_size = 0
			line = []
		line.append(item)
		
		item.rect = Rect2(line_size, line_interval * _lines.size(), text_size, line_interval)
		
		if item.expr == _focused_expr:
			fit_child_in_rect(_line_edit, item.rect)
		
		line_size += item.rect.size.x + item_separation
	if line or not _lines:
		_lines.append(line)
	
	queue_redraw()
	#_committing = false
	print('%6d # ' % Engine.get_frames_drawn(), '_resort за %d мкс' % (Time.get_ticks_usec() - t))


func has_point(point : Vector2) -> bool:
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

func get_line_at_position(p_position : Vector2) -> float:
	if has_point(p_position):
		return p_position.y / get_line_interval()
	return -1


class Item:
	var expr : ExprNode
	#var text_line := TextLine.new()
	var rect : Rect2
	#var text : String
	
	func _init(p_expr : ExprNode) -> void:
		expr = p_expr
