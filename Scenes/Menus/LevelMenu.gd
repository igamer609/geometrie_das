extends Control

var template_scene = preload("res://Scenes/Menus/level_template.tscn")
var tab = null

var current_level = 1

var tab_info = null
var tab_progress = null
var tab_play = null

var main_levels = {
	"1":
		{
			"Name" : "Glorious Morning",
			"Scene" : "res://Scenes/Levels/GloriousMorning.tscn",
			"ID" : 1,
			"MusicID" : 1,
			"MusicOffset" : 0.5,
			"Difficulty" : "easy",
			"Progress" : 0,
			"Practice" : 0
		},
	"2":
		{
			"Name" : "yStep",
			"Scene" : "res://Scenes/Levels/yStep.tscn",
			"ID" : 2,
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
	
	load_data()
	update_tab(0)

func update_progress(normal : int, practice : int, level_id : int):
	main_levels[str(level_id)]["Progress"] = round(normal)
	main_levels[str(level_id)]["Practice"] = round(practice)

func update_tab(index_change):
	
	var new_tab_info = null
	
	if (current_level + index_change) < 1:
		new_tab_info = main_levels[str(len(main_levels))]
		current_level = len(main_levels)
	elif (current_level + index_change) > (len(main_levels)):
		new_tab_info = main_levels["1"]
		current_level = 1
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
	
	if tab_play.pressed.is_connected(load_level.bind(new_tab_info["Scene"], new_tab_info["ID"], new_tab_info["MusicID"])):
		tab_play.pressed.disconnect(load_level.bind(new_tab_info["Scene"], new_tab_info["ID"], new_tab_info["MusicID"]))
	tab_play.pressed.connect(load_level.bind(new_tab_info["Scene"], new_tab_info["ID"], new_tab_info["MusicID"]))

func _on_back_button_pressed():
	update_tab(-1)

func load_data() -> void:
	var progress : Dictionary = PlayerData.get_main_levels_progress()
	for level in progress:
		main_levels[level]["Progress"] = progress[level]["n"]
		main_levels[level]["Practice"] =progress[level]["p"]

func load_level(scene_path : String, id : int, song_id : int) -> void:
	GameProgress.enter_level({"id" = main_levels[str(id)]["ID"], "song_id" = main_levels[str(song_id)]["MusicID"]})
	GameProgress.run_music = false
	
	MenuMusic.stop_music()
	
	GameProgress.music_offset = main_levels[str(current_level)]["MusicOffset"]
	GameProgress.music_to_load =  main_levels[str(current_level)]["MusicID"]
	TransitionScene.change_scene(scene_path)

func _on_scroll_right():
	update_tab(1)

func exit():
	TransitionScene.change_scene("res://Scenes/MainMenu.tscn")
	GameProgress.quit_menu()
