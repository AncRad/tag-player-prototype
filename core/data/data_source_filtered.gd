class_name DataSourceFiltered
extends DataSource

signal filters_changed

@export var solver : Solver:
	set(value):
		if value != solver:
			if solver:
				solver.changed.disconnect(changes_up)
			
			solver = value
			
			if solver:
				solver.changed.connect(changes_up)
			
			changes_up()

var tracks_filtered : Array[DataBase.Track] = []


func _init(p_source : DataSource = null):
	if p_source:
		source = p_source

func _update() -> void:
	var new_filtered : Array[DataBase.Track] = []
	
	if source:
		if solver:
			for track in source.get_tracks():
				if solver.solve(track):
					new_filtered.append(track)
		
		else:
			new_filtered = source.get_tracks().duplicate()
	
	if new_filtered != tracks_filtered:
		tracks_filtered = new_filtered
		tracks_filtered.make_read_only()
		changes_up()

func get_tracks() -> Array[DataBase.Track]:
	return tracks_filtered

#func _filter() -> void:
