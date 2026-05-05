extends Control

const Tag = DataBase.Tag
const MenuPanel = preload('res://gui/menu_panel/menu_panel.gd')

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
var menu : MenuPanel

var _updating : bool


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
			menu = %MenuPanel
			menu.hide()

func _on_add_delete_button_pressed() -> void:
	if selected_tag:
		delete_dialogue.show()
	else:
		if data_base:
			_on_tag_find_line_edit_complited()
			_on_name_edit_complited()
			_on_type_edit_complited()
			var names := name_edit.text.split(',', false, 10)
			if not names:
				var find_text := validate_text(tag_find.text)
				if find_text:
					names.append(find_text)
				else:
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
	if tag_find.is_editing():
		pass

func _on_tag_find_line_edit_complited() -> void:
	if tag_find.text:
		var valid_text := validate_text(tag_find.text)
		if tag_find.text != valid_text:
			tag_find.text = valid_text
		if data_base:
			var tags := data_base.find_tags_by_name(tag_find.text)
			if tags:
				selected_tag = tags[0]
				
				return
	selected_tag = null
	queue_update()

func _on_name_edit_text_changed() -> void:
	pass

func _on_name_edit_complited() -> void:
	var valid_text := validate_text(name_edit.text)
	if name_edit.text != valid_text:
		name_edit.text = valid_text
	var names := name_edit.text.split(',', false, 10)
	if selected_tag:
		if names:
			selected_tag.set_names(names)
		else:
			queue_update()

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
		if selected_tag:
			selected_tag.changed.disconnect(queue_update)
		selected_tag = value
		queue_update()
		if selected_tag:
			selected_tag.changed.connect(queue_update)
			delete_dialogue.hide()

func get_drag_data() -> Variant:
	if selected_tag:
		return selected_tag
	return null

func queue_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _update() -> void:
	if not _updating:
		return
	
	if selected_tag and not selected_tag.valid:
		selected_tag = null
	
	if selected_tag:
		add_delete_button.text = '-'
		add_delete_button.add_theme_color_override('font_pressed_color', Color('ff4040'))
		add_delete_button.add_theme_color_override('font_hover_pressed_color', Color('ff4040'))
		add_delete_button.disabled = not selected_tag.get_data_base()
		if not tag_find.is_editing():
			tag_find.text = selected_tag.get_name()
		if not name_edit.has_focus():
			name_edit.text = ','.join(selected_tag.get_names())
		if not type_edit.has_focus():
			type_edit.text = ','.join(selected_tag.get_types())
		grag_data_access.texture = preload('uid://drbgreqyvii44')
	
	else:
		add_delete_button.text = '+'
		add_delete_button.add_theme_color_override('font_pressed_color', Color('bdffff'))
		add_delete_button.add_theme_color_override('font_hover_pressed_color', Color('bdffff'))
		add_delete_button.disabled = not data_base
		if not tag_find.is_editing():
			tag_find.text = ''
		if not name_edit.has_focus():
			name_edit.text = ''
		if not type_edit.has_focus():
			type_edit.text = ''
		grag_data_access.texture = preload('uid://qhf4q0edd477')
		
		delete_dialogue.hide()
	
	_updating = false

static func validate_text(text : String) -> String:
	return ','.join(text.c_unescape().replace('\n', ',').strip_escapes().split(',', false, 10))
