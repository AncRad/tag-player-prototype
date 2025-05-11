extends Control

const TrackListTabContainer = preload('uid://bw51mlv7lmaao')
const TabHeader = preload('uid://brvv5v8wr1mu')

const TAB_HEADER = preload('uid://cn7sklr7p6d6g')
const TRACK_LIST = preload('uid://mqs6rjv3osx0')

@export
var tab_container : TrackListTabContainer:
	set(value):
		if value != tab_container:
			if is_instance_valid(tab_container):
				tab_container.tabs_changed.disconnect(queue_update)
				tab_container.main_tab_changed.disconnect(queue_update)
			
			tab_container = value
			
			if is_instance_valid(tab_container):
				tab_container.tabs_changed.connect(queue_update)
				tab_container.main_tab_changed.connect(queue_update)

@export
var default_source : DataSource

@export
var default_playback : Playback

var _add_tab_button : Control
var _updating : bool
var _updating_add_tab_button : bool


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_POSTINITIALIZE:
			set_drag_forwarding(Callable(), can_drop_data, drop_data)
		
		NOTIFICATION_SCENE_INSTANTIATED:
			_add_tab_button = %AddTabButton
			_add_tab_button.pressed.connect(_on_add_tab_button_pressed)
			var scroll := %ScrollContainer.get_h_scroll_bar() as HScrollBar
			scroll.focus_mode = Control.FOCUS_NONE
			scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
			scroll.modulate = Color(0,0,0,0)
			scroll.visibility_changed.connect(queue_update_add_tab_button)
			%ScrollContainer.set_drag_forwarding(Callable(), can_drop_data, drop_data)
			
			queue_update()
			queue_update_add_tab_button()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(tab_container):
		if event.is_pressed() and not event.is_echo():
			if event.is_action('track_list_panel_create_find_list'):
				var new_main_tab := TRACK_LIST.instantiate() as TrackList
				var old_main_tab := get_main_tab()
				if old_main_tab:
					new_main_tab.playback = old_main_tab.playback
					new_main_tab.source = DataSourceFiltered.new(old_main_tab.source.get_not_ordered()).get_ordered()
				elif default_source:
					new_main_tab.source = DataSourceFiltered.new(default_source.get_not_ordered()).get_ordered()
				tab_container.add_child(new_main_tab)
				tab_container.set_main_tab(new_main_tab)
				
				var old_main_header : TabHeader
				if old_main_tab:
					for header in get_headers():
						if header.tab == old_main_tab:
							old_main_header = header
							break
				var new_main_header := _add_header(new_main_tab)
				if old_main_header:
					move_header(new_main_header, old_main_header)

func queue_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func queue_update_add_tab_button() -> void:
	if not _updating_add_tab_button:
		_updating_add_tab_button = true
		_update_add_tab_button.call_deferred()

func move_header(header : TabHeader, to : TabHeader, offset := +1) -> void:
	var headers := get_headers()
	if not header in headers or not to in headers:
		push_error(); breakpoint; return
	#var count := %Headers.get_child_count()
	#var header_i := header.get_index()
	var to_i := to.get_index()
	%Headers.move_child(header, to_i + offset)

func get_headers() -> Array[TabHeader]:
	var headers : Array[TabHeader]
	for child in %Headers.get_children():
		if child is TabHeader:
			headers.append(child)
	return headers

func get_main_tab() -> TrackList:
	if is_instance_valid(tab_container):
		return tab_container.get_main_tab()
	return null

#func get_main_header() -> TabHeader:
	#var main_tab := get_main_tab()
	#if main_tab:
		#for header in get_headers():
			#if header.tab == main_tab:
				#return header
	#return null

func header_get_drag_data(_at_position: Vector2, header : TabHeader) -> Variant:
	var data := {}
	data.from = header
	data.tab_bar = self
	data.header = header
	data.track_list = header.tab
	
	if header.tab.source:
		data.source = header.tab.source
	
	if header.tab.playback:
		data.playback = header.tab.playback
		#if playback.current_track:
			#data.track = playback.current_track
	
	return data

func can_drop_data(_at_position: Vector2, data: Variant, header : TabHeader = null) -> bool:
	if not is_instance_valid(tab_container):
		return false
	if data is Dictionary:
		if 'header' in data:
			return false
		
		if 'tab_bar' in data:
			return false
		
		if 'source' in data and data.source is DataSource:
			return true
		
		if 'playback' in data and data.playback is Playback:
			return true
	return false

func drop_data(_at_position: Vector2, data: Variant) -> void:
	if not is_instance_valid(tab_container):
		return
	if data is Dictionary:
		if 'header' in data:
			return
		
		if 'tab_bar' in data:
			return
		
		var source : DataSource
		if 'source' in data and data.source is DataSource:
			source = data.source
		
		var playback : Playback
		if 'playback' in data and data.playback is Playback:
			playback = data.playback
		
		if source or playback:
			if not source:
				source = default_source
			if not playback:
				playback = default_playback
			if source and playback:
				var tab : TrackList = TRACK_LIST.instantiate()
				if Input.is_action_just_pressed('tab_bar_drop_as_child_modifer'):
					tab.source = DataSourceFiltered.new(source.get_not_ordered()).get_ordered()
				else:
					tab.source = source.get_ordered()
				tab.playback = playback
				tab_container.add_child(tab, true)
				#TODO: сделать добавление TabHeader с учетом at_position

func _on_add_tab_button_pressed() -> void:
	if is_instance_valid(tab_container):
		var tab : TrackList = TRACK_LIST.instantiate()
		if default_source:
			tab.source = DataSourceFiltered.new(default_source.get_not_ordered()).get_ordered()
		if default_playback:
			tab.playback = default_playback
		tab_container.add_child(tab, true)
		tab_container.set_main_tab(tab)

func _on_header_pressed(header : TabHeader) -> void:
	if is_instance_valid(header.tab) and tab_container and header.tab.get_parent() == tab_container:
		tab_container.set_main_tab(header.tab)
	else:
		queue_update()

func _on_header_close_pressed(header : TabHeader) -> void:
	if is_instance_valid(header.tab) and tab_container and header.tab.get_parent() == tab_container:
		header.tab.queue_free()
	else:
		queue_update()

func _add_header(tab : TrackList) -> TabHeader:
	var header : TabHeader = TAB_HEADER.instantiate()
	header.set_drag_forwarding(header_get_drag_data.bind(header), Callable(), Callable())
	header.pressed.connect(_on_header_pressed.bind(header))
	header.close_pressed.connect(_on_header_close_pressed.bind(header))
	header.text = 'unnamed'
	header.tab = tab
	%Headers.add_child(header)
	return header

func _remove_header(header : TabHeader) -> void:
	%Headers.remove_child(header)
	header.queue_free()

func _update() -> void:
	if not _updating:
		push_error(); breakpoint; return
	
	var tabs : Array[TrackList]
	if is_instance_valid(tab_container):
		tabs = tab_container.get_tabs()
	
	## удаляем лишние headers и составляем список _tab_to_header
	var _tab_to_header : Dictionary[TrackList, TabHeader]
	for header in get_headers():
		if is_instance_valid(header.tab) and header.tab in tabs:
			_tab_to_header[header.tab] = header
		else:
			_remove_header(header)
	
	## добавляем недостающие headers
	for tab in tabs:
		if not tab in _tab_to_header:
			_tab_to_header[tab] = _add_header(tab)
	
	_updating = false

func _update_add_tab_button() -> void:
	if not _updating_add_tab_button:
		push_error(); breakpoint; return
	if _updating:
		_update_add_tab_button.call_deferred()
		return
	
	var scroll := %ScrollContainer.get_h_scroll_bar() as HScrollBar
	if scroll.visible:
		if _add_tab_button.get_parent() == %RightFloatingPlace:
			%RightFloatingPlace.remove_child(_add_tab_button)
			%RightSidePlace.add_child(_add_tab_button)
	else:
		if _add_tab_button.get_parent() == %RightSidePlace:
			%RightSidePlace.remove_child(_add_tab_button)
			%RightFloatingPlace.add_child(_add_tab_button)
	
	_updating_add_tab_button = false
