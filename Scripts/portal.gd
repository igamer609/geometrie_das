# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Area2D

@export_enum("gravity_down", "gravity_up", "cube", "ship", "ball") var portal_type
@export var back_texture_scale : Vector2
@export var back_texture : AtlasTexture

var back_sprite : Sprite2D

func _spawn_back_side() -> void:
	if(back_texture):
		back_sprite = Sprite2D.new()
		back_sprite.texture = back_texture
		back_sprite.scale = back_texture_scale
		back_sprite.position = Vector2(-4, 0)
		back_sprite.z_index = -2
		add_child(back_sprite)

func activate() -> void:
	var tween : Tween = create_tween().bind_node(self)
	tween.set_meta("scope", 3)
	$Sprite.set_instance_shader_parameter("flash_intensity", 0.7)
	tween.tween_property($Sprite, "instance_shader_parameters/flash_intensity", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
