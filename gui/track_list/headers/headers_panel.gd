#class_name HeadersPanel
extends HBoxContainer

const Header = preload('header.gd')
const TRACK_LIST = preload('../track_list.tscn')

@export var lists_parent : Control:
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

@export var default_source : DataSource

@export var default_player : Player:
	set(value):
		if value != default_player:
			default_player = value

@export_range(0, 30, 0.1) var sight_borders : int = 15:
	set(value):
		sight_borders = value
		if _border_left:
			_border_left.custom_minimum_size.x = sight_borders
		if _border_right:
			_border_right.custom_minimum_size.x = sight_borders

@export_range(0, 30, 0.1) var headers_separation : int = 10:
	set(value):
		headers_separation = value
		pass

var _headers : Array[Header] = []
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

#func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	#if data is Dictionary:
		#if 'header' in data and data.header is Header:
			#return data.header.list != null
		#
		#if 'player' in data and data.player is Player:
			#return true
		#
		#if 'source' in data and data.source is DataSource:
			#return true
	#return false
#
#func _get_drag_data(at_position: Vector2, data := {}) -> Variant:
	#return

#func _drop_data(at_position: Vector2, data: Variant) -> void:
	#pass

func _on_header_can_drop_data(at_position: Vector2, data: Variant, header : Header) -> bool:
	return false

func _on_header_get_drag_data(at_position: Vector2, header : Header) -> Variant:
	if header in _headers:
		if is_instance_valid(header.list) and header.list.get_parent() == lists_parent:
			var data := header.list._get_drag_data(Vector2(INF, INF)) as Dictionary
			data.header = header
			return data
	return

func _on_header_drop_data(at_position: Vector2, data: Variant, header : Header) -> void:
	pass

func _on_headers_pre_sort_children() -> void:
	var last_position : float = 0.0
	var max_length : float = 120.0
	var font := get_theme_font('font', 'Button')
	var font_size := get_theme_font_size('font_size', 'Button')
	var font_height : float = font.get_height(font_size)
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
		
		lists_parent.add_child.call_deferred(list)

func _on_header_pressed(header : Header) -> void:
	if is_instance_valid(header.list):
		header.list.show()

func _on_header_close_pressed(header : Header) -> void:
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
					_header_create(list)
	
	for header in _headers.duplicate():
		if not is_instance_valid(header.list) or header.list.get_parent() != lists_parent:
			_header_remove(header)

func _header_create(list : TrackList) -> void:
	var header := Header.new()
	header.list = list
	if list.source and list.source.get_not_ordered() is DataBase:
		header.set_title('Source')
	header.set_drag_forwarding(_on_header_get_drag_data.bind(header),
			_on_header_can_drop_data.bind(header), _on_header_drop_data.bind(header))
	header.close_pressed.connect(_on_header_close_pressed.bind(header))
	header.pressed.connect(_on_header_pressed.bind(header))
	_headers.append(header)
	_headers_parent.add_child(header)

func _header_remove(header : Header) -> void:
	assert(header)
	_headers.erase(header)
	_headers_parent.remove_child(header)
	header.queue_free()

func _list_to_header(list : TrackList) -> Header:
	for header in _headers:
		if header.list == list:
			return header
	return null
