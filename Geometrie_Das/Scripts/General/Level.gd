extends Node2D

@export_node_path var player_parent_path
@export_node_path var ground_path
@export_node_path var ceiling_path
@export_node_path var tilemap_path
@export_node_path var endpos_path

var player_parent = null
var ceiling = null
var ground = null
var tilemap = null

var endpos = null
@onready var pause_ui = $Universal/PauseUI

var player = null
var player_cam = null

var first_attempt = true
var follow_cam = false

func _ready():
	
	player_parent = get_node(player_parent_path)
	ground = get_node(ground_path)
	ceiling = get_node(ceiling_path)
	tilemap = get_node(tilemap_path)
	endpos = get_node(endpos_path)
	
	initiate()

func initiate():
	GameProgress.in_game = true
	
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
		
		endpos.global_position.x = (x_size * 16) + 256
		
		print(endpos.global_position)

func player_died():
	follow_cam = false
	
	GameProgress.check_progress((player.global_position.x / endpos.global_position.x) * 100)

func player_respawn():
	player_cam.position_smoothing_enabled = false
	player.global_position.x = 0
	player.global_position.y = 9
	player_cam.global_position = Vector2(player.global_position.x, player.global_position.y - 16)
	follow_cam = true

func on_gamemode_change(portal, gamemode):
	
	if portal:
		if gamemode in ["ship"]:
			ceiling.visible = true
			
			ground.global_position = Vector2(player.global_position.x + 3500, portal.global_position.y + 88)
			ceiling.global_position = Vector2(player.global_position.x + 3500, portal.global_position.y - 88)
			
			
			if ground.global_position.y > 0:
				ground.global_position.y = 0
				ceiling.global_position.y = ground.global_position.y - 176
				
			
			player_cam.global_position.y = ground.global_position.y - 88
		elif gamemode in ["cube"]:
			ceiling.visible = false
			
			ground.global_position = Vector2(player.global_position.x + 3500, 0)
			ceiling.global_position = Vector2(player.global_position.x + 3500, 1000)
	else:
		if gamemode in ["ship"]:
			ceiling.visible = true
			
			ground.global_position.y = 0
			ceiling.global_position.y = ground.global_position.y - 176
		elif gamemode in ["cube"]:
			ground.global_position = Vector2(3500, 0)
			ceiling.global_position = Vector2(3500, 1000)

func _process(delta):
	if first_attempt:
		if player.global_position.x >= player_cam.global_position.x:
			first_attempt = false
			follow_cam = true
	
	if follow_cam:
		player_cam.position_smoothing_enabled = true
		player_cam.global_position.x = player.global_position.x
		
		if player.gamemode in ["cube"]:
			player_cam.global_position.y = player.global_position.y - 16
	
	GameProgress.update_bar((player.global_position.x / endpos.global_position.x) * 100)
	
	

func exit_level():
	GameProgress.in_game = false
	TransitionScene.change_scene("res://Scenes/Menus/LevelMenu.tscn")
