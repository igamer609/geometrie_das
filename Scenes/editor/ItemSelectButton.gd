# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Button

signal select_item(item_id : int)

@export var id : int

@onready var sprite = $Sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pressed.connect(send_select)
	
	if sprite:
		
		var item = load("res://Objects/obj_ids/" + str(id) + ".tres")
		
		if item:
			sprite.texture = item.texture

func send_select():
	if button_pressed:
		print("selected item with id " + str(id))
		emit_signal("select_item", id)
	else:
		print("deselected item")
		emit_signal("select_item", 0)
