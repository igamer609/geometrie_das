# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends AnimatedTextureButton

signal selected_icon

@export_enum("Cube", "Ship", "Ball") var gamemode : int
@export var id : int

func _ready():
	super()
	texture_normal.region = Rect2(id * 16, 0, 16, 16)
	connect("pressed", change_icon)

func change_icon():
	PlayerData.set_icon(gamemode, id)
	emit_signal("selected_icon", gamemode, id)
	PlayerData.save()
