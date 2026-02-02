# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------
extends Control

#============Defining create nodes===============#
@onready var name_box = $LevelDisplay/Create/Title
@onready var author_box = $LevelDisplay/Create/Author
#==Difficulty==#
@onready var difficulty_radio = $LevelDisplay/Create/DifficultyRadio
@onready var difficulty_rect = $LevelDisplay/Create/Difficulty
#===Create level button===#
@onready var edit_button = $LevelDisplay/Create/Edit

#============Defining Load nodes===============#
@onready var name_label = $LevelDisplay/Load/Title
@onready var author_label = $LevelDisplay/Load/Author
@onready var music_label = $LevelDisplay/Load/MusicLabel
#==Difficulty==#
@onready var load_difficulty_rect = $LevelDisplay/Load/Difficulty
#===Load level button===#
@onready var load_play_button = $LevelDisplay/Load/Play
@onready var load_edit_button = $LevelDisplay/Load/Edit

#=========Default level data=========#
var default_level_data = {
	"info" : {
		"local_id": generate_unique_id(),
		 "name" : "",
		 "author" : "", 
		"difficulty" : 0, 
		"version" : (str(ProjectSettings.get_setting("application/config/version.release"))), 
		"song_id" : 1, 
		"last_uid" : 0, 
		"song_offset" : 0,
		 "verified" : 0,
		 "published_id" : -1,
		"bg_color" : Color("0045e1")
		},
	"objects" : []
}

var level_data ={
	"info" : {
		"local_id": generate_unique_id(),
		 "name" : "",
		 "author" : "", 
		"difficulty" : 0, 
		"version" : (str(ProjectSettings.get_setting("application/config/version.release"))), 
		"song_id" : 1, 
		"last_uid" : 0, 
		"song_offset" : 0,
		 "verified" : 0,
		 "published_id" : -1,
		"bg_color" : Color("0045e1")
		},
	"objects" : []
}
var text_box_limit = ["$", "#", "@", "!", "%", "^", "&", "*", "(", ")", "'", '"']

func generate_unique_id() -> int:
	var time : int = Time.get_unix_time_from_system()
	var rand : int = randi() % 10000 + 1
	return time * 10000 + rand

func _ready():
	setup_difficulty_buttons()
	setup_text_boxes()
	setup_tab_buttons()
	
	edit_button.pressed.connect(create_level)

func setup_difficulty_buttons():
	var group = ButtonGroup.new()
	for button in difficulty_radio.get_children():
		button.button_group = group
		if button.name == "0":
			button.button_pressed = true
	
	group.pressed.connect(change_level_difficulty)

func change_level_difficulty(button):
	var difficulty_id = int(str(button.name))
	
	level_data["info"]["difficulty"] = difficulty_id
	difficulty_rect.texture.region = Rect2(Vector2(difficulty_id * 31, 0), Vector2(31, 32))

func check_text(text):
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

func setup_text_boxes():
	name_box.text_changed.connect(change_level_name)
	author_box.text_changed.connect(change_level_author)

func change_level_name(lvl_name):
	if lvl_name:
		var checked_name = check_text(lvl_name)
		
		level_data["info"]["name"] = checked_name
		
		if name_box.text != checked_name:
			name_box.text = checked_name
			name_box.caret_column = len(checked_name)

func change_level_author(author):
	if author:
		var checked_author = check_text(author)
		
		level_data["info"]["author"] = checked_author
		
		if author_box.text != checked_author:
			author_box.text = checked_author
			author_box.caret_column = len(checked_author)

func create_level():
	if level_data["info"]["name"] == "":
		level_data["info"]["name"] = "Untitled " + str(level_data["info"]["local_id"])
	if level_data["info"]["author"] == "":
		level_data["info"]["author"] = "Player"
	
	EditorTransition.load_editor(level_data)

func reset_create_tab():
	level_data = default_level_data
	
	name_box.text = ""
	author_box.text = ""
	setup_difficulty_buttons()
	change_level_difficulty(difficulty_radio.get_child(0))
	
	$LevelDisplay/Unloaded.visible = false
	$LevelDisplay/Load.visible = false
	$LevelDisplay/Create.visible = true

func setup_tab_buttons():
	for button in $TabContainer.get_children():
		if button.name == "Create":
			button.pressed.connect(TransitionScene.change_scene.bind("res://Scenes/Menus/CreateTab.tscn"))
		if button.name == "Load":
			button.pressed.connect(load_level_from_file)
		if button.name == "Saved":
			button.pressed.connect(TransitionScene.change_scene.bind("res://Scenes/Menus/CreateTab.tscn"))

func load_level_from_file():
	
	var file_dialogue = FileDialog.new()
	file_dialogue.access = FileDialog.ACCESS_FILESYSTEM
	file_dialogue.current_path = "user://"
	file_dialogue.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialogue.show_hidden_files = true
	file_dialogue.title = "Select level file "
	file_dialogue.add_filter("*.gdaslvl", "Geometrie Das Levels")
	
	add_child(file_dialogue)
	file_dialogue.popup_centered(Vector2i(700, 500))
	
	await file_dialogue.file_selected
	
	var file_path = file_dialogue.current_path
	get_tree().queue_delete(file_dialogue)
	
	var lvl_file = FileAccess.open(file_path, FileAccess.READ)
	var lvl_info = JSON.parse_string(lvl_file.get_line())
	
	var verified_data = verify_data(lvl_info)
	
	if verified_data == 0:
		level_data = lvl_info
		
		reset_load_tab()
	elif verified_data == 2:
		var dialog = AcceptDialog.new()
		dialog.title = "Level version is newer"
		dialog.dialog_text = "Update Geometrie Das to load this level. Modifying the level file can result in corruption and crashes!"
		dialog.dialog_autowrap = true
		dialog.size = Vector2i(580, 250)
		
		add_child(dialog)
		dialog.popup_centered()
	elif verified_data == 1:
		var dialog = AcceptDialog.new()
		dialog.title = "Error reading file"
		dialog.dialog_text = "The level file is corrupted or has been tampered with."
		dialog.dialog_autowrap = true
		dialog.size = Vector2i(580, 250)
		
		add_child(dialog)
		dialog.popup_centered()

func verify_data(data):
	if data.has("info") and data.has("objects"):
		
		if data["info"]["version"] <= float(ProjectSettings.get_setting("application/config/version.release")):
			return 0
		else:
			return 2
	else:
		return 1

func reset_load_tab():
	name_label.text = level_data["info"]["name"]
	author_label.text = "by " + level_data["info"]["author"]
	
	load_difficulty_rect.texture.region = Rect2(Vector2(level_data["info"]["difficulty"] * 31, 0), Vector2(31, 32))
	
	music_label.text = GameProgress.music_ids[int(level_data["info"]["song_id"])][1]
	
	$LevelDisplay/Unloaded.visible = false
	$LevelDisplay/Create.visible = false
	$LevelDisplay/Load.visible = true
	
	if load_play_button.is_connected("pressed", EditorTransition.load_game.bind(level_data)) and load_edit_button.is_connected("pressed", EditorTransition.load_editor.bind(level_data)):
		load_play_button.pressed.disconnect(EditorTransition.load_game.bind(level_data))
		load_edit_button.pressed.disconnect(EditorTransition.load_editor.bind(level_data))
	
	load_play_button.pressed.connect(EditorTransition.load_game.bind(level_data))
	load_edit_button.pressed.connect(EditorTransition.load_editor.bind(level_data))
	

func _on_exit_pressed():
	TransitionScene.change_scene("res://Scenes/MainMenu.tscn")
