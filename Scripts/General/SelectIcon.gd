extends TextureButton

signal selected_icon

@export_enum("Cube", "Ship", "Ball") var gamemode : int
@export var id : int

func _ready():
	texture_normal.region = Rect2(id * 16, 0, 16, 16)
	connect("pressed", change_icon)

func change_icon():
	PlayerData.set_icon(gamemode, id)
	emit_signal("selected_icon", gamemode, id)
	PlayerData.save()
