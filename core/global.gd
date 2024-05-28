class_name G
extends Object

func _init() -> void:
	assert(false)
	self.free()


## Просто.[br]
## if type is null or type is Object:
## 	return value if is_instance_valid(value) and value is <[param type]> else default[br]
## else:
## 	return value if is_instance_of(value, type) else return 
## Почему это не поставляется с движком?
static func validate(value: Variant, type: Variant = null, default: Variant =  null) -> Variant:
	if type == null or type is Object:
		if is_instance_valid(value):
			if type:
				if is_instance_of(value, type):
					if type is Script:
						var value_script := value.get_script() as Script
						while type:
							if value_script == type:
								return value
							value_script = value_script.get_base_script()
						return default
					return value
				return default
			return value
		return default
	
	elif type is int:
		if type >= 0 and type < TYPE_MAX and is_instance_of(value, type):
			return value
	
	elif type is Dictionary:
		if value is Dictionary:
			if value.has_all(type.keys()):
				for key in type.keys():
					if typeof(value[key]) != type[key]:
						return default
				return value
	
	return default
