# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

@export var special_channel_container : GridContainer
@export var normal_channel_container : GridContainer
@export var selected_color_button : GDChannelButton
@export var default_channel_button : GDChannelButton
@export var selected_channel_label : Label
@export var ok_button : AnimatedButton

var target_objects : Array[GDObject]
var current_channel : int = -1
var current_channel_button : GDChannelButton
var button_group : ButtonGroup

func _ready() -> void:
	
	if(target_objects):
		if(target_objects.size() == 1):
			current_channel = target_objects[0].color_channel
		else:
			var is_same_channel : bool = true
			var first_channel : int = target_objects[0].color_channel
			
			for object : GDObject in target_objects:
				if object.color_channel !=first_channel:
					is_same_channel = false
					break
			
			if(is_same_channel):
				current_channel = first_channel
			else:
				current_channel = -1
	
	button_group = ButtonGroup.new()
	
	for channel : GDChannelButton in special_channel_container.get_children():
		if(channel.name != "DefaultChannel"):
			channel.button_group = button_group
			channel.update_button_group()
			if(channel.channel_id == current_channel):
				current_channel_button = channel
	
	for channel : GDChannelButton in normal_channel_container.get_children():
		channel.button_group = button_group
		channel.update_button_group()
		if(channel.channel_id == current_channel):
			current_channel_button = channel
	
	_update_selected_channel()
	button_group.pressed.connect(_channel_selected)
	selected_color_button.button.pressed.connect(_open_channel_edit)
	default_channel_button.button.pressed.connect(_reset_channels)
	ok_button.pressed.connect(self.queue_free)

func _open_channel_edit() -> void:
	var channel_edit_menu : Control = ResourceLibrary.scenes["ChannelEditMenu"].instantiate()
	channel_edit_menu.channel_id = current_channel
	add_child(channel_edit_menu) 

func _reset_channels() -> void:
	if(target_objects):
		for object : GDObject in target_objects:
			object.color_channel = object.obj_res.default_channel
			object.update_color_channel()
		
		if(target_objects.size() == 1):
			current_channel = target_objects[0].color_channel
		else:
			var is_same_channel : bool = true
			var first_channel : int = target_objects[0].color_channel
			for object : GDObject in target_objects:
				if object.color_channel !=first_channel:
					is_same_channel = false
					break
			
			if(is_same_channel):
				current_channel = first_channel
			else:
				current_channel = -1
	
	_update_selected_channel()

func _channel_selected(color_button : GDColorButton) -> void:
	current_channel_button = color_button.channel_button
	current_channel = current_channel_button.channel_id
	
	for object : GDObject in target_objects:
		object.color_channel = current_channel
		object.update_color_channel()
	
	_update_selected_channel()

func _update_selected_channel() -> void:
	if(current_channel >= 0):
		selected_channel_label.show()
		if(current_channel_button.editable):
			selected_color_button.show()
			selected_color_button.channel_id = current_channel
			selected_color_button.update_channel()
		else:
			selected_color_button.hide()
		
		if(current_channel <= ColorManager.MAIN_CHANNELS.size() - 1):
			selected_channel_label.text = ColorManager.MAIN_CHANNELS.find_key(current_channel)
		else:
			selected_channel_label.text = str(current_channel - ColorManager.MAIN_CHANNELS.size() + 1)
	else:
		selected_color_button.hide(); selected_channel_label.hide()
