# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends Node

signal portal_preview_toggled(toggled : bool)

@export var ok_button : AnimatedButton
@export var preview_check_button : CheckBox

var target_objects : Array[GDObject]

func _ready() -> void:
	ok_button.pressed.connect(self.queue_free)
	preview_check_button.toggled.connect(_on_preview_toggled)

func _on_preview_toggled(toggled : bool) -> void:
	
	for object : GDObject in target_objects:
		object.other.set("portal_preview", toggled)
	
	portal_preview_toggled.emit(toggled)
	
