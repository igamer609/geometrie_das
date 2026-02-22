# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Button

signal select_item(item_id : int)

@export var id : int
@onready var sprite = $Sprite

func _ready():
	pressed.connect(send_select)
	if sprite:
		var item = load("res://Objects/obj_ids/" + str(id) + ".tres")
		if item:
			sprite.texture = item.texture

func send_select():
	if button_pressed:
		emit_signal("select_item", id)
	else:
		emit_signal("select_item", 0)
