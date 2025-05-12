@tool
extends Control

func _get_minimum_size() -> Vector2:
	var minsize := %AddDeleteButton.get_minimum_size() as Vector2
	minsize.x = maxf(minsize.x, size.y)
	return minsize
