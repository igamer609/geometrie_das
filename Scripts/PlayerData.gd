extends Node

@export var cube_id : int = 0
@export var ship_id : int = 0
@export var ball_id : int = 0

var uid : int = 0
var _progress : Dictionary = {
	"levels":[],
	"saved_levels":[],
	"published_levels":[],
	"stats":{
		"stars" : 0,
		"builder_points" : 0,
	},
	"icons":{
		"cube": 0,
		"ship":0,
		"ball":0
	}
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
		0 : cube_id = id; _progress["icons"]["cube"] = id;
		1 : ship_id = id; _progress["icons"]["ship"] = id;
		2: ball_id = id; _progress["icons"]["ball"] = id;

func load_save():
	if not FileAccess.file_exists("user://playerdata.save"):
		return
	else:
		var save_file : FileAccess = FileAccess.open("user://playerdata.save", FileAccess.READ)
		var json_string : String = save_file.get_line()
		var parsed_data : Dictionary = JSON.parse_string(json_string)
		
		if parsed_data.has("progress"):
			_progress = parsed_data["progress"]
		
			for item in _progress["icons"]:
				match item:
					"cube" : cube_id = _progress["icons"][item];
					"ship" : ship_id = _progress["icons"][item];
					"ball" : ball_id = _progress["icons"][item];
		else:
			return
		

func change_progress(new_progress : Dictionary) -> void:
	var level_id : String = str( new_progress["id"])
	
	if _has_dict_with_value(_progress["levels"], "id",level_id):
		_find_dict_with_value(_progress["levels"], "id",  level_id)["n"] = new_progress["normal"]
		_find_dict_with_value(_progress["levels"], "id",  level_id)["p"] = new_progress["practice"]
	else:
		_progress["levels"].append({
			"n" : new_progress["normal"],
			"p" : new_progress["practice"],
			"a" : 0,
			"j" : 0
		})
	
	if new_progress.has("main"):
		_find_dict_with_value(_progress["levels"], "id",  level_id)["main"] = true

func set_attempts(level_id : int, attempts : int) -> void:
	
	if _has_dict_with_value(_progress["levels"], "id",str(level_id)):
		_find_dict_with_value(_progress["levels"], "id", str(level_id))["a"] = attempts
	else:
		_progress["levels"].append({
			"id" : str(level_id),
			"n" : 0,
			"p" : 0,
			"a" : attempts,
			"j" : 0
		})

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
		var level : Dictionary = {
			"id" : level_id,
			"n" : 0,
			"p" : 0,
			"a" : 0
		}
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
