# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name HoldActionTextureButton
extends AnimatedTextureButton

##Fired when the button is held for more or equal than the [code]hold_time[/code] value.
signal button_held
##Fired when the button is released before the timer finishes
signal button_pressed_no_hold 

##Time in seconds to be held to send the [code]button_held[/code] signal
@export var hold_time = 0.25

var _timer : Timer

func _ready() -> void:
	super()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.ignore_time_scale = true
	add_child(_timer)
	
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down() -> void:
	_timer.start(hold_time)

func _on_button_up() -> void:
	if(_timer.time_left == 0):
		button_held.emit()
	elif(_timer.time_left >= 0):
		button_pressed_no_hold.emit()
