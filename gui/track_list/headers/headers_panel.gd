class_name HeadersPanel
extends Control
## HeadersPanel

const TRACK_LIST = preload('../track_list.tscn')

@export var lists_parent: TrackListSwitcher:
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

@export_range(0, 30, 0.5, 'or_greater') var sight_border: int = 15:
	set(value):
		sight_border = value
		if _border_left:
			_border_left.custom_minimum_size.x = sight_border
		if _border_right:
			_border_right.custom_minimum_size.x = sight_border

@export_range(0, 30, 0.5, 'or_greater') var headers_separation: int = 10:
	set(value):
		headers_separation = value
		if _headers_parent:
			_headers_parent.queue_sort()

@export_range(20, 300, 0.5, 'or_greater') var max_header_width: float = 120:
	set(value):
		max_header_width = value
		if _headers_parent:
			_headers_parent.queue_sort()


var _headers: Array[Header] = []
var _updating := false

var _headers_parent : Container
var _headers_scroll : ScrollContainer
var _headers_scroll_bar : ScrollBar
var _border_left : Control
var _border_right : Control
var _add_button_1 : BaseButton
var _add_button_2 : BaseButton


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCENE_INSTANTIATED:
			_headers_parent = %Headers as Container
			_headers_scroll = %HeadersScroll as ScrollContainer
			_headers_scroll_bar = _headers_scroll.get_h_scroll_bar() as ScrollBar
			_border_left = %BorderLeft as Control
			_border_right = %BorderRight as Control
			_add_button_1 = %AddButton1 as BaseButton
			_add_button_2 = %AddButton2 as BaseButton
			
			_headers_scroll_bar.focus_mode = Control.FOCUS_NONE
			_headers_scroll_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_headers_scroll_bar.visibility_changed.connect(_update_add_buttons_visible)
			
			sight_border = sight_border
			headers_separation = headers_separation
			_add_button_1.set_drag_forwarding(_get_drag_data.bind(_add_button_1), _can_drop_data.bind(_add_button_1),
					_drop_data.bind(_add_button_1))
			_add_button_2.set_drag_forwarding(_get_drag_data.bind(_add_button_2), _can_drop_data.bind(_add_button_2),
					_drop_data.bind(_add_button_2))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action('track_list_create_find_list', true):
		if not event.is_echo() and event.is_pressed():
			var focus_owner := get_viewport().gui_get_focus_owner()
			if lists_parent and focus_owner and lists_parent.is_ancestor_of(focus_owner):
				get_viewport().set_input_as_handled()
				
				if lists_parent:
					var to_header_index := _headers.size()
					var source := default_source
					var player := default_player
					
					var current_list := lists_parent.get_view_owner()
					if current_list and current_list.source and current_list.player:
						source = current_list.source
						player = current_list.player
						var header_index := _headers.find(_get_header_for_list(current_list))
						if header_index != -1:
							to_header_index = header_index + 1
					
					## создаем трек лист
					if source and player:
						var list := _create_track_list(DataSourceFiltered.new(source.get_not_ordered()).get_ordered(), player)
						list.focus_on_current_track()
						## создаем заголовок
						_header_create(list, to_header_index)
						list.gui_start_find()

func _get_drag_data(_at_position: Vector2, item: Object = null) -> Variant:
	var data := {}
	
	if not is_instance_valid(item):
		item = null
	
	if item is Header:
		var header := item as Header
		data.from = header
		if header.list:
			data.track_list = header.list
			if header.list.source:
				data.source = header.list.source
			if header.list.player:
				data.player = header.list.player
	
	else:
		data.from = self
		if default_source:
			#if item == _add_button_1 or item == _add_button_2:
			data.source = default_source
		if default_player:
			#if item == _add_button_1 or item == _add_button_2:
			data.player = default_player
	
	if data:
		return data
	return null

func _can_drop_data(at_position: Vector2, data: Variant, item: Object = null) -> bool:
	return drop_data(at_position, data, item, true)

func _drop_data(to_position: Vector2, data: Variant, item: Object = null) -> void:
	drop_data(to_position, data, item, false)

func _on_headers_pre_sort_children() -> void:
	var last_position: float = 0.0
	var font := get_theme_font('font', 'Button')
	var font_size := get_theme_font_size('font_size', 'Button')
	var font_height: float = font.get_height(font_size)
	for i in _headers.size():
		var header := _headers[i]
		#var list := header.list
		var trimmed_length := font.get_string_size(header.text, HORIZONTAL_ALIGNMENT_LEFT, max_header_width, font_size).x
		var rect := Rect2(last_position, 0, trimmed_length, font_height)
		_headers_parent.fit_child_in_rect(header, rect)
		assert(header.size.x <= trimmed_length)
		last_position = rect.end.x + headers_separation
	
	if _headers.size():
		last_position -= headers_separation
	
	_headers_parent.custom_minimum_size = Vector2(last_position, font_height)

func _on_add_button_pressed() -> void:
	if lists_parent:
		## создаем трек лист
		var list := _create_track_list(default_source.get_ordered(), default_player)
		list.focus_on_current_track()
		## создаем заголовок
		_header_create(list)

func _on_header_pressed(header: Header) -> void:
	if is_instance_valid(header.list):
		header.list.show()

func _on_header_close_pressed(header: Header) -> void:
	if is_instance_valid(header.list) and header.list.get_parent() == lists_parent:
		if header.list.visible:
			if _headers.size() > 1:
				var header_index := _headers.find(header)
				assert(header_index != -1)
				if header_index == _headers.size() - 1:
					_on_header_pressed(_headers[header_index - 1])
				else:
					_on_header_pressed(_headers[header_index + 1])
		header.list.queue_free()


func update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

## Обрабатывает события drag & drop.[br]
## Если [param item] is [Header] собственный, то используется для вычисления позиции новой [Header],
## иначе для вычисления используется [param to_position].[br]
## Параметр [param data] принимает словарь с даннымии.[br]
## Метод выполняет только одно действие по условию из списка в этом порядке:[br]
## 1. [param item] собственная кнопка добавления - будет создан и присвоен новый [TrackList] с копией [DataSource].[br]
## 2. [param data.from] is [Header] - источник, если свой [Header], то будет перемещен,
## если чужой то будет украден и присвоен [TrackList] из [member Header.list];[br]
## 3. [param data.track_list] is [TrackList] - будет украден и присвоен этот [TrackList];[br]
## 4. [param data.source] is [DataSource] и [param data.player] is [Player] - будет создан и присвоен
## новый [TrackList] с этим данными.[br]
## Если [param test] == [param true], то метод можно воспринимать как константный - никакую логику не выполняет, только вовращает
## [param true] или [param false], можно использовать вместо [member _can_drop_data].[br]
func drop_data(to_position: Vector2, data: Variant, item: Object = null, test := false) -> bool:
	if data is Dictionary:
		## Header в который была сброшена data
		var to_header := G.validate(item, Header) as Header
		## кнопка добавления в которую была сброшена data
		var to_add_button := item as BaseButton if item == _add_button_1 or item == _add_button_2 else null
		## номер Header куда будет помещен другой Header
		var to_index: int = _headers.size()
		## Header откуда была взята data
		var header := G.validate(data.get('from'), Header) as Header
		## TrackList из data
		var list := G.validate(data.get('track_list'), TrackList) as TrackList
		## DataSource из data
		var source := G.validate(data.get('source'), DataSource) as DataSource
		## Player из data
		var player := G.validate(data.get('player'), Player) as Player
		
		## не позволяем сбрасывать Header в самого себя
		if header and header == to_header:
			return false
		
		## если data была сброшена на кнопку AddButton, то игнорируем все кроме source и player
		if to_add_button:
			if header:
				## но TrackList из Header в приоритете перед TrackList из data
				list = header.list
			if list:
				## но Player и DataSource из TrackList в приоритете перед Player и DataSource из data
				source = list.source
				player = list.player
			if source:
				source = DataSourceFiltered.new(source.get_not_ordered()) ## создаем новый источник
			header = null ## игнорируем
			list = null ## игнорируем
		
		## вычисляем целевой индекс заголовка
		if to_header:
			to_index = _headers.find(to_header)
		else:
			## TODO: добавить вычисление to_index
			if to_position:
				pass
		
		
		if header: ## если есть заголовок
			if _has_header(header): ## если заголовок свой
				if not test:
					## перемещаем заголовок
					_headers.erase(header)
					_headers.insert(mini(to_index, _headers.size()), header)
					_headers_parent.queue_sort()
				return true
			
			elif is_instance_valid(lists_parent): ## если можем создавать трек листы
				if is_instance_valid(header.list): ## если у чужого заголовка есть трек лист
					if not test:
						## воруем трек лист
						assert(header.list != lists_parent)
						if header.list.get_parent():
							header.list.get_parent().remove_child(header.list)
						lists_parent.add_child(header.list)
						## создаем заголовок
						_header_create(list, to_index)
					return true
		
		elif is_instance_valid(lists_parent): ## если можем создавать трек листы
			if list: ## если есть трек лист
				if lists_parent != list.get_parent(): ## если трек лист чужой
					if not test:
						## воруем трек лист
						if header.list.get_parent():
							header.list.get_parent().remove_child(header.list)
						lists_parent.add_child(header.list)
						## создаем заголовок
						_header_create(list, to_index)
					return true
			
			else: ## если нет трек листа
				if source and player: ## если есть проигрыватель и источник
					if not test:
						## создаем трек лист
						list = _create_track_list(source.get_ordered(), player)
						list.focus_on_current_track()
						## создаем заголовок
						_header_create(list, to_index)
					return true
	return false


func _update_add_buttons_visible() -> void:
	if _headers:
		_add_button_1.visible = not _headers_scroll_bar.visible
		_add_button_2.visible = _headers_scroll_bar.visible
	else:
		_add_button_1.visible = true

func _update() -> void:
	_updating = false
	
	if lists_parent:
		for child in lists_parent.get_children():
			if child is TrackList:
				var list := child as TrackList
				if not _get_header_for_list(list):
					_header_create(list)
	
	for header in _headers.duplicate():
		if not lists_parent or not is_instance_valid(header.list) or header.list.get_parent() != lists_parent:
			_header_remove(header)

func _header_create(list: TrackList, index : int = _headers.size()) -> Header:
	var header := Header.new()
	header.list = list
	header.set_title(list.visible_name)
	header.set_drag_forwarding(_get_drag_data.bind(header), _can_drop_data.bind(header), _drop_data.bind(header))
	
	header.close_pressed.connect(_on_header_close_pressed.bind(header))
	header.pressed.connect(_on_header_pressed.bind(header))
	
	_headers.insert(mini(index, _headers.size()), header)
	_headers_parent.add_child(header)
	
	return header

func _header_remove(header: Header) -> void:
	_headers.erase(header)
	_headers_parent.remove_child(header)
	header.queue_free()

func _get_header_for_list(list: TrackList) -> Header:
	for header in _headers:
		if header.list == list:
			return header
	return null

func _has_header(header: Header) -> bool:
	return header in _headers

func _create_track_list(source := default_source, player := default_player) -> TrackList:
	assert(is_instance_valid(lists_parent))
	var list := TRACK_LIST.instantiate() as TrackList
	list.source = source
	list.player = player
	list.visible_name = 'NoName%d' % list.get_instance_id()
	list.focus_track_on_ready = true
	lists_parent.add_child(list)
	return list
