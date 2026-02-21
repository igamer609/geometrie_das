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

var level_meta : LevelMeta

var _is_verified : bool = false

var text_box_limit = ["$", "#", "@", "!", "%", "^", "&", "*", "(", ")", "'", '"']

var load_path : String = ""

func _generate_unique_id() -> int:
	var time : int = Time.get_unix_time_from_system()
	var rand : int = randi() % 10000 + 1
	return time * 10000 + rand

func _ready() -> void:
	exit_button.pressed.connect(_exit)
	edit_button.pressed.connect(_load_editor)
	play_button.pressed.connect(_play_level)
	delete_button.pressed.connect(_delete_level)
	title_box.text_changed.connect(_change_level_title)
	description_box.text_changed.connect(_change_level_description)

func load_level_meta(loaded_level_meta : LevelMeta, level_path : String) -> void:
	level_meta = loaded_level_meta
	load_path = level_path
	
	if level_meta.has("name"):
		level_meta.title = level_meta.name
		level_meta.erase("name")
	
	if not level_meta.has("description"):
		level_meta.description = ""
	
	level_meta.author = PlayerData.get_player_name()
	
	if level_meta.has("song_id"):
		song_label.text = ResourceLibrary.music_ids[level_meta.song_id][1]
	
	if level_meta.has("verified"):
		if level_meta.verified == 1:
			_is_verified = true
			status_label.text = "Verified"
	
	if not level_meta.has("length"):
		level_meta.length = 0
	
	_update_length_label(level_meta.length)
	
	title_box.text = level_meta.title
	description_box.text = level_meta.description

func _exit() -> void:
	if not load_path.is_empty():
		var entry_data : Dictionary = ResourceLibrary.entry_data_from_info(level_meta, load_path)
		ResourceLibrary.update_entry_and_main_file(str(level_meta.local_id), entry_data, true)
	TransitionScene.change_scene("res://Scenes/Menus/CreateTab.tscn")

func _load_level_from_file(path : String) -> Dictionary:
	var save_file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	var result : Dictionary = JSON.parse_string(save_file.get_line())
	
	return result

func _load_editor() -> void:
	if level_meta.title == "":
		level_meta.title = "Untitled " + str(int( level_meta.local_id))
	
	if load_path.is_empty():
		var path : String = _create_level()
		EditorTransition.load_editor(level_meta, path)
		return
	
	var object_data : Array = _load_level_from_file(load_path)["objects"]
	var level_data : Dictionary = {"info" : level_meta, "objects": object_data}
	EditorTransition.load_editor(level_data, load_path)

func _play_level() -> void:
	if level_meta.title == "":
		level_meta.title = "Untitled " + str(int( level_meta.local_id))
	
	if load_path.is_empty():
		var path : String = _create_level()
		EditorTransition.load_game(level_meta, false, true)
	
	var object_data : Array = _load_level_from_file(load_path)["objects"]
	var level_data : Dictionary = {"info" : level_meta, "objects": object_data}
	EditorTransition.load_game(level_data, false, true, path_to_self)

func _create_level() -> String:
	
	if not DirAccess.dir_exists_absolute("user://created_levels/"):
		DirAccess.make_dir_absolute("user://created_levels/")
	
	if not level_meta.has("local_id"):
		level_meta.local_id = str(_generate_unique_id())
	
	var path : String = "user://created_levels/" + str(int( level_meta.local_id)) + ".gdaslvl"
	var level_data : LevelData = LevelData.from_dict({
		"meta" : level_meta,
		"objects" : []
	})

	var save_file : FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	var save_string : String = JSON.stringify(level_data)
	var success : bool = save_file.store_line(save_string)
	
	if success:
		load_path = path
		var entry_data : LevelRegistryEntry = LevelRegistryEntry.generate_entry(level_meta, path)
		ResourceLibrary.current_registry.create_entry(level_meta.local_id, entry_data)
		level_meta = level_data.meta
		return path
	else:
		level_meta = level_data.meta
		return ""

func _delete_level() -> void:
	if load_path:
		load_path = ""
		ResourceLibrary.delete_level(str(level_meta.local_id))
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
	
	level_meta.title = checked_title
	
	if title_box.text != checked_title:
		title_box.text = checked_title
		title_box.caret_column = len(checked_title)

func _change_level_description(description : String) -> void:
	var checked_description = _check_text(description)
	
	level_meta.description = checked_description
	
	if description_box.text != checked_description:
		description_box.text = checked_description
		description_box.caret_column = len(checked_description)
