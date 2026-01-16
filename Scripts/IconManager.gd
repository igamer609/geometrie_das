extends Node

@export var cube_id : int = 0
@export var ship_id : int = 0
@export var ball_id : int = 0

var uid : int = 0
var progess : Array[Dictionary] = []

func _ready():
	load_save()

func save():
	var save_data = {
		"cube_id" : cube_id,
		"ship_id" : ship_id,
		"ball_id" : ball_id,
	}
	
	var save_file = FileAccess.open("user://playerdata.save", FileAccess.WRITE)
	var json_string = JSON.stringify(save_data)
	
	save_file.store_string(json_string)

func load_save():
	if not FileAccess.file_exists("user://playerdata.save"):
		return
	else:
		var save_file = FileAccess.open("user://playerdata.save", FileAccess.READ)
	
		var json_string = save_file.get_line()
		var parsed_data = JSON.parse_string(json_string)
		
		
			
		for item in parsed_data:
			if item == "cube_id":
				cube_id = parsed_data[item]
			elif item == "ship_id":
				ship_id = parsed_data[item]
			elif item == "ball_id":
				ball_id = parsed_data[item]
