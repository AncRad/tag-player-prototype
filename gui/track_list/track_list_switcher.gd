extends Container

var _block := false
var _checking_children := false
var _tracked_lists : Array[TrackList] = []
var _view_owner : TrackList


func _ready() -> void:
	child_entered_tree.connect(check_children.unbind(1))
	child_exiting_tree.connect(check_children.unbind(1))
	
	_check_children()

func hide_kindred(list : TrackList) -> void:
	if list.visible:
		if not _block:
			_block = true
			
			_view_owner = list
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
				
				if list.visible:
					if not is_instance_valid(_view_owner):
						hide_kindred(list)
					elif list != _view_owner:
						list.hide()
	
	var i := 0
	while i < _tracked_lists.size():
		var list := _tracked_lists[i]
		
		if not is_instance_valid(list):
			_tracked_lists.remove_at(i)
		
		elif list.get_parent() != self:
			assert(list.visibility_changed.is_connected(hide_kindred))
			if list.visibility_changed.is_connected(hide_kindred):
				list.visibility_changed.disconnect(hide_kindred)
			_tracked_lists.remove_at(i)
		
		else:
			i += 1
