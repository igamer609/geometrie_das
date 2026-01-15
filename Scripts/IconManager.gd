extends Node

@export var cube_id = 0
@export var ship_id = 0
@export var ball_id = 0

func _ready():
	load_ids()

func save_ids():
	var save_data = {
		"cube_id" : cube_id,
		"ship_id" : ship_id,
		"ball_id" : ball_id,
		
	}
	
	var save_file = FileAccess.open("user://iconsave.save", FileAccess.WRITE)
	var json_string = JSON.stringify(save_data)
	
	save_file.store_string(json_string)

func load_ids():
	if not FileAccess.file_exists("user://iconsave.save"):
		return
	else:
		var save_file = FileAccess.open("user://iconsave.save", FileAccess.READ)
	
		var json_string = save_file.get_line()
		var parsed_data = JSON.parse_string(json_string)
	
		for item in parsed_data:
			if item == "cube_id":
				cube_id = parsed_data[item]
			elif item == "ship_id":
				ship_id = parsed_data[item]
			elif item == "ball_id":
				ball_id = parsed_data[item]
