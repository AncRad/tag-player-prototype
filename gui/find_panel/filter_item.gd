extends LineEdit

const FilterItem = preload('filter_item.gd')

var expression : ExprNode:
	set(value):
		if not value:
			value = ExprNode.new()
		
		if value != expression:
			if expression:
				expression.changed.disconnect(queue_redraw)
				expression.type_changed.disconnect(_update_type)
			
			expression = value
			
			if expression:
				expression.changed.connect(queue_redraw)
				expression.type_changed.connect(_update_type)
			
			queue_redraw()


func _init() -> void:
	expression = null

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			selecting_enabled = false
			if has_focus():
				release_focus()
		
		NOTIFICATION_DRAG_END:
			selecting_enabled = true

func _draw() -> void:
	_update_type()
	
	if not has_focus():
		text = filter_to_string()
	
	if not expression.enabled:
		draw_line(Vector2(0, size.y / 2), Vector2(size.x, size.y / 2), get_theme_color('font_color'), 2)

func _get_drag_data(_at_position: Vector2) -> Variant:
	return self

func _get_tooltip(_at_position) -> String:
	if expression.is_operator():
		return 'Operator: %s' % expression.to_text()
	elif expression.is_operand():
		if expression.type == ExprNode.Type.Tag:
			return 'Tag: %s' % expression.to_text()
		else:
			if text:
				return 'Regualr expression: %s' % expression.to_text()
			else:
				return 'Click to enter text'
	elif is_seprarator():
		return 'Separator'
	return expression.to_text()

func filter_to_string() -> String:
	match expression.type:
		ExprNode.Type.MatchString:
			return expression.match_string
		
		ExprNode.Type.And, ExprNode.Type.Or, ExprNode.Type.Not:
			return expression.to_text()
		
		ExprNode.Type.BracketOpen:
			return '('
		
		ExprNode.Type.BracketClose:
			return ')'
		
		ExprNode.Type.Tag:
			if expression.tag and expression.tag.valid:
				if expression.tag.names:
					assert(expression.tag.names[0])
					return expression.tag.names[0]
				
				return '[Unnamed tag]'
			
			else:
				return '[Invalid tag]'
	
	return ''

func is_seprarator() -> bool:
	return expression.type == ExprNode.Type.Null

func empty() -> bool:
	match expression.type:
		ExprNode.Type.MatchString:
			return expression.match_string.is_empty() and text.is_empty()
		
		ExprNode.Type.And, ExprNode.Type.Or, ExprNode.Type.Not, ExprNode.Type.BracketOpen, ExprNode.Type.BracketClose, ExprNode.Type.Null:
			return false
		
		ExprNode.Type.Tag:
			return not expression.tag or not expression.tag.valid
	return true

#func get_match_string() -> String:
	#return '*%s*' % '*'.join(inputed_text.replace('*', ' ').split(' ', false))

func _update_type() -> void:
	placeholder_text = ''
	match expression.type:
		ExprNode.Type.And, ExprNode.Type.Or, ExprNode.Type.Not, ExprNode.Type.BracketOpen, ExprNode.Type.BracketClose:
			add_theme_color_override('font_color', Color('66afcc'))
		
		ExprNode.Type.Tag, ExprNode.Type.MatchString:
			add_theme_color_override('font_color', Color.WHITE.darkened(0.1))
		
		ExprNode.Type.Null:
			placeholder_text = '•'
			add_theme_color_override('font_color', Color.WHITE.darkened(0.1))
			add_theme_color_override('font_placeholder_color', Color.WHITE.darkened(0.5))
	
	queue_redraw()
