extends Camera2D

@export_node_path var player_node

var Ground_group = null
var Ground = null
var Ceiling = null

var player = null

var camera_mode = "normal"

func _ready():
	player = get_node(player_node)

func _process(delta):
	position.x = player.position.x
	
	if camera_mode == "normal":
		position.y = player.position.y

func _on_player_change_gamemode(last_portal, mode):
	if mode:
		if mode == "cube":
			camera_mode = "normal"
		elif mode == "ship":
			camera_mode = "static_y"
