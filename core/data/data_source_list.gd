class_name DataSourceList
extends DataSource

var _tracks : Array[DataBase.Track] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func set_source(value : DataSource) -> void:
	if value:
		var value_root := value.get_root()
		if value_root:
			super(value_root)
		else:
			assert(false)
	else:
		super(null)

func get_tracks() -> Array[DataBase.Track]:
	return _tracks

func append(track : DataBase.Track, merge := false) -> void:
	if not merge or not track in _tracks:
		_tracks.append(track)
		changes_up()

func append_array(p_tracks : Array[DataBase.Track], merge := false) -> void:
	var to_append : Array[DataBase.Track] = []
	
	if merge:
		for track in p_tracks:
			if not track in _tracks:
				to_append.append(track)
	else:
		to_append = p_tracks
	
	if to_append.size():
		_tracks.append_array(to_append)
		changes_up()

func erase(track : DataBase.Track) -> void:
	_tracks.erase(track)
	changes_up()

func clear() -> void:
	changes_up(_tracks.size())
	_tracks.clear()
