# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name Trigger extends Area2D

@export var trigger_id : int = 0
@export var target_id : int = 0
@export var enabled = true

var _in_editor : bool
var trigger_shape 

static func create_trigger(trig_id : int, trig_info : Dictionary, in_editor : bool = false) -> Trigger:
	match trig_id :
		1: return ColorTrigger.create_color_trigger(trig_info, in_editor);
		_: return null

static func get_default_info(trig_id : int) -> Dictionary:
	match trig_id:
		1: return ColorTrigger.default_info();
		_: return {"id": 0}

func _ready() -> void:
	_create_collision()
	body_entered.connect(_on_body_entered)

func _create_collision() -> void:
	if not _in_editor:
		var collision_shape : CollisionShape2D = CollisionShape2D.new()
		var shape : SegmentShape2D = SegmentShape2D.new()
		shape.a = Vector2(0, 2000)
		shape.b = Vector2(0, -2000)
		collision_shape.shape = shape
		collision_mask = 1
		collision_layer = 4
		add_child(collision_shape)
		collision_shape.global_position.x = global_position.x + 8
	else:
		var preview_line : Line2D = Line2D.new()
		preview_line.add_point(Vector2(0, 2000))
		preview_line.add_point(Vector2(0, -2000))
		preview_line.default_color = Color(1, 1, 1, 0.75)
		preview_line.width = 0.5
		preview_line.z_index = -9
		add_child(preview_line)
		preview_line.global_position.x = global_position.x + 8

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
