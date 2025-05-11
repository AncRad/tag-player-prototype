extends Control

const TRACK_LIST = preload('uid://mqs6rjv3osx0')

signal tabs_changed
signal main_tab_changed

var _updating : bool
var _main_tab : TrackList
var _tabs : Array[TrackList]


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED, NOTIFICATION_READY:
			queue_update()

func queue_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func get_tabs() -> Array[TrackList]:
	var tabs : Array[TrackList]
	for child in get_children():
		if child is TrackList:
			tabs.append(child)
	return tabs

func get_main_tab() -> TrackList:
	if not is_instance_valid(_main_tab):
		_main_tab = null
	return _main_tab

func set_main_tab(next_tab : TrackList) -> void:
	if _main_tab != next_tab:
		var tabs := get_tabs()
		if next_tab in tabs:
			_main_tab = next_tab
			for tab in tabs:
				tab.visible = tab == _main_tab
			main_tab_changed.emit()
		else:
			push_error()
			breakpoint

func _on_tab_visibility_changed(from : CanvasItem) -> void:
	if not from:
		push_error()
	if not from in get_tabs():
		from.visibility_changed.disconnect(_on_tab_visibility_changed)
		return
	queue_update()

func _update() -> void:
	if not _updating:
		push_error()
		breakpoint
		return
	
	var is_tabs_changed := false
	
	## составляем будущий список вкладко
	var tabs_next := get_tabs()
	
	## ищем и подкчаем новые вкладки
	for tab in tabs_next:
		if not tab in _tabs:
			is_tabs_changed = true
			tab.visibility_changed.connect(_on_tab_visibility_changed.bind(tab))
	
	## ищем и отключаем удаленные вкладки
	for tab in _tabs:
		if is_instance_valid(tab):
			if not tab in tabs_next:
				is_tabs_changed = true
				tab.visibility_changed.disconnect(_on_tab_visibility_changed)
		else:
			is_tabs_changed = true
	
	## обновляем список вкладок если нужно
	if is_tabs_changed:
		_tabs = tabs_next
		_tabs.make_read_only()
	
	## определяем следующую главную вкладку main_tab_next
	var main_tab_next := get_main_tab()
	if main_tab_next and not main_tab_next in _tabs:
		main_tab_next = null
	
	## обновляем видимость вкладок в соответствии с main_tab_next
	## или ищем первую видимую вкладку
	for tab in _tabs:
		if tab.visible:
			if not main_tab_next:
				main_tab_next = tab
		elif tab == main_tab_next:
			tab.show()
	
	## определяем новую главную вкладку, если не была найдена видимая вкладка на прошлом этапе
	if not main_tab_next and _tabs:
		main_tab_next = _tabs[0]
		main_tab_next.show()
	
	var is_main_tab_changed := false
	if _main_tab != main_tab_next:
		_main_tab = main_tab_next
		is_main_tab_changed = true
	
	## испускаем сигналы
	if is_tabs_changed:
		tabs_changed.emit()
	if is_main_tab_changed:
		main_tab_changed.emit()
	
	_updating = false
