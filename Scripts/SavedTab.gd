extends Control

@onready var lvl_template = preload("res://Scenes/Menus/saved_lvl_template/level_template.tscn")

var levels = []

func find_levels():
	var directory = DirAccess.get_files_at("user://saved_levels")
	
	for level in directory:
		var file_path = "user://saved_levels/" + level
		
		var lvl_file = FileAccess.open(file_path, FileAccess.READ)
		var lvl_info = JSON.parse_string(lvl_file.get_line())
		
		add_level_template(lvl_info)
	
	for level in levels:
		level.visible = true

func add_level_template(level_data):
	var new_lvl = lvl_template.instantiate()
	
	$Main/Scroll/Container.add_child(new_lvl)
	levels.append(new_lvl)
	
	if level_data["info"]["name"] != "":
		new_lvl.name = str(level_data["info"]["name"])
	else:
		new_lvl.name = str(new_lvl.get_instance_id())
	
	new_lvl.name_label.text = level_data["info"]["name"]
	
	if new_lvl.name_label.text == "":
		new_lvl.name_label.text = "Unnamed -"
	
	new_lvl.author_label.text = "by " + level_data["info"]["author"]
	
	if new_lvl.author_label.text == "by ":
		new_lvl.author_label.text = "by -"
	
	new_lvl.song_label.text = GameProgress.music_ids[int(level_data["info"]["song_id"])][1]
	new_lvl.play_button.pressed.connect(EditorTransition.load_game.bind(level_data))
	new_lvl.edit_button.pressed.connect(EditorTransition.load_editor.bind(level_data))

func _ready():
	find_levels()
