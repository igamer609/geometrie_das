# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node

enum RegistryType {CREATED, SAVED}

const _REGISTRY_PATHS : Dictionary = {
	0 : "user://created_levels/created_levels.datreg",
	1: "user://saved_levels/saved_levels.datreg"
}

var library : Dictionary = {}
var scenes : Dictionary = {}

var _res_load_queue : Array = []
var _scene_load_queue : Array = []
var _is_loading : bool = false

#Current registry structure:
#{"levels": {"id1" : {....}, "id2" : {...}, ...}, "order" : ["id2", "id1", ...]}
var current_registry = {}
var _current_registry_type : RegistryType

func _ready() -> void:
	_preload_resources()
	_preload_scenes()

func _preload_resources() -> void:
	var dir : PackedStringArray = DirAccess.get_files_at("res://Objects/obj_ids/")
	
	for file : String  in dir:
		var path : String = ("res://Objects/obj_ids/" + file).replace(".remap", "")
		_res_load_queue.append(path)
		ResourceLoader.load_threaded_request(path)
	
	_is_loading = true

func _preload_scenes() -> void:
	var scenes_to_be_loaded : Array[String] = [
		"res://Objects/GDObject.tscn",
	]
	
	for file : String in scenes_to_be_loaded:
		_scene_load_queue.append(file)
		ResourceLoader.load_threaded_request(file)
	
	_is_loading = true

func _process(_delta: float) -> void:
	if not _is_loading:
		return
	
	var finished_count : int = 0
	for path : String in _res_load_queue:
		var status : ResourceLoader.ThreadLoadStatus =  ResourceLoader.load_threaded_get_status(path)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res = ResourceLoader.load_threaded_get(path)
			library[res.id] = res
			finished_count += 1
	
	for path : String in _scene_load_queue:
		var status : ResourceLoader.ThreadLoadStatus =  ResourceLoader.load_threaded_get_status(path)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var scene = ResourceLoader.load_threaded_get(path)
			scenes[path.get_file().split(".")[0]] = scene
			finished_count += 1
	
	if finished_count == _res_load_queue.size() + _scene_load_queue.size():
		
		_res_load_queue.clear()
		_scene_load_queue.clear()
		
		_is_loading = false

func get_current_registry_type() -> RegistryType:
	return _current_registry_type

#can be replaced by custom RefCounted based object for easier management
func entry_data_from_info(info : Dictionary, path_ref : String) -> Dictionary:
	return {
		"info" : info,
		"ref" : path_ref
	}

func _check_registry_availability(reg_type : RegistryType) -> bool:
	match reg_type:
		RegistryType.CREATED: 
			if not DirAccess.dir_exists_absolute("user://created_levels/"):
				DirAccess.make_dir_absolute("user://created_levels/")
				return false
		RegistryType.SAVED:
			if not DirAccess.dir_exists_absolute("user://saved_levels/"):
				DirAccess.make_dir_absolute("user://saved_levels/")
				return false
		_:
			return false
	
	return FileAccess.file_exists(_REGISTRY_PATHS[reg_type])

func load_registry_to_memory(reg_type : RegistryType) -> void:
	
	var is_valid_load : bool = save_current_registry()
	
	var reg_file : FileAccess = FileAccess.open_compressed(_REGISTRY_PATHS[reg_type], FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	var reg_string : String = reg_file.get_line()
	
	if not reg_string.is_empty():
		current_registry = JSON.parse_string(reg_string)
	
	if current_registry.is_empty():
			current_registry["levels"] = {}
			current_registry["order"] = []
	
	_current_registry_type = reg_type

func create_entry(id : String, data : Dictionary) -> bool:
	
	var is_valid : bool = _check_registry_availability(_current_registry_type)
	
	if is_valid:
		if current_registry.is_empty():
			current_registry["levels"] = {}
			current_registry["order"] = []
		
		current_registry["levels"][id] = data
		current_registry["order"].push_front(id)
		return true
	
	return false

func save_current_registry() -> bool:
	var file_exists : bool = _check_registry_availability(_current_registry_type)
	
	if not file_exists:
		var reg_file : FileAccess = FileAccess.open_compressed(_REGISTRY_PATHS[_current_registry_type], FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
		reg_file.store_line("{}")
	
	if not current_registry.is_empty():
		var reg_file : FileAccess = FileAccess.open_compressed(_REGISTRY_PATHS[_current_registry_type], FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
		var reg_string : String = JSON.stringify(current_registry)
		var is_valid : bool = reg_file.store_line(reg_string)
		reg_file.close()
		
		if not is_valid:
			return false
		return true
	else: 
		return false

func updade_entry(id : String, data : Dictionary, save_after : bool = false) -> bool:
	
	var is_valid : bool = _check_registry_availability(_current_registry_type)
	
	if is_valid:
		if current_registry.is_empty():
			current_registry["levels"] = {}
			current_registry["order"] = []
			return create_entry(id, data)
		else:
			current_registry["levels"][id] = data
		
		if save_after:
			return save_current_registry()
		else:
			return true
	
	return false

func update_entry_and_main_file(id : String, data : Dictionary, save_after : bool = false) -> bool:
	
	var is_valid : bool = _check_registry_availability(_current_registry_type)
	
	if is_valid:
		if current_registry.is_empty():
			current_registry["levels"] = {}
			current_registry["order"] = []
			return create_entry(id, data)
		else:
			current_registry["levels"][id] = data
		
		var lvl_file : FileAccess = FileAccess.open_compressed(data["ref"], FileAccess.READ, FileAccess.COMPRESSION_GZIP)
		var lvl_data : Dictionary = JSON.parse_string(lvl_file.get_line())
		lvl_data["info"] = data["info"]
		var new_lvl_data = JSON.stringify(lvl_data)
		lvl_file.close()
		
		lvl_file = FileAccess.open_compressed(data["ref"], FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
		lvl_file.store_line(new_lvl_data)
		
		if save_after:
			return save_current_registry()
		else:
			return true
	
	return false
