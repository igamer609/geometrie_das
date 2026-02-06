# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

class_name EndEffects
extends Node2D

func activate_end_anim() -> void:
	$Animation.play("EndEffects")

func sync_to_pos(new_pos : Vector2) -> void:
	self.global_position = new_pos
