extends HFlowContainer

const TagFindLineEdit = preload('tag_find_line_edit.gd')

@export var root_db : DataBase

var tracks : Array[Dictionary]:
	set(value):
		if value != tracks:
			if tracks:
				for track in tracks:
					if track.notification.is_connected(update):
						track.notification.disconnect(update)
			
			tracks = value
			
			if tracks:
				for track in tracks:
					track.notification.connect(update.unbind(1))
			
			if _tag_find:
				_tag_find.text = ''
			
			update()


var _tag_find : TagFindLineEdit
var _track_name_label : Label
var _updating := false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			_tag_find = %TagFindLineEdit as TagFindLineEdit
			_track_name_label = %TrackNameLabel as Label
			
			_track_name_label.set_drag_forwarding(Callable(), drop_data.bind(true), drop_data.bind(false))
		
		NOTIFICATION_PREDELETE:
			tracks = []

func _ready() -> void:
	_notification(NOTIFICATION_SCENE_INSTANTIATED)

func _on_tag_find_line_edit_tag_selected(tag: Dictionary) -> void:
	_tag_find.text = ''
	_tag_find.grab_focus()
	for track in tracks:
		if not track.key in tag.track_key2priority:
			root_db.tag_track(track, tag)

func _on_tag_find_line_edit_tag_create_pressed(tag_name: String) -> void:
	if ' '.join(tag_name.split(' ', false)):
		if not root_db.name_to_tag(tag_name):
			_tag_find.text = ''
			_tag_find.grab_focus()
			var tag := root_db.tag_create(tag_name, Color.DARK_GRAY)
			for track in tracks:
				root_db.tag_track(track, tag)

func _on_tag_find_line_edit_text_submitted(_new_text: String) -> void:
	var tags := _tag_find.get_tags()
	if tags:
		_on_tag_find_line_edit_tag_selected(tags[0])
	
	else:
		_on_tag_find_line_edit_tag_create_pressed(_tag_find.text)

func _on_tag_item_pressed(tag_item : TagItem) -> void:
	if is_instance_valid(tag_item):
		if is_ancestor_of(tag_item):
			var tag := tag_item.tag
			for track in tracks:
				if track.key in tag.track_key2priority:
					root_db.untag_track(track, tag)

func drop_data(_pos, data : Variant, test : bool) -> bool:
	if data is Dictionary:
		
		if 'tracks' in data and data.tracks is Dictionary:
			var data_tracks := data.tracks as Dictionary
			if data_tracks:
				if not test:
					var new_tracks : Array[Dictionary] = []
					new_tracks.assign(data_tracks.values())
					tracks = new_tracks
				return true
			return false
		
		if 'track' in data and data.track is Dictionary:
			var data_track := data.track as Dictionary
			if data_track and data.track.get('key') is int:
				data_track = root_db.key_to_track(data.track.key)
				if data_track:
					if not test:
						var new_tracks : Array[Dictionary] = [data_track]
						tracks = new_tracks
					return true
			return false
	
	return false

func update():
	if not _updating:
		_updating = true
		_update.call_deferred()

func _update() -> void:
	_updating = false
	
	for child in get_children():
		if child is TagItem:
			remove_child(child)
			child.queue_free()
	
	var tags := {}
	for track in tracks:
		for tag in root_db.track_to_tags(track):
			tags[tag.key] = tag
	
	for key in tags:
		var tag_item := TagItem.new()
		tag_item.tag = tags[key]
		tag_item.pressed.connect(_on_tag_item_pressed.bind(tag_item))
		add_child(tag_item)
	
	move_child(_tag_find, -1)
	
	if tracks:
		if tracks.size() == 1:
			_track_name_label.text = tracks[0].file_name
		else:
			_track_name_label.text = '%s...' % tracks[0].file_name
	else:
		_track_name_label.text = ''


class TagItem extends Button:
	var tag : Dictionary:
		set(value):
			if value != tag:
				if tag:
					if tag.notification.is_connected(update):
						tag.notification.disconnect(update)
				
				tag = value
				
				if tag:
					tag.notification.connect(update.unbind(1))
				
				update()
	
	var _updating := false
	
	
	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
	
	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_PREDELETE:
				tag = {}
	
	func update():
		if not _updating:
			_updating = true
			_update.call_deferred()
	
	func _update() -> void:
		_updating = false
		if tag:
			text = tag.name
			self['theme_override_colors/font_color'] = tag.color

