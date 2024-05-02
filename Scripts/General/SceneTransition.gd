extends CanvasLayer

@onready var editor = "res://Objects/Editor.tscn"

func get_editor_root():
	var root = get_tree().root
	var editor_root = null
	
	for roots in root.get_children():
		if roots.name == "Editor":
			editor_root = roots
	
	return editor_root

func wait(seconds):
	var timer = Timer.new()
	add_child(timer)
	timer.start(seconds)
	
	await timer.timeout
	
	return true

func load_editor(level_info):
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(editor)
	
	await wait(2)
	var root = get_editor_root()
	await root.load_level_from_info(level_info)
	$AnimationPlayer.play_backwards("fade")
