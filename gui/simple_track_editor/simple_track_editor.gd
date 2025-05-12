extends MarginContainer

const Track = DataBase.Track
const Tag = DataBase.Tag

signal tag_selected(tag : Tag)

var selected_track : Track:
	set = set_selected_track

var tag_items : Control

var _updating : bool
var _selected_track_updating : bool


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			tag_items = %TagItems

func set_selected_track(value : Track) -> void:
	if value != selected_track:
		selected_track = value
		_selected_track_updating = true
		queuq_update()

func queuq_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _update() -> void:
	if not _updating:
		return
	
	if _selected_track_updating:
		if selected_track:
			%LineEditName.text = selected_track.name
			%LabelPath.text = selected_track.file_path
			%LabelOrder.text = selected_track.order_string
			%LabelFind.text = selected_track.find_string
			for tag in selected_track.get_tags():
				var tag_item := TagItem.new()
				tag_item.tag = tag
				tag_item.pressed.connect(tag_selected.emit.bind(tag))
				tag_items.add_child(tag_item)
		else:
			%LineEditName.text = ''
			%LabelPath.text = ''
			%LabelOrder.text = ''
			%LabelFind.text = ''
			for node in tag_items.get_children():
				tag_items.remove_child(node)
				node.queue_free()
	
	_selected_track_updating = false
	_updating = false

class TagItem:
	extends Button
	
	var tag : Tag:
		set(value):
			if tag:
				tag.changed.disconnect(queuq_update)
			tag = value
			if tag:
				tag.changed.connect(queuq_update)
			queuq_update()
	
	var _updating : bool
	
	
	func _init() -> void:
		add_theme_font_size_override('font_size', 14)
		focus_mode = Control.FOCUS_NONE
		flat = true
	
	func queuq_update() -> void:
		if not _updating:
			_updating = true
			_update.call_deferred()

	func _update() -> void:
		if not _updating:
			return
		
		if tag:
			text = tag.get_name()
		
		_updating = false
