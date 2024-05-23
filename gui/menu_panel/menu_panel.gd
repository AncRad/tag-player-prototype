extends MarginContainer

signal focus_released

var _in_focus := false:
	set(value):
		if value != _in_focus:
			_in_focus = value
			if not _in_focus:
				focus_released.emit()

var _tree : Tree
var _root : TreeItem


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED, NOTIFICATION_READY:
			_tree = %Tree as Tree
			clear()
		
		NOTIFICATION_FOCUS_ENTER:
			_tree.grab_focus()
			if _root.get_child_count():
				_tree.set_selected(_root.get_child(0), 0)

func _process(_delta = null) -> void:
	_in_focus = in_focus()

func _input(event: InputEvent) -> void:
	if event.is_pressed() and 'position' in event:
		if not get_rect().has_point(event.position):
			if in_focus():
				get_viewport().gui_get_focus_owner().release_focus()

func _on_tree_item_pressed() -> void:
	var item := _tree.get_selected()
	assert(item is ItemButton)
	if item is ItemButton:
		item.pressed.emit()

func in_focus() -> bool:
	if has_focus():
		return true
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner and is_ancestor_of(focus_owner)

func add_button(text := '', color := Color()) -> ItemButton:
	var item := _root.create_child()
	item.set_script(ItemButton)
	item = item as ItemButton
	item.set_text(0, text)
	item.disable_folding = true
	if color:
		item.set_custom_color(0, color)
	return item

func get_buttons() -> Array[ItemButton]:
	var buttons := [] as Array[ItemButton]
	buttons.assign(_root.get_children())
	return buttons

func clear() -> void:
	_tree.clear()
	_root = _tree.create_item()


class ItemButton extends TreeItem:
	signal pressed
