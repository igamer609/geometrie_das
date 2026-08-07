# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Control

@export var ok : Button

func _ready() -> void:
	ok.pressed.connect(_exit)

func _exit() -> void:
	queue_free()
