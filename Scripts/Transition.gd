extends CanvasLayer


func change_scene(scene_path):
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(scene_path)
	
	if get_tree().paused:
		get_tree().paused = false
	
	$AnimationPlayer.play_backwards("fade")
