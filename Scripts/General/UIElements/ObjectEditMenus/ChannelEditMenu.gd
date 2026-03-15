# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

@export var channel_id : int
@export var color_picker : ColorPicker
@export var current_color_rect : ColorRect
@export var previous_color_rect : ColorRect
@export var ok_button : AnimatedButton

func _ready() -> void:
	var color : Color = ColorManager.get_color_channel(channel_id)
	color_picker.color = color; current_color_rect.color = color; previous_color_rect.color = color
	color_picker.color_changed.connect(_update_color)
	ok_button.pressed.connect(self.queue_free)

func _update_color(new_color : Color) -> void:
	ColorManager.change_color_channel(channel_id, new_color)
	current_color_rect.color = new_color
