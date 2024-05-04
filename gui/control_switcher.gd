class_name ControlSwitcher
extends Container

signal view_owner_changed(view_owner : Control)
signal lists_changed

var view_owner : Control: set = set_view_owner, get = get_view_owner

var _changing_view_owner := false
var _checking_children := false
var _tracked_lists : Array[Control] = []


func _init() -> void:
	child_entered_tree.connect(check_children.unbind(1))
	child_exiting_tree.connect(check_children.unbind(1))

func _ready() -> void:
	_check_children()

func _on_list_visibility_changed(list : Control) -> void:
	if list and is_instance_valid(list) and list.get_parent() == self:
		if list.visible:
			set_view_owner(list)

func set_view_owner(value : Control) -> void:
	if not _changing_view_owner:
		_changing_view_owner = true
		
		if value and (not is_instance_valid(value) or value.get_parent() != self):
			value = null
		
		if value != view_owner:
			view_owner = value
			
			if view_owner:
				view_owner.show()
			
			for child in get_children():
				if child is Control:
					if child != view_owner and child.visible:
						child.hide()
			
			view_owner_changed.emit()
		
		_changing_view_owner = false

func check_children() -> void:
	if not _checking_children:
		_checking_children = true
		_check_children.call_deferred()

func get_view_owner() -> Control:
	if is_instance_valid(view_owner) and view_owner.get_parent() == self:
		return view_owner
	return null

func _check_children() -> void:
	_checking_children = false
	
	var changed := false
	
	var new_view_owner : Control
	for child in get_children():
		if child is Control:
			var list := child as Control
			
			if not list.visibility_changed.is_connected(_on_list_visibility_changed):
				list.visibility_changed.connect(_on_list_visibility_changed.bind(list))
			
			if not list in _tracked_lists:
				_tracked_lists.append(list)
				changed = true
				
				if list.visible:
					new_view_owner = list
	if new_view_owner:
		set_view_owner(new_view_owner)
	
	var i := 0
	while i < _tracked_lists.size():
		var list := _tracked_lists[i]
		
		if not is_instance_valid(list):
			_tracked_lists.remove_at(i)
			changed = true
		
		elif list.get_parent() != self:
			assert(list.visibility_changed.is_connected(_on_list_visibility_changed))
			if list.visibility_changed.is_connected(_on_list_visibility_changed):
				list.visibility_changed.disconnect(_on_list_visibility_changed)
			_tracked_lists.remove_at(i)
			changed = true
		
		else:
			i += 1
	
	if changed:
		lists_changed.emit()
