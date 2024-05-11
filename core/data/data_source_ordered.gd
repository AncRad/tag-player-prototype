class_name DataSourceOrdered
extends DataSource

@export var inverted := false:
	set(value):
		if value != inverted:
			inverted = value
			changes_up()

var tracks_ordered : Array[DataBase.Track] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func _update() -> void:
	var new_order : Array[DataBase.Track] = []
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
		changes_up()

func get_tracks() -> Array[DataBase.Track]:
	return tracks_ordered

#func _sort() -> void:

static func compare(track_a : DataBase.Track, track_b : DataBase.Track) -> bool:
	return track_a.order_string < track_b.order_string

static func compare_inv(track_a : DataBase.Track, track_b : DataBase.Track) -> bool:
	return track_a.order_string > track_b.order_string
