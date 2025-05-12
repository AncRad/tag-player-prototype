extends MarginContainer

const Track = DataBase.Track
const Tag = DataBase.Tag

signal tag_selected(tag : Tag)

var tracks : Array[Track]:
	set = set_tracks

var _tag_items : Control
var _line_edit_name : LineEdit

var _updating : bool
var _tracks_updating : bool


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			_tag_items = %TagItems
			_tag_items.set_drag_forwarding(Callable(), can_drop_tag, drop_tag)
			_line_edit_name = %LineEditName

func set_tracks(value : Array[Track] = []) -> void:
	if value != tracks:
		tracks = value
		_tracks_updating = true
		queuq_update()

func can_drop_tag(_pos, data : Variant) -> bool:
	if tracks:
		if data is Tag and data.valid:
			return true
	return false

func drop_tag(_pos, data : Variant) -> void:
	if tracks:
		if data is Tag and data.valid:
			var tag : Tag = data as Tag
			for track in tracks:
				if not tag in track.get_tags():
					tag.tag(track)

func queuq_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _on_line_edit_name_text_changed(text: String) -> void:
	if tracks.size() == 1:
		text = text.strip_escapes()
		if _line_edit_name.text != text:
			#TODO: сделать это с заботой
			_line_edit_name.text = text
		tracks[0].name = text
		tracks[0].changes_up()

func _on_tag_item_gui_input(event : InputEvent, tag_item : TagItem) -> void:
	if event.is_pressed() and not event.is_echo():
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				var tag := tag_item.tag
				for track in tracks:
					if track.is_tagged(tag):
						tag.untag(track)

func _update() -> void:
	if not _updating:
		return
	
	assert(_tracks_updating)
	if _tracks_updating:
		for node in _tag_items.get_children():
			_tag_items.remove_child(node)
			node.queue_free()
		
		var tags_added : Dictionary[Tag, bool]
		for track in tracks:
			for tag in track.get_tags():
				if not tag in tags_added:
					var tag_item := TagItem.new()
					tag_item.tag = tag
					tag_item.pressed.connect(tag_selected.emit.bind(tag))
					tag_item.gui_input.connect(_on_tag_item_gui_input.bind(tag_item))
					_tag_items.add_child(tag_item)
					tags_added[tag] = true
		
		if tracks:
			if tracks.size() == 1:
				var track := tracks[0]
				_line_edit_name.text = track.name
				_line_edit_name.editable = true
				%LabelPath.text = track.file_path
				%LabelOrder.text = track.order_string
				%LabelFind.text = track.find_string
			else:
				_line_edit_name.text = 'Выделено %s треков' % tracks.size()
				_line_edit_name.editable = false
				%LabelPath.text = ''
				%LabelOrder.text = ''
				%LabelFind.text = ''
			
		else:
			_line_edit_name.text = ''
			_line_edit_name.editable = false
			%LabelPath.text = ''
			%LabelOrder.text = ''
			%LabelFind.text = ''
	
	_tracks_updating = false
	_updating = false

static func validate_text(text : String) -> String:
	return ','.join(text.c_unescape().replace('\n', ',').strip_escapes().split(',', false, 10))


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
		add_theme_color_override('font_color', Color.WHITE.darkened(0.5))
		add_theme_color_override('font_hover_color', Color.WHITE.darkened(0.3))
		add_theme_color_override('font_pressed_color', Color.WHITE.darkened(0.1))
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
			#if tag in track.tag_to_type:
				#text = '%s\n%s' % [tag.get_name(), track.tag_to_type[tag]]
			#else:
				text = tag.get_name()
		
		_updating = false
