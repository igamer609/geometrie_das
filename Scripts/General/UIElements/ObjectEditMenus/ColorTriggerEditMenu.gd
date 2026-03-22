# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

@export var channel_id : int
@export var color_picker : ColorPicker
@export var current_color : ColorRect
@export var previous_color : Button
@export var ok_button : AnimatedButton
@export var select_channel_button : AnimatedButton
@export var fade_time_prop : GDPropertySlider

var target_triggers : Array[GDObject] = []
var current_channel : int = 1

func _ready() -> void:
	
	if(target_triggers):
		var all_color_triggers : bool = true
		for object : GDObject in target_triggers:
			if(!(target_triggers[0].trigger && target_triggers[0].trigger.trigger_id in Trigger.COLOR)):
				all_color_triggers = false
				break
		
		if(all_color_triggers):
			if(target_triggers.size() == 1):
				current_channel = target_triggers[0].trigger.target_id
			else:
				var is_same_channel : bool = true
				var first_channel : int = target_triggers[0].trigger.target_id
				
				for object : GDObject in target_triggers:
					if object.trigger.target_id !=first_channel:
						is_same_channel = false
						break
				
				if(is_same_channel):
					current_channel = first_channel
				else:
					current_channel = 1
			
			fade_time_prop.set_value(target_triggers[0].trigger.fade_time)
	
	var color : Color = target_triggers[0].trigger.target_color
	
	color_picker.color = color; current_color.color = color; previous_color.self_modulate = color
	previous_color.pressed.connect(_update_color.bind(previous_color.self_modulate))
	color_picker.color_changed.connect(_update_color)
	fade_time_prop.value_changed.connect(_update_fade_time)
	select_channel_button.pressed.connect(_open_channel_select)
	ok_button.pressed.connect(self.queue_free)

func _update_color(new_color : Color) -> void:
	
	for object : GDObject in target_triggers:
		if(object.trigger):
			if(object.trigger.trigger_id in Trigger.COLOR):
				object.trigger.target_color = new_color
	
	current_color.color = new_color

func _open_channel_select() -> void:
	var channel_select_menu : Control = ResourceLibrary.scenes["ChannelSelect"].instantiate()
	channel_select_menu.target_triggers = target_triggers
	channel_select_menu.current_channel = current_channel
	channel_select_menu.channel_selected.connect(_channel_selected)
	add_child(channel_select_menu)

func _channel_selected(new_channel : int) -> void:
	current_channel = new_channel
	
	for object : GDObject in target_triggers:
		if(object.trigger):
			if(object.trigger.trigger_id in Trigger.COLOR):
				object.trigger.target_id = new_channel
	
	if(new_channel < ColorManager.MAIN_CHANNELS.size()):
		select_channel_button.text = ColorManager.MAIN_CHANNELS.find_key(new_channel)
	else:
		select_channel_button.text = str(new_channel - ColorManager.MAIN_CHANNELS.size() + 1)

func _update_fade_time(fade_time : float) -> void:
	for object : GDObject in target_triggers:
		if(object.trigger):
			if(object.trigger.trigger_id in Trigger.COLOR):
				object.trigger.fade_time = fade_time
