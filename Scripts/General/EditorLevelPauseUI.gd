# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends CanvasLayer

#to be replaced by more efficient methods

func _process(delta) -> void:
	if get_tree().paused:
		visible = true
	else:
		visible = false
