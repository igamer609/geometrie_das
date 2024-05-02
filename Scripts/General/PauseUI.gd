extends CanvasLayer

var level_names = {
	"0" : "Glorious Morning",
	"1" : "yStep"
}

func _ready():
	$Control/Rect/LevelName.text = level_names[str(GameProgress.current_level)]

func _process(delta):
	if get_tree().paused:
		visible = true
		$Control/Rect/Progress.value = GameProgress.current_level_progress
		$Control/Rect/Practice.value = GameProgress.current_level_practice
	else:
		visible = false
