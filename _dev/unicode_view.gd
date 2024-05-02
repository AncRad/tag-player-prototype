@tool
extends TextEdit

@export var update : bool:
	set(_value):
		generate()
#@export var from_int : int = 0
#@export var from_hex : String = ""

#@export var to_int : int = 0
#@export var to_hex : String = ""


func generate() -> void:
	
	var from := "▀".unicode_at(0)
	var list := PackedStringArray()
	list.resize(200)
	for i in list.size():
		list.set(i, String.chr(from + i))
	text = " ".join(list)
