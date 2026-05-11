# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609 and Contributors
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends CanvasLayer

var level_names = {
	"1" : "Glorious Morning",
	"2" : "yStep"
}

func _ready():
	$Control/Rect/LevelName.text = level_names[str(GameProgress.current_level_id)]

func _process(delta):
	if get_tree().paused:
		visible = true
		if Input.is_action_just_pressed("ui_cancel"):
			
			var progress : LevelProgress = GameProgress.get_current_level_progress()
			
			$Control/Rect/Progress.value = progress.normal_progress
			$Control/Rect/Practice.value = progress.practice_progress
	else:
		visible = false
