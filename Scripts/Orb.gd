# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Area2D

@export_enum("pink", "yellow", "blue", "green") var jump_type : int

func _ready() -> void:
	var ring : GPUParticles2D = $Ring
	ring.connect("finished", ring.hide)

func player_enter():
	var ring : GPUParticles2D = $Ring
	ring.visible = true
	ring.emitting = true

func activate() -> void:
	var orb_sprite : Sprite2D = $Sprite
	
	var tween : Tween = create_tween().bind_node(self)
	tween.set_meta("scope", 3)
	orb_sprite.set_instance_shader_parameter("flash_intensity", 1.0)
	tween.tween_property(orb_sprite, "scale", Vector2(1.2, 1.2), 0.065).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(orb_sprite, "instance_shader_parameters/flash_intensity", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(orb_sprite, "scale", Vector2(0.8, 0.8), 0.1).set_trans(Tween.TRANS_LINEAR)
