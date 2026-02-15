# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

@onready var lvl_template = preload("res://Scenes/Menus/saved_lvl_template/level_template.tscn")

const PAGE_LENGTH = 10
var page = 0
var levels = []

func find_levels():
	
	ResourceLibrary.load_registry_to_memory(ResourceLibrary.RegistryType.CREATED)
	
	var number_of_levels : int = ResourceLibrary.current_registry["order"].size()
	
	if number_of_levels > 0:
		for i in range((page * PAGE_LENGTH), min((page + 1) * PAGE_LENGTH - 1, number_of_levels)):
			var current_id : String = ResourceLibrary.current_registry["order"][i]
			
			if ResourceLibrary.current_registry["levels"].has(current_id):
				var current_lvl : Dictionary = ResourceLibrary.current_registry["levels"][current_id]
				add_level_template(current_lvl["info"], current_lvl["ref"])
		
	
	for level in levels:
		level.visible = true

func add_level_template(level_info : Dictionary, path : String):
	var new_lvl = lvl_template.instantiate()
	
	$Main/Scroll/Container.add_child(new_lvl)
	levels.append(new_lvl)
	
	if level_info.has("name"):
		level_info["title"] = level_info["name"]
		level_info.erase("name")
	
	if level_info["title"] != "":
		new_lvl.name = str(level_info["title"])
	else:
		new_lvl.name = str(new_lvl.get_instance_id())
	
	new_lvl.name_label.text = level_info["title"]
	
	if new_lvl.name_label.text == "":
		new_lvl.name_label.text = "Unnamed -"
	
	new_lvl.author_label.text = "by " + level_info["author"]
	
	if new_lvl.author_label.text == "by ":
		new_lvl.author_label.text = "by -"
	
	new_lvl.song_label.text = ResourceLibrary.music_ids[int(level_info["song_id"])][1]
	new_lvl.view_button.pressed.connect(EditorTransition.load_level_edit_menu.bind(level_info, path))

func _ready():
	find_levels()
	
	$Create.pressed.connect(EditorTransition.load_level_edit_menu.bind({}, ""))

func _on_exit_pressed() -> void:
	TransitionScene.change_scene("res://Scenes/Menus/EditorTab.tscn")
