# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Area2D

signal bg_change(color, fade)

@export var color : Color
@export var fade_time : float

var enabled = true



func _on_body_entered(body):
	if body.is_in_group("Player") and enabled:
		emit_signal("bg_change", color, fade_time)
		enabled = false
