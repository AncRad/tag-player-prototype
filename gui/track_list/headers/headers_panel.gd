#class_name HeadersPanel
extends HBoxContainer

const Header = preload('header.gd')
const TRACK_LIST = preload('../track_list.tscn')

@export var lists_parent: Control:
	set(value):
		if value != lists_parent:
			if lists_parent:
				lists_parent.child_entered_tree.disconnect(update)
				lists_parent.child_exiting_tree.disconnect(update)
			
			lists_parent = value
			
			if lists_parent:
				lists_parent.child_entered_tree.connect(update.unbind(1))
				lists_parent.child_exiting_tree.connect(update.unbind(1))
			
			update()

@export var default_source: DataSource

@export var default_player: Player:
	set(value):
		if value != default_player:
			default_player = value

@export_range(0, 30, 0.1) var sight_borders: int = 15:
	set(value):
		sight_borders = value
		if _border_left:
			_border_left.custom_minimum_size.x = sight_borders
		if _border_right:
			_border_right.custom_minimum_size.x = sight_borders

@export_range(0, 30, 0.1) var headers_separation: int = 10:
	set(value):
		headers_separation = value
		pass

var _headers: Array[Header] = []
var _updating := false

@onready var _headers_parent := %Headers as Container
@onready var _headers_scroll := %HeadersScroll as ScrollContainer
@onready var _headers_scroll_bar := _headers_scroll.get_h_scroll_bar() as ScrollBar
@onready var _border_left := %BorderLeft as Control
@onready var _border_right := %BorderRight as Control
@onready var _add_button_1 := %AddButton1 as BaseButton
@onready var _add_button_2 := %AddButton2 as BaseButton


func _ready() -> void:
	_headers_scroll_bar.focus_mode = Control.FOCUS_NONE
	_headers_scroll_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#_headers_scroll_bar.process_mode = Node.PROCESS_MODE_DISABLED
	_headers_scroll_bar.visibility_changed.connect(_update_add_buttons_visible)
	
	sight_borders = sight_borders
	headers_separation = headers_separation

func update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _get_drag_data(_at_position: Vector2, at_header: Header = null) -> Variant:
	var data := {}
	if at_header:
		data.from = at_header
		if at_header.list:
			data.track_list = at_header.list
			if at_header.list.source:
				data.source = at_header.list.source
			if at_header.list.player:
				data.player = at_header.list.player
	
	if data:
		return data
	return null

func _can_drop_data(at_position: Vector2, data: Variant, to_header: Header = null) -> bool:
	return drop_data(at_position, data, to_header, true)

func _drop_data(to_position: Vector2, data: Variant, to_header: Header = null) -> void:
	drop_data(to_position, data, to_header, false)

func drop_data(to_position: Vector2, data: Variant, to_header: Header = null, test := false) -> bool:
	if data is Dictionary:
		var to_index: int = -1
		var header := G.validate(data.get('from'), Header) as Header
		var list := G.validate(data.get('track_list'), TrackList) as TrackList
		var source := G.validate(data.get('source'), DataSource) as DataSource
		var player := G.validate(data.get('player'), Player) as Player
		
		## вычислить целевой индекс
		if _has_header(to_header):
			to_index = to_header.find(to_header)
		else:
			pass ## TODO: to_index = ????
		
		## если есть заголовок
		if header:
			## если заголовок свой, то переместить и закончить
			if _has_header(header):
				if not test:
					_headers.erase(header)
					_headers.insert(to_index, header)
				return true
			
			## если заголовок чужой и есть трек лист, то украсть трек лист
			elif is_instance_valid(header.list):
				if test:
					return true
				list = header.list
			
			else:
				return false
		
		## если есть трек лист, то украсть
		if list:
			if test:
				return true
			if list.get_panret():
				list.get_parent().remove_child(list)
		
		## если нет трек листа, но есть проигрыватель и источник, то создать трек лист
		elif player and source:
			if test:
				return true
			list = TRACK_LIST.instantiate() as TrackList
			list.source = source
			list.player = player
		else:
			return false
		
		
		## если нет заголовка и есть трек лист, то создать заголовок
		if not header and list:
			if test:
				header = _header_create(list)
				_headers.insert(to_index, header)
				_headers_parent.add_child(header)
			return true
		
		## если есть заголовок, то добавить в точку to_index
		if header:
			if not test:
				_headers.insert(to_index, header)
				_headers_parent.add_child(header)
			return true
	
	
		if header:
			if _has_header(header):
				if not test:
					## переместить заголовок
					_headers.erase(header)
					_headers.insert(to_index, header)
				return true
			
			elif is_instance_valid(header.list):
				if not test:
					## украсть лист
					if header.list.get_parent():
						header.list.get_parent().remove_child(header.list)
					lists_parent.add_child(header.list)
					
					## создать заголовок
					var new_header := _header_create(list)
					_headers.insert(to_index, new_header)
					_headers_parent.add_child(new_header)
				return true
			
			else:
				return false
		
		elif list:
			if not test:
				## украсть лист
				if header.list.get_parent():
					header.list.get_parent().remove_child(header.list)
				lists_parent.add_child(header.list)
				
				## создать заголовок
				var new_header := _header_create(list)
				_headers.insert(to_index, new_header)
				_headers_parent.add_child(new_header)
			return true
		
		elif source and player:
			if not test:
				## создать лист
				list = TRACK_LIST.instantiate() as TrackList
				list.source = source
				list.player = player
				## создать заголовок
				var new_header := _header_create(list)
				_headers.insert(to_index, new_header)
				_headers_parent.add_child(new_header)
			return true
		
		else:
			return false
	
	
	return false

func _on_headers_pre_sort_children() -> void:
	var last_position: float = 0.0
	var max_length: float = 120.0
	var font := get_theme_font('font', 'Button')
	var font_size := get_theme_font_size('font_size', 'Button')
	var font_height: float = font.get_height(font_size)
	for i in _headers.size():
		var header := _headers[i]
		#var list := header.list
		var trimmed_length := font.get_string_size(header.text, HORIZONTAL_ALIGNMENT_LEFT, max_length, font_size).x
		var rect := Rect2(last_position, 0, trimmed_length, font_height)
		_headers_parent.fit_child_in_rect(header, rect)
		assert(header.size.x <= trimmed_length)
		last_position = rect.end.x + headers_separation
	
	if _headers.size():
		last_position -= headers_separation
	
	_headers_parent.custom_minimum_size = Vector2(last_position, font_height)

func _on_add_button_pressed() -> void:
	if lists_parent:
		var list := TRACK_LIST.instantiate() as TrackList
		
		if default_source:
			list.source = default_source.get_ordered()
		
		if default_player:
			list.player = default_player
		
		list.focus_track_on_ready = true
		list.visible_name = 'NoName%d' % list.get_instance_id()
		
		lists_parent.add_child.call_deferred(list)

func _on_header_pressed(header: Header) -> void:
	if is_instance_valid(header.list):
		header.list.show()

func _on_header_close_pressed(header: Header) -> void:
	if is_instance_valid(header.list):
		if header.list.visible:
			if _headers.size() > 1:
				var header_index := _headers.find(header)
				assert(header_index != -1)
				if header_index == _headers.size() - 1:
					_on_header_pressed(_headers[header_index - 1])
				else:
					_on_header_pressed(_headers[header_index + 1])
		header.list.queue_free()

func _update_add_buttons_visible() -> void:
	_add_button_1.visible = not _headers_scroll_bar.visible
	_add_button_2.visible = _headers_scroll_bar.visible

func _update() -> void:
	_updating = false
	
	if lists_parent:
		for child in lists_parent.get_children():
			if child is TrackList:
				var list := child as TrackList
				if not _list_to_header(list):
					var header := _header_create(list)
					_headers.append(header)
					_headers_parent.add_child(header)
	
	for header in _headers.duplicate():
		if not is_instance_valid(header.list) or header.list.get_parent() != lists_parent:
			_header_remove(header)

func _header_create(list: TrackList) -> Header:
	var header := Header.new()
	header.list = list
	header.set_title(list.visible_name)
	header.set_drag_forwarding(_get_drag_data.bind(header), _can_drop_data.bind(header), _drop_data.bind(header))
	
	header.close_pressed.connect(_on_header_close_pressed.bind(header))
	header.pressed.connect(_on_header_pressed.bind(header))
	
	return header

func _header_remove(header: Header) -> void:
	assert(header)
	_headers.erase(header)
	_headers_parent.remove_child(header)
	header.queue_free()

func _list_to_header(list: TrackList) -> Header:
	for header in _headers:
		if header.list == list:
			return header
	return null

func _has_header(header: Header) -> bool:
	return header in _headers
