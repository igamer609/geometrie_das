# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Area2D

@export_enum("pink", "yellow", "blue") var jump_type : int

func activate() -> void:
	var tween : Tween = create_tween().bind_node(self)
	tween.set_meta("scope", 3)
	$Sprite.set_instance_shader_parameter("flash_intensity", 1.0)
	tween.tween_property($Sprite, "instance_shader_parameters/flash_intensity", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
