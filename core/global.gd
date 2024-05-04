class_name G
extends Object

func _init() -> void:
	assert(false)
	self.free()


## Просто.[br]
## object if is_instance_valid(object) and variant is <[param type]> else null[br]
## Почему это не поставляется с движком?
static func validate(object: Variant, type: Variant = null) -> Variant:
	if is_instance_valid(object):
		if type:
			if is_instance_of(object, type):
				if type is Script:
					var object_script := object.get_script() as Script
					while type:
						if object_script == type:
							return object
						object_script = object_script.get_base_script()
					return null
				return object
			return null
		return object
	return null
