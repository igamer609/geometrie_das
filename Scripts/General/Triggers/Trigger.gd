# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name Trigger extends Area2D

@export var trigger_id : int = 0
@export var target_id : int = 0
@export var enabled = true

var trigger_shape 

static func create_trigger(trig_id : int, trig_info : Dictionary) -> Trigger:
	match trig_id :
		1: return ColorTrigger.create_color_trigger(trig_info);
		_: return null

func _ready() -> void:
	_create_collision()
	body_entered.connect(_on_body_entered)

func _create_collision() -> void:
	var collision_shape : CollisionShape2D = CollisionShape2D.new()
	var shape : SegmentShape2D = SegmentShape2D.new()
	shape.a = Vector2(global_position.x, 2000)
	shape.b = Vector2(global_position.x, -2000)
	collision_shape.shape = shape
	collision_mask = 1
	collision_layer = 4
	add_child(collision_shape)

func _on_body_entered(body):
	if body.is_in_group("Player") and enabled:
		_activate()
		enabled = false

func _activate() -> void:
	pass

func get_info() -> Dictionary:
	return {
		"id" : trigger_id,
		"target" : target_id,
	}
