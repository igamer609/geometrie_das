# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Area2D

@export_enum("pink", "yellow", "blue", "green") var jump_type : int

func player_enter():
	$AnimationPlayer.play("player_enter")

func jump_activate():
	$AnimationPlayer.play("activate")
