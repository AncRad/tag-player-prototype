class_name DataSourceFiltered
extends DataSource

signal filters_changed

@export var name_filter : String:
	set(value):
		if value != name_filter:
			name_filter = value
			changes_up()
			filters_changed.emit()

@export var tag_names_filter : Array[String] = []:
	set(value):
		tag_names_filter = value
		changes_up()
		filters_changed.emit()

var tags_filter : Array[DataBase.Tag] = []:
	set(value):
		tags_filter = value
		changes_up()
		filters_changed.emit()

var tracks_filtered : Array[DataBase.Track] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func _update() -> void:
	var new_filtered : Array[DataBase.Track] = []
	
	if source:
		new_filtered = source.get_tracks().duplicate()
		
		if name_filter:
			new_filtered = filter_by_name(new_filtered, name_filter)
		
		var current_tag_filters := tags_filter.duplicate()
		if tag_names_filter:
			var root := get_root()
			if root:
				for name in tag_names_filter:
					current_tag_filters.append_array(root.find_tags_by_name(name))
		
		if current_tag_filters:
			var dict := {}
			for tag in current_tag_filters:
				dict[tag] = null
			current_tag_filters.clear()
			current_tag_filters.assign(dict.keys())
			new_filtered = filter_by_tags(new_filtered, current_tag_filters, true)
	
	if new_filtered != tracks_filtered:
		tracks_filtered = new_filtered
		tracks_filtered.make_read_only()
		changes_up()

func get_tracks() -> Array[DataBase.Track]:
	return tracks_filtered

#func _filter() -> void:

static func filter_by_tags(input : Array[DataBase.Track], p_filter : Array[DataBase.Tag], any := false) -> Array[DataBase.Track]:
	if p_filter:
		var out : Array[DataBase.Track] = []
		
		if any:
			for track in input:
				for tag in p_filter:
					if track.is_tagged(tag):
						out.append(track)
						break
		
		else:
			for track in input:
				var all := true
				for tag in p_filter:
					if not track.is_tagged(tag):
						all = false
						break
				if all:
					out.append(track)
		
		return out
	return input

static func filter_by_name(input : Array[DataBase.Track], p_filter : String) -> Array[DataBase.Track]:
	if p_filter:
		var out : Array[DataBase.Track] = []
		for track in input:
			if track.find_string.matchn(p_filter):
				out.append(track)
		return out
	return input
