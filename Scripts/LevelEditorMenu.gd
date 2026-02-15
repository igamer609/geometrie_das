# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

const path_to_self : String = "res://Scenes/Menus/LevelEditingMenu.tscn"
const level_lengths : Array[String] = ["Tiny", "Short", "Medium", "Long", "XL"]

#============ Controls ===============#
@onready var title_box : LineEdit = $Container/Title
@onready var description_box = $Container/Descirption

@onready var exit_button = $Exit
@onready var edit_button = $Container/Edit
@onready var play_button = $Container/Play
@onready var publish_button = $Container/Publish
@onready var delete_button = $Delete

@onready var length_label = $Container/Length
@onready var song_label = $Container/Song
@onready var status_label = $Container/Status

#=========Default level data=========#
#can also be replaced by custom RefCounted implementation to allow for easier management
var default_level_info : Dictionary = {
		"local_id": _generate_unique_id(),
		 "title" : "",
		 "author" : "", 
		"description" : "",
		"difficulty" : 0, 
		"version" : (str(ProjectSettings.get_setting("application/config/version.release"))), 
		"song_id" : 1, 
		"last_uid" : 0, 
		"song_offset" : 0,
		 "verified" : 0,
		 "published_id" : -1,
		"bg_color" : Color("0045e1"),
		"original_id" : -1,
		"length" :  0,
}

var level_info : Dictionary

var _is_verified : bool = false

var text_box_limit = ["$", "#", "@", "!", "%", "^", "&", "*", "(", ")", "'", '"']

var load_path : String = ""

func _generate_unique_id() -> int:
	var time : int = Time.get_unix_time_from_system()
	var rand : int = randi() % 10000 + 1
	return time * 10000 + rand

func _ready() -> void:
	level_info = default_level_info.duplicate(true)
	exit_button.pressed.connect(_exit)
	edit_button.pressed.connect(_load_editor)
	play_button.pressed.connect(_play_level)
	delete_button.pressed.connect(_delete_level)
	title_box.text_changed.connect(_change_level_title)
	description_box.text_changed.connect(_change_level_description)

func load_level_info(loaded_level_info : Dictionary, level_path : String) -> void:
	level_info = default_level_info.duplicate(true)
	level_info.merge(loaded_level_info, true)
	load_path = level_path
	
	if level_info.has("name"):
		level_info["title"] = level_info["name"]
		level_info.erase("name")
	
	if level_info.has("version"):
		level_info["game_version"] = level_info["version"]
	
	if not level_info.has("description"):
		level_info["description"] = ""
	
	level_info["author"] = PlayerData.get_player_name()
	
	level_info["local_id"] = int(level_info["local_id"])
	level_info["published_id"] = int(level_info["published_id"])
	
	if level_info.has("song_id"):
		level_info["song_id"] = int(level_info["song_id"])
		var song_id : int = level_info["song_id"]
		song_label.text = ResourceLibrary.music_ids[song_id][1]
	
	if level_info.has("verified"):
		level_info["verified"] = int(level_info["verified"])
		if level_info["verified"] == 1:
			_is_verified = true
			status_label.text = "Verified"
	
	if not level_info.has("length"):
		level_info["length"] = 0
	
	_update_length_label(level_info["length"])
	
	title_box.text = level_info["title"]
	description_box.text = level_info["description"]

func _exit() -> void:
	if not load_path.is_empty():
		var entry_data : Dictionary = ResourceLibrary.entry_data_from_info(level_info, load_path)
		ResourceLibrary.update_entry_and_main_file(str(level_info["local_id"]), entry_data, true)
	TransitionScene.change_scene("res://Scenes/Menus/CreateTab.tscn")

func _load_level_from_file(path : String) -> Dictionary:
	var save_file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	var result : Dictionary = JSON.parse_string(save_file.get_line())
	
	return result

func _load_editor() -> void:
	if level_info["title"] == "":
		level_info["title"] = "Untitled " + str(int( level_info["local_id"]))
	
	if load_path.is_empty():
		var path : String = _create_level()
		EditorTransition.load_editor(level_info, path)
		return
	
	var object_data : Array = _load_level_from_file(load_path)["objects"]
	var level_data : Dictionary = {"info" : level_info, "objects": object_data}
	EditorTransition.load_editor(level_data, load_path)

func _play_level() -> void:
	if level_info["title"] == "":
		level_info["title"] = "Untitled " + str(int( level_info["local_id"]))
	
	if load_path.is_empty():
		var path : String = _create_level()
		EditorTransition.load_game(level_info, false, true)
	
	var object_data : Array = _load_level_from_file(load_path)["objects"]
	var level_data : Dictionary = {"info" : level_info, "objects": object_data}
	EditorTransition.load_game(level_data, false, true, path_to_self)

func _create_level() -> String:
	
	if not DirAccess.dir_exists_absolute("user://created_levels/"):
		DirAccess.make_dir_absolute("user://created_levels/")
	
	if not level_info.has("local_id"):
		level_info["local_id"] = _generate_unique_id()
	
	var path : String = "user://created_levels/" + str(int( level_info["local_id"])) + ".gdaslvl"
	var level_data : Dictionary = {
		"info" : level_info,
		"objects" : []
	}

	var save_file : FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	var save_string : String = JSON.stringify(level_data)
	var success : bool = save_file.store_line(save_string)
	
	if success:
		load_path = path
		var entry_data : Dictionary = ResourceLibrary.entry_data_from_info(level_info, path)
		ResourceLibrary.create_entry(str(int( level_info["local_id"])), entry_data)
		level_info = level_data
		return path
	else:
		level_info = level_data
		return ""

func _delete_level() -> void:
	if load_path:
		load_path = ""
		ResourceLibrary.delete_level(str(level_info["local_id"]))
	_exit()

func _update_length_label(length : int) -> void:
	
	if length in range(1, 9):
		length_label.text = level_lengths[0]
	elif length in range(9, 30):
		length_label.text = level_lengths[1]
	elif  length in range(30, 60):
		length_label.text = level_lengths[2]
	elif  length in range(60, 120):
		length_label.text = level_lengths[3]
	elif length > 120:
		length_label.text = level_lengths[4]
	
	
func _check_text(text : String) -> String:
	var text_array = []
		
	for letter in text:
		text_array.append(letter)
	
	for letter in text_array:
		if letter in text_box_limit:
			text_array.erase(letter)
	
	var checked_text = ""
	
	for letter in text_array:
		checked_text += letter
	
	return checked_text

func _change_level_title(title : String) -> void:
	var checked_title = _check_text(title)
	
	level_info["title"] = checked_title
	
	if title_box.text != checked_title:
		title_box.text = checked_title
		title_box.caret_column = len(checked_title)

func _change_level_description(description : String) -> void:
	var checked_description = _check_text(description)
	
	level_info["description"] = checked_description
	
	if description_box.text != checked_description:
		description_box.text = checked_description
		description_box.caret_column = len(checked_description)
