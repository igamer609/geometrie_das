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

func load_editor(level_entry: LevelRegistryEntry) -> void:
	ResourceLibrary.load_registry(LevelRegistry.RegistryType.NONE)
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(editor)
	
	await get_tree().tree_changed
	
	var root = get_editor_root()
	var loaded_level : LevelData = load(level_entry.ref)
	await root.load_level_from_info(loaded_level, level_entry.ref)
	$AnimationPlayer.play_backwards("fade")

func load_game_from_entry(level_entry : LevelRegistryEntry) -> void:
	ResourceLibrary.load_registry(LevelRegistry.RegistryType.NONE)
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(template_level)
	
	await get_tree().tree_changed
	
	var root = get_level_root()
	var loaded_level : LevelData = load(level_entry.ref)
	root.load_level_data(loaded_level, level_entry.ref)

func load_game_from_data(level_data : LevelData, restart = false, playtesting = false, level_path : String = "", return_scene : String = "") -> void:
	ResourceLibrary.load_registry(ResourceLibrary.NONE)
	
	if not restart:
		$AnimationPlayer.play("fade")
		await $AnimationPlayer.animation_finished
	
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(template_level)
	
	await get_tree().tree_changed
	
	var root = get_level_root()
	var loaded_level : LevelData = load(level_path)
	root.load_level_data(loaded_level, restart, playtesting, return_scene)
	
	if not restart:
		$AnimationPlayer.play_backwards("fade")

func load_level_edit_menu(level_entry: LevelRegistryEntry) -> void:
	ResourceLibrary.load_registry(LevelRegistry.RegistryType.CREATED)
	
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	
	ResourceLibrary.free_objects.emit()
	
	get_tree().change_scene_to_file("res://Scenes/Menus/LevelEditingMenu.tscn")
	await get_tree().tree_changed
	
	var root = get_level_edit_menu()
	root.load_level_meta(level_entry.meta, level_entry.ref)
	$AnimationPlayer.play_backwards("fade")
	
	if get_tree().paused:
		get_tree().paused = false
