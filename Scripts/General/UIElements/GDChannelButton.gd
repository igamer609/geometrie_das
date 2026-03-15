# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name GDChannelButton extends Control

signal color_pressed(channel_id, channel_name)

@export var channel_id : int
@export var channel_name : String
@export var selected : bool
@export var selectable : bool = true
@export var editable : bool = true
@export var button_group : ButtonGroup

@onready var button : GDColorButton = $Button
@onready var label : Label = $Button/Label
@onready var selection_rect : TextureRect = $SelectionRect

func _ready() -> void:
	update_button_group()
	
	button.self_modulate = ColorManager.get_color_channel(channel_id)
	button.channel_button = self
	ColorManager.channel_changed.connect(_update_color)
	
	if(channel_name):
		label.text = channel_name
	else:
		label.text = str(channel_id - ColorManager.MAIN_CHANNELS.size() + 1)

func _update_color(updated_channel_id, new_color : Color) -> void:
	if(updated_channel_id == channel_id):
		button.self_modulate = new_color

func _update_selection(pressed_button : GDColorButton) -> void:
	if(pressed_button == button):
		color_pressed.emit(channel_id, channel_name)
		selection_rect.visible = true
	else:
		selection_rect.visible = false

func update_button_group() -> void:
	if(button_group && button.button_group == null):
		button.button_group = button_group
		button_group.pressed.connect(_update_selection)

func update_channel() -> void:
	button.self_modulate = ColorManager.get_color_channel(channel_id)
	
	if(channel_name):
		label.text = channel_name
	else:
		label.text = str(channel_id - ColorManager.MAIN_CHANNELS.size() + 1)
