extends CanvasLayer

@onready var editor = "res://Objects/Editor.tscn"
@onready var template_level = "res://Scenes/Levels/CustomLevel.tscn"

func get_editor_root():
	var root = get_tree().root
	var editor_root = null
	
	for roots in root.get_children():
		if roots.name == "Editor":
			editor_root = roots
	
	return editor_root

func get_level_root():
	var root = get_tree().root
	var level_root = null
	
	for roots in root.get_children():
		if roots.name == "LevelRoot":
			level_root = roots
	
	return level_root

func wait(seconds):
	var timer = Timer.new()
	add_child(timer)
	timer.start(seconds)
	
	await timer.timeout
	
	return true

func load_editor(level_info):
	print(level_info)
	
	$AnimationPlayer.play("fade")
	await $AnimationPlayer.animation_finished
	
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(editor)
	
	await get_tree().tree_changed
	
	var root = get_editor_root()
	await root.load_level_from_info(level_info)
	$AnimationPlayer.play_backwards("fade")

func load_game(level_info, restart = false):
	if not restart:
		$AnimationPlayer.play("fade")
		await $AnimationPlayer.animation_finished
	
	MenuMusic.stop_music()
	get_tree().change_scene_to_file(template_level)
	
	await get_tree().tree_changed
	
	var root = get_level_root()
	
	root.load_level_data(level_info, restart)
	
	if not restart:
		$AnimationPlayer.play_backwards("fade")
