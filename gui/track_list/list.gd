class_name List
extends Control

signal scroll_changed(scroll : float)
signal scroll_progress_changed(scroll_progress : float)

var scroll : float = 0.0:
	set(value):
		value = clampf(value, 0, get_scroll_max())
		if value != scroll:
			scroll = value
			queue_redraw()
			scroll_changed.emit(scroll)
			scroll_progress_changed.emit(scroll_progress)

var scroll_progress : float = 0.0: set = set_scroll_progress, get = get_scroll_progress

var _line_regions : Array[Array] = []


func has_point(point : Vector2) -> bool:
	return Rect2(Vector2(), size).grow(0.005).has_point(point)

func get_font() -> Font:
	return get_theme_font('font')

func get_font_size() -> int:
	return 14

func get_line_height() -> int:
	return int(get_font().get_height(get_font_size()))

func get_line_ascent() -> int:
	return int(get_font().get_ascent(get_font_size()))

func get_line_descent() -> int:
	return int(get_font().get_descent(get_font_size()))

func get_line_separation() -> int:
	return 2

func get_line_interval() -> int:
	return get_line_height() + get_line_separation()

func get_line_at_position(p_position : Vector2) -> float:
	if has_point(p_position):
		return p_position.y / get_line_interval() + wrapf(scroll, 0, 1)
	return -1

func get_line_max_count() -> int:
	return maxi(0, ceili(get_line_at_position(Vector2(0, size.y))))

func get_line_regions(line : int) -> Array[Dictionary]:
	assert(line >= 0 and line < _line_regions.size())
	if line >= 0 and line < _line_regions.size():
		return _line_regions[line]
	return []

func get_region_at_position(p_position : Vector2) -> Dictionary:
	var line := int(get_line_at_position(p_position))
	if line >= 0 and line < _line_regions.size():
		var line_regions := get_line_regions(line)
		for region in line_regions:
			if (region.rect as Rect2).has_point(p_position):
				return region
	return {}

func get_scroll_max() -> float:
	return 0

func get_scroll_progress() -> float:
	return clampf(scroll / get_scroll_max(), 0, 1)

func set_scroll_progress(value : float) -> void:
		scroll = get_scroll_max() * clampf(value, 0, 1)
