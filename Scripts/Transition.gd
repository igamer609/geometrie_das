# ----------------------------------------------------------
#	Copyright (c) 2026 igamer609
#	Licensed under the MIT License.
#	See the LICENSE file in the project root for full license information
# ----------------------------------------------------------

extends CanvasLayer

func change_scene(scene_path):
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(scene_path)
	
	if get_tree().paused:
		get_tree().paused = false
	
	$AnimationPlayer.play_backwards("fade")
