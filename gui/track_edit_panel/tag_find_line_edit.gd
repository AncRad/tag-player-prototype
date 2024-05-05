extends LineEdit

signal tag_selected(tag : Dictionary)
signal tag_create_pressed(tag_name : String)

@export var root_db : DataBase

var tree : Tree

var _tree_item_to_tag := {}
var _checking_focus := false
var _releasing_focus := false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			tree = %Tree as Tree

func _ready() -> void:
	_notification(NOTIFICATION_SCENE_INSTANTIATED)

func _input(event: InputEvent) -> void:
	if not _releasing_focus and (has_focus() or tree.has_focus()):
		if event.is_pressed() and 'position' in event:
			var our_event := get_global_rect().has_point(event.position) and is_visible_in_tree() and focus_mode != FOCUS_NONE
			var tree_event := (tree.get_global_rect().has_point(event.position) and tree.is_visible_in_tree()
					and tree.focus_mode != FOCUS_NONE)
			
			if not our_event and not tree_event:
				_releasing_focus = true
				if not _checking_focus:
					_checking_focus = true
					_check_focus.call_deferred()

func _on_text_changed() -> void:
	if has_focus():
		
		var can_create := false
		var finded_tags : Array[Dictionary] = []
		var splited_text := text.split(' ', false)
		var cleared_text := ' '.join(splited_text)
		var filter := '*%s*' % '*'.join(splited_text)
		if root_db:
			if splited_text:
				can_create = true
				var tags := root_db.get_tags()
				for tag in tags:
					if tag.name.matchn(filter):
						finded_tags.append(tag)
						if tag.name == cleared_text:
							can_create = false
		
		_tree_clear()
		if finded_tags or can_create:
			var root := tree.create_item()
			for tag in finded_tags:
				var item := tree.create_item(root)
				item.set_text(0, tag.name)
				item.set_custom_color(0, tag.color)
				_tree_item_to_tag[item] = tag
			
			if can_create:
				var item := tree.create_item(root)
				item.set_text(0, 'Создать тег: %s' % cleared_text)
				_tree_item_to_tag[item] = cleared_text
			
			if not tree.visible:
				tree.show()
				tree.set_begin(global_position + Vector2(10, size.y))
				tree.set_end(tree.position + Vector2(250, 200))
		
		elif tree.visible:
			_hide_tree()


func _on_focus_exited() -> void:
	if not _checking_focus:
		_checking_focus = true
		_check_focus.call_deferred()

func _on_focus_entered() -> void:
	_on_text_changed()

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		if tree.has_focus():
			tree.release_focus()
		if has_focus():
			release_focus()
		if tree.visible:
			_hide_tree()


func _on_tree_focus_entered() -> void:
	if not _checking_focus:
		_checking_focus = true
		_check_focus.call_deferred()

func _on_tree_focus_exited() -> void:
	if not _checking_focus:
		_checking_focus = true
		_check_focus.call_deferred()

func _on_tree_item_activated() -> void:
	var selected := tree.get_selected()
	if selected:
		assert(selected in _tree_item_to_tag)
		if selected in _tree_item_to_tag:
			if _tree_item_to_tag[selected] is Dictionary:
				tag_selected.emit(_tree_item_to_tag[selected])
			
			elif _tree_item_to_tag[selected] is String:
				tag_create_pressed.emit(_tree_item_to_tag[selected])
			
			else:
				assert(false)
		_hide_tree()


func get_tags() -> Array[Dictionary]:
	var tags : Array[Dictionary] = []
	for value in _tree_item_to_tag.values():
		if value is Dictionary:
			tags.append(value)
	return tags


func _tree_clear() -> void:
	tree.clear()
	_tree_item_to_tag.clear()

func _hide_tree() -> void:
	tree.hide()
	_tree_clear()

func _check_focus() -> void:
	if _releasing_focus:
		if has_focus():
			release_focus()
		elif tree.has_focus():
			tree.release_focus()
	
	if _checking_focus:
		if not tree.has_focus() and not has_focus():
			_hide_tree()
	
	_releasing_focus = false
	_checking_focus = false
