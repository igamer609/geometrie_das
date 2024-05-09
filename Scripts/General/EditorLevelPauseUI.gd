extends CanvasLayer

func _process(delta):
	if get_tree().paused:
		visible = true
	else:
		visible = false
