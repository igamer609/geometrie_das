extends Node2D

signal loaded_level()

var level_data = {
	"info" : {
		"name" : "Untitled",
		"author" : "-",
		"difficulty" : 0,
		"version" : 1.1,
		"song_id" : 1,
		"bg_color" : Color("0045e1")
		},
	"objects" : []
}

@onready var obj_base = preload("res://Objects/object.tscn")

@export var start_bg : Color

@export var player_parent : Node
@export var ceiling : Node
@export var ground : Node
@export var level : Node
@export var endpos : Node

@export var pause_ui : Node
@export var end_ui : Node

@export var end_particles : Node
@export var end_animation : Node

@export var death_particle : Node

var player : CharacterBody2D = null
var player_cam : Camera2D = null

var rect_x = 0

var first_attempt = true
var follow_cam = false
var level_ended = false
var obtain_endpos = true

func get_endpos():
	var last_x = 0
	
	for obj in level.get_children():
		
		if obj.global_position.x > last_x:
			last_x = obj.global_position.x
	
	rect_x = last_x
	endpos.global_position.x = last_x + 348
	
	print(endpos.global_position.x)

func load_level_data(level_info, restart = false):
	level_data = level_info
	
	if restart:
		first_attempt = false
	
	if level_data.has("info"):
		if level_data.has("objects"):
			for obj in level_data["objects"]:
				load_object(obj["obj_id"], obj["uid"], str_to_var(obj["transform"][0]), obj["transform"][1], obj["other"])
		if level_data["info"].has("song_id"):
			GameProgress.music_to_load = level_data["info"]["song_id"]
		if level_data.has("bg_color"):
			start_bg = level_data["info"]["bg_color"]
	
	emit_signal("loaded_level")

func load_object(obj_id, uid, pos, rot, other):
	var item = load("res://Objects/obj_ids/" + str(int(obj_id)) + ".tres")
	
	var object = obj_base.instantiate()
	object.obj_res = item
	
	object.in_level = true
	
	object.global_position = Vector2(pos.x + 8, pos.y)
	object.global_rotation = rot
	
	level.call_deferred("add_child", object)

func _ready():
	initiate()


func initiate():
	await loaded_level
	$Universal/PauseUI/Control/Rect/LevelName.text = level_data["info"]["name"]
	
	GameProgress.in_game = true
	GameProgress.run_music = true
	
	GameProgress.play_lvl_music_from_id(0)
	
	for child in player_parent.get_children():
		if child.is_in_group("Player"):
			player = child
		if child.name == "Camera2D":
			player_cam = child
	
	if player:
		player.changed_gamemode.connect(on_gamemode_change)
		player.died.connect(player_died)
		player.respawned.connect(player_respawn)
		
		player_cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	
	ground.global_position = Vector2(40, 0)
	
	if player_cam and first_attempt:
		player_cam.global_position.x = player.global_position.x + 200
		player_cam.global_position.y = player.global_position.y - 16
	elif player_cam:
		follow_cam = true
	
	change_background(start_bg, 0)

	for trigger in $BG_triggers.get_children():
		trigger.bg_change.connect(change_background)

func player_died():
	follow_cam = false
	GameProgress.run_music = false
	
	GameProgress.stop_lvl_music()
	
	death_particle.global_position = player.global_position
	death_particle.emitting = true

func player_respawn():
	end_bg_tweens()
	
	GameProgress.play_lvl_music_from_id(0)
	
	change_background(start_bg, 0)
	
	end_animation.play("RESET")
	player_cam.position_smoothing_enabled = false
	player.velocity = Vector2.ZERO
	player.gravity = player.CUBE_GRAVITY
	
	player.global_position.x = 0
	player.global_position.y = -12
	
	ground.global_position = Vector2(player.global_position.x + 3500, 0)
	
	player_cam.global_position = Vector2(player.global_position.x, player.global_position.y - 16)
	
	follow_cam = true

func on_gamemode_change(portal, gamemode):
	
	if portal:
		if gamemode in ["cube"]:
			ceiling.visible = false
			
			ground.global_position = Vector2(player.global_position.x + 3500, 0)
			ceiling.global_position = Vector2(player.global_position.x + 3500, 1000)
		elif gamemode in ["ship"]:
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
		elif gamemode in ["ball"]:
			ceiling.visible = true
			
			ground.global_position = Vector2(player.global_position.x + 3500, portal.global_position.y + 72)
			ceiling.global_position = Vector2(player.global_position.x + 3500, portal.global_position.y - 72)
			
			
			if ground.global_position.y > 0:
				ground.global_position.y = 0
				ceiling.global_position.y = ground.global_position.y - 144
			
			player_cam.global_position.y = ground.global_position.y - 72
	else:
		if gamemode in ["cube"]:
			ground.global_position = Vector2(3500, 0)
			ceiling.global_position = Vector2(3500, 1000)
		elif gamemode in ["ship"]:
			ceiling.visible = true
			
			ground.global_position.y = 0
			ceiling.global_position.y = ground.global_position.y - 176
		elif gamemode in ["ball"]:
			ceiling.visible = true
			
			ground.global_position.y = 0
			ceiling.global_position.y = ground.global_position.y - 112

func _process(delta):
	
	if obtain_endpos:
		get_endpos()
		obtain_endpos = false
	
	if first_attempt:
		if player.global_position.x >= player_cam.global_position.x:
			first_attempt = false
			follow_cam = true
	
	if follow_cam:
		GameProgress.run_music = true
		player_cam.global_position.x = player.global_position.x
		player_cam.position_smoothing_enabled = true
		
		endpos.global_position.y = player_cam.global_position.y
		
		if player.gamemode in ["cube"]:
			player_cam.global_position.y = player.global_position.y - 16
	
	GameProgress.update_bar((player.global_position.x / endpos.global_position.x) * 100)
	
	if Input.is_action_just_pressed("ui_cancel") and not is_finishing():
		get_tree().paused = !get_tree().paused
	
	if is_finishing():
		follow_cam = false
		player.gravity = 10
		player.velocity.y = -50
		player.speed += 5
	
	if (player.global_position.x / endpos.global_position.x) * 100 >= 100 and not level_ended:
		level_ended = true
		end_level()

func is_finishing() -> bool:
	return player.global_position.x >= rect_x + 152

func exit_level():
	GameProgress.in_game = false
	GameProgress.music_to_load = 0
	GameProgress.stop_lvl_music()
	MenuMusic.start_music()
	TransitionScene.change_scene("res://Scenes/Menus/SavedTab.tscn")

func end_level():
	GameProgress.check_progress(100)
	
	end_particles.global_position = player.global_position
	end_animation.play("end_anim")
	
	player_cam.position_smoothing_enabled = false

func restart():
	GameProgress.stop_lvl_music()
	get_tree().paused = false
	EditorTransition.load_game(level_data, true)

func change_background(new_colour, fade_time):
	
	end_bg_tweens()
	
	if fade_time > 0:
		var tween = get_tree().create_tween()
		tween.set_meta("trigger", "bg")
		tween.tween_property($Universal/BG/BGLayer/BGSprite, "modulate", new_colour, fade_time)
	else:
		$Universal/BG/BGLayer/BGSprite.modulate = new_colour

func end_bg_tweens():
	for tween in get_tree().get_processed_tweens():
		if tween.get_meta("trigger", "bg"):
			tween.stop()
