# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node

signal free_objects
signal change_editor_layer

@onready var music_ids : Dictionary = {
	1 : [preload("res://Assets/music/Levels/Glorious Morning.mp3"), "Glorious Morning"],
	2 : [preload("res://Assets/music/Levels/yStep.mp3"), "yStep"]
}

var library : Dictionary = {}
var scenes : Dictionary = {}

var _res_load_queue : Array = []
var _scene_load_queue : Array = []
var _is_loading : bool = false

var current_registry : LevelRegistry

func _init() -> void:
	current_registry = LevelRegistry.new()

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

func load_registry(type : LevelRegistry.RegistryType) -> void:
	current_registry.save()
	current_registry = LevelRegistry.create_registry(type)
