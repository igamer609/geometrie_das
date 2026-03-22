# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

signal channel_selected(new_channel : int)

@export var special_channel_container : GridContainer
@export var normal_channel_container : GridContainer
@export var ok_button : AnimatedButton

var target_triggers : Array[GDObject] = []
var current_channel : int = -1
var current_channel_button : GDChannelButton
var button_group : ButtonGroup

func _ready() -> void:
	button_group = ButtonGroup.new()
	
	for channel : GDChannelButton in special_channel_container.get_children():
		channel.button_group = button_group
		channel.update_button_group()
		if(channel.channel_id == current_channel):
			current_channel_button = channel
	
	for channel : GDChannelButton in normal_channel_container.get_children():
		channel.button_group = button_group
		channel.update_button_group()
		if(channel.channel_id == current_channel):
			current_channel_button = channel
	
	button_group.pressed.connect(_channel_selected)
	ok_button.pressed.connect(self.queue_free)

func _channel_selected(color_button : GDColorButton) -> void:
	current_channel_button = color_button.channel_button
	current_channel = current_channel_button.channel_id
	
	for object : GDObject in target_triggers:
		if(object.trigger):
			if(object.trigger.trigger_id in Trigger.COLOR):
				object.trigger.target_id = current_channel
	
	channel_selected.emit(current_channel)
