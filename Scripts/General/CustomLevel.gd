# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node2D

signal loaded_level()

var level_data : LevelData = LevelData.new()

var _playtesting : bool = false
var _return_scene : String
var _loaded_path : String

var _debugging : bool
@export var debug_properties : Control

@export var player_parent : Node
@export var ceiling : Node
@export var ground : Node
@export var level : Node
@export var endpos : Node

@export var pause_ui : Node
@export var end_ui : Node
@export var restart_button : TextureButton
@export var exit_button : TextureButton

@export var end_effects : EndEffects
@export var end_animation : Node

@export var death_particle : Node

var player : CharacterBody2D = null
var player_cam : Camera2D = null

var rect_x = 0

var first_attempt = true
var follow_cam = false
var level_ended = false
var obtain_endpos = true
var _smoothing_delay : int = 1

func _get_endpos() -> void:
	var last_x = 0
	
	for obj in level.get_children():
		
		if obj.global_position.x > last_x:
			last_x = obj.global_position.x
	
	rect_x = last_x
	endpos.global_position.x = last_x + 348

func _get_path_to_level() -> String:
	var file_path : String = ""
	if _playtesting:
		var directory : PackedStringArray = DirAccess.get_files_at("user://created_levels")
		
		for this_level : String  in directory:
			if int(this_level.get_slice(".", 0)) == level_data["info"]["local_id"]:
				file_path = "user://created_levels/" + this_level
	else:
		var directory : PackedStringArray = DirAccess.get_files_at("user://saved_levels")
		
		for this_level : String  in directory:
			if int(this_level.get_slice(".", 0)) == level_data["info"]["id"]:
				file_path = "user://saved_levels/" + this_level
	
	return file_path

func load_level_data(new_level_data : LevelData, restart = false, playtesting = false, level_path : String = "", return_scene = "") -> void:
	level_data = new_level_data
	
	if restart:
		first_attempt = false
		follow_cam = true
	
	if not playtesting:
		GameProgress.current_level_id = level_data.meta.published_id
	
	for obj : LevelObject  in level_data.objects:
		load_object(obj.obj_id, obj.uid, str_to_var(obj.transform[0]), obj.transform[1], obj.other)
	
	GameProgress.music_to_load = level_data.meta.song_id
	ColorManager._end_current_tweens(0)
	ColorManager.load_palette(new_level_data.meta.color_palette)
	
	_playtesting = playtesting
	_loaded_path = level_path
	_return_scene = return_scene
	
	exit_button.pressed.connect(_exit_level)
	restart_button.pressed.connect(_restart)
	
	emit_signal("loaded_level")

func load_object(obj_id : int, uid : int, pos : Vector2, rot : float, other) -> void:
	var object : GDObject = GDObject.create_object(obj_id, uid, pos, rot, other, true)
	level.call_deferred("add_child", object)

func _ready() -> void:
	await initiate()
	
	_debugging = OS.has_feature("editor")
	
	if(_debugging):
		_init_debug_labels()

func initiate() -> void:
	await loaded_level
	$Universal/PauseUI/Control/Rect/LevelName.text = level_data.meta.title
	
	RenderingServer.global_shader_parameter_set("current_editor_layer", -1)
	
	GameProgress.in_game = true
	GameProgress.run_music = true
	
	GameProgress.play_lvl_music_from_id(0)
	
	for child in player_parent.get_children():
		if child.is_in_group("Player"):
			player = child
		if child.name == "Camera2D":
			player_cam = child
	
	if(player):
		player.changed_gamemode.connect(on_gamemode_change)
		player.died.connect(player_died)
		player.respawned.connect(player_respawn)
		
		player.global_position.x = -64
		player.global_position.y = -8
		
		player.change_gamemode(level_data.meta.starting_gamemode + 2, null)
		player.change_gravity(level_data.meta.starting_gravity)
	
	if(player_cam):
		
		player_cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		player_cam.position_smoothing_enabled = false
	
	ground.global_position = Vector2(40, 0)
	
	ColorManager.load_palette(level_data.meta.color_palette)

func player_died() -> void:
	follow_cam = false
	GameProgress.run_music = false
	GameProgress.stop_lvl_music()
	
	ColorManager._end_all_tweens()
	
	death_particle.global_position = player.global_position
	death_particle.emitting = true

func player_respawn() -> void:
	GameProgress.play_lvl_music_from_id(0)
	ColorManager.load_palette(level_data.meta.color_palette)
	
	end_animation.play("RESET")
	player_cam.position_smoothing_enabled = false
	player.velocity = Vector2.ZERO
	
	player.change_gamemode(level_data.meta.starting_gamemode + 2, null)
	player.change_gravity(level_data.meta.starting_gravity)
	
	player.global_position.x = -64
	player.global_position.y = -8
	
	ground.global_position = Vector2(player.global_position.x + 3500, 0)
	
	_smoothing_delay = 1
	follow_cam = true
	
	for object : GDObject in level.get_children():
		if object.trigger:
			object.trigger.call_deferred("set", "enabled", true)

func on_gamemode_change(portal : Area2D, gamemode : int) -> void:
	if portal:
		match gamemode:
			0:  # cube
				ceiling.visible = false
				ground.global_position = Vector2(player.global_position.x + 3500, 0)
				ceiling.global_position = Vector2(player.global_position.x + 3500, 1000)
			1: # ship
				ceiling.visible = true
				
				var ground_pos : Vector2 = Vector2(player.global_position.x + 3500, portal.global_position.y + 88)
				if ground_pos.y > 0:
					ground_pos.y = 0
				
				ground.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
				ceiling.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
				
				ground.global_position = ground_pos
				ceiling.global_position = Vector2(player.global_position.x + 3500, ground.global_position.y - 176)
				
				ground.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
				ceiling.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
				
				player_cam.global_position.y = ground.global_position.y - 88
			2:  # ball
				ceiling.visible = true
				
				ground.global_position = Vector2(player.global_position.x + 3500, portal.global_position.y + 72)
				ceiling.global_position = Vector2(player.global_position.x + 3500, portal.global_position.y - 72)
				
				if ground.global_position.y > 0:
					ground.global_position.y = 0
					ceiling.global_position.y = ground.global_position.y - 144
				
				player_cam.global_position.y = ground.global_position.y - 72
	else:
		match gamemode:
			0:  # cube
				ground.global_position = Vector2(3500, 0)
				ceiling.global_position = Vector2(3500, 1000)
				
				if(first_attempt):
					player_cam.global_position = Vector2(128, -24)
				
			1:  # ship
				ceiling.visible = true
				
				ground.global_position.y = 0
				ceiling.global_position.y = ground.global_position.y - 176
				
				player_cam.global_position = Vector2(32, ground.global_position.y - 88)
			2:  # ball
				ceiling.visible = true
				
				ground.global_position.y = 0
				ceiling.global_position.y = ground.global_position.y - 112
				
				player_cam.global_position = Vector2(32, ground.global_position.y - 56)

func _process(_delta) -> void:
	if obtain_endpos:
		_get_endpos()
		obtain_endpos = false
	
	if first_attempt:
		follow_cam = false
		if player.global_position.x >= player_cam.global_position.x:
			first_attempt = false
			follow_cam = true
	
	if follow_cam:
		GameProgress.run_music = true
		player_cam.global_position.x = player.global_position.x
		
		if(_smoothing_delay > 0):
			_smoothing_delay -= 1
		else:
			player_cam.position_smoothing_enabled = true
		
		match player.gamemode:
			Player.GamemodeTypes.CUBE:
				player_cam.global_position.y = player.global_position.y - 16
			Player.GamemodeTypes.SHIP:
				player_cam.global_position.y = ground.global_position.y - 88
			Player.GamemodeTypes.BALL:
				player_cam.global_position.y = ground.global_position.y - 56
		
		endpos.global_position.y = player_cam.global_position.y
	
	GameProgress.update_bar((player.global_position.x / endpos.global_position.x) * 100)
	
	if Input.is_action_just_pressed("ui_cancel") and not is_finishing():
		get_tree().paused = !get_tree().paused
	
	if is_finishing():
		follow_cam = false
		player.invulnerable = true
		player.gravity = 10
		player.velocity.y = -50
		player.speed += 5
	
	if (player.global_position.x / endpos.global_position.x) * 100 >= 100 and not level_ended:
		level_ended = true
		_end_level()

func is_finishing() -> bool:
	return player.global_position.x >= rect_x + 152

func _exit_level():
	GameProgress.in_game = false
	GameProgress.music_to_load = 0
	GameProgress.stop_lvl_music()
	MenuMusic.start_music()
	
	match _return_scene:
		"res://Scenes/Menus/LevelEditingMenu.tscn":
			SceneTransition.load_level_edit_menu(LevelRegistryEntry.generate_entry(level_data.meta, _loaded_path))
		_:
			SceneTransition.change_scene("res://Scenes/Menus/CreateTab.tscn")

func _end_level():
	if _playtesting:
		_verify_level()
	
	end_effects.sync_to_pos(player.global_position)
	end_effects.activate_end_anim()
	end_animation.play("end_anim")
	
	player_cam.position_smoothing_enabled = false

func _verify_level():
	level_data.meta.verified = 1
	var entry_data = LevelRegistryEntry.generate_entry(level_data.meta, _loaded_path)
	ResourceLibrary.current_registry.update_entry_and_main_file(level_data.meta.local_id, entry_data, true)

func _restart():
	GameProgress.stop_lvl_music()
	get_tree().paused = false
	
	ResourceLibrary.free_objects.emit()
	SceneTransition.load_game_from_data(level_data, true, _playtesting, _loaded_path, _return_scene)

func _init_debug_labels() -> void:
	
	debug_properties.visible = true
	
	if(player):
		for label : DebugPropertyLabel in debug_properties.get_children():
			label.target = player
