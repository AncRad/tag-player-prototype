extends LineEdit

const FilterItem = preload('filter_item.gd')

enum Type {MatchString, And, Or, Not, Tag, BracketOpen, BracketClose, Separator}

var type : Type = Type.MatchString:
	set(value):
		if value != type:
			type = value
			
			placeholder_text = ''
			
			match type:
				Type.MatchString:
					add_theme_color_override('font_color', Color.WHITE.darkened(0.1))
				
				Type.And, Type.Or, Type.Not, Type.BracketOpen, Type.BracketClose:
					add_theme_color_override('font_color', Color('66afcc'))
				
				Type.Tag:
					add_theme_color_override('font_color', Color.WHITE.darkened(0.1))
				
				Type.Separator:
					placeholder_text = '•'
					add_theme_color_override('font_color', Color.WHITE.darkened(0.1))
					add_theme_color_override('font_placeholder_color', Color.WHITE.darkened(0.5))

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

func _get_drag_data(_at_position: Vector2) -> Variant:
	return self

func empty() -> bool:
	match type:
		Type.MatchString:
			return inputed_text.is_empty() and text.is_empty()
		
		Type.And, Type.Or, Type.Not, Type.BracketOpen, Type.BracketClose, Type.Separator:
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
		
		Type.BracketOpen:
			return '('
		
		Type.BracketClose:
			return ')'
		
		Type.Tag:
			if tag and tag.valid:
				if tag.names:
					assert(tag.names[0])
					return tag.names[0]
				
				return '[Unnamed tag]'
			
			else:
				return '[Invalid tag]'
	
	return ''

func is_seprarator() -> bool:
	return type == Type.Separator

func get_match_string() -> String:
	return '*%s*' % '*'.join(inputed_text.replace('*', ' ').split(' ', false))
