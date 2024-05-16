class_name DataSourceOrdered
extends DataSource

@export var inverted := false:
	set(value):
		if value != inverted:
			inverted = value
			changes_up()

var _tracks : Array[DataBase.Track] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func _update() -> void:
	var new_tracks : Array[DataBase.Track] = []
	if source:
		new_tracks = source.get_tracks().duplicate()
		
		if inverted:
			new_tracks.sort_custom(compare_inv)
		
		else:
			new_tracks.sort_custom(compare)
	
	if new_tracks != _tracks:
		_tracks = new_tracks
		_tracks.make_read_only()
		changes_up()

func get_tracks() -> Array[DataBase.Track]:
	return _tracks

static func compare(track_a : DataBase.Track, track_b : DataBase.Track) -> bool:
	return track_a.order_string < track_b.order_string

static func compare_inv(track_a : DataBase.Track, track_b : DataBase.Track) -> bool:
	return track_a.order_string > track_b.order_string
