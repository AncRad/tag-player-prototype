extends Container

@export var expression : ExprNode:
	set(value):
		if not value:
			value = ExprNode.new(ExprNode.Type.SubExpression)
		
		if value != expression:
			if expression:
				expression.changed.disconnect(queue_sort)
			
			expression = value
			
			if expression:
				expression.changed.connect(queue_sort)

var _line_edit : LineEdit
var _node_to_item := {}
var _items : Array[Item] = []
var _lines : Array[Array] = []

var _focused_node : ExprNode:
	set(value):
		if value != _focused_node:
			print(value)
			if _focused_node in _node_to_item:
				var item := _node_to_item[_focused_node] as Item
				_line_edit.hide()
			
			_focused_node = value
			
			if _focused_node in _node_to_item:
				var item := _node_to_item[_focused_node] as Item
				_line_edit.text = item.get_visible_text()
				_line_edit.grab_focus()
				_line_edit.show()
			
			else:
				_focused_node = null
			
			queue_sort()
#
#var _caret_blink_interval : float = 0.6
#var _caret_blink_time : float = 0.0
#var _caret_visible : bool = false:
	#set(value):
		#_caret_visible = value
		#_caret_draw = _caret_visible
		#_caret_blink_time = 0.0
		#queue_redraw()
#var _caret_draw : bool = false:
	#set(value):
		#_caret_draw = value
		#_caret_blink_time = 0.0
		#queue_redraw()


func _init() -> void:
	expression = null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_line_edit = %LineEdit as LineEdit
		
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
					for line : Array[Item] in _lines:
						for item in line:
							if item.rect.has_point(event.position):
								_focused_node = item.expr
								_line_edit.grab_focus()
								var text_line := TextLine.new()
								text_line.add_string(_line_edit.text, get_font(), get_font_size())
								_line_edit.caret_column = text_line.hit_test(event.position.x - item.rect.position.x)
								return
					_focused_node = null

func _on_line_edit_gui_input(event: InputEvent) -> void:
	if event.is_pressed():
		if _focused_node in _node_to_item:
			if event.is_action('ui_text_backspace') or event.is_action('ui_text_caret_left'):
				if _line_edit.caret_column == 0:
					_line_edit.accept_event()
					if _focused_node and _focused_node in _node_to_item:
						var item := _node_to_item[_focused_node] as Item
						var index := _items.find(item)
						if _items.size() > 1 and index > 0:
							_focused_node = _items[index - 1].expr
							_line_edit.caret_column = _line_edit.text.length()
			
			elif event.is_action('ui_text_delete') or event.is_action('ui_text_caret_right'):
				if _line_edit.caret_column == _line_edit.text.length():
					_line_edit.accept_event()
					if _focused_node and _focused_node in _node_to_item:
						var item := _node_to_item[_focused_node] as Item
						var index := _items.find(item)
						if _items.size() > 1 and index < _items.size() - 1:
							_focused_node = _items[index + 1].expr
							_line_edit.caret_column = 0

#func _process(delta: float) -> void:
	#if _caret_visible:
		#_caret_blink_time += delta
		#if _caret_blink_time > _caret_blink_interval:
			#_caret_draw = not _caret_draw
			#_caret_blink_time = 0.0

func _draw() -> void:
	print('%6d # ' % Engine.get_frames_drawn(), '_draw')
	
	if not _line_edit.has_focus():
		_focused_node = null
	
	var font : Font = get_font()
	var font_size : int = get_font_size()
	var font_ascent : int = get_line_ascent()
	#var font_color_default := Color.WHITE.darkened(0.5)
	#var font_color_light := Color.WHITE.darkened(0.2)
	var item_separation : int = 15
	var line_separation : int = get_line_separation()
	var line_interval : int = get_line_interval()
	var line_max_size : float = size.x - item_separation
	#var line_max_count : int = get_line_max_count()
	
	for line_i in _lines.size():
		var line := _lines[line_i] as Array[Item]
		#var line_size : float = 0
		for item_i in line.size():
			var item := line[item_i]
			if item.expr != _focused_node:
				var pos := Vector2(item.rect.position.x, item.rect.position.y + font_ascent + line_separation / 2.0)
				font.draw_string(get_canvas_item(), pos, item.get_visible_text(), HORIZONTAL_ALIGNMENT_LEFT, item.rect.size.x, font_size)
			#line_size += text_size + item_separation
			#if line_size <= 0:
				#break
	
	#if _caret_draw:
		#if _focused_node in _node_to_item:
			#var item := _node_to_item[_focused_node] as Item
			#var pos_x := item.rect.position.x
			#var text := _line_edit.text
			#if text:
				#pos_x += get_font().get_string_size(text.left(_line_edit.caret_column), HORIZONTAL_ALIGNMENT_LEFT, -1,
						#get_font_size(), TextServer.JUSTIFICATION_NONE).x
			#var line_pos_a := Vector2(pos_x, item.rect.position.y + get_line_separation() / 2.0)
			#var line_pos_b := Vector2(pos_x, item.rect.end.y - get_line_separation() / 2.0)
			#draw_line(line_pos_a, line_pos_b, Color.WHITE)

func _get_minimum_size() -> Vector2:
	print('%6d # ' % Engine.get_frames_drawn(), '_get_minimum_size')
	return Vector2(get_line_height() * 3, get_line_interval() * maxi(1, _lines.size()) - get_line_separation())

func _on_line_edit_text_changed() -> void:
	if _focused_node and _focused_node in _node_to_item:
		#var item := _node_to_item[_focused_node] as Item
		#item.text = _line_edit.text
		queue_sort()

func _resort() -> void:
	if not is_visible_in_tree():
		return
	
	var t := Time.get_ticks_usec()
	
	var font : Font = get_font()
	var font_size : int = get_font_size()
	#var font_ascent : int = get_line_ascent()
	#var font_color_default := Color.WHITE.darkened(0.5)
	#var font_color_light := Color.WHITE.darkened(0.2)
	var item_separation : int = 15
	var line_separation : int = get_line_separation()
	var line_interval : int = get_line_interval()
	var line_max_size : float = size.x - item_separation
	#var line_max_count : int = get_line_max_count()
	
	var new_node_to_item := _node_to_item.duplicate()
	var items := [] as Array[Item]
	for expr in expression.expressions:
		if expr.enabled and not expr.virtual and expr.type != ExprNode.Type.Null:
			var item : Item
			if expr in _node_to_item:
				item = _node_to_item[expr]
			else:
				item = Item.new(expr)
			
			new_node_to_item[expr] = item
			items.append(item)
	_node_to_item = new_node_to_item
	_items = items
	
	if _focused_node and not _focused_node in _node_to_item:
		_focused_node = null
		release_focus()
	
	_lines.clear()
	var line := [] as Array[Item]
	var line_size : float
	#var pack := [] as Array[Item]
	#var pack_size : float
	for item in items:
		var text := item.get_visible_text()
		if item.expr == _focused_node:
			text = _line_edit.text
		
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var fit := line_size + text_size < line_max_size
		if not fit and line:
			_lines.append(line)
			line_size = 0
			line = []
		line.append(item)
		
		item.rect = Rect2(line_size, line_interval * _lines.size(), text_size, line_interval)
		
		if item.expr == _focused_node:
			fit_child_in_rect(_line_edit, item.rect)
		
		line_size += item.rect.size.x + item_separation
	if line or not _lines:
		_lines.append(line)
	
	queue_redraw()
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
	
	func get_visible_text() -> String:
		#if text:
			#return text
		return expression_to_text(expr)
	
	func get_expression_text() -> String:
		assert(expr)
		if not expr:
			return ''
		return expression_to_text(expr)
	
	#
	#func get_size() -> 
	#
	static func expression_to_text(expression : ExprNode) -> String:
		match expression.type:
			ExprNode.Type.Null:
				return '•'
			
			ExprNode.Type.Not:
				return 'NOT'
			
			ExprNode.Type.And:
				return 'AND'
			
			ExprNode.Type.Or:
				return 'OR'
			
			ExprNode.Type.Tag:
				if expression.tag and expression.tag.valid:
					if expression.tag.names:
						assert(expression.tag.names[0])
						return expression.tag.names[0]
					
					return '[Unnamed tag]'
				
				else:
					return '[Invalid tag]'
			
			ExprNode.Type.MatchString:
				return expression.get_value()
			
			ExprNode.Type.BracketOpen:
				return '('
			
			ExprNode.Type.BracketClose:
				return ')'
			
			_:
				assert(false)
				return '<err expr>'

