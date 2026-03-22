# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name GDPropertySlider extends Control

signal value_changed(new_value : float)

@export var slider : Slider
@export var label : Label
@export var input : LineEdit

@export_category("Display")
@export var display_name : String = "Prop"
@export var min_value : int = 0
@export var max_value : int = 5
@export var step : float = 0.01

func _ready() -> void:
	slider.step = step; slider.max_value = max_value; slider.min_value = min_value 
	input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	input.max_length = 5; input.emoji_menu_enabled = false
	label.text = display_name + ":"
	
	slider.value_changed.connect(_slider_value_changed)
	input.text_changed.connect(_input_value_changed)

func _slider_value_changed(new_value : float) -> void:
	input.text = str(new_value)
	value_changed.emit(new_value)

func _input_value_changed(new_value : String) -> void:
	var final_value : float = float(new_value)
	slider.set_value_no_signal(final_value)
	value_changed.emit(final_value)

func set_value(new_value : float) -> void:
	slider.set_value_no_signal(new_value)
	input.text = str(new_value)
