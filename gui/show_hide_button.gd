extends Button

@export var puppet : Control:
	set(value):
		if value != puppet:
			if puppet:
				puppet.visibility_changed.disconnect(_on_puppet_visibility_changed)
				disabled = true
			
			puppet = value
			
			if puppet:
				puppet.visibility_changed.connect(_on_puppet_visibility_changed)
				disabled = false

var _block := false


func _ready() -> void:
	_on_puppet_visibility_changed()

func _pressed() -> void:
	if not _block:
		_block = true
		
		if is_instance_valid(puppet):
			puppet.visible = button_pressed
		else:
			disabled = true
			button_pressed = false
		
		_block = false

func _on_puppet_visibility_changed() -> void:
	if not _block:
		_block = true
		
		if is_instance_valid(puppet):
			button_pressed = puppet.visible
		else:
			disabled = true
			button_pressed = false
		
		_block = false
