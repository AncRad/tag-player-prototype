extends Container

var _block := false
var _checking_children := false
var _tracked_lists : Array[TrackList] = []


func _ready() -> void:
	child_entered_tree.connect(check_children)
	child_exiting_tree.connect(check_children)
	
	_check_children()
	
	for child in get_children():
		if child is TrackList:
			if child.visible:
				hide_kindred(child)
				break

func hide_kindred(list : TrackList) -> void:
	if not _block:
		_block = true
		
		if list.visible:
			for child in get_children():
				if child is TrackList:
					if child != list and child.visible:
						child.hide()
		
		_block = false

func check_children() -> void:
	if not _checking_children:
		_checking_children = true
		_check_children.call_deferred()

func _check_children() -> void:
	_checking_children = false
	
	for child in get_children():
		if child is TrackList:
			var list := child as TrackList
			if not list.visibility_changed.is_connected(hide_kindred):
				
				list.visibility_changed.connect(hide_kindred.bind(list))
				
				if not list in _tracked_lists:
					_tracked_lists.append(list)
	
	for list in _tracked_lists.duplicate():
		if not is_instance_valid(list) or list.get_parent() != self:
			
			if list.visibility_changed.is_connected(hide_kindred):
				list.visibility_changed.disconnect(hide_kindred)
			
			if list in _tracked_lists:
				_tracked_lists.erase(list)
