class_name ColorManager extends Resource

const max_channels : int = 16

const main_channels : Dictionary = {
	0: "BG",
	1: "OBJ",
	2: "LINE",
	3: "G1"
}

func _ready() -> void:
	
	var image : Image = Image.create_empty(max_channels, 1, false, Image.FORMAT_ETC2_RGB8)
	var texture : ImageTexture = ImageTexture.create_from_image(image)
	RenderingServer.global_shader_parameter_add("color_texture", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, texture)

func change_color_channel(channel_id, target_color : Color, trans_time : float = 0, ease_type : Tween.EaseType = Tween.EaseType.EASE_IN, trans_type : Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR) -> void:
	pass
