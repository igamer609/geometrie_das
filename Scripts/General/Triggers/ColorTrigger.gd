# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name ColorTrigger extends Trigger

@export var target_color : Color
@export var fade_time : float

static func create_color_trigger(trigger_info : Dictionary) -> ColorTrigger:
	
	var trigger : ColorTrigger = ColorTrigger.new()
	trigger.trigger_id = 1
	trigger.target_id = trigger_info.get("target_id")
	trigger.target_color = trigger_info.get("target_color", Color.WHITE)
	trigger.fade_time = trigger_info.get("fade_time", 0.0)
	
	return trigger

func _activate() -> void:
	pass

func get_info() -> Dictionary:
	return {
		"id" : trigger_id,
		"target_id" : target_id,
		"target_color" : target_color,
		"fade_time" : fade_time
	}
