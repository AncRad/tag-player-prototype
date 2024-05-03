class_name G
extends Object

func _init() -> void:
	assert(false)
	self.free()


static func validate(variant: Variant, type: Variant = null) -> Variant:
	if is_instance_valid(variant):
		if type:
			if is_instance_of(variant, type):
				return variant
			else:
				return null
		else:
			return variant
	return null
