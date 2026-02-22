# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

@onready var lvl_template = preload("res://Scenes/Menus/saved_lvl_template/level_template.tscn")

const PAGE_LENGTH = 10
var page = 0
var levels : Array = []

func find_levels():
	
	ResourceLibrary.load_registry(LevelRegistry.RegistryType.CREATED)
	
	var number_of_levels : int = ResourceLibrary.current_registry.order.size()
	
	print(ResourceLibrary.current_registry)
	
	if number_of_levels > 0:
		for i in range((page * PAGE_LENGTH), min((page + 1) * PAGE_LENGTH - 1, number_of_levels)):
			var current_id : String = ResourceLibrary.current_registry.order[i]
			
			if ResourceLibrary.current_registry.levels.has(current_id):
				var current_lvl : LevelRegistryEntry = ResourceLibrary.current_registry.levels[current_id]
				add_level_template(current_lvl)
		
	
	for level in levels:
		level.visible = true

func add_level_template(level_entry : LevelRegistryEntry):
	var new_lvl = lvl_template.instantiate()
	
	$Main/Scroll/Container.add_child(new_lvl)
	levels.append(new_lvl)
	
	if level_entry.meta.title != "":
		new_lvl.name = str(level_entry.meta.title)
	else:
		new_lvl.name = str(new_lvl.get_instance_id())
	
	new_lvl.name_label.text = level_entry.meta.title
	
	new_lvl.song_label.text = ResourceLibrary.music_ids[int(level_entry.meta.song_id)][1]
	new_lvl.view_button.pressed.connect(EditorTransition.load_level_edit_menu.bind(level_entry))

func _ready():
	find_levels()
	
	$Create.pressed.connect(EditorTransition.load_level_edit_menu.bind(LevelRegistryEntry.new()))

func _on_exit_pressed() -> void:
	TransitionScene.change_scene("res://Scenes/Menus/EditorTab.tscn")
