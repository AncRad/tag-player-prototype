class_name DataSourceOrdered
extends DataSource

@export var inverted := false:
	set(value):
		if value != inverted:
			inverted = value
			changes_up()

var tracks_ordered : Array[Dictionary] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func _update() -> void:
	if not _updated or source and not source._updated:
		sort()

func get_tracks() -> Array[Dictionary]:
	return tracks_ordered

func sort() -> void:
	var new_order : Array[Dictionary] = []
	if source:
		new_order = source.get_tracks().duplicate()
		if inverted:
			new_order.sort_custom(compare_inv)
		else:
			new_order.sort_custom(compare)
	
	if new_order != tracks_ordered:
		tracks_ordered = new_order
		new_order = []
		tracks_ordered.make_read_only()
		data_changed.emit()

static func compare(track_a : Dictionary, track_b : Dictionary) -> bool:
	return track_a.file_name < track_b.file_name

static func compare_inv(track_a : Dictionary, track_b : Dictionary) -> bool:
	return track_a.file_name > track_b.file_name
