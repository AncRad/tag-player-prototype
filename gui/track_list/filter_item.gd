extends LineEdit

const FilterItem = preload('filter_item.gd')

enum Type {MatchString, And, Or, Not, Tag}

var type : Type = Type.MatchString:
	set(value):
		if value != type:
			type = value
			
			match type:
				Type.MatchString:
					expand_to_text_length = false
					size_flags_horizontal = Control.SIZE_EXPAND_FILL
					alignment = HORIZONTAL_ALIGNMENT_LEFT
					add_theme_color_override('font_color', Color.WHITE.darkened(0.1))
				
				Type.And, Type.Or, Type.Not:
					custom_minimum_size.x = 1
					expand_to_text_length = true
					alignment = HORIZONTAL_ALIGNMENT_CENTER
					size_flags_horizontal = Control.SIZE_FILL
					add_theme_color_override('font_color', Color('66afcc'))
				
				Type.Tag:
					custom_minimum_size.x = 1
					expand_to_text_length = true
					size_flags_horizontal = Control.SIZE_FILL
					alignment = HORIZONTAL_ALIGNMENT_CENTER
					add_theme_color_override('font_color', Color.WHITE.darkened(0.1))

var tag : DataBase.Tag
var inputed_text : String


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			selecting_enabled = false
			if has_focus():
				release_focus()
		
		NOTIFICATION_DRAG_END:
			selecting_enabled = true

func _input(event: InputEvent) -> void:
	if has_focus() and event.is_pressed():
		if 'position' in event:
			if not Rect2(Vector2(), size).has_point(event.position):
				release_focus()

func _gui_input(event: InputEvent) -> void:
	if has_focus() and event.is_pressed():
		if (event.is_action('ui_text_caret_left') or event.is_action('ui_text_caret_line_start')
				or event.is_action('ui_text_backspace')):
			if caret_column == 0:
				var item = get_node_or_null(focus_previous)
				if item is FilterItem:
					item.grab_focus()
					item.caret_column = 10000
				accept_event()
		
		elif (event.is_action('ui_text_caret_right') or event.is_action('ui_text_caret_line_end')
				or event.is_action('ui_text_delete')):
			if caret_column == text.length():
				var item = get_node_or_null(focus_next)
				if item is FilterItem:
					item.grab_focus()
				accept_event()
		
		elif event.is_action('ui_text_caret_down'):
			if caret_column == text.length():
				print('смахнуть вниз')
				accept_event()
		
		elif event.is_action('ui_text_caret_up'):
			if caret_column == 0:
				print('смахнуть вверх')
				accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	return self

func _on_text_changed(_new_text = null) -> void:
	pass

func _on_text_submitted(_new_text = null) -> void:
	pass

func _on_focus_exited() -> void:
	pass

func empty() -> bool:
	match type:
		Type.MatchString:
			return inputed_text.is_empty() and text.is_empty()
		
		Type.And, Type.Or, Type.Not:
			return false
		
		Type.Tag:
			return not tag or not tag.valid
	return true

func filter_to_string() -> String:
	match type:
		Type.MatchString:
			return inputed_text
		
		Type.And, Type.Or, Type.Not:
			return (Type.find_key(type) as StringName).to_upper()
		
		Type.Tag:
			if tag and tag.valid:
				if tag.names:
					assert(tag.names[0])
					return tag.names[0]
				
				return '[Unnamed tag]'
			
			else:
				return '[Invalid tag]'
	
	return ''
