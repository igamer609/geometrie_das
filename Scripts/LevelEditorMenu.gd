# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
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

var level : LevelRegistryEntry

var _is_verified : bool = false

var text_box_limit = ["$", "#", "@", "!", "%", "^", "&", "*", "(", ")", "'", '"']

var load_path : String = ""

func _generate_unique_id() -> int:
	var time : int = Time.get_unix_time_from_system()
	var rand : int = randi() % 10000 + 1
	return time * 10000 + rand

func _init() -> void:
	level = LevelRegistryEntry.new()

func _ready() -> void:
	exit_button.pressed.connect(_exit)
	edit_button.pressed.connect(_load_editor)
	play_button.pressed.connect(_play_level)
	delete_button.pressed.connect(_delete_level)
	title_box.text_changed.connect(_change_level_title)
	description_box.text_changed.connect(_change_level_description)

func load_level(loaded_level : LevelRegistryEntry) -> void:
	level = loaded_level
	
	level.meta.author = PlayerData.get_player_name()
	
	song_label.text = ResourceLibrary.music_ids[level.meta.song_id][1]
	
	if level.meta.verified == 1:
		_is_verified = true
		status_label.text = "Verified"
	
	_update_length_label(level.meta.length)
	
	title_box.text = level.meta.title
	description_box.text = level.meta.description

func _exit() -> void:
	if not level.ref.is_empty():
		ResourceLibrary.current_registry.update_entry_and_main_file(level.meta.local_id, level, true)
	TransitionScene.change_scene("res://Scenes/Menus/CreateTab.tscn")

func _load_level_from_file(path : String) -> Dictionary:
	var save_file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	var result : Dictionary = JSON.parse_string(save_file.get_line())
	
	return result

func _load_editor() -> void:
	if level.meta.title == "":
		level.meta.title = "Untitled " + level.meta.local_id
	
	if load_path.is_empty():
		_create_level()
		EditorTransition.load_editor(level)
		return
	
	EditorTransition.load_editor(level)

func _play_level() -> void:
	if level.meta.title == "":
		level.meta.title = "Untitled " +  level.meta.local_id
	
	if level.ref.is_empty():
		_create_level()
		EditorTransition.load_game_from_entry(level, true, path_to_self)
	
	EditorTransition.load_game_from_entry(level, true, path_to_self)

func _create_level() -> void:
	
	if not DirAccess.dir_exists_absolute("user://created_levels/"):
		DirAccess.make_dir_absolute("user://created_levels/")
	
	level.meta.local_id = str(_generate_unique_id())
	
	var path : String = "user://created_levels/" +  level.meta.local_id + ".gdaslvl"
	var level_data : LevelData = LevelData.from_dict({
		"meta" : level,
		"objects" : []
	})

	var error : Error = ResourceSaver.save(level_data, path, ResourceSaver.FLAG_COMPRESS)
	
	if error == OK:
		var entry_data : LevelRegistryEntry = LevelRegistryEntry.generate_entry(level_data.meta, path)
		ResourceLibrary.current_registry.create_entry(level.meta.local_id, entry_data)
		level.ref = path
	else:
		error_string(error)
		level.ref = path

func _delete_level() -> void:
	if level.ref:
		level.ref = ""
		ResourceLibrary.current_registry.delete_level(level.meta.local_id)
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
	
	level.meta.title = checked_title
	
	if title_box.text != checked_title:
		title_box.text = checked_title
		title_box.caret_column = len(checked_title)

func _change_level_description(description : String) -> void:
	var checked_description = _check_text(description)
	
	level.meta.description = checked_description
	
	if description_box.text != checked_description:
		description_box.text = checked_description
		description_box.caret_column = len(checked_description)
