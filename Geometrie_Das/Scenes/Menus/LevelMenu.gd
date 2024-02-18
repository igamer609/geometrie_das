extends Control

var template_scene = preload("res://Scenes/Menus/level_template.tscn")
var tab = null

var current_level = 0

var tab_info = null
var tab_progress = null
var tab_play = null

var main_levels = {
	"0":
		{
			"Name" : "TestLevel",
			"Scene" : "res://Scenes/Levels/TestLevel.tscn",
			"Difficulty" : "easy",
			"Progress" : 0,
			"Practice" : 0
		},
	"1":
		{
			"Name" : "asasasa",
			"Scene" : "res://Scenes/MainMenu.tscn",
			"Difficulty" : "easy",
			"Progress" : 0,
			"Practice" : 0
		}
}

func _ready():
	tab = template_scene.instantiate()
	add_child(tab)
	
	tab_info = tab.get_child(0)
	tab_progress = tab.get_child(1)
	tab_play = tab.get_child(2)
	
	if GameProgress.progress_to_update:
		update_progress(GameProgress.current_level_progress, GameProgress.current_level_practice, GameProgress.current_level)
		GameProgress.progress_to_update = false
		
		save_data()
	
	load_data()
	
	update_tab(current_level)

func update_progress(progress, practice, level):
	main_levels[str(level)]["Progress"] = round(progress)
	main_levels[str(level)]["Practice"] = round(practice)
	

func update_tab(index_change):
	
	var new_tab_info = null
	
	if (current_level + index_change) < 0:
		new_tab_info = main_levels[str(len(main_levels) - 1)]
		current_level = len(main_levels) - 1
	elif (current_level + index_change) > (len(main_levels) - 1):
		new_tab_info = main_levels[str(0)]
		current_level = 0
	else:
		new_tab_info = main_levels[str(current_level + index_change)]
		current_level += index_change
	
	for child in tab_info.get_children():
		if child.name == "Difficulty":
			child.texture.region = Rect2(["easy", "hard", "insane"].find(new_tab_info["Difficulty"]) * 31, 0, 31, 32)
		elif child.name == "Label":
			child.text = new_tab_info["Name"]
	
	for child in tab_progress.get_children():
		if child.name == "NormalProgress":
			child.value = new_tab_info["Progress"]
		if child.name == "PracticeProgress":
			child.value = new_tab_info["Practice"]
	
	if tab_play.pressed.is_connected(load_level.bind(new_tab_info["Scene"])):
		tab_play.pressed.disconnect(load_level.bind(new_tab_info["Scene"]))
	tab_play.pressed.connect(load_level.bind(new_tab_info["Scene"]))

func _on_back_button_pressed():
	update_tab(-1)

func save():
	var data = {
		
	}
	
	for level in main_levels:
		data[str(level)] = main_levels[str(level)]
	
	return data

func save_data():
	var save_file = FileAccess.open("user://level_data.save", FileAccess.WRITE)
	
	var save_string = JSON.stringify(save())
	
	print(save_string)
	
	save_file.store_line(save_string)

func load_data():
	if not FileAccess.file_exists("user://level_data.save"):
		return
	
	var saved_data = FileAccess.open("user://level_data.save", FileAccess.READ)
	
	var json_string = saved_data.get_line()
	var parsed_data = JSON.parse_string(json_string)
	
	for level in parsed_data:
		main_levels[level] = parsed_data[level]
	
	print(main_levels)

func load_level(scene):
	GameProgress.current_level = current_level
	GameProgress.current_level_progress = main_levels[str(current_level)]["Progress"]
	GameProgress.current_level_practice = main_levels[str(current_level)]["Practice"]
	TransitionScene.change_scene(scene)

func _on_scroll_right():
	update_tab(1)
