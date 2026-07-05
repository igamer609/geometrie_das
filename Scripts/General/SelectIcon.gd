# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends AnimatedTextureButton

signal selected_icon

@onready var cube_icon_atlas = preload("res://Assets/cube32.png")
@onready var ball_icon_atlas = preload("res://Assets/ball32.png")

@export_enum("Cube", "Ship", "Ball") var gamemode : int
@export var id : int

func _ready():
	super()
	var new_texture : AtlasTexture = AtlasTexture.new()
	match gamemode:
		0: new_texture.atlas = cube_icon_atlas
		2: new_texture.atlas = ball_icon_atlas
	new_texture.region = Rect2(id * 32, 0, 32, 32)
	texture_normal = new_texture
	connect("pressed", change_icon)

func change_icon():
	PlayerData.set_icon(gamemode, id)
	emit_signal("selected_icon", gamemode, id)
	PlayerData.save()
