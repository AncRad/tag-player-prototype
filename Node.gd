extends Node

func _ready() -> void:
	const db = preload('res://core/data_base.tres')
	
	var track := db.get_tags()
	
