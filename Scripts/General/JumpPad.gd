# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Area2D
@onready var anim_player : AnimationPlayer

@export_enum("pink", "yellow", "blue") var jump_type : int

func _ready() -> void:
	anim_player = find_child("AnimationPlayer")

func activate() -> void:
	if anim_player:
		anim_player.play("activate")
