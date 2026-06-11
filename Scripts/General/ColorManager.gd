# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node

signal channel_changed(channel_id : int, new_color : Color)

const max_channels : int = 21
const MAIN_CHANNELS : Dictionary = {
	"BG" : 0,
	"OBJ" : 1,
	"G" : 2,
	"LINE" : 3,
	"LBG" : 4,
}
const ON_LOAD_IGNORED_CHANNELS : Array[int] = [
	4,
]

var pallete_image : Image
var pallete_texture : ImageTexture
var _texture_update_queued : bool = false

##Defines if the respective channel copies another channel, and if it has any transformations applied to it.
var relationships : Array[Array] = [
	[0, 4, Color(3.5, 3.5, 3.5, 0.90)]
]

func _ready() -> void:
	pallete_image = Image.create_empty(max_channels, 1, false, Image.FORMAT_RGBA8)
	for index in range(0, max_channels - 1):
		pallete_image.set_pixel(index, 0, Color.WHITE)
	pallete_texture = ImageTexture.create_from_image(pallete_image)
	RenderingServer.global_shader_parameter_set("color_texture", pallete_texture)

func _end_current_tweens(channel_id) -> void:
	for prev_tween : Tween in get_tree().get_processed_tweens():
		if prev_tween.has_meta("channel_id"):
			if prev_tween.get_meta("channel_id") == channel_id:
				prev_tween.kill()

func _end_all_tweens() -> void:
	for i in range(0, max_channels - 1):
		_end_current_tweens(i)

func load_palette(palette : GDColorPalette) -> void:
	_end_all_tweens()
	for i in range(0, palette.length - 1):
		if(i not in ON_LOAD_IGNORED_CHANNELS):
			change_color_channel(i, palette.color_palette[i])

func change_color_channel(channel_id, target_color : Color) -> void:
	var index : int
	
	if channel_id is String:
		index = MAIN_CHANNELS[channel_id]
	else:
		index = channel_id
	
	for relationship : Array in relationships:
		if(relationship[0] == index):
			var relative_color : Color = target_color * relationship[2]
			pallete_image.set_pixel(relationship[1], 0, relative_color)
			channel_changed.emit(relationship[1], relative_color)
	
	pallete_image.set_pixel(index, 0, target_color)
	channel_changed.emit(index, target_color)
	_texture_update_queued = true

func get_color_channel(channel_id) -> Color:
	var index : int
	
	if channel_id is String:
		index = MAIN_CHANNELS[channel_id]
	else:
		index = channel_id
	
	var pallete_color : Color = pallete_image.get_pixel(index, 0)
	return pallete_color

func _process(_delta: float) -> void:
	if _texture_update_queued:
		pallete_texture.update(pallete_image)

func fade_color(channel_id, final_color : Color, fade_time : float = 0) -> void:
	
	_end_current_tweens(channel_id)
	
	if fade_time <= 0:
		change_color_channel(channel_id, final_color)
		return
	
	var tween : Tween = create_tween()
	tween.set_meta("channel_id", channel_id)
	var initial_color : Color = get_color_channel(channel_id)
	
	tween.tween_method(
		func(c : Color): change_color_channel(channel_id, c),
		initial_color, final_color, fade_time
	).set_trans(Tween.TRANS_LINEAR)

func pulse_color(channel_id, final_color : Color, fade_in : float, fade_out: float, hold : float) -> void:
	
	_end_current_tweens(channel_id)
	
	var initial_color : Color = get_color_channel(channel_id)
	var tween : Tween = create_tween()
	
	tween.tween_method(
		func(c : Color): change_color_channel(channel_id, c),
		initial_color, final_color, fade_in
	).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_interval(hold)
	
	tween.tween_method(
		func(c : Color): change_color_channel(channel_id, c),
		final_color, initial_color, fade_out
	).set_trans(Tween.TRANS_LINEAR)
