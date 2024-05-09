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
			"Name" : "Glorious Morning",
			"Scene" : "res://Scenes/Levels/GloriousMorning.tscn",
			"MusicID" : 1,
			"MusicOffset" : 0.5,
			"Difficulty" : "easy",
			"Progress" : 0,
			"Practice" : 0
		},
	"1":
		{
			"Name" : "yStep",
			"Scene" : "res://Scenes/Levels/yStep.tscn",
			"MusicID" : 2,
			"MusicOffset" : 1,
			"Difficulty" : "hard",
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
		load_data()
		
		update_progress(GameProgress.current_level_progress, GameProgress.current_level_practice, GameProgress.current_level)
		GameProgress.progress_to_update = false
		
		save_data()
	
	load_data()
	
	update_tab(GameProgress.current_level)
	
	print("hey")

func update_progress(progress, practice, level):
	main_levels[str(level)]["Progress"] = round(progress)
	main_levels[str(level)]["Practice"] = round(practice)
	

func update_tab(index_change):
	
	print("help!")
	
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
		print(level)
		data[level] = main_levels[level]
	
	print(data)
	return data

func save_data():
	var save_file = FileAccess.open("user://level_data.save", FileAccess.WRITE)
	
	var save_string = JSON.stringify(save())
	
	save_file.store_line(save_string)

func load_data():
	if not FileAccess.file_exists("user://level_data.save"):
		return
	
	var saved_data = FileAccess.open("user://level_data.save", FileAccess.READ)
	
	var json_string = saved_data.get_line()
	var parsed_data = JSON.parse_string(json_string)
	
	for level in parsed_data:
		print(level)
		main_levels[level]["Progress"] = parsed_data[level]["Progress"]
		main_levels[level]["Practice"] = parsed_data[level]["Practice"]

func load_level(scene):
	GameProgress.current_level = current_level
	GameProgress.current_level_progress = main_levels[str(current_level)]["Progress"]
	GameProgress.current_level_practice = main_levels[str(current_level)]["Practice"]
	GameProgress.run_music = false
	
	MenuMusic.stop_music()
	
	GameProgress.music_offset = main_levels[str(current_level)]["MusicOffset"]
	GameProgress.music_to_load =  main_levels[str(current_level)]["MusicID"]
	TransitionScene.change_scene(scene)

func _on_scroll_right():
	update_tab(1)


func exit():
	TransitionScene.change_scene("res://Scenes/MainMenu.tscn")
	GameProgress.current_level = 0
