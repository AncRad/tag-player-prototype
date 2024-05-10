extends RichTextLabel

@export var source : DataSource:
	set(value):
		if value != source:
			source = value

func _ready() -> void:
	source.data_changed.connect(update)

func update():
	#var line_separation := get_theme_constant('line_separation')
	
	clear()
	var tracks := source.get_tracks()
	
	for i in tracks.size():
		var track := tracks[i]
		var name_string := track.name_string as String
		var split := name_string.split(' - ', false)
		pop_all()
		if split.size() == 2:
			var split2 := split[0].replace(' feat. ', ', ').split(', ', false)
			if split2:
				for j in split2.size():
					push_color(Color.WHITE.darkened(0.5))
					push_meta(split2[j])
					add_text(split2[j])
					pop()
					
					if j < split2.size() - 1:
						push_color(Color.WHITE.darkened(0.7))
						add_text(', ')
			else:
				push_color(Color.WHITE.darkened(0.5))
				push_meta(split[0])
				add_text(split[0])
				pop()
			
			push_color(Color.WHITE.darkened(0.7))
			add_text(' - ')
			
			push_color(Color.WHITE.darkened(0.6))
			add_text(split[1])
			
		else:
			push_color(Color.WHITE.darkened(0.6))
			add_text(name_string)
		
		if i < tracks.size() - 1:
			add_text('\n')


func _on_meta_clicked(meta: Variant) -> void:
	print(meta)
