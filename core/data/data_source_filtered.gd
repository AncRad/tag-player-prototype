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

var tags_filter : Array[Dictionary] = []:
	set(value):
		tags_filter = value
		changes_up()
		filters_changed.emit()

var tracks_filtered : Array[Dictionary] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func _update() -> void:
	var new_filtered : Array[Dictionary] = source.get_tracks()
	if source:
		
		var current_tag_filters := tags_filter.duplicate()
		if tag_names_filter:
			var root := get_root()
			if root:
				for name in tag_names_filter:
					var tag := root.name_to_tag(name)
					if tag:
						current_tag_filters.append(tag)
		
		if name_filter:
			new_filtered = filter_by_name(new_filtered, name_filter)
		
		if current_tag_filters:
			new_filtered = filter_by_tags(new_filtered, current_tag_filters)
	
	if new_filtered != tracks_filtered:
		tracks_filtered = new_filtered
		new_filtered = []
		tracks_filtered.make_read_only()
		changes_up()

func get_tracks() -> Array[Dictionary]:
	return tracks_filtered

#func _filter() -> void:

static func filter_by_tags(input : Array[Dictionary], p_filter : Array[Dictionary]) -> Array[Dictionary]:
	if p_filter:
		var out : Array[Dictionary] = []
		for track in input:
			var all := true
			for tag in p_filter:
				if not track in tag.track2priority:
					all = false
					break
			if all:
				out.append(track)
		return out
	return input

static func filter_by_name(input : Array[Dictionary], p_filter : String) -> Array[Dictionary]:
	if p_filter:
		var out : Array[Dictionary] = []
		for track in input:
			if track.file_name.matchn(p_filter):
				out.append(track)
		return out
	return input
