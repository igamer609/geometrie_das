class_name GDColorButton extends Control

signal color_pressed(channel_id, channel_name)

@export var channel_id : int
@export var channel_name : String
@export var selected : bool
@export var selectable : bool
@export var button_group : ButtonGroup

@onready var button : AnimatedTextureButton = $Button
@onready var label : Label = $Button/Label
@onready var selection_rect : TextureRect = $SelectionRect

func _ready() -> void:
	if(button_group):
		button.button_group = button_group
		button_group.pressed.connect(_update_selection)
	
	button.self_modulate = ColorManager.get_color_channel(channel_id)
	
	if(channel_name):
		label.text = channel_name
	else:
		label.text = str(channel_id - ColorManager.MAIN_CHANNELS.size() + 1)

func _update_selection(pressed_button : AnimatedTextureButton) -> void:
	if(pressed_button == button):
		color_pressed.emit(channel_id, channel_name)
		selection_rect.visible = true
	else:
		selection_rect.visible = false

func _update() -> void:
	button.self_modulate = ColorManager.get_color_channel(channel_id)
