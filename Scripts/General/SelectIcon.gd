extends TextureButton

signal selected_icon

@export_enum("Cube", "Ship", "Ball") var type
@export var id : int

func _ready():
	texture_normal.region = Rect2(id * 16, 0, 16, 16)
	
	connect("pressed", change_icon)

func change_icon():
	if type == 0:
		PlayerData.cube_id = id
	elif type == 1:
		PlayerData.ship_id = id
	elif type == 2:
		PlayerData.ball_id = id
	
	emit_signal("selected_icon", type, id)
	
	PlayerData.save()
