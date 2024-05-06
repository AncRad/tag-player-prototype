extends Node

@export var data_base : DataBase
@export var load_on_ready : bool = false
@export var update_on_process : bool = false
@export var handle_files_dropped : bool = false
@export var handle_close_requested : bool = false


func _enter_tree() -> void:
	get_window().files_dropped.connect(_on_files_dropped)
	get_window().close_requested.connect(_on_close_requested)

func _exit_tree() -> void:
	get_window().files_dropped.disconnect(_on_files_dropped)
	get_window().close_requested.disconnect(_on_close_requested)

func _ready() -> void:
	if load_on_ready:
		if FileAccess.file_exists(get_default_data_base_file()):
			data_base_load(get_default_data_base_file())
			data_base.update()

func _process(_delta) -> void:
	if update_on_process:
		data_base.update()

func _on_files_dropped(files : PackedStringArray) -> void:
	if handle_files_dropped:
		var finded : Array[String] = []
		for file in files:
			if DirAccess.dir_exists_absolute(file):
				finded.append_array(find_files(file))
			elif FileAccess.file_exists(file):
				if file.get_extension().to_lower() in ["mp3"]:
					finded.append(file)
		
		if finded:
			var tracks := data_base.tracks_create(finded)
			var tag := data_base.name_to_tag("tagme")
			if not tag:
				tag = data_base.tag_create("tagme", Color.BLUE_VIOLET.lightened(0.2))
			for track in tracks:
				data_base.tag_track(track, tag, 50)

func _on_close_requested() -> void:
	if handle_close_requested:
		data_base_save(get_default_data_base_file())
		get_tree().quit()

func data_base_save(path : String) -> void:
	var temp_path := "%s/.%s" % [path.get_base_dir(), path.get_file()]
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	var err := FileAccess.get_open_error()
	assert(err == OK)
	if file and err == OK:
		file.store_buffer(data_base.to_bytes())
		err = file.get_error()
		assert(err == OK)
		if err == OK:
			file.flush()
			err = file.get_error()
			assert(err == OK)
			if err == OK:
				if FileAccess.file_exists(path):
					err = DirAccess.remove_absolute(path)
				assert(err == OK)
				if err == OK:
					err = DirAccess.rename_absolute(temp_path, path)
					assert(err == OK)
					if err == OK:
						data_base.changes_cached = data_base.changes

func data_base_load(path : String) -> void:
	var bytes := FileAccess.get_file_as_bytes(path)
	var err := FileAccess.get_open_error()
	assert(err == OK)
	if err == OK and bytes:
		data_base.from_bytes(bytes)

static func get_default_data_base_file_name() -> String:
	return "data_base.tpdb"

static func get_default_data_base_dir() -> String:
	return OS.get_user_data_dir()

static func get_default_data_base_file() -> String:
	return "%s/%s" % [get_default_data_base_dir(), get_default_data_base_file_name()]

static func find_files(dir_path : String) -> Array[String]:
	var files : Array[String] = []
	var directories : Array[String] = [dir_path]
	while directories.size():
		var dir_name := directories[-1]
		directories.remove_at(directories.size() - 1)
		
		var dir := DirAccess.open(dir_name)
		if dir:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					directories.push_back("%s/%s" % [dir_name, file_name])
				elif file_name.get_extension().to_lower() in ["mp3"]:
					files.push_back("%s/%s" % [dir_name, file_name])
				file_name = dir.get_next()
	return files

