@tool
extends Texture2D
class_name PlaybackIconTexture

const Types : Dictionary[StringName, StringName] = {
	&'Play' : &'Play',
	&'Pause' : &'Pause',
	&'Stop' : &'Stop',
	&'Next' : &'Next',
	&'Prev' : &'Prev',
}

var type : StringName = Types.Play:
	set(value):
		if value != type:
			if value not in Types:
				assert(value in Types)
				return
			type = value
			emit_changed()
@export_range(16, 120, 0.1) var size : float = 32:
	set(value):
		if value != size:
			size = value
			emit_changed()
@export_range(0, 20, 0.1) var margin : float = 2:
	set(value):
		if value != margin:
			margin = value
			emit_changed()
#@export_range(0, 20, 0.1) var width : float = 2:
	#set(value):
		#if value != width:
			#width = value
			#emit_changed()

func _validate_property(property: Dictionary) -> void:
	if property.name == &'type':
		property.usage |= PROPERTY_USAGE_DEFAULT
		property.hint |= PROPERTY_HINT_ENUM
		property.hint_string = ','.join(Types.keys())

@warning_ignore('unused_parameter')
func _draw(item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	var points : PackedVector2Array
	points.resize(3)
	points.set(i, Vector2())
	RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([modulate]), -1, false)

@warning_ignore('unused_parameter')
func _draw_rect(item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	_draw(item, rect.position, modulate, transpose)

@warning_ignore('unused_parameter')
func _draw_rect_region(item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	_draw(item, rect.position, modulate, transpose)

func _get_height() -> int:
	return int(size)

func _get_width() -> int:
	return int(size)
