# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name LevelRegistry extends Resource

enum RegistryType {NONE, CREATED, SAVED}

const _REGISTRY_PATHS : Dictionary = {
	1 : "user://created_levels/created_levels.datreg",
	2: "user://saved_levels/saved_levels.datreg"
}

@export var type : RegistryType = RegistryType.NONE
@export var levels: Dictionary = {}
@export var order: Array = []

static func create_registry(type : RegistryType) -> LevelRegistry:
	var registry : LevelRegistry = LevelRegistry.new()
	registry.type = type
	
	if type != RegistryType.NONE:
		if registry._check_registry_availability():
			registry = load(_REGISTRY_PATHS[type])
		
		if not registry:
			registry = LevelRegistry.new()
			registry.type = type
			registry._check_registry_availability()
	
	return registry

func to_dict() -> Dictionary:
	var level_dictionaries : Dictionary = {}
	
	for id : String in levels.keys():
		level_dictionaries[id] = levels[id].meta.to_dict()
	
	return {
		"levels" : level_dictionaries,
		"order": order
	}

func _check_registry_availability() -> bool:
	
	match type:
		RegistryType.NONE:
			return false
		RegistryType.CREATED: 
			if not DirAccess.dir_exists_absolute("user://created_levels/"):
				DirAccess.make_dir_absolute("user://created_levels/")
		RegistryType.SAVED:
			if not DirAccess.dir_exists_absolute("user://saved_levels/"):
				DirAccess.make_dir_absolute("user://saved_levels/")
		_:
			return false
	
	if not FileAccess.file_exists(_REGISTRY_PATHS[type]):
		save()
	
	return true

func create_entry(id : String, data : LevelRegistryEntry) -> Error:
	var is_valid : bool = _check_registry_availability()
	
	if is_valid:
		levels[id] = data
		order.push_front(id)
		return OK
	
	return ERR_DATABASE_CANT_WRITE

func save() -> Error:
	var error : Error = OK
	
	if type != RegistryType.NONE:
		error = ResourceSaver.save(self, _REGISTRY_PATHS[type], ResourceSaver.FLAG_COMPRESS)
	
	return error

func updade_entry(id : String, data : LevelRegistryEntry, save_after : bool = false) -> Error:
	var is_valid : bool = _check_registry_availability()
	
	if is_valid:
		if levels.is_empty():
			return create_entry(id, data)
		else:
			levels[id] = data
		
		if save_after:
			return save()
		else:
			return OK
	
	return ERR_DATABASE_CANT_WRITE

func update_entry_and_main_file(id : String, data : LevelRegistryEntry, save_after : bool = false) -> Error:
	var is_valid : bool = _check_registry_availability()
	
	if is_valid:
		levels[id] = data
		
		var lvl_data : LevelData = ResourceLoader.load(data.ref) as LevelData
		lvl_data.meta = data.meta
		ResourceSaver.save(lvl_data, data.ref)
		
		if save_after:
			return save()
		else:
			return OK
	
	return ERR_FILE_CANT_WRITE

func delete_level(id: String) -> Error:
	var is_valid : bool = _check_registry_availability()
	
	if is_valid:
		if levels.has(id):
			levels.erase(id)
			order.erase(id)
		else:
			return ERR_DOES_NOT_EXIST
		
		var path : String = ""
		if type == RegistryType.CREATED:
			path = "user://created_levels/"
		elif type == RegistryType.SAVED:
			path = "user://saved_levels/"
		
		DirAccess.remove_absolute(path + id + ".gdaslvl")
		return save()
	
	return ERR_FILE_NOT_FOUND
