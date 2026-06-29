# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name EditorSaveLoad
extends Node

signal exit_level

@export var editor : Node2D
@export var obj_system : Node

@export var level : Node2D

func _ready() -> void:
	editor.load_level_data.connect(load_level_from_data)

func _save_level() -> bool:
	editor.level_meta.verified = 0
	var saved_objects : Array[LevelObject] = _get_data_of_objects(level.get_children())
	
	var save_data = LevelData.new()
	save_data.meta = editor.level_meta
	save_data.objects = saved_objects
	
	if save_data.meta.title.is_empty():
		save_data.meta.title = "Untitled " + save_data.meta.local_id
	
	var error : Error = ResourceSaver.save(save_data, editor.level_path)
	
	if error == Error.OK:
		if ResourceLibrary.current_registry.type != LevelRegistry.RegistryType.CREATED:
			ResourceLibrary.load_registry( LevelRegistry.RegistryType.CREATED)
		
		var entry_data : LevelRegistryEntry = LevelRegistryEntry.generate_entry(save_data.meta, editor.level_path)
		ResourceLibrary.current_registry.updade_entry(save_data.meta.local_id, entry_data, true)
	
	return error

func _get_data_of_objects(objects : Array[Node]) -> Array:
	objects.sort_custom(func(a : Node, b : Node) : return b.global_position.x > a.global_position.x)
	
	if objects.size() > 0:
		var last_object_x = objects.back().global_position.x
		editor.level_meta.length =( last_object_x + 348) / 130
	else:
		editor.level_meta.length = 1
	
	var obj_data : Array[LevelObject] = []
	for obj  in objects:
		if obj.is_in_group("Object"):
			var obj_info : LevelObject = LevelObject.new()

			obj_info.obj_id = obj.obj_res.id
			obj_info.uid = obj.uid
			obj_info.transform = [var_to_str(obj.global_position), obj.global_rotation]
			obj_info.other["group_ids"] = obj.group_ids
			obj_info.other["editor_layer"] = obj.editor_layer
			obj_info.other["channel_id"] = obj.color_channel
			if obj.trigger:
				obj_info.other["trigger"] = obj.trigger.get_info()
			obj_data.append(obj_info)
	return obj_data

func _generate_unique_id() -> int:
	var time : int =int(Time.get_unix_time_from_system())
	var rand : int = randi() % 10000 + 1
	return time * 10000 + rand

func load_level_from_data(level_data : LevelData) ->  void:
	editor.level_meta = level_data.meta
	
	if editor.level_meta.local_id.is_empty():
		editor.level_meta.local_id = str(_generate_unique_id())
	
	if editor.level_meta.title.is_empty():
		editor.level_meta.title = "Untitled " + editor.level_meta.local_id
	
	if(editor.level_meta.color_palette.color_palette.is_empty()):
		editor.level_meta.color_palette = GDColorPalette.default_palette(ColorManager.max_channels)
	
	ColorManager.load_palette(editor.level_meta.color_palette)

func _save_and_exit():
	_save_level()
	
	MenuMusic.start_music()
	
	exit_level.emit()
	
	SceneTransition.load_level_edit_menu(LevelRegistryEntry.generate_entry(editor.level_meta,editor. level_path))

func _save_and_play():
	_save_level()
	
	exit_level.emit()
	SceneTransition.load_game_from_entry(LevelRegistryEntry.generate_entry(editor.level_meta, editor.level_path), true, "res://Scenes/Menus/LevelEditingMenu.tscn")

func _exit():
	var dialog = $Editor_Object/Menu_Layer/EditorMenu/ExitDialog
	dialog.visible = true
	await dialog.confirmed
	MenuMusic.start_music()
	
	var lvl_res : LevelData = load(editor.level_path) as LevelData
	
	exit_level.emit()
	SceneTransition.load_level_edit_menu(LevelRegistryEntry.generate_entry(editor.level_meta,editor. level_path))
