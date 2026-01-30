# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node

@export var cube_id : int = 0
@export var ship_id : int = 0
@export var ball_id : int = 0

var new : bool = false

var uid : int = 0
var _progress : Dictionary = {
	"levels":[],
	"completions":[],
	"saved_levels":[],
	"published_levels":[],
	"stats":{
		"stars" : 0,
		"builder_points" : 0,
	},
	"icon_kit":{
		"cube": 0,
		"ship":0,
		"ball":0
	},
	"new" : true,
	"version" : str(ProjectSettings.get_setting("application/config/version.release"))
}

func _new_level(id : String, normal_progress : int = 0, practice_progress : int = 0, attempts : int = 0, jumps : int = 0) -> Dictionary:
	return {
		"id" : id,
		"n" : normal_progress,
		"p" : practice_progress,
		"a" : attempts,
		"j" : jumps
	}

func _ready():
	load_save()

func save():
	var save_data = {
		"progress" : _progress
	}
	
	var save_file = FileAccess.open("user://playerdata.save", FileAccess.WRITE)
	var json_string = JSON.stringify(save_data)
	
	save_file.store_string(json_string)

func set_icon(gamemode : int, id : int) -> void:
	match gamemode:
		0 : cube_id = id; _progress["icon_kit"]["cube"] = id;
		1 : ship_id = id; _progress["icon_kit"]["ship"] = id;
		2: ball_id = id; _progress["icon_kit"]["ball"] = id;

func load_save():
	if not FileAccess.file_exists("user://playerdata.save"):
		
		if !(str(ProjectSettings.get_setting("application/config/version.release")) == _progress["version"]):
			_progress["version"] = str(ProjectSettings.get_setting("application/config/version.release"))
			_progress["new"] = true
		
		new = _progress["new"]
		return
	else:
		var save_file : FileAccess = FileAccess.open("user://playerdata.save", FileAccess.READ)
		var json_string : String = save_file.get_line()
		var parsed_data : Dictionary = JSON.parse_string(json_string)
		
		if parsed_data.has("progress"):
			_progress = parsed_data["progress"]
			
			if _progress.has("icons"):
				_progress["icon_kit"] = _progress["icons"]
				_progress.erase("icons")
		
			for item in _progress["icon_kit"]:
				match item:
					"cube" : cube_id = _progress["icon_kit"][item];
					"ship" : ship_id = _progress["icon_kit"][item];
					"ball" : ball_id = _progress["icon_kit"][item];
			
		else:
			return
		

func change_progress(new_progress : Dictionary) -> void:
	var level_id : String = str( new_progress["id"])
	
	if _has_dict_with_value(_progress["levels"], "id",level_id):
		_find_dict_with_value(_progress["levels"], "id",  level_id)["n"] = new_progress["normal"]
		_find_dict_with_value(_progress["levels"], "id",  level_id)["p"] = new_progress["practice"]
	else:
		_progress["levels"].append(_new_level(level_id,new_progress["normal"],new_progress["practice"],0,0))
	
	if new_progress.has("main"):
		_find_dict_with_value(_progress["levels"], "id",  level_id)["main"] = true

func set_attempts(level_id : int, attempts : int) -> void:
	
	if _has_dict_with_value(_progress["levels"], "id",str(level_id)):
		_find_dict_with_value(_progress["levels"], "id", str(level_id))["a"] = attempts
	else:
		_progress["levels"].append(_new_level(str(level_id),0,0,attempts,0))

func get_main_levels_progress() -> Dictionary:
	var main_levels : Dictionary = {}
	for level : Dictionary in _progress["levels"]:
		if level.has("main"):
			main_levels[level["id"]] = _find_dict_with_value(_progress["levels"], "id", level["id"])
	return main_levels

func get_level_progress(id : int) -> Dictionary:
	var level_id : String = str( id)
	
	if _has_dict_with_value(_progress["levels"], "id", level_id):
		return _find_dict_with_value(_progress["levels"], "id", level_id)
	else:
		var level : Dictionary = _new_level(level_id)
		_progress["levels"].append(level)
		return level

func _has_dict_with_value(array : Array, key : String, value: Variant) -> bool:
	for dict : Dictionary in array:
		if dict.has(key):
			if dict[key] == value: return true
	return false

func _find_dict_with_value(array : Array, key : String, value: Variant) -> Dictionary:
	for dict : Dictionary in array:
		if dict.has(key):
			if dict[key] == value: return dict
	return {}

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save()
