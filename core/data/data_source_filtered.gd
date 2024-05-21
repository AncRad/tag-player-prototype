class_name DataSourceFiltered
extends DataSource

signal filters_changed

@export var expression : ExprNode:
	set(value):
		if not value:
			value = ExprNode.new(ExprNode.Type.SubExpression)
		
		if value != expression:
			if expression:
				expression.changed.disconnect(changes_up)
			
			expression = value
			
			if expression:
				expression.changed.connect(changes_up)
			
			changes_up()
			filters_changed.emit()

var _tracks : Array[DataBase.Track] = []


func _init(p_source : DataSource = null):
	expression = null
	if p_source:
		source = p_source

func _update() -> void:
	var new_tracks : Array[DataBase.Track] = []
	
	if source:
		if expression:
			for track in source.get_tracks():
				if expression.solve(track):
					new_tracks.append(track)
		
		else:
			new_tracks = source.get_tracks().duplicate()
	
	if new_tracks != _tracks:
		_tracks = new_tracks
		_tracks.make_read_only()
		changes_up()

func get_tracks() -> Array[DataBase.Track]:
	return _tracks
