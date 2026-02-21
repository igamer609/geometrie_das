class_name LevelRegistry extends Resource

enum RegistryType {NONE, CREATED, SAVED}

const _REGISTRY_PATHS : Dictionary = {
	1 : "user://created_levels/created_levels.datreg/",
	2: "user://saved_levels/saved_levels.datreg/"
}

@export var type : RegistryType = RegistryType.NONE
@export var levels: Dictionary = {}
@export var order: Array = []

static func create_registry(type : RegistryType) -> LevelRegistry:
	var registry : LevelRegistry = null
	
	if type != RegistryType.NONE:
		
		registry = load(_REGISTRY_PATHS[type])
		
		if not registry:	
			registry = LevelRegistry.new()
			var reg_file : FileAccess = FileAccess.open_compressed(_REGISTRY_PATHS[type], FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
			var reg_string : String = reg_file.get_line()
		
			var dict : Dictionary = JSON.parse_string(reg_string)
		
			for id : String in dict["levels"].keys():
				registry.levels[id] = LevelRegistryEntry.from_raw_dict(dict["levels"][id])
		
			registry.order = dict.get("order", [])
	
	return registry

func to_dict() -> Dictionary:
	var level_dictionaries : Dictionary = {}
	
	for id : String in levels.keys():
		level_dictionaries[id] = levels[id].meta.to_dict()
	
	return {
		"levels" : levels,
		"order": order
	}

func _check_registry_availability() -> bool:
	match type:
		RegistryType.NONE:
			return false
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
	
	return FileAccess.file_exists(_REGISTRY_PATHS[type])

func create_entry(id : String, data : LevelRegistryEntry) -> bool:
	var is_valid : bool = _check_registry_availability()
	
	if is_valid:
		levels[id] = data
		order.push_front(id)
		return true
	
	return false

func save() -> bool:
	var file_exists : bool = _check_registry_availability()
	var reg_file : FileAccess
	
	if not file_exists and type != RegistryType.NONE:
		reg_file = FileAccess.open_compressed(_REGISTRY_PATHS[type], FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
		reg_file.store_line(JSON.stringify(to_dict()))
	
	reg_file = FileAccess.open_compressed(_REGISTRY_PATHS[type], FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	var reg_string : String = JSON.stringify(to_dict())
	var is_valid : bool = reg_file.store_line(reg_string)
	reg_file.close()
	
	if not is_valid:
		return false
	
	return true


func updade_entry(id : String, data : LevelRegistryEntry, save_after : bool = false) -> bool:
	var is_valid : bool = _check_registry_availability()
	
	if is_valid:
		if levels.is_empty():
			return create_entry(id, data)
		else:
			levels[id] = data
		
		if save_after:
			return save()
		else:
			return true
	
	return false

func update_entry_and_main_file(id : String, data : LevelRegistryEntry, save_after : bool = false) -> bool:
	
	var is_valid : bool = _check_registry_availability()
	
	if is_valid:
		if levels.is_empty():
			return create_entry(id, data)
		else:
			levels[id] = data
		
		var lvl_file : FileAccess = FileAccess.open_compressed(data.ref, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
		var lvl_data : LevelData = LevelData.from_dict(JSON.parse_string(lvl_file.get_line())) 
		lvl_data.meta = data.meta
		var new_lvl_data = JSON.stringify(lvl_data.to_dict())
		lvl_file.close()
		lvl_file = FileAccess.open_compressed(data.ref, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
		lvl_file.store_line(new_lvl_data)
		
		if save_after:
			return save()
		else:
			return true
	
	return false

func delete_level(id: String) -> bool:
	var is_valid : bool = _check_registry_availability()
	
	if is_valid:
		if levels.has(id):
			levels.erase(id)
			order.erase(id)
		else:
			return false
		
		var path : String = ""
		if type == RegistryType.CREATED:
			path = "user://created_levels/"
		elif type == RegistryType.SAVED:
			path = "user://saved_levels/"
		
		DirAccess.remove_absolute(path + id + ".gdaslvl")
		return save()
	
	return false
