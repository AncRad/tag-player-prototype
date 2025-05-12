extends Control

const Tag = DataBase.Tag

@export
var data_base : DataBase

var selected_tag : Tag:
	set = set_selected_tag

var add_delete_button : Button
var tag_find : LineEdit
var name_edit : TextEdit
var type_edit : TextEdit
var grag_data_access : TextureRect
var delete_dialogue : Control

var _updating : bool
var _selected_tag_updating : bool


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			add_delete_button = %AddDeleteButton
			tag_find = %TagFindLineEdit
			name_edit = %NameEdit
			type_edit = %TypeEdit
			grag_data_access = %GetDragData
			grag_data_access.set_drag_forwarding(get_drag_data.unbind(1), Callable(), Callable())
			delete_dialogue = %DeleteDialogue
			delete_dialogue.hide()

func _on_add_delete_button_pressed() -> void:
	if selected_tag:
		delete_dialogue.show()
	else:
		if data_base:
			_on_tag_find_line_edit_complited()
			_on_name_edit_complited()
			_on_type_edit_complited()
			var names := tag_find.text.split(',', false, 10)
			names.append_array(name_edit.text.split(',', false, 10))
			if names.size() > 10:
				names = names.slice(0, 10)
			elif not names:
				names.append('tag_unnamed')
			var types := type_edit.text.split(',', false, 10)
			selected_tag = data_base.tag_create(names, types)

func _on_delete_yes_button_pressed() -> void:
	if selected_tag:
		if selected_tag.get_data_base():
			selected_tag.get_data_base().tag_remove(selected_tag)
		selected_tag = null
	delete_dialogue.hide()

func _on_tag_find_line_edit_text_changed() -> void:
	pass

func _on_tag_find_line_edit_complited() -> void:
	var valid_text := validate_text(tag_find.text)
	if tag_find.text != valid_text:
		tag_find.text = valid_text

func _on_name_edit_text_changed() -> void:
	pass

func _on_name_edit_complited() -> void:
	var valid_text := validate_text(name_edit.text)
	if name_edit.text != valid_text:
		name_edit.text = valid_text
	var names := name_edit.text.split(',', false, 10)
	if selected_tag:
		selected_tag.set_names(names)
	if names:
		tag_find.text = names[0]
	else:
		tag_find.text = ''

func _on_type_edit_text_changed() -> void:
	pass # Replace with function body.

func _on_type_edit_complited() -> void:
	var valid_text := validate_text(type_edit.text)
	if type_edit.text != valid_text:
		type_edit.text = valid_text
	if selected_tag:
		selected_tag.set_types(type_edit.text.split(',', false, 10))

func set_selected_tag(value : Tag) -> void:
	if value != selected_tag:
		selected_tag = value
		_selected_tag_updating = true
		queuq_update()

func get_drag_data() -> Variant:
	if selected_tag:
		return selected_tag
	return false

func queuq_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _update() -> void:
	if not _updating:
		return
	
	if _selected_tag_updating:
		if selected_tag:
			add_delete_button.text = '-'
			add_delete_button.add_theme_color_override('font_pressed_color', Color('ff4040'))
			add_delete_button.add_theme_color_override('font_hover_pressed_color', Color('ff4040'))
			add_delete_button.disabled = not selected_tag.get_data_base()
			tag_find.text = selected_tag.get_name()
			name_edit.text = ','.join(selected_tag.get_names())
			type_edit.text = ','.join(selected_tag.get_types())
			grag_data_access.texture = preload('uid://drbgreqyvii44')
		
		else:
			add_delete_button.text = '+'
			add_delete_button.add_theme_color_override('font_pressed_color', Color('bdffff'))
			add_delete_button.add_theme_color_override('font_hover_pressed_color', Color('bdffff'))
			add_delete_button.disabled = not data_base
			tag_find.text = ''
			name_edit.text = ''
			type_edit.text = ''
			grag_data_access.texture = preload('uid://qhf4q0edd477')
		
		delete_dialogue.hide()
	
	_selected_tag_updating = false
	_updating = false

static func validate_text(text : String) -> String:
	return ','.join(text.c_unescape().replace('\n', ',').strip_escapes().split(',', false, 10))
