class_name Solver
extends Resource

var invert := false
var all := false
var items : Array


func _init(p_invert : bool = false, p_all : bool = false, p_items : Array = []):
	invert = p_invert
	all = p_all
	items = p_items

func solve(track : DataBase.Track) -> bool:
	var condition := true
	for item in items:
		condition = false
		if item is DataBase.Tag:
			condition = track.is_tagged(item)
		elif item is String:
			condition = track.find_string.matchn(item)
		elif item is Solver:
			condition = item.solve(track)
		else:
			assert(false)
		
		if all != condition:
			break
	
	if invert:
		return not condition
	return condition
