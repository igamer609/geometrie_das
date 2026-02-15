# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends CanvasLayer

@onready var editor = "res://Objects/Editor.tscn"
@onready var template_level = "res://Scenes/Levels/CustomLevel.tscn"

func get_editor_root() -> Node:
	var root = get_tree().root
	var editor_root = null
	
	for roots in root.get_children():
		if roots.name == "Editor":
			editor_root = roots
	
	return editor_root

func get_level_root() -> Node:
	var root = get_tree().root
	var level_root = null
	
	for roots in root.get_children():
		if roots.name == "LevelRoot":
			level_root = roots
	
	return level_root

func get_level_edit_menu() -> Node:
	var root = get_tree().root
	var menu_root = null
	
	for node in root.get_children():
		if node.name == "LevelEditMenu":
			menu_root = node
	
	return menu_root

func wait(seconds) -> bool:
	var timer = Timer.new()
	add_child(timer)
	timer.start(seconds)
	
	await timer.timeout
	
	return true

func load_editor(level_info : Dictionary, level_path : String = "") -> void:
	ResourceLibrary.load_registry_to_memory(ResourceLibrary.RegistryType.NONE)
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(editor)
	
	await get_tree().tree_changed
	
	var root = get_editor_root()
	await root.load_level_from_info(level_info, level_path)
	$AnimationPlayer.play_backwards("fade")

func load_game(level_info : Dictionary, restart = false, playtesting = false, return_scene : String = "") -> void:
	ResourceLibrary.load_registry_to_memory(ResourceLibrary.RegistryType.NONE)
	
	if not restart:
		$AnimationPlayer.play("fade")
		await $AnimationPlayer.animation_finished
	
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(template_level)
	
	await get_tree().tree_changed
	
	var root = get_level_root()
	
	root.load_level_data(level_info, restart, playtesting, return_scene)
	
	if not restart:
		$AnimationPlayer.play_backwards("fade")

func load_level_edit_menu(level_info : Dictionary, level_path : String) -> void:
	ResourceLibrary.load_registry_to_memory(ResourceLibrary.RegistryType.CREATED)
	
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	
	ResourceLibrary.free_objects.emit()
	
	get_tree().change_scene_to_file("res://Scenes/Menus/LevelEditingMenu.tscn")
	await get_tree().tree_changed
	
	var root = get_level_edit_menu()
	root.load_level_info(level_info, level_path)
	$AnimationPlayer.play_backwards("fade")
	
	if get_tree().paused:
		get_tree().paused = false
