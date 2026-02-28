# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node

const max_channels : int = 20

var pallete_image : Image
var pallete_texture : ImageTexture

var _texture_update_queued : bool = false

const MAIN_CHANNELS : Dictionary = {
	"BG" : 0,
	"OBJ" : 1,
	"G" : 2,
	"LINE" : 3
}

func _ready() -> void:
	pallete_image = Image.create_empty(max_channels, 1, false, Image.FORMAT_RGB8)
	for index in range(0, max_channels - 1):
		pallete_image.set_pixel(index, 0, Color.WHITE)
	pallete_texture = ImageTexture.create_from_image(pallete_image)
	RenderingServer.global_shader_parameter_set("color_texture", pallete_texture)

func _end_current_tweens(channel_id) -> void:
	for prev_tween : Tween in get_tree().get_processed_tweens():
		if prev_tween.has_meta("channel_id"):
			if prev_tween.get_meta("channel_id") == channel_id:
				prev_tween.kill()

func change_color_channel(channel_id, target_color : Color) -> void:
	var index : int
	
	if channel_id is String:
		index = MAIN_CHANNELS[channel_id]
	else:
		index = channel_id
	
	pallete_image.set_pixel(index, 0, target_color)
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
