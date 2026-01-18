extends Node2D

@export var start_bg : Color
@export var music_delay : float

@export var player_parent : Node
@export var ceiling : Node
@export var ground : Node
@export var tilemap : Node
@export var endpos : Node

@export var pause_ui : Node
@export var end_ui : Node

@export var end_particles : Node
@export var end_animation : Node

@export var death_particle : Node

var player = null
var player_cam = null

var rect_x = 0

var first_attempt = true
var follow_cam = false
var level_ended = false

func _ready():
	initiate()

func initiate():
	GameProgress.in_game = true
	GameProgress.run_music = true
	
	GameProgress.play_lvl_music_from_id(music_delay)
	
	for child in player_parent.get_children():
		if child.is_in_group("Player"):
			player = child
		if child.name == "Camera2D":
			player_cam = child
	
	if player:
		player.changed_gamemode.connect(on_gamemode_change)
		player.died.connect(player_died)
		player.respawned.connect(player_respawn)
	
	ground.global_position = Vector2(40, 0)
	
	if player_cam:
		player_cam.global_position.x = player.global_position.x + 200
		player_cam.global_position.y = player.global_position.y - 16
	
	if tilemap:
		var rect = tilemap.get_used_rect()
		
		var x_size = rect.size.x
		
		rect_x = x_size * 16
		
		endpos.global_position.x = rect_x + 304
	
	change_background(start_bg, 0)
	
	for trigger in $BG_triggers.get_children():
		trigger.bg_change.connect(change_background)

func player_died():
	follow_cam = false
	GameProgress.run_music = false
	
	GameProgress.stop_lvl_music()
	
	death_particle.global_position = player.global_position
	death_particle.emitting = true
	
	GameProgress.check_progress((player.global_position.x / endpos.global_position.x) * 100)

func player_respawn():
	GameProgress.play_lvl_music_from_id(music_delay)
	
	for trigger in $BG_triggers.get_children():
		trigger.enabled = true
	
	end_tweens()
	
	change_background(start_bg, 0)
	
	end_animation.play("RESET")
	player_cam.position_smoothing_enabled = false
	player.velocity = Vector2.ZERO
	player.gravity = player.CUBE_GRAVITY
	
	player.global_position.x = 0
	player.global_position.y = -8
	
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
			
			ground.global_position = Vector2(player.global_position.x + 3500, portal.global_position.y + 88)
			ceiling.global_position = Vector2(player.global_position.x + 3500, portal.global_position.y - 88)
			
			
			if ground.global_position.y > 0:
				ground.global_position.y = 0
				ceiling.global_position.y = ground.global_position.y - 176
			
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
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = !get_tree().paused
	
	if player.global_position.x >= rect_x + 152:
		follow_cam = false
		player.gravity = 10
		player.velocity.y = -50
		player.speed += 5
	
	if (player.global_position.x / endpos.global_position.x) * 100 >= 100 and not level_ended:
		level_ended = true
		end_level()

func exit_level():
	GameProgress.in_game = false
	GameProgress.run_music = false
	
	GameProgress.music_to_load = 0

	MenuMusic.start_music()
	
	TransitionScene.change_scene("res://Scenes/MainMenu.tscn")

func end_level():
	GameProgress.check_progress(100)
	
	end_particles.global_position = player.global_position
	end_animation.play("end_anim")
	
	player_cam.position_smoothing_enabled = false

func restart():
	GameProgress.run_music = false
	get_tree().reload_current_scene()

func change_background(new_colour, fade_time):
	
	end_tweens()
	
	if fade_time > 0:
		var tween = get_tree().create_tween()
		tween.tween_property($Universal/BG/BGLayer/BGSprite, "modulate", new_colour, fade_time)
	else:
		$Universal/BG/BGLayer/BGSprite.modulate = new_colour

func end_tweens():
	for tween in get_tree().get_processed_tweens():
		tween.stop()
