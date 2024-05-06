class_name Player
extends AudioStreamPlayer
## Player

@export var playback : Playback:
	set(value):
		if value:
			assert(not playback and is_instance_valid(value))
			if not playback and is_instance_valid(value):
				value.player = self
				assert(value.player == self)
				if value.player == self:
					playback = value

func _process(_delta) -> void:
	if playback:
		playback.progress_changed.emit(playback.get_progress())
