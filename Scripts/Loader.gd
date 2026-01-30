# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node

var library : Dictionary = {}
var _load_queue : Array = []
var _is_loading : bool = false

func _ready() -> void:
	_preload_resources()

func _preload_resources() -> void:
	var dir : PackedStringArray = DirAccess.get_files_at("res://Objects/obj_ids/")
	
	for file : String  in dir:
		var path : String = "res://Objects/obj_ids/" + file
		_load_queue.append(path)
		ResourceLoader.load_threaded_request(path)
	
	_is_loading = true

func _process(_delta: float) -> void:
	if not _is_loading:
		return
	
	var finished_count : int = 0
	for path : String in _load_queue:
		var status : ResourceLoader.ThreadLoadStatus =  ResourceLoader.load_threaded_get_status(path)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res : GD_Object = ResourceLoader.load_threaded_get(path)
			library[res.id] = res
			finished_count += 1
	
	if finished_count == _load_queue.size():
		_is_loading = false
